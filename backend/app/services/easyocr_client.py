"""
ReceiptLedger – EasyOCR Client (Handwritten / Informal Receipts)
=================================================================
EasyOCR uses a PyTorch-based CRNN architecture and is optimised for
CPU inference (gpu=False).  The singleton reader is created once at
module import time to avoid the expensive model-load penalty on every request.

The secondary digit-voting step cross-checks every numeric token emitted by
EasyOCR against the Tesseract digit-only pass to correct common ambiguities:
  0 ↔ 8,  1 ↔ 7,  6 ↔ 9

References:
  docs/09_DEVELOPMENT_PLAN.md § 3.2 – EasyOCR Engine
"""

from __future__ import annotations

import asyncio
import logging
from typing import List, Optional

import numpy as np

from app.core.config import settings
from app.core.models import BoundingBox, OCRToken

logger = logging.getLogger(__name__)

# Module-level singleton — one reader for the lifetime of the process.
_reader: Optional["easyocr.Reader"] = None  # type: ignore[name-defined]
_reader_lock = asyncio.Lock()


def _get_reader():
    """Lazy-initialise the EasyOCR reader (CPU mode, English language)."""
    global _reader
    if _reader is None:
        import easyocr  # deferred import so the module loads fast if unused
        logger.info("Initialising EasyOCR reader (CPU mode)…")
        _reader = easyocr.Reader(["en"], gpu=False)
        logger.info("EasyOCR reader ready.")
    return _reader


def is_available() -> bool:
    """Return True if EasyOCR is importable."""
    try:
        import easyocr  # noqa: F401
        return True
    except ImportError:
        return False


def extract_tokens(image: np.ndarray) -> List[OCRToken]:
    """
    Run EasyOCR on the given grayscale (or colour) NumPy image array.

    The EasyOCR result for each detection is:
        (bounding_box_polygon, text, confidence)
    where bounding_box_polygon is [[x1,y1],[x2,y1],[x2,y2],[x1,y2]].

    Returns:
        List of OCRToken sorted top-to-bottom then left-to-right.
    """
    try:
        reader = _get_reader()
        results = reader.readtext(image, detail=1, paragraph=False)
    except Exception as exc:
        logger.error("EasyOCR extraction failed: %s", exc)
        return []

    tokens: List[OCRToken] = []

    for bbox_poly, text, confidence in results:
        raw_text = text.strip()
        if not raw_text:
            continue

        # EasyOCR bbox: [[x1,y1],[x2,y1],[x2,y2],[x1,y2]]
        xs = [pt[0] for pt in bbox_poly]
        ys = [pt[1] for pt in bbox_poly]
        x_min, x_max = int(min(xs)), int(max(xs))
        y_min, y_max = int(min(ys)), int(max(ys))

        # Secondary digit voting for numeric tokens
        final_text = _vote_digits(image, raw_text, x_min, y_min, x_max, y_max)

        tokens.append(
            OCRToken(
                text=final_text,
                confidence=float(confidence),
                bounding_box=BoundingBox(
                    x_min=x_min, y_min=y_min,
                    x_max=x_max, y_max=y_max,
                ),
            )
        )

    # Sort: top-to-bottom, then left-to-right
    tokens.sort(key=lambda t: (t.bounding_box.y_min, t.bounding_box.x_min))
    logger.debug("EasyOCR extracted %d tokens.", len(tokens))
    return tokens


def _vote_digits(
    image: np.ndarray,
    text: str,
    x_min: int, y_min: int, x_max: int, y_max: int,
) -> str:
    """
    If the token looks numeric, crop that region and re-run Tesseract with a
    digit-only whitelist.  Prefer the Tesseract result if it's longer or equal
    in length (more digits = more likely correct).
    """
    import re
    if not re.match(r"^\d[\d.,]*$", text):
        return text  # Not a numeric token – skip voting

    try:
        from app.services.tesseract_client import validate_digit_token

        # Clip to image bounds before slicing
        h, w = image.shape[:2]
        crop = image[
            max(0, y_min): min(h, y_max),
            max(0, x_min): min(w, x_max),
        ]
        if crop.size == 0:
            return text

        tess_result = validate_digit_token(crop)
        cleaned = tess_result.replace(" ", "").replace("\n", "")
        if cleaned and len(cleaned) >= len(text):
            return cleaned
    except Exception:
        pass  # Voting is best-effort; fall back to EasyOCR output

    return text
