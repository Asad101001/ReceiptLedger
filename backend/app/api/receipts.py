"""
ReceiptLedger – Receipt Upload Endpoint
POST /api/v1/receipts/upload

Accepts a multipart/form-data upload containing the receipt image plus optional
metadata (device_timestamp, capture_mode).  Runs the full ingestion pipeline
and returns the structured UploadReceiptResponse.

HTTP Status codes:
  200  Successfully processed (PROCESSED or PENDING_REVIEW)
  409  Duplicate receipt detected
  413  File too large
  422  Image could not be processed (blur, decode error, etc.)
  500  Internal pipeline failure
"""

from __future__ import annotations

import logging
from typing import Optional

from fastapi import APIRouter, File, Form, HTTPException, UploadFile, status
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.models import ReceiptStatus, UploadReceiptResponse
from app.services.ingestion import ingest_receipt

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "/receipts/upload",
    response_model=UploadReceiptResponse,
    summary="Upload and process a receipt image",
    tags=["Receipts"],
    responses={
        409: {"description": "Duplicate receipt – already exists in the ledger."},
        413: {"description": "File exceeds maximum allowed size (10 MB)."},
        422: {"description": "Image cannot be processed (blurry, corrupt, or unsupported format)."},
    },
)
async def upload_receipt(
    file: UploadFile = File(..., description="JPEG or PNG receipt image"),
    device_timestamp: Optional[str] = Form(
        None,
        description="ISO-8601 timestamp from the capturing device (e.g. 2026-10-05T14:30:00Z)",
    ),
    capture_mode: str = Form(
        "single",
        description="'single' for one receipt, 'batch' for multi-receipt session",
    ),
) -> UploadReceiptResponse:
    """
    Multipart receipt image upload endpoint.

    Orchestrates the full pipeline:
    1. Validate file type and size
    2. OpenCV preprocessing (deskew, contrast)
    3. OCR extraction (Cloud Vision or EasyOCR/Tesseract)
    4. NLP normalization and fuzzy matching
    5. Deduplication check (pHash + text fingerprint)
    6. Database insertion
    7. Review queue flagging for low-confidence items
    """
    # ── File type validation ──────────────────────────────────────────────────
    content_type = file.content_type or ""
    if content_type not in ("image/jpeg", "image/jpg", "image/png", "image/webp"):
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Unsupported file type: {content_type}. Accepted: JPEG, PNG, WEBP.",
        )

    # ── Read and size-check file ──────────────────────────────────────────────
    image_bytes = await file.read()
    if len(image_bytes) > settings.max_upload_bytes:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File size {len(image_bytes)} bytes exceeds limit of {settings.max_upload_bytes} bytes.",
        )

    if len(image_bytes) == 0:
        raise HTTPException(
            status_code=422,
            detail="Uploaded file is empty.",
        )

    # ── Run ingestion pipeline ────────────────────────────────────────────────
    try:
        result = await ingest_receipt(
            image_bytes=image_bytes,
            device_timestamp=device_timestamp,
            capture_mode=capture_mode,
        )
    except ValueError as exc:
        # Image could not be decoded or is too blurry
        raise HTTPException(
            status_code=422,
            detail=str(exc),
        )
    except Exception as exc:
        logger.error("Ingestion pipeline error: %s", exc, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Receipt processing failed. Please try again.",
        )

    # ── Duplicate → 409 ──────────────────────────────────────────────────────
    if result.status == ReceiptStatus.DUPLICATE:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content=result.model_dump(mode="json"),
        )

    return result
