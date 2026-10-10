"""
ReceiptLedger – In-Memory Data Store
======================================
When Supabase is not configured (e.g., local dev / CLI testing), this module
acts as the persistence layer, providing all the same query operations against
in-memory Python dicts.  The interface mirrors what the Supabase client would
provide, making it trivial to swap in the real DB later.

Tables (as Python dicts keyed by UUID str):
  - receipts
  - line_items
  - review_queue
  - categories  (pre-seeded at module load)

All UUIDs are generated via Python's `uuid` module.
"""

from __future__ import annotations

import uuid
from datetime import datetime, date
from typing import Any, Dict, List, Optional

from app.core.models import SEEDED_CATEGORIES


# ── In-Memory Tables ──────────────────────────────────────────────────────────

_categories: Dict[str, Dict] = {}
_receipts: Dict[str, Dict] = {}
_line_items: Dict[str, Dict] = {}
_review_queue: Dict[str, Dict] = {}


def _seed_categories() -> None:
    """Pre-populate the categories table with baseline category definitions."""
    for cat in SEEDED_CATEGORIES:
        cat_id = str(uuid.uuid4())
        _categories[cat_id] = {
            "id": cat_id,
            "name": cat["name"],
            "color_hex": cat["color_hex"],
            "description": cat["description"],
        }


_seed_categories()


# ── Category Helpers ──────────────────────────────────────────────────────────

def get_category_id(name: str) -> Optional[str]:
    """Return the category UUID for a given category name, or None if not found."""
    for cat_id, cat in _categories.items():
        if cat["name"] == name:
            return cat_id
    return None


def get_all_categories() -> List[Dict]:
    return list(_categories.values())


# ── Receipt Operations ────────────────────────────────────────────────────────

def insert_receipt(
    merchant_name: Optional[str],
    receipt_date: Optional[str],
    total_amount: float,
    receipt_type: str,
    status: str,
    ocr_confidence: float,
    user_id: Optional[str] = None,
) -> Dict:
    receipt_id = str(uuid.uuid4())
    row = {
        "id": receipt_id,
        "user_id": user_id or "anonymous",
        "merchant_name": merchant_name,
        "receipt_date": receipt_date or date.today().isoformat(),
        "total_amount": total_amount,
        "receipt_type": receipt_type,
        "status": status,
        "ocr_confidence": ocr_confidence,
        "created_at": datetime.utcnow().isoformat(),
    }
    _receipts[receipt_id] = row
    return row


def get_receipt(receipt_id: str) -> Optional[Dict]:
    return _receipts.get(receipt_id)


def list_receipts(user_id: Optional[str] = None) -> List[Dict]:
    rows = list(_receipts.values())
    if user_id:
        rows = [r for r in rows if r.get("user_id") == user_id]
    return sorted(rows, key=lambda r: r["created_at"], reverse=True)


# ── Line Item Operations ──────────────────────────────────────────────────────

def insert_line_item(
    receipt_id: str,
    raw_text: str,
    item_name: str,
    quantity: float,
    unit: str,
    unit_price: float,
    total_price: float,
    confidence_score: float,
    category: str,
    is_verified: bool = False,
) -> Dict:
    item_id = str(uuid.uuid4())
    cat_id = get_category_id(category) or get_category_id("Miscellaneous")
    row = {
        "id": item_id,
        "receipt_id": receipt_id,
        "category_id": cat_id,
        "category_name": category,
        "raw_text": raw_text,
        "item_name": item_name,
        "quantity": quantity,
        "unit": unit,
        "unit_price": unit_price,
        "total_price": total_price,
        "confidence_score": confidence_score,
        "is_verified": is_verified,
    }
    _line_items[item_id] = row
    return row


def get_line_items_for_receipt(receipt_id: str) -> List[Dict]:
    return [li for li in _line_items.values() if li["receipt_id"] == receipt_id]


def update_line_item(item_id: str, updates: Dict[str, Any]) -> Optional[Dict]:
    if item_id not in _line_items:
        return None
    _line_items[item_id].update(updates)
    return _line_items[item_id]


