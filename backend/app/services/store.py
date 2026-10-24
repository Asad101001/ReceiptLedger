"""
ReceiptLedger – Data Persistence Store (Supabase + In-Memory Fallback)
=======================================================================
Provides transactional storage operations for:
  • Receipts
  • Line Items
  • Review Queue Items
  • Receipt Deduplication Hashes
  • Spend Categories & Analytics

When Supabase is configured (`settings.supabase_enabled`), all CRUD operations
persist directly to the PostgreSQL database on Supabase.
When Supabase is not configured (e.g. offline dev, isolated test runs), operations
operate against in-memory dictionaries with identical semantics.
"""

from __future__ import annotations

import logging
import uuid
from datetime import date, datetime, timedelta
from typing import Any, Dict, List, Optional

from app.core.config import settings
from app.core.models import SEEDED_CATEGORIES

logger = logging.getLogger(__name__)

# ── In-Memory Tables / Local Cache ────────────────────────────────────────────

_categories: Dict[str, Dict] = {}
_receipts: Dict[str, Dict] = {}
_line_items: Dict[str, Dict] = {}
_review_queue: Dict[str, Dict] = {}
_hashes: Dict[str, Dict] = {}

# Supabase Client Singleton
_supabase_client = None


def _safe_uuid(val: Optional[str]) -> Optional[str]:
    """Ensures a string is a valid UUID, returning None if invalid (e.g. 'anonymous')."""
    if not val:
        return None
    try:
        return str(uuid.UUID(str(val)))
    except (ValueError, AttributeError):
        return None


def get_supabase_client():
    """Lazily initializes and returns the Supabase client if configured."""
    global _supabase_client
    if _supabase_client is not None:
        return _supabase_client

    if not settings.supabase_enabled:
        return None

    try:
        from supabase import create_client

        # Prefer service role key if available for full server access, else anon key
        key = settings.supabase_service_role_key or settings.supabase_anon_key
        _supabase_client = create_client(settings.supabase_url, key)
        logger.info("Supabase client initialized successfully (%s)", settings.supabase_url)
        return _supabase_client
    except Exception as exc:
        logger.error("Failed to initialize Supabase client: %s", exc)
        return None


def _seed_categories() -> None:
    """Pre-populate local category definitions from SEEDED_CATEGORIES."""
    for cat in SEEDED_CATEGORIES:
        cat_id = str(uuid.uuid4())
        _categories[cat_id] = {
            "id": cat_id,
            "name": cat["name"],
            "color_hex": cat["color_hex"],
            "description": cat["description"],
        }


def _sync_categories() -> None:
    """Sync categories from Supabase if configured, otherwise seed locally."""
    client = get_supabase_client()
    if client:
        try:
            res = client.table("categories").select("*").execute()
            if res.data and len(res.data) > 0:
                _categories.clear()
                for row in res.data:
                    _categories[row["id"]] = {
                        "id": row["id"],
                        "name": row["name"],
                        "color_hex": row.get("color_hex", "#6B7280"),
                        "description": row.get("description", ""),
                    }
                return
        except Exception as exc:
            logger.debug("Initial category sync failed: %s", exc)

    _seed_categories()


# Initialize categories on module load
_sync_categories()


def init_supabase() -> bool:
    """
    Called on backend startup when Supabase is enabled.
    Synchronizes categories from Supabase and preloads deduplication hashes.
    """
    client = get_supabase_client()
    if not client:
        return False

    try:
        # 1. Sync Categories from Supabase
        _sync_categories()
        logger.info("Synced %d categories from Supabase", len(_categories))

        # 2. Preload Hashes into Dedup Engine
        hash_res = client.table("receipt_hashes").select("receipt_id, phash_64, text_fingerprint_sha256").execute()
        if hash_res.data:
            from app.services import dedup
            dedup.load_hashes_from_db(hash_res.data)
            logger.info("Preloaded %d deduplication hashes from Supabase", len(hash_res.data))

        return True
    except Exception as exc:
        logger.warning("Supabase initialization sync encountered issue: %s", exc)
        return False


# ── Category Helpers ──────────────────────────────────────────────────────────

def get_category_id(name: str) -> Optional[str]:
    """Return the category UUID for a given category name, or None if not found."""
    # Exact match (case-insensitive)
    for cat_id, cat in _categories.items():
        if cat["name"].lower() == name.lower():
            return cat_id

    # Substring / partial match
    for cat_id, cat in _categories.items():
        if name.lower() in cat["name"].lower() or cat["name"].lower() in name.lower():
            return cat_id

    # Fallback to Miscellaneous
    for cat_id, cat in _categories.items():
        if "misc" in cat["name"].lower():
            return cat_id

    # Fallback to first available category
    if _categories:
        return list(_categories.keys())[0]

    return None


def get_category_name(cat_id: str) -> str:
    """Return category name for a given UUID, defaulting to 'Miscellaneous'."""
    cat = _categories.get(cat_id)
    return cat["name"] if cat else "Miscellaneous"


def get_all_categories() -> List[Dict]:
    """Return all categories."""
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
    receipt_id: Optional[str] = None,
    created_at: Optional[str] = None,
) -> Dict:
    receipt_id = receipt_id or str(uuid.uuid4())
    safe_user = _safe_uuid(user_id)
    r_date = receipt_date or date.today().isoformat()

    row = {
        "id": receipt_id,
        "user_id": user_id or "anonymous",
        "merchant_name": merchant_name,
        "receipt_date": r_date,
        "total_amount": float(total_amount),
        "receipt_type": receipt_type,
        "status": status,
        "ocr_confidence": float(ocr_confidence),
        "created_at": created_at or datetime.utcnow().isoformat(),
    }
    _receipts[receipt_id] = row

    # Persist to Supabase if enabled
    client = get_supabase_client()
    if client:
        try:
            db_payload = {
                "id": receipt_id,
                "user_id": safe_user,
                "merchant_name": merchant_name,
                "receipt_date": r_date,
                "total_amount": float(total_amount),
                "receipt_type": receipt_type,
                "status": status,
                "ocr_confidence": float(ocr_confidence),
            }
            client.table("receipts").insert(db_payload).execute()
        except Exception as exc:
            logger.warning("Failed to insert receipt to Supabase (%s), stored in-memory", exc)

    return row


def get_receipt(receipt_id: str) -> Optional[Dict]:
    """Fetch single receipt by ID."""
    if receipt_id in _receipts:
        return _receipts[receipt_id]

    client = get_supabase_client()
    if client:
        try:
            res = client.table("receipts").select("*").eq("id", receipt_id).execute()
            if res.data and len(res.data) > 0:
                row = res.data[0]
                _receipts[receipt_id] = row
                return row
        except Exception as exc:
            logger.warning("Supabase get_receipt error: %s", exc)

    return None


def list_receipts(user_id: Optional[str] = None, include_items: bool = False) -> List[Dict]:
    """
    List all receipts ordered by created_at descending.
    When include_items=True, executes a single join query (select("*, line_items(*)"))
    in Supabase or pre-populates line items from local cache, eliminating N+1 queries.
    """
    client = get_supabase_client()
    if client:
        try:
            select_cols = "*, line_items(*)" if include_items else "*"
            q = client.table("receipts").select(select_cols).order("created_at", desc=True)
            safe_user = _safe_uuid(user_id)
            if safe_user:
                q = q.eq("user_id", safe_user)
            res = q.execute()
            if res.data is not None:
                for r in res.data:
                    _receipts[r["id"]] = r
                    if include_items:
                        items = r.get("line_items") or []
                        for li in items:
                            li["category_name"] = get_category_name(li.get("category_id", ""))
                            cached = _line_items.get(li["id"])
                            if cached and "bbox" in cached and not li.get("bbox"):
                                li["bbox"] = cached["bbox"]
                            _line_items[li["id"]] = li
                return res.data
        except Exception as exc:
            logger.warning("Supabase list_receipts query error: %s", exc)

    rows = list(_receipts.values())
    if user_id and user_id != "anonymous":
        rows = [r for r in rows if r.get("user_id") == user_id]
    sorted_rows = sorted(rows, key=lambda r: r.get("created_at", ""), reverse=True)

    if include_items:
        enriched = []
        for r in sorted_rows:
            r_copy = dict(r)
            r_copy["line_items"] = [
                li for li in _line_items.values()
                if li.get("receipt_id") == r.get("id")
            ]
            enriched.append(r_copy)
        return enriched

    return sorted_rows


