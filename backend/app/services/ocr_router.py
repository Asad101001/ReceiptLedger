"""
ReceiptLedger – OCR Decision Router & Spatial Line Reassembly
==============================================================
Responsibilities:
  1. Classify receipt type (PRINTED / HANDWRITTEN) using edge density heuristic.
  2. Route to the correct OCR engine with quota-aware fallback logic.
  3. Reassemble flat OCR token lists into logical horizontal text lines.

Routing priority:
  PRINTED  → Cloud Vision API → (quota fallback) Tesseract 5
  HANDWRITTEN → EasyOCR + Tesseract digit voting

Concurrency control:
  An asyncio.Semaphore limits simultaneous heavy OCR tasks to prevent
  memory saturation from concurrent EasyOCR inference.

References:
  docs/09_DEVELOPMENT_PLAN.md § 3.2, 3.3
"""

from __future__ import annotations

import asyncio
import logging
from typing import List, Tuple

import numpy as np

from app.core.config import settings
from app.core.models import OCRToken, ReceiptType

logger = logging.getLogger(__name__)

# Semaphore: max concurrent heavy OCR tasks (EasyOCR is ~500 MB RAM per call)
_ocr_semaphore = asyncio.Semaphore(settings.max_concurrent_ocr)


# ── Receipt Type Classifier ───────────────────────────────────────────────────

def classify_receipt_type(image: np.ndarray) -> ReceiptType:
    """
    Heuristic classifier: distinguishes structured machine-printed receipts
    from informal handwritten slips using edge density and connected component
    analysis. Now calibrated for CLAHE-enhanced grayscale (not binarized) images.

    Printed receipts: strong horizontal edge regularity, high uniform glyph density.
    Handwritten slips: irregular stroke widths, lower edge periodicity.
    """
    import cv2

    if len(image.shape) == 3:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    else:
        gray = image

    # ── Feature 1: Edge density via Canny ─────────────────────────────────────
    blurred = cv2.GaussianBlur(gray, (3, 3), 0)
    edges = cv2.Canny(blurred, 50, 150)
    edge_density = np.count_nonzero(edges) / max(edges.size, 1)

    # ── Feature 2: Glyph height variance (connected components) ───────────────
    _, thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    _, _, stats, _ = cv2.connectedComponentsWithStats(thresh)
    valid_stats = [s for s in stats[1:] if 10 < s[cv2.CC_STAT_AREA] < 50000]

    if not valid_stats:
        return ReceiptType.PRINTED

    heights = [s[cv2.CC_STAT_HEIGHT] for s in valid_stats]
    widths  = [s[cv2.CC_STAT_WIDTH]  for s in valid_stats]
    mean_h = float(np.mean(heights)) + 1e-5
    std_h  = float(np.std(heights))
    cv_h   = std_h / mean_h

    # Aspect ratio: printed chars are taller-relative; handwritten glyphs sprawl
    mean_aspect = float(np.mean([w / (h + 1e-5) for w, h in zip(widths, heights)]))

    glyph_count  = len(valid_stats)
    image_area   = gray.shape[0] * gray.shape[1]
    glyph_density = glyph_count / max(image_area, 1) * 1e6

    # ── Decision rule ──────────────────────────────────────────────────────────
    # Empirical values from sample images after CLAHE preprocessing:
    #   Printed:     edge=0.13, cv_h=1.24, aspect=1.49, glyph_density=658
    #   Handwritten: edge=0.21, cv_h=1.35, aspect=4.86, glyph_density=696
    #
    # Mean glyph aspect ratio is the STRONGEST discriminator:
    #   Handwritten receipts have ruling lines / large ink strokes → very wide glyphs
    #   Printed receipts have compact typeface characters → moderate aspect ratio
    printed_score = 0
    if mean_aspect < 2.5:
        printed_score += 3   # Strong signal: compact chars = printed
    if cv_h < 1.3:
        printed_score += 1
    if edge_density < 0.15:
        printed_score += 1

    if printed_score >= 3:
        return ReceiptType.PRINTED
    return ReceiptType.HANDWRITTEN


# ── OCR Routing & Extraction ──────────────────────────────────────────────────

async def route_and_extract(
    image: np.ndarray,
    image_bytes: bytes,
    receipt_type: ReceiptType,
) -> Tuple[List[OCRToken], str]:
    """
    Route to the appropriate OCR engine and extract tokens.

    Returns:
        (tokens, engine_used): The extracted OCR tokens and a string
        identifying which engine was used (for logging/debugging).
    """
    async with _ocr_semaphore:
        if receipt_type == ReceiptType.PRINTED:
            return await _extract_printed(image_bytes)
        else:
            return await _extract_handwritten(image)


