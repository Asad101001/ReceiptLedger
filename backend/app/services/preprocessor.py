"""
ReceiptLedger – OpenCV Image Preprocessor
==========================================
Pipeline:
  1. Decode bytes → NumPy array
  2. Grayscale + Gaussian blur
  3. Canny edge detection
  4. Contour extraction + 4-point Douglas-Peucker approximation
  5. Perspective warp transform (deskew)
  6. CLAHE contrast enhancement
  7. Adaptive Gaussian binarization
  8. Encode back to JPEG bytes

All parameters are tuned to the specifications in docs/09_DEVELOPMENT_PLAN.md.
"""

from __future__ import annotations

import io
import logging
from typing import Optional, Tuple

import cv2
import numpy as np
from PIL import Image

logger = logging.getLogger(__name__)


# ── Public Interface ──────────────────────────────────────────────────────────

def preprocess_image(image_bytes: bytes) -> Tuple[np.ndarray, bytes]:
    """
    Accept raw image bytes, run the full CV preprocessing pipeline.

    Returns:
        warped_gray (np.ndarray): The processed 2-D grayscale image array
                                  (used downstream by OCR engines).
        jpeg_bytes  (bytes):      JPEG-encoded version of the processed image
                                  (for storage / blob upload).
    """
    # 1 ── Decode ─────────────────────────────────────────────────────────────
    np_arr = np.frombuffer(image_bytes, dtype=np.uint8)
    image = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    if image is None:
        raise ValueError("Could not decode image – unsupported format or corrupt data.")

    # 2 ── Grayscale + Gaussian blur ───────────────────────────────────────────
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)

    # 3 ── Canny edge map ──────────────────────────────────────────────────────
    edged = cv2.Canny(blurred, 75, 200)

    # 4 ── Contour extraction & 4-point corner detection ──────────────────────
    quad_pts = _detect_receipt_corners(edged)

    # 5 ── Perspective warp (deskew) ───────────────────────────────────────────
    if quad_pts is not None:
        warped = _four_point_transform(gray, quad_pts)
        logger.debug("Perspective warp applied using detected 4-corner polygon.")
    else:
        # Fallback: crop to centre 90 % of the grayscale image
        warped = _center_crop(gray, 0.90)
        logger.debug("No 4-corner polygon found; using centre-crop fallback.")

    # 6 ── CLAHE contrast enhancement ─────────────────────────────────────────
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(warped)

    # 7 ── Adaptive Gaussian binarization ─────────────────────────────────────
    binarized = cv2.adaptiveThreshold(
        enhanced, 255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        blockSize=11, C=2,
    )

    # 8 ── Encode to JPEG ──────────────────────────────────────────────────────
    success, buffer = cv2.imencode(".jpg", binarized, [cv2.IMWRITE_JPEG_QUALITY, 85])
    if not success:
        raise RuntimeError("Failed to encode preprocessed image to JPEG.")

    return binarized, bytes(buffer)


def assess_blur(image_bytes: bytes) -> float:
    """
    Compute the Laplacian variance of the image as a blur metric.
    Higher value = sharper. Values below ~100 are typically too blurry.

    Returns:
        float: Laplacian variance (blur score).
    """
    np_arr = np.frombuffer(image_bytes, dtype=np.uint8)
    image = cv2.imdecode(np_arr, cv2.IMREAD_GRAYSCALE)
    if image is None:
        return 0.0
    return float(cv2.Laplacian(image, cv2.CV_64F).var())


def validate_dimensions(image_bytes: bytes, min_width: int = 720, min_height: int = 1280) -> bool:
    """
    Check that the image meets minimum resolution requirements.
    The spec requires images ≥ 720 × 1280 pixels.
    """
    np_arr = np.frombuffer(image_bytes, dtype=np.uint8)
    image = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    if image is None:
        return False
    h, w = image.shape[:2]
    # Accept portrait OR landscape orientation
    return (w >= min_width and h >= min_height) or (h >= min_width and w >= min_height)


# ── Private Helpers ───────────────────────────────────────────────────────────

def _detect_receipt_corners(edged: np.ndarray) -> Optional[np.ndarray]:
    """
    Find the four corners of the receipt in the edge-detected image.
    Returns an (4, 2) float32 array of corner coordinates, or None if not found.
    """
    contours, _ = cv2.findContours(edged, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    # Sort by area descending, keep top 5 candidates
    contours = sorted(contours, key=cv2.contourArea, reverse=True)[:5]

    for c in contours:
        peri = cv2.arcLength(c, True)
        approx = cv2.approxPolyDP(c, 0.02 * peri, True)
        if len(approx) == 4:
            return approx.reshape(4, 2).astype(np.float32)

    return None


def _order_points(pts: np.ndarray) -> np.ndarray:
    """
    Order four corner points as: [top-left, top-right, bottom-right, bottom-left].
    Uses the property that:
      - top-left  has smallest (x + y) sum
      - bottom-right has largest (x + y) sum
      - top-right has smallest (y - x) difference
      - bottom-left has largest (y - x) difference
    """
    rect = np.zeros((4, 2), dtype=np.float32)
    s = pts.sum(axis=1)
    rect[0] = pts[np.argmin(s)]   # top-left
    rect[2] = pts[np.argmax(s)]   # bottom-right
    diff = np.diff(pts, axis=1)
    rect[1] = pts[np.argmin(diff)]  # top-right
    rect[3] = pts[np.argmax(diff)]  # bottom-left
    return rect


def _four_point_transform(image: np.ndarray, pts: np.ndarray) -> np.ndarray:
    """
    Apply a perspective warp transform using the four detected corner points.
    """
    rect = _order_points(pts)
    tl, tr, br, bl = rect

    # Compute destination rectangle width
    w_top    = np.linalg.norm(tr - tl)
    w_bottom = np.linalg.norm(br - bl)
    w_max    = int(max(w_top, w_bottom))

    # Compute destination rectangle height
    h_left   = np.linalg.norm(bl - tl)
    h_right  = np.linalg.norm(br - tr)
    h_max    = int(max(h_left, h_right))

    dst = np.array(
        [[0, 0], [w_max - 1, 0], [w_max - 1, h_max - 1], [0, h_max - 1]],
        dtype=np.float32,
    )
    M = cv2.getPerspectiveTransform(rect, dst)
    return cv2.warpPerspective(image, M, (w_max, h_max))


def _center_crop(image: np.ndarray, ratio: float = 0.90) -> np.ndarray:
    """
    Crop the central `ratio` portion of the image (fallback when corners are undetected).
    """
    h, w = image.shape[:2]
    margin_h = int(h * (1 - ratio) / 2)
    margin_w = int(w * (1 - ratio) / 2)
    return image[margin_h: h - margin_h, margin_w: w - margin_w]
