"""
ReceiptLedger – Tesseract 5 OCR Client
========================================
Wraps pytesseract with the page segmentation mode and character whitelists
specified in docs/09_DEVELOPMENT_PLAN.md.

Primary configuration:
  --oem 1  → LSTM neural net engine
  --psm 6  → Assume uniform block of text

Digit-only secondary pass (for price validation):
  --psm 10 -c tessedit_char_whitelist=0123456789.
"""

from __future__ import annotations

import logging
from typing import List

import numpy as np
import pytesseract
from pytesseract import Output

from app.core.models import BoundingBox, OCRToken

logger = logging.getLogger(__name__)

# Primary Tesseract config for full receipt text
_FULL_TEXT_CONFIG = "--oem 1 --psm 6"
# Digit-only config used when validating numeric tokens (prices, quantities)
_DIGIT_CONFIG = "--psm 10 -c tessedit_char_whitelist=0123456789."


def is_available() -> bool:
    """Return True if Tesseract is installed and callable."""
    try:
        version = pytesseract.get_tesseract_version()
        return version is not None
    except Exception:
        return False


def extract_tokens(image: np.ndarray) -> List[OCRToken]:
    """
    Run Tesseract on the given grayscale image array.
    Returns a list of OCRToken objects sorted by reading order (top → bottom, left → right).

    Args:
        image: Preprocessed grayscale 2-D NumPy array.

    Returns:
        List of OCRToken (text, confidence, bounding_box).
    """
    try:
        data = pytesseract.image_to_data(
            image,
            output_type=Output.DICT,
            config=_FULL_TEXT_CONFIG,
        )
    except Exception as exc:
        logger.error("Tesseract extraction failed: %s", exc)
        return []

    tokens: List[OCRToken] = []
    n_boxes = len(data["text"])

    for i in range(n_boxes):
        raw_text = data["text"][i].strip()
        if not raw_text:
            continue

        conf_raw = data["conf"][i]
        # Tesseract returns -1 for boxes with no text; skip them
        if conf_raw < 0:
            continue

        confidence = float(conf_raw) / 100.0  # Normalise to [0, 1]

        x = data["left"][i]
        y = data["top"][i]
        w = data["width"][i]
        h = data["height"][i]

        tokens.append(
            OCRToken(
                text=raw_text,
                confidence=min(confidence, 1.0),
                bounding_box=BoundingBox(
                    x_min=x, y_min=y,
                    x_max=x + w, y_max=y + h,
                ),
            )
        )

    logger.debug("Tesseract extracted %d tokens.", len(tokens))
    return tokens


def validate_digit_token(image_patch: np.ndarray) -> str:
    """
    Run the digit-only whitelist pass on a small image crop (e.g., a price region).
    Used by the dual-pass EasyOCR+Tesseract digit voting step.

    Args:
        image_patch: Cropped grayscale region containing a numeric value.

    Returns:
        str: Recognised digit string (may be empty if unrecognised).
    """
    try:
        result = pytesseract.image_to_string(
            image_patch,
            config=_DIGIT_CONFIG,
        ).strip()
        return result
    except Exception as exc:
        logger.warning("Tesseract digit validation failed: %s", exc)
        return ""