def get_paginated_receipts(
    page: int = 1,
    page_size: int = 20,
    search: Optional[str] = None,
    user_id: Optional[str] = None,
    include_items: bool = True,
) -> Tuple[List[Dict], int]:
    """
    Fetch a paginated slice of receipts with exact total count directly from Supabase or local store.
    Uses database-level .range() and .ilike() filtering to avoid loading the entire table into memory.
    """
    offset = max(0, (page - 1) * page_size)
    client = get_supabase_client()
    if client:
        try:
            select_cols = "*, line_items(*)" if include_items else "*"
            q = client.table("receipts").select(select_cols, count="exact")
            safe_user = _safe_uuid(user_id)
            if safe_user:
                q = q.eq("user_id", safe_user)
            if search and search.strip():
                q = q.ilike("merchant_name", f"%{search.strip()}%")
            q = q.order("created_at", desc=True)
            q = q.range(offset, offset + page_size - 1)
            res = q.execute()

            if res.data is not None:
                total_count = res.count if res.count is not None else len(res.data)
                for r in res.data:
                    _receipts[r["id"]] = r
                    if include_items:
                        items = r.get("line_items") or []
                        for li in items:
                            li["category_name"] = get_category_name(li.get("category_id", ""))
                            cached = _line_items.get(li["id"])
                            if cached and "bbox" in cached and not li.get("bbox"):
                                li["bbox"] = cached["bbox"]
                            _line_items[li["id"]] = li
                return res.data, total_count
        except Exception as exc:
            logger.warning("Supabase get_paginated_receipts query error: %s", exc)

    # Local in-memory fallback
    rows = list(_receipts.values())
    if user_id and user_id != "anonymous":
        rows = [r for r in rows if r.get("user_id") == user_id]
    if search and search.strip():
        s_lower = search.strip().lower()
        rows = [r for r in rows if s_lower in (r.get("merchant_name") or "").lower()]
    sorted_rows = sorted(rows, key=lambda r: r.get("created_at", ""), reverse=True)
    total_count = len(sorted_rows)
    paged_rows = sorted_rows[offset:offset + page_size]

    if include_items:
        enriched = []
        for r in paged_rows:
            r_copy = dict(r)
            r_copy["line_items"] = [
                li for li in _line_items.values()
                if li.get("receipt_id") == r.get("id")
            ]
            enriched.append(r_copy)
        return enriched, total_count

    return paged_rows, total_count


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
    bbox: Optional[Dict[str, Any]] = None,
    item_id: Optional[str] = None,
) -> Dict:
    item_id = item_id or str(uuid.uuid4())
    cat_id = get_category_id(category) or get_category_id("Miscellaneous") or list(_categories.keys())[0]

    row = {
        "id": item_id,
        "receipt_id": receipt_id,
        "category_id": cat_id,
        "category_name": category,
        "raw_text": raw_text,
        "item_name": item_name,
        "quantity": float(quantity),
        "unit": unit,
        "unit_price": float(unit_price),
        "total_price": float(total_price),
        "confidence_score": float(confidence_score),
        "is_verified": is_verified,
        "bbox": bbox,
    }
    _line_items[item_id] = row

    client = get_supabase_client()
    if client:
        db_payload = {
            "id": item_id,
            "receipt_id": receipt_id,
            "category_id": cat_id,
            "raw_text": raw_text,
            "item_name": item_name,
            "quantity": float(quantity),
            "unit": unit,
            "unit_price": float(unit_price),
            "total_price": float(total_price),
            "confidence_score": float(confidence_score),
            "is_verified": is_verified,
        }
        if bbox is not None:
            db_payload["bbox"] = bbox

        try:
            client.table("line_items").insert(db_payload).execute()
        except Exception as exc:
            err_msg = str(exc)
            if "bbox" in err_msg or "PGRST204" in err_msg:
                # Column 'bbox' pending migration in Supabase schema cache; retry without bbox
                try:
                    db_payload.pop("bbox", None)
                    client.table("line_items").insert(db_payload).execute()
                    logger.debug("Inserted line item to Supabase without bbox (migration pending): %s", item_id)
                except Exception as retry_exc:
                    logger.warning("Failed to insert line item to Supabase after stripping bbox: %s", retry_exc)
            else:
                logger.warning("Failed to insert line item to Supabase: %s", exc)

    return row


def get_line_items_for_receipt(receipt_id: str) -> List[Dict]:
    """Retrieve all line items associated with a receipt."""
    client = get_supabase_client()
    if client:
        try:
            res = client.table("line_items").select("*").eq("receipt_id", receipt_id).execute()
            if res.data:
                for item in res.data:
                    item["category_name"] = get_category_name(item.get("category_id", ""))
                    # Preserve runtime bbox if DB table schema has not yet migrated
                    cached = _line_items.get(item["id"])
                    if cached and "bbox" in cached and not item.get("bbox"):
                        item["bbox"] = cached["bbox"]
                    _line_items[item["id"]] = item
                return res.data
        except Exception as exc:
            logger.warning("Supabase get_line_items error: %s", exc)

    return [li for li in _line_items.values() if li.get("receipt_id") == receipt_id]


def get_line_item(item_id: str) -> Optional[Dict]:
    """Retrieve a single line item by ID from cache or database."""
    if item_id in _line_items:
        return _line_items[item_id]
    client = get_supabase_client()
    if client:
        try:
            res = client.table("line_items").select("*").eq("id", item_id).execute()
            if res.data and len(res.data) > 0:
                row = res.data[0]
                row["category_name"] = get_category_name(row.get("category_id", ""))
                _line_items[item_id] = row
                return row
        except Exception as exc:
            logger.warning("Supabase get_line_item error: %s", exc)
    return None


def update_line_item(item_id: str, updates: Dict[str, Any]) -> Optional[Dict]:
    """Update line item fields."""
    if item_id in _line_items:
        _line_items[item_id].update(updates)

    client = get_supabase_client()
    if client:
        try:
            # Clean fields for Supabase table
            db_updates = {k: v for k, v in updates.items() if k != "category_name"}
            client.table("line_items").update(db_updates).eq("id", item_id).execute()
        except Exception as exc:
            logger.warning("Supabase update_line_item error: %s", exc)

    return _line_items.get(item_id)


# ── Deduplication Hashes Persistence ─────────────────────────────────────────

def insert_receipt_hash(receipt_id: str, phash_64: str, text_sha256: str) -> Dict:
    """Stores visual & textual deduplication hashes in Supabase."""
    hash_id = str(uuid.uuid4())
    row = {
        "id": hash_id,
        "receipt_id": receipt_id,
        "phash_64": phash_64,
        "text_fingerprint_sha256": text_sha256,
        "created_at": datetime.utcnow().isoformat(),
    }
    _hashes[receipt_id] = row

    client = get_supabase_client()
    if client:
        try:
            client.table("receipt_hashes").insert({
                "id": hash_id,
                "receipt_id": receipt_id,
                "phash_64": phash_64,
                "text_fingerprint_sha256": text_sha256,
            }).execute()
        except Exception as exc:
            logger.warning("Failed to persist receipt hash to Supabase: %s", exc)

    return row


# ── Review Queue Operations ───────────────────────────────────────────────────

def insert_review_queue_item(
    line_item_id: str,
    candidate_text: str,
    model_confidence: float,
    queue_id: Optional[str] = None,
) -> Dict:
    queue_id = queue_id or str(uuid.uuid4())
    row = {
        "id": queue_id,
        "line_item_id": line_item_id,
        "candidate_text": candidate_text,
        "model_confidence": float(model_confidence),
        "review_status": "UNRESOLVED",
        "flagged_at": datetime.utcnow().isoformat(),
        "resolved_at": None,
    }
    _review_queue[queue_id] = row

    client = get_supabase_client()
    if client:
        try:
            client.table("review_queue").insert({
                "id": queue_id,
                "line_item_id": line_item_id,
                "candidate_text": candidate_text,
                "model_confidence": float(model_confidence),
                "review_status": "UNRESOLVED",
            }).execute()
        except Exception as exc:
            logger.warning("Failed to insert review queue item to Supabase: %s", exc)

    return row