async def _extract_printed(image_bytes: bytes) -> Tuple[List[OCRToken], str]:
    """
    Printed path: Cloud Vision → Tesseract fallback.
    """
    # Try Cloud Vision first
    if settings.cloud_vision_enabled:
        try:
            from app.services.cloud_vision_client import (
                CloudVisionQuotaExceededError,
                extract_tokens as cv_extract,
                is_available as cv_available,
            )
            if cv_available():
                logger.info("Using Google Cloud Vision for printed receipt.")
                loop = asyncio.get_event_loop()
                tokens = await loop.run_in_executor(None, cv_extract, image_bytes)
                return tokens, "cloud_vision"
        except CloudVisionQuotaExceededError:
            logger.warning(
                "Cloud Vision quota reached. Falling back to Tesseract for this request."
            )
        except Exception as exc:
            logger.warning("Cloud Vision unavailable (%s). Falling back to Tesseract.", exc)

    # Fallback: Tesseract
    return await _run_tesseract(image_bytes)


async def _extract_handwritten(image: np.ndarray) -> Tuple[List[OCRToken], str]:
    """
    Handwritten path: EasyOCR with Tesseract digit voting.
    """
    try:
        from app.services.easyocr_client import (
            extract_tokens as easy_extract,
            is_available as easy_available,
        )
        if easy_available():
            logger.info("Using EasyOCR for handwritten receipt.")
            loop = asyncio.get_event_loop()
            tokens = await loop.run_in_executor(None, easy_extract, image)
            return tokens, "easyocr"
    except Exception as exc:
        logger.warning("EasyOCR failed (%s). Falling back to Tesseract.", exc)

    # Fallback: Tesseract
    return await _run_tesseract(None, image=image)


async def _run_tesseract(
    image_bytes: bytes | None,
    image: np.ndarray | None = None,
) -> Tuple[List[OCRToken], str]:
    """Run Tesseract 5 extraction (used as fallback for both paths)."""
    import numpy as _np

    from app.services.tesseract_client import (
        extract_tokens as tess_extract,
        is_available as tess_available,
    )

    if not tess_available():
        logger.error("Tesseract is not installed or not on PATH.")
        return [], "none"

    if image is None:
        np_arr = _np.frombuffer(image_bytes, dtype=_np.uint8)
        import cv2
        image = cv2.imdecode(np_arr, cv2.IMREAD_GRAYSCALE)

    loop = asyncio.get_event_loop()
    tokens = await loop.run_in_executor(None, tess_extract, image)
    logger.info("Tesseract extracted %d tokens.", len(tokens))
    return tokens, "tesseract"


# ── Spatial Line Reassembly ───────────────────────────────────────────────────

def reassemble_lines(
    tokens: List[OCRToken],
    y_tolerance: int = 15,
) -> List[List[OCRToken]]:
    """
    Group flat OCR token list into logical horizontal text lines using a
    sweep-line algorithm (as specified in docs/09_DEVELOPMENT_PLAN.md § 3.3).

    Algorithm:
      1. Sort tokens by y_min (top-to-bottom).
      2. For each token, compute its y_center.
      3. If |y_center - current_line_y_avg| ≤ y_tolerance, add to current line.
      4. Otherwise, finalise current line (sorted left→right by x_min) and start new line.

    Args:
        tokens: Flat list of OCRToken from any OCR engine.
        y_tolerance: Maximum vertical pixel distance to consider same line.

    Returns:
        List of text lines, each line being a list of OCRToken sorted left-to-right.
    """
    if not tokens:
        return []

    sorted_tokens = sorted(tokens, key=lambda t: t.bounding_box.y_min)

    lines: List[List[OCRToken]] = []
    current_line: List[OCRToken] = []

    for token in sorted_tokens:
        if not current_line:
            current_line.append(token)
            continue

        curr_y = token.bounding_box.y_center
        line_y_avg = sum(t.bounding_box.y_center for t in current_line) / len(current_line)

        if abs(curr_y - line_y_avg) <= y_tolerance:
            current_line.append(token)
        else:
            # Finalise line: sort left-to-right
            lines.append(sorted(current_line, key=lambda t: t.bounding_box.x_min))
            current_line = [token]

    if current_line:
        lines.append(sorted(current_line, key=lambda t: t.bounding_box.x_min))

    logger.debug("Reassembled %d tokens into %d text lines.", len(tokens), len(lines))
    return lines
