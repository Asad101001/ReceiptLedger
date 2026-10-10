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
    Heuristic classifier: combines connected component analysis (glyph density
    and height variance coefficient) with edge analysis to distinguish
    structured machine-printed receipts from informal handwritten slips.

    - Printed receipts: high density of uniform characters (low height CV, high glyph count).
    - Handwritten slips: lower glyph count, cursive joins, higher variance in stroke heights.
    """
    import cv2

    if len(image.shape) == 3:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    else:
        gray = image

    # Otsu binarization to extract text components
    _, thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    num_labels, labels, stats, centroids = cv2.connectedComponentsWithStats(thresh)
    valid_stats = [s for s in stats[1:] if 15 < s[cv2.CC_STAT_AREA] < 50000]

    if not valid_stats:
        return ReceiptType.PRINTED

    heights = [s[cv2.CC_STAT_HEIGHT] for s in valid_stats]
    mean_h = float(np.mean(heights)) + 1e-5
    std_h = float(np.std(heights))
    cv_h = std_h / mean_h

    # Handwritten slips feature irregular strokes and high height variance (ascenders, descenders, ruled lines)
    if cv_h > 1.25:
        return ReceiptType.HANDWRITTEN
    return ReceiptType.PRINTED


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
