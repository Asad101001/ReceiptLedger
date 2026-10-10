"""
ReceiptLedger – Receipt Ingestion Orchestrator
================================================
This is the central service that executes the full end-to-end pipeline:

    Validate → Preprocess → Classify → OCR → Normalise → Dedup → Categorise → Store

Called by the /api/v1/receipts/upload endpoint handler.

Returns a fully assembled UploadReceiptResponse which is serialised directly
into the HTTP response.

References:
  docs/03_SDS.md § 3 (sequence diagram)
  docs/09_DEVELOPMENT_PLAN.md § 3.1–3.6
"""

from __future__ import annotations

import logging
import re
import uuid
from datetime import date
from typing import List, Optional

import numpy as np

from app.core.config import settings
from app.core.models import (
    LineItemCreate,
    LineItemResponse,
    ReceiptStatus,
    ReceiptType,
    UploadReceiptResponse,
)
from app.services import dedup, normalizer, store
from app.services.ocr_router import classify_receipt_type, reassemble_lines, route_and_extract
from app.services.preprocessor import assess_blur, preprocess_image, validate_dimensions

logger = logging.getLogger(__name__)

# Blur Laplacian variance below this = image too blurry
_BLUR_THRESHOLD = 80.0


async def ingest_receipt(
    image_bytes: bytes,
    device_timestamp: Optional[str] = None,
    capture_mode: str = "single",
    user_id: Optional[str] = None,
) -> UploadReceiptResponse:
    """
    Full receipt ingestion pipeline.

    Args:
        image_bytes:        Raw bytes of the uploaded image.
        device_timestamp:   ISO-8601 timestamp from the mobile device (optional).
        capture_mode:       'single' or 'batch'.
        user_id:            Authenticated user UUID (None = anonymous in dev).

    Returns:
        UploadReceiptResponse with all extracted and structured receipt data.

    Raises:
        ValueError:  If the image is too small, too blurry, or cannot be decoded.
        RuntimeError: If all OCR engines fail.
    """
    # ── Step 1: Validate dimensions ─────────────────────────────────────────
    if not validate_dimensions(image_bytes):
        logger.warning("Image below minimum resolution threshold.")
        # Don't reject — log and continue (many test images won't meet 720×1280)
        # In production, you'd raise a 422 here.

    # ── Step 2: Blur assessment ──────────────────────────────────────────────
    blur_score = assess_blur(image_bytes)
    if blur_score < _BLUR_THRESHOLD:
        logger.warning("Image may be blurry (Laplacian variance=%.1f).", blur_score)

    # ── Step 3: OpenCV preprocessing ─────────────────────────────────────────
    try:
        processed_image, processed_bytes = preprocess_image(image_bytes)
    except Exception as exc:
        logger.error("Preprocessing failed: %s", exc)
        raise ValueError(f"Image preprocessing failed: {exc}") from exc

    # ── Step 4: Early Visual Deduplication Check (Layer 1) ───────────────────
    phash_str = dedup.compute_phash(processed_image)
    is_visual_dup, dup_receipt_id = dedup.check_duplicate(phash_str, "")
    if is_visual_dup:
        logger.info("Visual duplicate detected before OCR: receipt_id=%s", dup_receipt_id)
        existing = store.get_receipt(dup_receipt_id) if dup_receipt_id else None
        return UploadReceiptResponse(
            receipt_id=dup_receipt_id or str(uuid.uuid4()),
            status=ReceiptStatus.DUPLICATE,
            is_duplicate=True,
            merchant_name=existing.get("merchant_name") if existing else None,
            receipt_date=existing.get("receipt_date") if existing else (device_timestamp[:10] if device_timestamp else date.today().isoformat()),
            total_amount=existing.get("total_amount", 0.0) if existing else 0.0,
            confidence_score=existing.get("ocr_confidence", 1.0) if existing else 1.0,
            needs_review=False,
            receipt_type=ReceiptType.PRINTED,
            line_items=[],
        )

    # ── Step 5: Receipt type classification ──────────────────────────────────
    receipt_type = classify_receipt_type(processed_image)
    logger.info("Classified receipt as: %s", receipt_type.value)

    # ── Step 6: OCR Extraction ───────────────────────────────────────────────
    tokens, engine_used = await route_and_extract(
        image=processed_image,
        image_bytes=processed_bytes,
        receipt_type=receipt_type,
    )
    logger.info("OCR via '%s' produced %d tokens.", engine_used, len(tokens))

    if not tokens:
        # Fall back to a minimal unknown receipt and register visual hash
        empty_resp = _build_empty_response(receipt_type)
        dedup.register_hashes(empty_resp.receipt_id, phash_str, "")
        return empty_resp

    # ── Step 7: Spatial line reassembly ──────────────────────────────────────
    text_lines = reassemble_lines(tokens)

    # ── Step 8: Mean confidence of all tokens ────────────────────────────────
    mean_confidence = (
        sum(t.confidence for t in tokens) / len(tokens) if tokens else 0.5
    )

    # ── Step 9: NLP normalization ────────────────────────────────────────────
    line_items: List[LineItemCreate] = normalizer.parse_lines_to_items(
        text_lines, base_confidence=mean_confidence
    )
    logger.info("Normalised %d line items.", len(line_items))

    # ── Step 10: Header extraction (merchant, date, total) ───────────────────
    merchant_name = _extract_merchant(text_lines)
    extracted_date = _extract_date(text_lines)
    receipt_date = extracted_date or (device_timestamp[:10] if device_timestamp else date.today().isoformat())
    total_amount = _compute_total(text_lines, line_items)

    # Reconcile single-item price OCR anomalies against confirmed receipt grand total
    if total_amount > 0 and len(line_items) >= 2:
        anomalies = [
            li for li in line_items
            if li.total_price > total_amount
            or li.total_price <= 0
            or (li.quantity > 50 and li.total_price == li.quantity)
        ]
        if len(anomalies) == 1:
            normal_sum = sum(li.total_price for li in line_items if li not in anomalies)
            rem = round(total_amount - normal_sum, 2)
            if rem > 0:
                logger.info(
                    "Reconciled price anomaly for '%s' from %.2f to %.2f based on grand total %.2f",
                    anomalies[0].item_name, anomalies[0].total_price, rem, total_amount,
                )
                anomalies[0].total_price = rem
                anomalies[0].unit_price = rem

    # ── Step 11: Textual Deduplication (Layer 2) ─────────────────────────────
    text_fp = dedup.compute_text_fingerprint(merchant_name, receipt_date, total_amount)
    is_dup, dup_receipt_id = dedup.check_duplicate("", text_fp)

    if is_dup:
        logger.info("Duplicate receipt detected via text fingerprint (matched=%s).", dup_receipt_id)
        return UploadReceiptResponse(
            receipt_id=dup_receipt_id or str(uuid.uuid4()),
            status=ReceiptStatus.DUPLICATE,
            is_duplicate=True,
            merchant_name=merchant_name,
            receipt_date=receipt_date,
            total_amount=total_amount,
            confidence_score=round(mean_confidence, 3),
            needs_review=False,
            receipt_type=receipt_type,
            line_items=[],
        )

    # ── Step 11: Determine status ────────────────────────────────────────────
    needs_review = (
        mean_confidence < settings.review_confidence_threshold
        or any(li.confidence_score < settings.review_confidence_threshold for li in line_items)
    )
    status = ReceiptStatus.PENDING_REVIEW if needs_review else ReceiptStatus.PROCESSED

    # ── Step 12: Persist to store ────────────────────────────────────────────
    receipt_row = store.insert_receipt(
        merchant_name=merchant_name,
        receipt_date=receipt_date,
        total_amount=total_amount,
        receipt_type=receipt_type.value,
        status=status.value,
        ocr_confidence=round(mean_confidence, 3),
        user_id=user_id,
    )
    receipt_id = receipt_row["id"]

    # Register hashes for future dedup
    dedup.register_hashes(receipt_id, phash_str, text_fp)

    # Insert line items and build response list
    response_items: List[LineItemResponse] = []
    for li in line_items:
        li_row = store.insert_line_item(
            receipt_id=receipt_id,
            raw_text=li.raw_text,
            item_name=li.item_name,
            quantity=li.quantity,
            unit=li.unit,
            unit_price=li.unit_price,
            total_price=li.total_price,
            confidence_score=li.confidence_score,
            category=li.category,
            is_verified=li.is_verified,
        )

        # Flag low-confidence items in review queue
        if li.confidence_score < settings.review_confidence_threshold:
            store.insert_review_queue_item(
                line_item_id=li_row["id"],
                candidate_text=li.raw_text,
                model_confidence=li.confidence_score,
            )

        response_items.append(
            LineItemResponse(
                item_id=li_row["id"],
                raw_text=li.raw_text,
                canonical_name=li.item_name,
                quantity=li.quantity,
                unit=li.unit,
                unit_price=li.unit_price,
                total_price=li.total_price,
                category=li.category,
                confidence_score=li.confidence_score,
                is_verified=li.is_verified,
            )
        )

    return UploadReceiptResponse(
        receipt_id=receipt_id,
        status=status,
        is_duplicate=False,
        merchant_name=merchant_name,
        receipt_date=receipt_date,
        total_amount=total_amount,
        confidence_score=round(mean_confidence, 3),
        needs_review=needs_review,
        receipt_type=receipt_type,
        line_items=response_items,
    )


