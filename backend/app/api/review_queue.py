"""
ReceiptLedger – Review Queue Endpoints
GET  /api/v1/review-queue          → Fetch unresolved low-confidence items
PATCH /api/v1/review-queue/{id}    → Human-in-the-loop resolution

References:
  docs/02_SRS.md § 4.1 (FR-6 Review Queue)
  docs/09_DEVELOPMENT_PLAN.md § 4 (Week 3 / Day 18)
"""

from __future__ import annotations

import logging
from typing import List

from fastapi import APIRouter, HTTPException, Path, status

from app.core.models import ReviewQueueItem, ReviewQueueResolveRequest, ReviewStatus
from app.services import store

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get(
    "/review-queue",
    summary="Fetch items pending human review",
    tags=["Review Queue"],
    responses={
        200: {"description": "List of unresolved low-confidence line items."},
    },
)
async def get_review_queue(
    status_filter: ReviewStatus = ReviewStatus.UNRESOLVED,
) -> List[dict]:
    """
    Returns all review queue items with the given status (default: UNRESOLVED).
    Each item includes the original receipt context and the low-confidence
    raw OCR candidate text for the reviewer to confirm or correct.
    """
    items = store.get_review_queue(status=status_filter.value)
    return items


@router.patch(
    "/review-queue/{queue_id}",
    summary="Resolve a review queue item",
    tags=["Review Queue"],
    responses={
        200: {"description": "Item resolved and line item updated."},
        404: {"description": "Review queue item not found."},
    },
)
async def resolve_review_item(
    queue_id: str = Path(..., description="UUID of the review queue record"),
    payload: ReviewQueueResolveRequest = ...,
) -> dict:
    """
    Human-in-the-loop resolution endpoint.

    The reviewer submits confirmed values (name, quantity, unit, prices).
    The system:
    1. Updates the line_item record with the confirmed values.
    2. Marks the queue item as ACCEPTED or EDITED.
    3. Sets `is_verified = TRUE` on the line item.
    """
    resolved = store.resolve_review_queue_item(
        queue_id=queue_id,
        review_status=payload.action.value,
        confirmed_name=payload.confirmed_name,
        confirmed_quantity=payload.confirmed_quantity,
        confirmed_unit=payload.confirmed_unit,
        confirmed_unit_price=payload.confirmed_unit_price,
        confirmed_total_price=payload.confirmed_total_price,
    )

    if resolved is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Review queue item '{queue_id}' not found.",
        )

    logger.info("Review queue item %s resolved as %s.", queue_id, payload.action.value)
    return resolved
