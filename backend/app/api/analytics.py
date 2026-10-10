"""
ReceiptLedger – Analytics Endpoints
/api/v1/analytics/monthly    GET
/api/v1/analytics/trends     GET
/api/v1/analytics/receipts   GET  (paginated receipt log)

References:
  docs/02_SRS.md § 4.1 (FR-6 Spending Analytics Dashboard)
  docs/09_DEVELOPMENT_PLAN.md § 4 (Week 3 / Day 15)
"""

from __future__ import annotations

import logging
from datetime import date
from typing import Optional

from fastapi import APIRouter, HTTPException, Query, status

from app.core.models import MonthlySummaryResponse, TrendResponse, MonthlyTrendPoint
from app.services import store

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get(
    "/analytics/monthly",
    response_model=MonthlySummaryResponse,
    summary="Monthly spend aggregation and category breakdown",
    tags=["Analytics"],
)
async def get_monthly_summary(
    year: int = Query(
        default=...,
        ge=2020, le=2099,
        description="Calendar year, e.g. 2026",
        examples=[2026],
    ),
    month: int = Query(
        default=...,
        ge=1, le=12,
        description="Calendar month (1-12)",
        examples=[10],
    ),
) -> MonthlySummaryResponse:
    """
    Returns aggregated spending data for the requested month.

    Includes:
    - Total spend
    - Delta vs. the previous month (positive = spent more, negative = spent less)
    - Category breakdown (PKR amounts per category)
    - Receipt count
    """
    current = store.get_monthly_summary(year, month)

    # Compute previous month for delta
    if month == 1:
        prev_year, prev_month = year - 1, 12
    else:
        prev_year, prev_month = year, month - 1

    previous = store.get_monthly_summary(prev_year, prev_month)
    delta = (
        round(current["total_spend"] - previous["total_spend"], 2)
        if previous["total_spend"] > 0
        else None
    )

    return MonthlySummaryResponse(
        period=current["period"],
        total_spend=current["total_spend"],
        delta_previous_month=delta,
        receipt_count=current["receipt_count"],
        category_breakdown=current["category_breakdown"],
    )


@router.get(
    "/analytics/trends",
    response_model=TrendResponse,
    summary="Multi-month spending trend series",
    tags=["Analytics"],
)
async def get_trends(
    months: int = Query(
        default=3,
        ge=1, le=12,
        description="Number of months to include in the trend (1-12)",
    ),
) -> TrendResponse:
    """
    Returns a rolling trend series of monthly spend data for the past N months.
    Used by the multi-month Category Spend Velocity line chart on the dashboard.
    """
    raw = store.get_monthly_trend(months=months)
    return TrendResponse(
        months=[
            MonthlyTrendPoint(
                period=m["period"],
                total_spend=m["total_spend"],
                category_breakdown=m["category_breakdown"],
            )
            for m in raw
        ]
    )


@router.get(
    "/analytics/receipts",
    summary="Paginated receipt ledger",
    tags=["Analytics"],
)
async def get_receipts(
    page: int = Query(default=1, ge=1, description="Page number"),
    page_size: int = Query(default=20, ge=1, le=100, description="Records per page"),
    search: Optional[str] = Query(default=None, description="Filter by merchant name"),
) -> dict:
    """
    Paginated, searchable historical receipt ledger.
    Supports filtering by merchant name substring.
    """
    all_receipts = store.list_receipts()

    if search:
        search_lower = search.lower()
        all_receipts = [
            r for r in all_receipts
            if search_lower in (r.get("merchant_name") or "").lower()
        ]

    total = len(all_receipts)
    start = (page - 1) * page_size
    end = start + page_size
    page_data = all_receipts[start:end]

    # Enrich each receipt with its line items
    enriched = []
    for r in page_data:
        items = store.get_line_items_for_receipt(r["id"])
        enriched.append({**r, "line_items": items})

    return {
        "total": total,
        "page": page,
        "page_size": page_size,
        "receipts": enriched,
    }