def get_review_queue(status: str = "UNRESOLVED") -> List[Dict]:
    """Return review queue items enriched with receipt and line item details."""
    client = get_supabase_client()
    if client:
        try:
            q = client.table("review_queue").select("*, line_items(*, receipts(*))")
            if status != "ALL":
                q = q.eq("review_status", status)
            q = q.order("flagged_at", desc=True)
            res = q.execute()

            if res.data:
                enriched = []
                for item in res.data:
                    li_data = item.get("line_items") or {}
                    rcpt_data = li_data.get("receipts") or {}
                    li_data["category_name"] = get_category_name(li_data.get("category_id", ""))
                    enriched.append({
                        "id": item["id"],
                        "line_item_id": item["line_item_id"],
                        "candidate_text": item.get("candidate_text", ""),
                        "model_confidence": item.get("model_confidence", 0.0),
                        "review_status": item.get("review_status", "UNRESOLVED"),
                        "flagged_at": item.get("flagged_at"),
                        "resolved_at": item.get("resolved_at"),
                        "line_item": li_data,
                        "receipt_id": li_data.get("receipt_id"),
                        "merchant_name": rcpt_data.get("merchant_name"),
                    })
                return enriched
        except Exception as exc:
            logger.warning("Supabase get_review_queue query error (%s), using local store", exc)

    # Local fallback
    results = []
    for q in _review_queue.values():
        if q["review_status"] != status and status != "ALL":
            continue
        li = _line_items.get(q["line_item_id"], {})
        receipt = _receipts.get(li.get("receipt_id", ""), {})
        results.append({
            **q,
            "line_item": li,
            "receipt_id": li.get("receipt_id"),
            "merchant_name": receipt.get("merchant_name"),
        })
    return sorted(results, key=lambda r: r.get("flagged_at", ""), reverse=True)


def get_review_queue_item(queue_id: str) -> Optional[Dict]:
    """Retrieve a single review queue item enriched with line item and receipt context."""
    client = get_supabase_client()
    if client:
        try:
            res = client.table("review_queue").select("*, line_items(*, receipts(*))").eq("id", queue_id).maybe_single().execute()
            if res and res.data:
                item = res.data
                li_data = item.get("line_items") or {}
                rcpt_data = li_data.get("receipts") or {}
                li_data["category_name"] = get_category_name(li_data.get("category_id", ""))
                return {
                    "id": item["id"],
                    "line_item_id": item["line_item_id"],
                    "candidate_text": item.get("candidate_text", ""),
                    "model_confidence": item.get("model_confidence", 0.0),
                    "review_status": item.get("review_status", "UNRESOLVED"),
                    "flagged_at": item.get("flagged_at"),
                    "resolved_at": item.get("resolved_at"),
                    "line_item": li_data,
                    "receipt_id": li_data.get("receipt_id"),
                    "merchant_name": rcpt_data.get("merchant_name"),
                }
        except Exception as exc:
            logger.warning("Supabase get_review_queue_item error: %s", exc)

    q = _review_queue.get(queue_id)
    if not q:
        return None
    li = _line_items.get(q["line_item_id"], {})
    receipt = _receipts.get(li.get("receipt_id", ""), {})
    return {
        **q,
        "line_item": li,
        "receipt_id": li.get("receipt_id"),
        "merchant_name": receipt.get("merchant_name"),
    }


def resolve_review_queue_item(
    queue_id: str,
    review_status: str,
    confirmed_name: Optional[str] = None,
    confirmed_quantity: Optional[float] = None,
    confirmed_unit: Optional[str] = None,
    confirmed_unit_price: Optional[float] = None,
    confirmed_total_price: Optional[float] = None,
) -> Optional[Dict]:
    """Resolve a review item, updating both review_queue and the target line item."""
    now_str = datetime.utcnow().isoformat()

    # Update in-memory
    if queue_id in _review_queue:
        _review_queue[queue_id]["review_status"] = review_status
        _review_queue[queue_id]["resolved_at"] = now_str
        line_item_id = _review_queue[queue_id]["line_item_id"]
    else:
        line_item_id = None

    updates: Dict[str, Any] = {"is_verified": True}
    if confirmed_name:
        updates["item_name"] = confirmed_name
    if confirmed_quantity is not None:
        updates["quantity"] = float(confirmed_quantity)
    if confirmed_unit:
        updates["unit"] = confirmed_unit
    if confirmed_unit_price is not None:
        updates["unit_price"] = float(confirmed_unit_price)
    if confirmed_total_price is not None:
        updates["total_price"] = float(confirmed_total_price)

    client = get_supabase_client()
    if client:
        try:
            # 1. Update review_queue table
            client.table("review_queue").update({
                "review_status": review_status,
                "resolved_at": now_str,
            }).eq("id", queue_id).execute()

            # 2. Get line_item_id if not found locally
            if not line_item_id:
                rq_row = client.table("review_queue").select("line_item_id").eq("id", queue_id).execute()
                if rq_row.data:
                    line_item_id = rq_row.data[0]["line_item_id"]

            # 3. Update line_item
            if line_item_id:
                update_line_item(line_item_id, updates)
        except Exception as exc:
            logger.warning("Supabase resolve_review_queue_item error: %s", exc)

    if line_item_id:
        update_line_item(line_item_id, updates)

    return _review_queue.get(queue_id)


# ── Analytics Queries ─────────────────────────────────────────────────────────

def get_monthly_summary(year: int, month: int) -> Dict:
    """
    Aggregate spend data for the given year/month.
    Returns category_breakdown, total_spend, receipt_count.
    """
    import calendar as _cal

    period = f"{year:04d}-{month:02d}"
    _, last_day = _cal.monthrange(year, month)

    client = get_supabase_client()
    if client:
        try:
            # Receipts for period
            r_query = client.table("receipts").select("id, total_amount, status") \
                .gte("receipt_date", f"{period}-01") \
                .lte("receipt_date", f"{period}-{last_day:02d}") \
                .neq("status", "DUPLICATE").execute()

            if r_query.data is not None:
                period_receipts = r_query.data
                receipt_ids = [r["id"] for r in period_receipts]
                receipt_count = len(period_receipts)
                total_spend = sum(float(r.get("total_amount", 0.0)) for r in period_receipts)

                category_breakdown: Dict[str, float] = {}
                if receipt_ids:
                    items_res = client.table("line_items").select("total_price, category_id").in_("receipt_id", receipt_ids).execute()
                    if items_res.data:
                        for li in items_res.data:
                            cat_name = get_category_name(li.get("category_id", ""))
                            val = float(li.get("total_price", 0.0))
                            category_breakdown[cat_name] = round(category_breakdown.get(cat_name, 0.0) + val, 2)

                return {
                    "period": period,
                    "total_spend": round(total_spend, 2),
                    "receipt_count": receipt_count,
                    "category_breakdown": category_breakdown,
                }
        except Exception as exc:
            logger.warning("Supabase get_monthly_summary query error: %s", exc)

    # In-memory aggregation fallback
    period_receipts = [
        r for r in _receipts.values()
        if r.get("receipt_date", "").startswith(period) and r.get("status") != "DUPLICATE"
    ]
    receipt_ids = {r["id"] for r in period_receipts}
    items_in_period = [li for li in _line_items.values() if li.get("receipt_id") in receipt_ids]

    total_spend = sum(li.get("total_price", 0.0) for li in items_in_period)
    category_breakdown = {}
    for li in items_in_period:
        cat = li.get("category_name", "Miscellaneous")
        category_breakdown[cat] = round(category_breakdown.get(cat, 0.0) + li.get("total_price", 0.0), 2)

    return {
        "period": period,
        "total_spend": round(total_spend, 2),
        "receipt_count": len(period_receipts),
        "category_breakdown": category_breakdown,
    }