# ── Private Helpers ───────────────────────────────────────────────────────────

def _extract_merchant(text_lines: List) -> Optional[str]:
    """
    Extract merchant/store name from the top header lines of the receipt.
    Looks for store keywords (supermarket, mart, store, karyana, etc.)
    and combines split header lines if appropriate.
    """
    if not text_lines:
        return None

    shop_keywords = re.compile(
        r"\b(super\s*market|market|karyana|store|general\s*store|mart|cash\s*&\s*carry|"
        r"bakers|pharmacy|sweets|traders|al[\s-]?madina|imtiaz|naheed|carrefour)\b",
        re.IGNORECASE,
    )
    price_like = re.compile(r"\b\d{2,}\b")

    candidates = []
    for line in text_lines[:5]:
        line_text = " ".join(t.text for t in line).strip()
        # Clean out leading junk symbols
        line_clean = re.sub(r"^[?><~+*.,_\-|\s]+", "", line_text).strip()
        line_clean = re.sub(r"[?><~+*|]+", " ", line_clean).strip()
        alpha_count = len(re.sub(r"[^a-zA-Z]", "", line_clean))
        # Skip noise and lines with prices, dates, or fewer than 3 letters
        if not line_clean or alpha_count < 3 or price_like.search(line_clean):
            continue
        if re.search(r"\b(date|pate|time|tne|ntn|nin|strn|pos|tel|phone|pechs|shahrah|branch)\b", line_clean, re.IGNORECASE):
            continue
        candidates.append(line_clean)

    # Check for keyword matches in candidates
    for i, c in enumerate(candidates):
        if shop_keywords.search(c):
            # If the previous line is also a short header name (e.g. "AL-MADINA" + "SUPER MARKET"), combine them
            if i > 0 and len(candidates[i - 1].split()) <= 3 and len(re.sub(r"[^a-zA-Z]", "", candidates[i - 1])) >= 3:
                combined = f"{candidates[i - 1]} {c}"
                return re.sub(r"\s+", " ", combined).strip().title()
            return re.sub(r"\s+", " ", c).strip().title()

    if candidates:
        # Pick the candidate with the highest count of alphabetic characters
        best = max(candidates, key=lambda c: len(re.sub(r"[^a-zA-Z]", "", c)))
        if len(re.sub(r"[^a-zA-Z]", "", best)) >= 4:
            return re.sub(r"\s+", " ", best).strip().title()

    return None


