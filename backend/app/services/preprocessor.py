"""
ReceiptLedger – OpenCV Image Preprocessor
==========================================
Pipeline:
  1. Decode bytes → NumPy array
  2. Auto-rotate via EXIF orientation (phone photos)
  3. Downscale to OCR-friendly size if too large (preserves detail)
  4. Grayscale + Gaussian blur
  5. Canny edge detection
  6. Contour extraction + 4-point Douglas-Peucker approximation
     (only applied if detected quad covers ≥ 15 % of image area)
  7. CLAHE contrast enhancement
  8. Optional: light adaptive denoising
  9. Encode to JPEG bytes

Key design decisions:
  - Adaptive binarization is deliberately NOT applied here.
    Tesseract's LSTM engine (OEM 1) reads grayscale better than
    hard-binarized images, especially for thin thermal-print text.
  - Perspective warp is only applied when the detected rectangle is
    substantially large (≥ 15 % of image area), preventing mis-warp
    on screen UI elements, borders, or partial captures.
"""

from __future__ import annotations

import io
import logging
from typing import Optional, Tuple

import cv2
import numpy as np
from PIL import Image, ExifTags

logger = logging.getLogger(__name__)

# Minimum fraction of image area the detected quad must cover to trigger warp
_MIN_QUAD_AREA_RATIO = 0.15
# Maximum long-edge dimension to feed into OCR (larger images are downscaled)
_OCR_MAX_LONG_EDGE = 2400


# ── Public Interface ──────────────────────────────────────────────────────────

def preprocess_image(image_bytes: bytes) -> Tuple[np.ndarray, bytes]:
    """
    Accept raw image bytes, run the full CV preprocessing pipeline.

    Returns:
        processed_gray (np.ndarray): The processed 2-D grayscale image array
                                      (used downstream by OCR engines).
        jpeg_bytes  (bytes):          JPEG-encoded version of the processed image
                                      (for storage / blob upload).
    """
    # 1 ── Decode + EXIF auto-rotate (fixes upside-down phone captures) ────────
    image = _decode_with_exif_rotation(image_bytes)
    if image is None:
        raise ValueError("Could not decode image – unsupported format or corrupt data.")

    # 2 ── Downscale if the image is very large (preserves OCR quality) ────────
    image = _limit_long_edge(image, _OCR_MAX_LONG_EDGE)
    h_orig, w_orig = image.shape[:2]

    # 3 ── Grayscale + gentle Gaussian blur ────────────────────────────────────
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)

    # 4 ── Canny edge map ──────────────────────────────────────────────────────
    edged = cv2.Canny(blurred, 50, 150)

    # 5 ── Contour extraction & 4-point corner detection ──────────────────────
    quad_pts = _detect_receipt_corners(edged, h_orig * w_orig)

    # 6 ── Perspective warp (only if quad is plausibly the receipt) ────────────
    if quad_pts is not None:
        warped = _four_point_transform(gray, quad_pts)
        logger.debug("Perspective warp applied using detected 4-corner polygon.")
    else:
        warped = gray  # Use full grayscale image — don't crop or warp
        logger.debug("No large 4-corner polygon found; using full grayscale image.")

    # 7 ── CLAHE contrast enhancement ─────────────────────────────────────────
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(warped)

    # 8 ── Encode to JPEG ──────────────────────────────────────────────────────
    success, buffer = cv2.imencode(".jpg", enhanced, [cv2.IMWRITE_JPEG_QUALITY, 92])
    if not success:
        raise RuntimeError("Failed to encode preprocessed image to JPEG.")

    return enhanced, bytes(buffer)


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


def validate_dimensions(image_bytes: bytes, min_width: int = 400, min_height: int = 600) -> bool:
    """
    Check that the image meets minimum resolution requirements.
    Relaxed from 720×1280 to 400×600 to accommodate phone gallery screenshots.
    """
    np_arr = np.frombuffer(image_bytes, dtype=np.uint8)
    image = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    if image is None:
        return False
    h, w = image.shape[:2]
    # Accept portrait OR landscape orientation
    return (w >= min_width and h >= min_height) or (h >= min_width and w >= min_height)