def get_monthly_trend(months: int = 3) -> List[Dict]:
    """
    Return per-month totals for the past N months (oldest to newest).
    Executes a single multi-month window query to Supabase and aggregates into
    periods in-memory, replacing up to 24 sequential queries with 1 fast round trip.
    """
    import calendar as _cal
    today = date.today()
    periods = []
    for i in range(months - 1, -1, -1):
        m = today.month - i
        y = today.year
        while m < 1:
            m += 12
            y -= 1
        periods.append((y, m, f"{y:04d}-{m:02d}"))

    earliest_y, earliest_m, earliest_period = periods[0]
    latest_y, latest_m, latest_period = periods[-1]
    _, last_day = _cal.monthrange(latest_y, latest_m)

    window_start = f"{earliest_period}-01"
    window_end = f"{latest_period}-{last_day:02d}"

    client = get_supabase_client()
    if client:
        try:
            # Single round trip to fetch all receipts and their line items in the entire multi-month window
            res = client.table("receipts").select("id, receipt_date, total_amount, status, line_items(total_price, category_id)") \
                .gte("receipt_date", window_start) \
                .lte("receipt_date", window_end) \
                .neq("status", "DUPLICATE") \
                .execute()

            if res.data is not None:
                # Group by period in-memory
                period_map = {
                    p_str: {"period": p_str, "total_spend": 0.0, "receipt_count": 0, "category_breakdown": {}}
                    for _, _, p_str in periods
                }

                for r in res.data:
                    r_date = str(r.get("receipt_date") or "")[:7]
                    if r_date in period_map:
                        bucket = period_map[r_date]
                        bucket["receipt_count"] += 1
                        bucket["total_spend"] = round(bucket["total_spend"] + float(r.get("total_amount", 0.0)), 2)
                        for li in (r.get("line_items") or []):
                            cat_name = get_category_name(li.get("category_id", ""))
                            val = float(li.get("total_price", 0.0))
                            bucket["category_breakdown"][cat_name] = round(bucket["category_breakdown"].get(cat_name, 0.0) + val, 2)

                return [period_map[p_str] for _, _, p_str in periods]
        except Exception as exc:
            logger.warning("Supabase get_monthly_trend bulk query error: %s", exc)

    # In-memory aggregation fallback
    results = []
    for y, m, _ in periods:
        summary = get_monthly_summary(y, m)
        results.append(summary)
    return results


# ── Dashboard Groundwork Helpers ─────────────────────────────────────────────

def get_review_summary() -> Dict[str, int]:
    """Return counts of review queue items by status."""
    client = get_supabase_client()
    if client:
        try:
            res = client.table("review_queue").select("review_status").execute()
            if res.data is not None:
                total = len(res.data)
                unresolved = sum(1 for q in res.data if q.get("review_status") == "UNRESOLVED")
                accepted = sum(1 for q in res.data if q.get("review_status") == "ACCEPTED")
                edited = sum(1 for q in res.data if q.get("review_status") == "EDITED")
                return {
                    "total": total,
                    "unresolved": unresolved,
                    "accepted": accepted,
                    "edited": edited,
                }
        except Exception as exc:
            logger.warning("Supabase get_review_summary error: %s", exc)

    total = len(_review_queue)
    unresolved = sum(1 for q in _review_queue.values() if q.get("review_status") == "UNRESOLVED")
    accepted = sum(1 for q in _review_queue.values() if q.get("review_status") == "ACCEPTED")
    edited = sum(1 for q in _review_queue.values() if q.get("review_status") == "EDITED")
    return {
        "total": total,
        "unresolved": unresolved,
        "accepted": accepted,
        "edited": edited,
    }


def get_categories_detailed() -> List[Dict]:
    """Return all categories with aggregated spend and item counts across all receipts."""
    client = get_supabase_client()
    cat_spend: Dict[str, float] = {}
    cat_items: Dict[str, int] = {}
    total_all_spend = 0.0

    if client:
        try:
            items_res = client.table("line_items").select("total_price, category_id").execute()
            if items_res.data:
                for li in items_res.data:
                    cname = get_category_name(li.get("category_id", ""))
                    price = float(li.get("total_price", 0.0))
                    cat_spend[cname] = cat_spend.get(cname, 0.0) + price
                    cat_items[cname] = cat_items.get(cname, 0) + 1
                    total_all_spend += price
        except Exception as exc:
            logger.warning("Supabase get_categories_detailed error: %s", exc)

    if not cat_spend:
        for li in _line_items.values():
            cname = li.get("category_name", "Miscellaneous")
            price = li.get("total_price", 0.0)
            cat_spend[cname] = cat_spend.get(cname, 0.0) + price
            cat_items[cname] = cat_items.get(cname, 0) + 1
            total_all_spend += price

    results = []
    for cat in SEEDED_CATEGORIES:
        name = cat["name"]
        spend = round(cat_spend.get(name, 0.0), 2)
        count = cat_items.get(name, 0)
        pct = round((spend / total_all_spend * 100.0), 1) if total_all_spend > 0 else 0.0
        results.append({
            "category_name": name,
            "color_hex": cat["color_hex"],
            "description": cat["description"],
            "total_spend": spend,
            "item_count": count,
            "percentage_of_total": pct,
        })
    return results


def get_dashboard_overview(year: Optional[int] = None, month: Optional[int] = None) -> Dict:
    """
    Consolidated single-call overview data for the Web Dashboard.
    Provides key metric cards, category breakdown, trend context, and recent activity.
    """
    today = date.today()
    target_year = year or today.year
    target_month = month or today.month

    current = get_monthly_summary(target_year, target_month)

    # Previous month calculation
    if target_month == 1:
        prev_year, prev_month = target_year - 1, 12
    else:
        prev_year, prev_month = target_year, target_month - 1

    previous = get_monthly_summary(prev_year, prev_month)

    delta = None
    delta_pct = None
    if previous["total_spend"] > 0:
        delta = round(current["total_spend"] - previous["total_spend"], 2)
        delta_pct = round((delta / previous["total_spend"]) * 100.0, 1)

    # Detailed category breakdown for current period
    cat_map = {c["name"]: c for c in SEEDED_CATEGORIES}
    cat_breakdown: List[Dict] = []
    cur_total = current["total_spend"]

    for name, spend in current["category_breakdown"].items():
        meta = cat_map.get(name, {"color_hex": "#6B7280", "description": ""})
        pct = round((spend / cur_total * 100.0), 1) if cur_total > 0 else 0.0

        cat_breakdown.append({
            "category_name": name,
            "color_hex": meta["color_hex"],
            "description": meta.get("description", ""),
            "total_spend": spend,
            "item_count": 0,
            "percentage_of_total": pct,
        })

    cat_breakdown.sort(key=lambda c: c["total_spend"], reverse=True)
    rev_summary = get_review_summary()

    # Verified items count
    client = get_supabase_client()
    verified_items = 0
    if client:
        try:
            vres = client.table("line_items").select("id", count="exact").eq("is_verified", True).execute()
            verified_items = vres.count or 0
        except Exception:
            verified_items = sum(1 for li in _line_items.values() if li.get("is_verified"))
    else:
        verified_items = sum(1 for li in _line_items.values() if li.get("is_verified"))

    recent = list_receipts()[:5]

    stat_cards = [
        {
            "key": "total_spend",
            "label": "Monthly Expenditure",
            "value": current["total_spend"],
            "formatted_value": f"PKR {current['total_spend']:,.2f}",
            "change": delta,
            "change_type": "increase" if delta and delta > 0 else ("decrease" if delta and delta < 0 else "neutral"),
            "helper_text": f"{delta_pct:+.1f}% vs previous month" if delta_pct is not None else "Baseline month",
        },
        {
            "key": "receipt_count",
            "label": "Ingested Receipts",
            "value": current["receipt_count"],
            "formatted_value": str(current["receipt_count"]),
            "change": current["receipt_count"] - previous["receipt_count"],
            "change_type": "increase" if current["receipt_count"] >= previous["receipt_count"] else "decrease",
            "helper_text": f"{previous['receipt_count']} receipts in prior month",
        },
        {
            "key": "pending_reviews",
            "label": "Pending Verification",
            "value": rev_summary["unresolved"],
            "formatted_value": str(rev_summary["unresolved"]),
            "change": None,
            "change_type": "increase" if rev_summary["unresolved"] > 0 else "neutral",
            "helper_text": "Human-in-the-loop review queue items (< 85% confidence)",
        },
        {
            "key": "avg_ticket",
            "label": "Average Receipt Value",
            "value": round(current["total_spend"] / max(current["receipt_count"], 1), 2) if current["receipt_count"] > 0 else 0.0,
            "formatted_value": f"PKR {round(current['total_spend'] / max(current['receipt_count'], 1), 2) if current['receipt_count'] > 0 else 0.0:,.2f}",
            "change": None,
            "change_type": "neutral",
            "helper_text": "Per transaction average",
        },
    ]

    return {
        "period": current["period"],
        "year": target_year,
        "month": target_month,
        "total_spend": current["total_spend"],
        "delta_previous_month": delta,
        "delta_percentage": delta_pct,
        "receipt_count": current["receipt_count"],
        "pending_review_count": rev_summary["unresolved"],
        "verified_items_count": verified_items,
        "stat_cards": stat_cards,
        "category_breakdown": cat_breakdown,
        "recent_receipts": recent,
    }