# ── Review Queue Operations ───────────────────────────────────────────────────

def insert_review_queue_item(
    line_item_id: str,
    candidate_text: str,
    model_confidence: float,
) -> Dict:
    queue_id = str(uuid.uuid4())
    row = {
        "id": queue_id,
        "line_item_id": line_item_id,
        "candidate_text": candidate_text,
        "model_confidence": model_confidence,
        "review_status": "UNRESOLVED",
        "flagged_at": datetime.utcnow().isoformat(),
        "resolved_at": None,
    }
    _review_queue[queue_id] = row
    return row


def get_review_queue(status: str = "UNRESOLVED") -> List[Dict]:
    """Return review queue items, enriched with receipt/line_item data."""
    results = []
    for q in _review_queue.values():
        if q["review_status"] != status and status != "ALL":
            continue
        # Enrich with line item data
        li = _line_items.get(q["line_item_id"], {})
        receipt = _receipts.get(li.get("receipt_id", ""), {})
        results.append({
            **q,
            "line_item": li,
            "receipt_id": li.get("receipt_id"),
            "merchant_name": receipt.get("merchant_name"),
        })
    return sorted(results, key=lambda r: r["flagged_at"], reverse=True)


def resolve_review_queue_item(
    queue_id: str,
    review_status: str,
    confirmed_name: Optional[str] = None,
    confirmed_quantity: Optional[float] = None,
    confirmed_unit: Optional[str] = None,
    confirmed_unit_price: Optional[float] = None,
    confirmed_total_price: Optional[float] = None,
) -> Optional[Dict]:
    if queue_id not in _review_queue:
        return None

    # Update queue record
    _review_queue[queue_id]["review_status"] = review_status
    _review_queue[queue_id]["resolved_at"] = datetime.utcnow().isoformat()

    # Update the underlying line item with confirmed values
    line_item_id = _review_queue[queue_id]["line_item_id"]
    updates: Dict[str, Any] = {"is_verified": True}
    if confirmed_name:
        updates["item_name"] = confirmed_name
    if confirmed_quantity is not None:
        updates["quantity"] = confirmed_quantity
    if confirmed_unit:
        updates["unit"] = confirmed_unit
    if confirmed_unit_price is not None:
        updates["unit_price"] = confirmed_unit_price
    if confirmed_total_price is not None:
        updates["total_price"] = confirmed_total_price

    update_line_item(line_item_id, updates)
    return _review_queue[queue_id]


# ── Analytics Queries ─────────────────────────────────────────────────────────

def get_monthly_summary(year: int, month: int) -> Dict:
    """
    Aggregate spend data for the given year/month.
    Returns category_breakdown, total_spend, receipt_count.
    """
    period = f"{year:04d}-{month:02d}"
    period_receipts = [
        r for r in _receipts.values()
        if r["receipt_date"].startswith(period) and r["status"] != "DUPLICATE"
    ]

    receipt_ids = {r["id"] for r in period_receipts}
    items_in_period = [li for li in _line_items.values() if li["receipt_id"] in receipt_ids]

    total_spend = sum(li["total_price"] for li in items_in_period)
    receipt_count = len(period_receipts)

    # Category breakdown
    category_breakdown: Dict[str, float] = {}
    for li in items_in_period:
        cat = li.get("category_name", "Miscellaneous")
        category_breakdown[cat] = round(category_breakdown.get(cat, 0.0) + li["total_price"], 2)

    return {
        "period": period,
        "total_spend": round(total_spend, 2),
        "receipt_count": receipt_count,
        "category_breakdown": category_breakdown,
    }


def get_monthly_trend(months: int = 3) -> List[Dict]:
    """
    Return per-month totals for the past N months (newest first).
    Useful for the multi-month trend chart.
    """
    from datetime import date, timedelta
    import calendar

    results = []
    today = date.today()

    for i in range(months - 1, -1, -1):
        # Compute target month
        target = today.replace(day=1) - timedelta(days=i * 28)
        # Normalise to first of month
        target = target.replace(day=1)
        summary = get_monthly_summary(target.year, target.month)
        results.append(summary)

    return results