# ── Private Helpers ───────────────────────────────────────────────────────────

def _decode_with_exif_rotation(image_bytes: bytes) -> Optional[np.ndarray]:
    """
    Decode image bytes and apply EXIF orientation correction.
    Phone cameras embed rotation metadata; OpenCV ignores it.
    """
    try:
        pil_img = Image.open(io.BytesIO(image_bytes))
        # Apply EXIF orientation if present
        try:
            exif = pil_img.getexif()
            orientation_key = next(
                k for k, v in ExifTags.TAGS.items() if v == "Orientation"
            )
            orientation = exif.get(orientation_key, 1)
            rotations = {3: 180, 6: 270, 8: 90}
            if orientation in rotations:
                pil_img = pil_img.rotate(rotations[orientation], expand=True)
        except (StopIteration, AttributeError, Exception):
            pass  # No EXIF or no orientation tag — fine

        pil_img = pil_img.convert("RGB")
        img_array = np.array(pil_img)
        # Convert RGB → BGR for OpenCV
        return cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
    except Exception:
        # Fallback to raw OpenCV decode
        np_arr = np.frombuffer(image_bytes, dtype=np.uint8)
        return cv2.imdecode(np_arr, cv2.IMREAD_COLOR)


def _limit_long_edge(image: np.ndarray, max_px: int) -> np.ndarray:
    """Downscale image so the longest edge ≤ max_px, preserving aspect ratio."""
    h, w = image.shape[:2]
    long_edge = max(h, w)
    if long_edge <= max_px:
        return image
    scale = max_px / long_edge
    new_w, new_h = int(w * scale), int(h * scale)
    return cv2.resize(image, (new_w, new_h), interpolation=cv2.INTER_AREA)


def _detect_receipt_corners(
    edged: np.ndarray,
    image_area: int,
) -> Optional[np.ndarray]:
    """
    Find the four corners of the receipt in the edge-detected image.
    Only returns a quad if it covers ≥ _MIN_QUAD_AREA_RATIO of the image area,
    preventing small UI borders from triggering a mis-warp.

    Returns an (4, 2) float32 array of corner coordinates, or None if not found.
    """
    contours, _ = cv2.findContours(edged, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    # Sort by area descending, keep top 5 candidates
    contours = sorted(contours, key=cv2.contourArea, reverse=True)[:5]

    min_area = image_area * _MIN_QUAD_AREA_RATIO

    for c in contours:
        area = cv2.contourArea(c)
        if area < min_area:
            continue  # Too small — skip, don't warp to a tiny region
        peri = cv2.arcLength(c, True)
        approx = cv2.approxPolyDP(c, 0.02 * peri, True)
        if len(approx) == 4:
            return approx.reshape(4, 2).astype(np.float32)

    return None


def _order_points(pts: np.ndarray) -> np.ndarray:
    """
    Order four corner points as: [top-left, top-right, bottom-right, bottom-left].
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

    # Guard against degenerate transforms
    if w_max < 50 or h_max < 50:
        logger.debug("Detected quad too small (%dx%d), skipping warp.", w_max, h_max)
        return image

    dst = np.array(
        [[0, 0], [w_max - 1, 0], [w_max - 1, h_max - 1], [0, h_max - 1]],
        dtype=np.float32,
    )
    M = cv2.getPerspectiveTransform(rect, dst)
    return cv2.warpPerspective(image, M, (w_max, h_max))


def _center_crop(image: np.ndarray, ratio: float = 0.90) -> np.ndarray:
    """
    Crop the central `ratio` portion of the image (legacy helper, kept for compatibility).
    """
    h, w = image.shape[:2]
    margin_h = int(h * (1 - ratio) / 2)
    margin_w = int(w * (1 - ratio) / 2)
    return image[margin_h: h - margin_h, margin_w: w - margin_w]