def seed_demo_data() -> Dict[str, int]:
    """
    Populate realistic demo receipts, line items, and review queue items.
    Generates 148 receipts for the primary workspace month totaling PKR 184,250.00
    with 7 items in the human review queue, exactly matching the desktop design brief.
    """
    import os
    import shutil
    import random
    from pathlib import Path
    from app.core.run_logger import save_run_log

    today = date.today()
    target_period = "2026-10"
    prev_period = "2026-09"
    today_period = today.strftime("%Y-%m")

    # Sample images directory
    backend_root = Path(__file__).resolve().parents[2]
    repo_root = backend_root.parent
    sample_images_dir = repo_root / "data" / "sample_receipts"
    image_store = _image_store_path()

    def _link_sample_img(receipt_id: str, sample_name: str) -> None:
        src = sample_images_dir / sample_name
        if src.exists():
            ext = src.suffix.lstrip(".")
            dst = image_store / f"{receipt_id}.{ext}"
            try:
                shutil.copyfile(src, dst)
            except Exception:
                pass

    # ── 1. The 7 Human-in-the-Loop Review Queue Receipts ─────────────────────
    # Exact item from PDF Section 6.2:
    review_receipt_1_id = "41fd8d2a-e322-4f5f-aa37-ed65ffab5519"
    review_item_1_id = "93b118b5-12ea-44d5-8bc2-a5d6f1406541"
    review_queue_1_id = "7a79f40f-3047-4d76-a577-a41a58af9a56"

    specific_review_receipts = [
        {
            "receipt_id": review_receipt_1_id,
            "merchant": "Chaudhry Sabzi & Fruit Store",
            "date": f"{target_period}-18",
            "type": "HANDWRITTEN",
            "confidence": 0.76,
            "sample_img": "challenging_greengrocer_marble.jpg",
            "phash": "a7b3c2d4e5f60812",
            "items": [
                {
                    "item_id": review_item_1_id,
                    "queue_id": review_queue_1_id,
                    "name": "Sweet Melon",
                    "raw_text": "129728 WITHA PER KG 0.640",
                    "qty": 0.64,
                    "unit": "kg",
                    "u_price": 199.0,
                    "t_price": 127.36,
                    "conf": 0.745,
                    "cat": "Groceries & Food",
                    "verified": False,
                    "bbox": {"ymin": 0.32, "xmin": 0.08, "ymax": 0.44, "xmax": 0.92},
                },
                {
                    "name": "Fresh Farm Tomatoes 1.5kg",
                    "raw_text": "TOMATOES FARM FRESH 1.5K",
                    "qty": 1.5,
                    "unit": "kg",
                    "u_price": 120.0,
                    "t_price": 180.0,
                    "conf": 0.94,
                    "cat": "Groceries & Food",
                    "verified": True,
                    "bbox": {"ymin": 0.45, "xmin": 0.08, "ymax": 0.55, "xmax": 0.92},
                },
                {
                    "name": "White Potatoes (Aaloo) 2kg",
                    "raw_text": "AALOO 2.0 KG 80",
                    "qty": 2.0,
                    "unit": "kg",
                    "u_price": 80.0,
                    "t_price": 160.0,
                    "conf": 0.91,
                    "cat": "Groceries & Food",
                    "verified": True,
                    "bbox": {"ymin": 0.56, "xmin": 0.08, "ymax": 0.66, "xmax": 0.92},
                },
            ],
        },
        {
            "receipt_id": "8b192e44-d130-4e89-9a71-678cba0123ef",
            "merchant": "Javed Nihari Restaurant",
            "date": f"{target_period}-16",
            "type": "PRINTED",
            "confidence": 0.81,
            "sample_img": "javed_nahari_sample.png",
            "phash": "b8f219c0de3456a1",
            "items": [
                {
                    "name": "Nalli Nihari (Half)",
                    "raw_text": "1 NALLI NIHARI HLF 1150",
                    "qty": 1.0,
                    "unit": "plate",
                    "u_price": 1150.0,
                    "t_price": 1150.0,
                    "conf": 0.762,
                    "cat": "Dining Out",
                    "verified": False,
                    "bbox": {"ymin": 0.40, "xmin": 0.12, "ymax": 0.48, "xmax": 0.88},
                },
                {
                    "name": "Special Roghni Naan",
                    "raw_text": "4 ROGHNI NAAN @ 40",
                    "qty": 4.0,
                    "unit": "pcs",
                    "u_price": 40.0,
                    "t_price": 160.0,
                    "conf": 0.95,
                    "cat": "Dining Out",
                    "verified": True,
                    "bbox": {"ymin": 0.49, "xmin": 0.12, "ymax": 0.56, "xmax": 0.88},
                },
                {
                    "name": "GST Punjab Revenue (16%)",
                    "raw_text": "GST SALES TAX 16% 209.6",
                    "qty": 1.0,
                    "unit": "tax",
                    "u_price": 209.6,
                    "t_price": 209.6,
                    "conf": 0.93,
                    "cat": "Dining Out",
                    "verified": True,
                    "bbox": {"ymin": 0.58, "xmin": 0.12, "ymax": 0.65, "xmax": 0.88},
                },
            ],
        },
        {
            "receipt_id": "a93c72b1-50e4-4fa0-b88d-e4c19208aef7",
            "merchant": "Metro Cash & Carry",
            "date": f"{target_period}-14",
            "type": "PRINTED",
            "confidence": 0.84,
            "sample_img": "metro_safari_park_sample.png",
            "phash": "c4d5e6f7a8b90123",
            "items": [
                {
                    "name": "Ariel Touch of Downy 2kg",
                    "raw_text": "490243015923 ARIEL TOUCH DOWNY 2KG",
                    "qty": 1.0,
                    "unit": "bag",
                    "u_price": 1480.0,
                    "t_price": 1480.0,
                    "conf": 0.795,
                    "cat": "Household & Cleaning",
                    "verified": False,
                    "bbox": {"ymin": 0.46, "xmin": 0.10, "ymax": 0.53, "xmax": 0.90},
                },
                {
                    "name": "Nestle MilkPak 1L x 12 Ctn",
                    "raw_text": "896101412035 NESTLE MILKPAK 12PK",
                    "qty": 1.0,
                    "unit": "ctn",
                    "u_price": 3450.0,
                    "t_price": 3450.0,
                    "conf": 0.96,
                    "cat": "Groceries & Food",
                    "verified": True,
                    "bbox": {"ymin": 0.54, "xmin": 0.10, "ymax": 0.61, "xmax": 0.90},
                },
            ],
        },
        {
            "receipt_id": "3f8812e9-40b8-4c3d-8e44-d890aef01bc3",
            "merchant": "Bin Hashim Pharmacy",
            "date": f"{target_period}-12",
            "type": "PRINTED",
            "confidence": 0.82,
            "sample_img": "challenging_pharmacy_receipt.jpg",
            "phash": "d5e6f7a8b9c01234",
            "items": [
                {
                    "name": "Panadol Extra 500mg Strip",
                    "raw_text": "PANADOL EXTR TAB 20S 140",
                    "qty": 2.0,
                    "unit": "strip",
                    "u_price": 140.0,
                    "t_price": 280.0,
                    "conf": 0.710,
                    "cat": "Health & Pharmacy",
                    "verified": False,
                    "bbox": {"ymin": 0.32, "xmin": 0.08, "ymax": 0.40, "xmax": 0.92},
                },
                {
                    "name": "Colgate Total Toothpaste 140g",
                    "raw_text": "COLGATE TOT TP 140G 310",
                    "qty": 1.0,
                    "unit": "tube",
                    "u_price": 310.0,
                    "t_price": 310.0,
                    "conf": 0.94,
                    "cat": "Personal Care",
                    "verified": True,
                    "bbox": {"ymin": 0.42, "xmin": 0.08, "ymax": 0.50, "xmax": 0.92},
                },
            ],
        },
        {
            "receipt_id": "e721a908-34b2-4d51-9ef2-5bc098124ef1",
            "merchant": "Al-Madina Kiryana Store",
            "date": f"{target_period}-10",
            "type": "HANDWRITTEN",
            "confidence": 0.79,
            "sample_img": "handwritten_receipt_sample.jpg",
            "phash": "e6f7a8b9c0d12345",
            "items": [
                {
                    "name": "Cooking Oil (Dalda Pouch)",
                    "raw_text": "DALDA OIL POUCH 1L 530",
                    "qty": 1.0,
                    "unit": "ltr",
                    "u_price": 530.0,
                    "t_price": 530.0,
                    "conf": 0.720,
                    "cat": "Groceries & Food",
                    "verified": False,
                    "bbox": {"ymin": 0.36, "xmin": 0.06, "ymax": 0.45, "xmax": 0.94},
                },
                {
                    "name": "Sugar (Cheeni) 2kg",
                    "raw_text": "CHEENI 2KG 320",
                    "qty": 2.0,
                    "unit": "kg",
                    "u_price": 160.0,
                    "t_price": 320.0,
                    "conf": 0.92,
                    "cat": "Groceries & Food",
                    "verified": True,
                    "bbox": {"ymin": 0.46, "xmin": 0.06, "ymax": 0.55, "xmax": 0.94},
                },
                {
                    "name": "Eggs (Anday) 1 Dozen",
                    "raw_text": "ANDAY 1 DOZEN 360",
                    "qty": 1.0,
                    "unit": "dozen",
                    "u_price": 360.0,
                    "t_price": 360.0,
                    "conf": 0.95,
                    "cat": "Groceries & Food",
                    "verified": True,
                    "bbox": {"ymin": 0.56, "xmin": 0.06, "ymax": 0.65, "xmax": 0.94},
                },
            ],
        },
        {
            "receipt_id": "c1093b45-78e2-4f12-a89c-30981245def9",
            "merchant": "Subhan Milk Shop",
            "date": f"{target_period}-08",
            "type": "HANDWRITTEN",
            "confidence": 0.78,
            "sample_img": "challenging_carbon_copy_karyana.jpg",
            "phash": "f7a8b9c0d1e23456",
            "items": [
                {
                    "name": "Fresh Khoya Desi 500g",
                    "raw_text": "KHOYA 1/2 KG 450",
                    "qty": 0.5,
                    "unit": "kg",
                    "u_price": 900.0,
                    "t_price": 450.0,
                    "conf": 0.685,
                    "cat": "Groceries & Food",
                    "verified": False,
                    "bbox": {"ymin": 0.34, "xmin": 0.08, "ymax": 0.43, "xmax": 0.90},
                },
                {
                    "name": "Fresh Buffalo Milk 4L",
                    "raw_text": "DOODH 4LTR 880",
                    "qty": 4.0,
                    "unit": "ltr",
                    "u_price": 220.0,
                    "t_price": 880.0,
                    "conf": 0.93,
                    "cat": "Groceries & Food",
                    "verified": True,
                    "bbox": {"ymin": 0.44, "xmin": 0.08, "ymax": 0.52, "xmax": 0.90},
                },
            ],
        },
        {
            "receipt_id": "7421890b-ca56-41e9-9a10-89104523def1",
            "merchant": "Naheed Supermarket",
            "date": f"{target_period}-06",
            "type": "PRINTED",
            "confidence": 0.85,
            "sample_img": "printed_receipt_sample.jpg",
            "phash": "a8b9c0d1e2f34567",
            "items": [
                {
                    "name": "Shan Special Biryani Masala",
                    "raw_text": "SHAN SPEC BIRYANI 100G",
                    "qty": 2.0,
                    "unit": "pack",
                    "u_price": 175.0,
                    "t_price": 350.0,
                    "conf": 0.780,
                    "cat": "Groceries & Food",
                    "verified": False,
                    "bbox": {"ymin": 0.30, "xmin": 0.10, "ymax": 0.38, "xmax": 0.88},
                },
                {
                    "name": "National Tomato Ketchup 500g",
                    "raw_text": "NATIONAL KETCHUP 500G 320",
                    "qty": 1.0,
                    "unit": "bottle",
                    "u_price": 320.0,
                    "t_price": 320.0,
                    "conf": 0.96,
                    "cat": "Groceries & Food",
                    "verified": True,
                    "bbox": {"ymin": 0.40, "xmin": 0.10, "ymax": 0.48, "xmax": 0.88},
                },
                {
                    "name": "Lipton Yellow Label 400g",
                    "raw_text": "LIPTON YLW 400G 680",
                    "qty": 1.0,
                    "unit": "box",
                    "u_price": 680.0,
                    "t_price": 680.0,
                    "conf": 0.95,
                    "cat": "Groceries & Food",
                    "verified": True,
                    "bbox": {"ymin": 0.50, "xmin": 0.10, "ymax": 0.58, "xmax": 0.88},
                },
            ],
        },
    ]

    receipt_count = 0
    item_count = 0
    review_count = 0

    current_month_seeded_total = 0.0

    # Insert the 7 review receipts first
    for r in specific_review_receipts:
        total = sum(i["t_price"] for i in r["items"])
        current_month_seeded_total += total
        rcpt = insert_receipt(
            merchant_name=r["merchant"],
            receipt_date=r["date"],
            total_amount=round(total, 2),
            receipt_type=r["type"],
            status="PENDING_REVIEW",
            ocr_confidence=r["confidence"],
            receipt_id=r.get("receipt_id"),
        )
        receipt_count += 1
        _link_sample_img(rcpt["id"], r["sample_img"])
        insert_receipt_hash(rcpt["id"], r.get("phash", "a1b2c3d4e5f67890"), f"fingerprint_{rcpt['id']}")

        for item in r["items"]:
            li = insert_line_item(
                receipt_id=rcpt["id"],
                raw_text=item["raw_text"],
                item_name=item["name"],
                quantity=item["qty"],
                unit=item["unit"],
                unit_price=item["u_price"],
                total_price=item["t_price"],
                confidence_score=item["conf"],
                category=item["cat"],
                is_verified=item["verified"],
                bbox=item.get("bbox"),
                item_id=item.get("item_id"),
            )
            item_count += 1
            if not item["verified"]:
                insert_review_queue_item(
                    line_item_id=li["id"],
                    candidate_text=item["name"],
                    model_confidence=item["conf"],
                    queue_id=item.get("queue_id"),
                )
                review_count += 1

    # ── 2. Synthesize remaining receipts to reach exactly 148 receipts & PKR 184,250.00 ──
    target_count = 148
    remaining_receipts_count = target_count - len(specific_review_receipts)  # 141 receipts
    target_total_spend = 184250.00
    spend_needed = target_total_spend - current_month_seeded_total

    store_catalog = [
        ("Imtiaz Super Market", "PRINTED", [
            ("Wheat Flour (Chakki Atta) 10kg", 1.0, "bag", 1450.0, "Groceries & Food"),
            ("Olper's Full Cream Milk 1L", 4.0, "ltr", 280.0, "Groceries & Food"),
            ("Surf Excel Detergent 1kg", 1.0, "pkt", 680.0, "Household & Cleaning"),
            ("Tapal Danedar Tea 430g", 1.0, "box", 720.0, "Groceries & Food"),
            ("Dalda Canola Cooking Oil 5L", 1.0, "tin", 2650.0, "Groceries & Food"),
        ]),
        ("Chase Up Departmental Store", "PRINTED", [
            ("Dettol Antibacterial Soap 3-Pk", 1.0, "pack", 450.0, "Personal Care"),
            ("Lays Wavy Masala Potato Chips", 3.0, "pcs", 100.0, "Snacks & Beverages"),
            ("National Tomato Ketchup 500g", 1.0, "bottle", 320.0, "Groceries & Food"),
            ("Ariel Matic Laundry Pods 20s", 1.0, "box", 1250.0, "Household & Cleaning"),
        ]),
        ("Hyperstar Carrefour Clifton", "PRINTED", [
            ("Basmati Super Kernel Rice 5kg", 1.0, "bag", 1850.0, "Groceries & Food"),
            ("Nutella Hazelnut Spread 350g", 1.0, "jar", 980.0, "Snacks & Beverages"),
            ("Dove Moisture Shampoo 360ml", 1.0, "bottle", 790.0, "Personal Care"),
            ("French Baguette Bread", 2.0, "pcs", 220.0, "Groceries & Food"),
        ]),
        ("K-Electric Online Billing", "PRINTED", [
            ("Residential Electricity Bill", 1.0, "bill", 5840.0, "Utilities & Bills"),
        ]),
        ("Sui Southern Gas Company (SSGC)", "PRINTED", [
            ("Monthly Gas Utility Invoice", 1.0, "bill", 1450.0, "Utilities & Bills"),
        ]),
        ("PSO Fuel Station Defense", "PRINTED", [
            ("Altron Premium Petrol 25 Litres", 25.0, "ltr", 282.0, "Transportation"),
        ]),
        ("Shell Select Express", "PRINTED", [
            ("Super Unleaded Petrol 18L", 18.0, "ltr", 282.0, "Transportation"),
            ("Red Bull Energy Drink Can", 2.0, "can", 350.0, "Snacks & Beverages"),
        ]),
        ("D.Watson Chemist & Superstore", "PRINTED", [
            ("Surbex-Z Multivitamin Tablets", 1.0, "box", 480.0, "Health & Pharmacy"),
            ("Dettol Antiseptic Liquid 250ml", 1.0, "bottle", 420.0, "Health & Pharmacy"),
            ("Oral-B Pro-Health Toothbrush", 2.0, "pcs", 290.0, "Personal Care"),
        ]),
        ("Aghas Supermarket Clifton", "PRINTED", [
            ("Philadelphia Cream Cheese 200g", 1.0, "tub", 850.0, "Groceries & Food"),
            ("Twinings Earl Grey Tea 50 Bags", 1.0, "box", 1150.0, "Groceries & Food"),
            ("Belgian Dark Chocolate 100g", 2.0, "bar", 480.0, "Snacks & Beverages"),
        ]),
        ("Rahat Bakery", "PRINTED", [
            ("Special Chicken Patties 6-Pack", 6.0, "pcs", 90.0, "Snacks & Beverages"),
            ("Chocolate Fudge Cake 1.5lb", 1.0, "cake", 1200.0, "Snacks & Beverages"),
            ("Fresh Bran Bread Large", 1.0, "loaf", 180.0, "Groceries & Food"),
        ]),
        ("Espresso Coffee Bar", "PRINTED", [
            ("Double Shot Cafe Latte", 2.0, "cup", 650.0, "Dining Out"),
            ("Belgian Waffle with Maple Syrup", 1.0, "plate", 980.0, "Dining Out"),
        ]),
        ("Del Frio Restaurant", "PRINTED", [
            ("Grilled Moroccan Chicken Steak", 1.0, "plate", 1650.0, "Dining Out"),
            ("Oreo Mudslide Ice Cream Shake", 1.0, "glass", 680.0, "Dining Out"),
        ]),
        ("Baqai Medical Pharmacy", "PRINTED", [
            ("Augmentin 625mg Tablets 14s", 1.0, "box", 740.0, "Health & Pharmacy"),
            ("Brufen 400mg Suspension", 1.0, "bottle", 160.0, "Health & Pharmacy"),
        ]),
    ]

    # Pre-generate target totals that sum exactly to spend_needed
    base_shares = [
        random.uniform(300, 2800) for _ in range(remaining_receipts_count)
    ]
    scale_factor = spend_needed / sum(base_shares)
    adjusted_totals = [round(v * scale_factor, 2) for v in base_shares]
    rounding_diff = round(spend_needed - sum(adjusted_totals), 2)
    adjusted_totals[0] = round(adjusted_totals[0] + rounding_diff, 2)

    sample_hashes = [
        "1a2b3c4d5e6f7089", "9876543210abcdef", "fedcba9876543210",
        "aabbccddeeff0011", "2233445566778899", "3344556677889900",
        "4455667788990011", "5566778899001122", "6677889900112233"
    ]

    for idx, r_total in enumerate(adjusted_totals):
        day_num = 1 + (idx % 28)
        r_date = f"{target_period}-{day_num:02d}"
        store_info = store_catalog[idx % len(store_catalog)]
        m_name, r_type, items_list = store_info

        # Select items fitting r_total
        item_data = []
        item_subtotal = 0.0
        for i_name, i_qty, i_unit, i_uprice, i_cat in items_list:
            t_price = round(i_qty * i_uprice, 2)
            item_data.append((i_name, i_qty, i_unit, i_uprice, t_price, i_cat))
            item_subtotal += t_price

        # Proportionally calibrate item prices so sum equals r_total
        final_items = []
        c_ratio = r_total / max(item_subtotal, 1.0)
        accum = 0.0
        for i_idx, (i_name, i_qty, i_unit, i_uprice, t_price, i_cat) in enumerate(item_data):
            if i_idx == len(item_data) - 1:
                cur_t = round(r_total - accum, 2)
            else:
                cur_t = round(t_price * c_ratio, 2)
                accum += cur_t
            cur_u = round(cur_t / max(i_qty, 1.0), 2)
            final_items.append((i_name, i_qty, i_unit, cur_u, cur_t, i_cat))

        rcpt = insert_receipt(
            merchant_name=m_name,
            receipt_date=r_date,
            total_amount=r_total,
            receipt_type=r_type,
            status="PROCESSED",
            ocr_confidence=round(random.uniform(0.91, 0.99), 3),
        )
        receipt_count += 1
        insert_receipt_hash(rcpt["id"], sample_hashes[idx % len(sample_hashes)], f"sha_{rcpt['id'][:8]}")

        for i_name, i_qty, i_unit, cur_u, cur_t, i_cat in final_items:
            insert_line_item(
                receipt_id=rcpt["id"],
                raw_text=f"{i_name.upper()} {cur_t}",
                item_name=i_name,
                quantity=i_qty,
                unit=i_unit,
                unit_price=cur_u,
                total_price=cur_t,
                confidence_score=round(random.uniform(0.92, 0.99), 3),
                category=i_cat,
                is_verified=True,
            )
            item_count += 1

    # ── 3. Prior Month Baseline (130 Receipts, PKR 161,620.00 -> +14.0% Delta) ──
    prior_count = 130
    prior_target_spend = 161620.00
    prior_shares = [random.uniform(400, 2500) for _ in range(prior_count)]
    prior_scale = prior_target_spend / sum(prior_shares)
    prior_totals = [round(v * prior_scale, 2) for v in prior_shares]
    prior_diff = round(prior_target_spend - sum(prior_totals), 2)
    prior_totals[0] = round(prior_totals[0] + prior_diff, 2)

    for idx, p_total in enumerate(prior_totals):
        day_num = 1 + (idx % 28)
        p_date = f"{prev_period}-{day_num:02d}"
        store_info = store_catalog[idx % len(store_catalog)]
        m_name, r_type, items_list = store_info

        rcpt = insert_receipt(
            merchant_name=m_name,
            receipt_date=p_date,
            total_amount=p_total,
            receipt_type=r_type,
            status="PROCESSED",
            ocr_confidence=round(random.uniform(0.89, 0.98), 3),
        )

        n_items = min(2, len(items_list))
        sub_t_base = round(p_total / n_items, 2)
        accum_p = 0.0
        for i_idx in range(n_items):
            i_name, i_qty, i_unit, i_uprice, i_cat = items_list[i_idx]
            if i_idx == n_items - 1:
                cur_t = round(p_total - accum_p, 2)
            else:
                cur_t = sub_t_base
                accum_p += cur_t
            insert_line_item(
                receipt_id=rcpt["id"],
                raw_text=f"{i_name.upper()}",
                item_name=i_name,
                quantity=i_qty,
                unit=i_unit,
                unit_price=round(cur_t / max(i_qty, 1.0), 2),
                total_price=cur_t,
                confidence_score=round(random.uniform(0.90, 0.98), 3),
                category=i_cat,
                is_verified=True,
            )

    # ── 4. Seed Observability Benchmark Run Logs (PDF 6.0 & Bottom Ribbon) ───
    try:
        save_run_log(
            descriptor="gemini_flash_lite_evaluation_run",
            records=[
                {"receipt_id": review_receipt_1_id, "merchant": "Chaudhry Sabzi & Fruit Store", "model": "gemini-3.5-flash-lite", "latency_ms": 340, "accuracy": 0.962, "success": True},
                {"receipt_id": "8b192e44-d130-4e89-9a71-678cba0123ef", "merchant": "Javed Nihari Restaurant", "model": "gemini-3.5-flash-lite", "latency_ms": 420, "accuracy": 0.958, "success": True},
                {"receipt_id": "a93c72b1-50e4-4fa0-b88d-e4c19208aef7", "merchant": "Metro Cash & Carry", "model": "gemini-3.5-flash-lite", "latency_ms": 490, "accuracy": 0.971, "success": True},
            ],
            metrics={
                "total_records": 148,
                "success_count": 141,
                "failure_count": 7,
                "accuracy_percentage": 96.2,
                "average_latency_ms": 385,
                "p95_latency_ms": 610,
                "model": "gemini-3.5-flash-lite",
            },
            metadata={
                "pipeline": "OpenCV Deskew -> Perceptual Hash -> Gemini Vision -> NLP Normalizer",
                "environment": "Monorepo Gateway v1.0.0",
                "device": "Desktop Ops Console",
            },
            summary_text="ReceiptLedger Benchmark Run: 148 Receipts evaluated. Accuracy: 96.2%. Average latency: 385ms."
        )

        save_run_log(
            descriptor="cloud_vision_hybrid_benchmark",
            records=[
                {"test_set": "sroie_and_pakistani_pos", "accuracy": 0.948, "latency_ms": 520, "success": True}
            ],
            metrics={
                "total_records": 100,
                "success_count": 95,
                "failure_count": 5,
                "accuracy_percentage": 94.8,
                "average_latency_ms": 512,
                "model": "Google Cloud Vision + Tesseract Fallback",
            },
            metadata={"quota_remaining": 950, "batch_mode": True},
        )
    except Exception as exc:
        logger.debug("Observability benchmark run log save exception: %s", exc)

    return {
        "receipts": receipt_count,
        "line_items": item_count,
        "review_items": review_count,
    }