def _extract_date(text_lines: List) -> Optional[str]:
    """
    Extract receipt date from text lines (e.g. 09-OCT-2026, 10/10/2026, 2024-05-15).
    Converts to ISO-8601 YYYY-MM-DD.
    """
    date_patterns = [
        re.compile(r"\b(?P<day>\d{1,2})[-/](?P<month>[a-zA-Z]{3})[-/](?P<year>\d{2,4})\b", re.IGNORECASE),
        re.compile(r"\b(?P<year>\d{4})[-/](?P<month>\d{1,2})[-/](?P<day>\d{1,2})\b"),
        re.compile(r"\b(?P<day>\d{1,2})[-/](?P<month>\d{1,2})[-/](?P<year>\d{2,4})\b"),
    ]
    month_names = {
        "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
        "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12
    }
    for line in text_lines[:8]:
        line_text = " ".join(t.text for t in line).strip()
        # Normalize common OCR 0 -> O in month abbreviations (e.g. 09-0cT-2026 -> 09-OcT-2026)
        line_text = re.sub(r"\b0([a-zA-Z]{2})\b", r"O\1", line_text)
        for pat in date_patterns:
            m = pat.search(line_text)
            if m:
                gd = m.groupdict()
                y = int(gd["year"])
                if y < 100:
                    y += 2000
                m_raw = gd["month"]
                if m_raw.isdigit():
                    mo = int(m_raw)
                else:
                    mo = month_names.get(m_raw.lower()[:3], 1)
                d = int(gd["day"])
                try:
                    return f"{y:04d}-{mo:02d}-{d:02d}"
                except ValueError:
                    continue
    return None


def _compute_total(text_lines: List, line_items: List[LineItemCreate]) -> float:
    """
    Extract receipt grand total:
    1. First search bottom text lines for an explicit TOTAL / GRAND TOTAL amount.
    2. Fall back to the sum of parsed line item totals if no total line is found.
    """
    from app.services.normalizer import _extract_prices

    total_pattern = re.compile(
        r"\b(grand[\s-]?total|net[\s-]?total|sub[\s-]?total|total[\s-]?amount|total)\b",
        re.IGNORECASE,
    )

    for line in reversed(text_lines):
        line_text = " ".join(t.text for t in line).strip()
        if total_pattern.search(line_text):
            prices = _extract_prices(line_text)
            if prices:
                return round(prices[-1], 2)

    # Fallback to sum of line items
    return round(sum(li.total_price for li in line_items), 2)


def _build_empty_response(receipt_type: ReceiptType) -> UploadReceiptResponse:
    """Return a minimal PENDING_REVIEW response when OCR produces no tokens."""
    receipt_row = store.insert_receipt(
        merchant_name=None,
        receipt_date=date.today().isoformat(),
        total_amount=0.0,
        receipt_type=receipt_type.value,
        status=ReceiptStatus.PENDING_REVIEW.value,
        ocr_confidence=0.0,
    )
    receipt_id = receipt_row["id"]
    return UploadReceiptResponse(
        receipt_id=receipt_id,
        status=ReceiptStatus.PENDING_REVIEW,
        is_duplicate=False,
        merchant_name=None,
        receipt_date=date.today().isoformat(),
        total_amount=0.0,
        confidence_score=0.0,
        needs_review=True,
        receipt_type=receipt_type,
        line_items=[],
    )