def reset_store() -> None:
    """Clear all receipts, line items, and review items, re-initializing categories."""
    global _receipts, _line_items, _review_queue, _categories, _hashes
    _receipts.clear()
    _line_items.clear()
    _review_queue.clear()
    _categories.clear()
    _hashes.clear()
    _seed_categories()

    client = get_supabase_client()
    if client:
        try:
            # Cascading delete from receipts clears line_items, hashes, and review_queue
            client.table("receipts").delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
            logger.info("Cleared all receipts and related records from Supabase")
        except Exception as exc:
            logger.warning("Supabase reset_store error: %s", exc)


# ── Image Storage Operations ──────────────────────────────────────────────────

def _image_store_path() -> "Path":
    """Return the absolute path to the local image store directory, creating it if needed."""
    from pathlib import Path
    base = Path(settings.image_store_dir)
    if not base.is_absolute():
        # Resolve relative to backend/ root (two levels up from this file: services → app → backend)
        base = Path(__file__).resolve().parents[2] / settings.image_store_dir
    base.mkdir(parents=True, exist_ok=True)
    return base


def save_receipt_image(receipt_id: str, image_bytes: bytes, ext: str = "jpg") -> Optional[str]:
    """
    Persist a preprocessed receipt image.

    Strategy (in order of preference):
    1. Upload to Supabase Storage bucket (``receipt-images``) when configured.
    2. Save to local disk under ``settings.image_store_dir``.

    Returns the local file path (str) on success, or None on failure.
    """
    from pathlib import Path

    local_path = _image_store_path() / f"{receipt_id}.{ext}"

    # Always save locally as a reliable fallback
    try:
        local_path.write_bytes(image_bytes)
        logger.debug("Receipt image saved locally: %s", local_path)
    except Exception as exc:
        logger.warning("Failed to save receipt image locally: %s", exc)
        return None

    # Attempt Supabase Storage upload (non-blocking — local copy is the source of truth)
    client = get_supabase_client()
    if client:
        try:
            storage_path = f"{receipt_id}.{ext}"
            client.storage.from_(settings.supabase_storage_bucket).upload(
                path=storage_path,
                file=image_bytes,
                file_options={"content-type": f"image/{ext}", "upsert": "true"},
            )
            logger.info("Receipt image uploaded to Supabase Storage: %s", storage_path)
        except Exception as exc:
            logger.warning("Supabase Storage upload failed (local copy retained): %s", exc)

    return str(local_path)


def get_receipt_image_path(receipt_id: str) -> Optional[str]:
    """
    Return the local filesystem path for a receipt image, or None if not found.
    Searches for any supported extension (jpg, jpeg, png, webp).
    """
    base = _image_store_path()
    for ext in ("jpg", "jpeg", "png", "webp"):
        p = base / f"{receipt_id}.{ext}"
        if p.exists():
            return str(p)
    return None


def get_receipt_image_bytes(receipt_id: str) -> Optional[bytes]:
    """
    Return raw bytes of a receipt image.

    Checks the local filesystem copy first (<1ms latency), and falls back
    to Supabase Storage if the image was processed on another server or purged locally.
    """
    # 1. Try local disk first (<1ms)
    local_path = get_receipt_image_path(receipt_id)
    if local_path:
        try:
            from pathlib import Path
            return Path(local_path).read_bytes()
        except Exception as exc:
            logger.warning("Failed to read local receipt image: %s", exc)

    # 2. Fall back to Supabase Storage
    client = get_supabase_client()
    if client:
        for ext in ("jpg", "jpeg", "png", "webp"):
            try:
                data = client.storage.from_(settings.supabase_storage_bucket).download(
                    f"{receipt_id}.{ext}"
                )
                if data:
                    logger.debug("Receipt image retrieved from Supabase Storage: %s.%s", receipt_id, ext)
                    return data
            except Exception:
                continue

    return None


def get_supabase_image_url(receipt_id: str, expires_in: int = 3600) -> Optional[str]:
    """
    Generate a temporary signed URL for a receipt image stored in Supabase Storage.

    Args:
        receipt_id: UUID of the receipt.
        expires_in: Seconds until the URL expires (default 1 hour).

    Returns:
        Signed URL string, or None if Supabase Storage is unavailable.
    """
    client = get_supabase_client()
    if not client:
        return None

    for ext in ("jpg", "jpeg", "png", "webp"):
        try:
            result = client.storage.from_(settings.supabase_storage_bucket).create_signed_url(
                path=f"{receipt_id}.{ext}",
                expires_in=expires_in,
            )
            url = result.get("signedURL") or result.get("signedUrl")
            if url:
                return url
        except Exception:
            continue

    return None

