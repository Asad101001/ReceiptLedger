import os
import sys
import io
import json
import httpx

# Ensure UTF-8 output on Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# Load env variables from backend/.env
env_file = r"c:\Users\Asad\Desktop\ReceiptLedger\backend\.env"
env_vars = {}
if os.path.exists(env_file):
    with open(env_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                env_vars[k.strip()] = v.strip()

SUPABASE_URL = env_vars.get("SUPABASE_URL", "https://okuxmizxjfddxyrfvdib.supabase.co")
SERVICE_KEY = env_vars.get("SUPABASE_SERVICE_ROLE_KEY", env_vars.get("SUPABASE_ANON_KEY", ""))

headers = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
}

print("=" * 70)
print("             RECEIPTLEDGER - COMPLETE DATABASE DUMP")
print("=" * 70 + "\n")

# 1. Categories
try:
    r = httpx.get(f"{SUPABASE_URL}/rest/v1/categories?select=*&order=name.asc", headers=headers, timeout=15.0)
    cats = r.json() if r.status_code == 200 else []
    cat_map = {c["id"]: c["name"] for c in cats if "id" in c}
    print(f"📁 CATEGORIES ({len(cats)} registered):")
    for idx, c in enumerate(cats, 1):
        print(f"  [{idx}] {c.get('name')} (Hex: {c.get('color_hex')}) - ID: {c.get('id')}")
        if c.get("description"):
            print(f"      Description: {c.get('description')}")
    print()
except Exception as e:
    cat_map = {}
    print("Error querying categories:", e)

print("-" * 70)

# 2. Receipts
try:
    r = httpx.get(f"{SUPABASE_URL}/rest/v1/receipts?select=*&order=created_at.desc", headers=headers, timeout=15.0)
    receipts = r.json() if r.status_code == 200 else []
    print(f"\n📊 RECEIPTS TABLE ({len(receipts)} total):")
    if not receipts:
        print("   (No receipts recorded in database yet)")
    for idx, rec in enumerate(receipts, 1):
        print(f"  [{idx}] Receipt ID : {rec.get('id')}")
        print(f"      Merchant   : {rec.get('merchant_name') or 'Unknown'}")
        print(f"      Date       : {rec.get('receipt_date')} | Total Amount: Rs. {rec.get('total_amount')}")
        print(f"      Type       : {rec.get('receipt_type')} | Status: {rec.get('status')}")
        print(f"      Confidence : {float(rec.get('ocr_confidence') or 0):.2%}")
        print(f"      Created At : {rec.get('created_at')}")
        print()
except Exception as e:
    print("Error querying receipts:", e)

print("-" * 70)

# 3. Line Items
try:
    r = httpx.get(f"{SUPABASE_URL}/rest/v1/line_items?select=*&order=receipt_id,item_name", headers=headers, timeout=15.0)
    items = r.json() if r.status_code == 200 else []
    print(f"\n📦 LINE ITEMS TABLE ({len(items)} total):")
    if not items:
        print("   (No line items recorded yet)")
    for idx, item in enumerate(items, 1):
        cat_name = cat_map.get(item.get("category_id"), item.get("category_id"))
        print(f"  [{idx}] Item ID   : {item.get('id')}")
        print(f"      Receipt ID: {item.get('receipt_id')}")
        print(f"      Name      : {item.get('item_name')} | Category: {cat_name}")
        print(f"      Pricing   : {item.get('quantity')} {item.get('unit')} @ Rs. {item.get('unit_price')} = Rs. {item.get('total_price')}")
        print(f"      Confidence: {float(item.get('confidence_score') or 0):.2%} | Verified: {item.get('is_verified')}")
        if item.get("raw_text"):
            print(f"      Raw OCR   : \"{item.get('raw_text')}\"")
        if item.get("bbox"):
            print(f"      BBox      : {item.get('bbox')}")
        print()
except Exception as e:
    print("Error querying line_items:", e)

print("-" * 70)

# 4. Review Queue
try:
    r = httpx.get(f"{SUPABASE_URL}/rest/v1/review_queue?select=*&order=flagged_at.desc", headers=headers, timeout=15.0)
    reviews = r.json() if r.status_code == 200 else []
    print(f"\n⚠️ REVIEW QUEUE ({len(reviews)} total):")
    if not reviews:
        print("   (Queue is clean - 0 pending reviews)")
    for idx, rev in enumerate(reviews, 1):
        print(f"  [{idx}] Queue ID    : {rev.get('id')}")
        print(f"      Line Item ID: {rev.get('line_item_id')}")
        print(f"      Candidate   : \"{rev.get('candidate_text')}\"")
        print(f"      Confidence  : {float(rev.get('model_confidence') or 0):.2%}")
        print(f"      Status      : {rev.get('review_status')} | Flagged At: {rev.get('flagged_at')}")
        print()
except Exception as e:
    print("Error querying review_queue:", e)

print("-" * 70)

# 5. Receipt Hashes (Deduplication)
try:
    r = httpx.get(f"{SUPABASE_URL}/rest/v1/receipt_hashes?select=*&order=created_at.desc", headers=headers, timeout=15.0)
    hashes = r.json() if r.status_code == 200 else []
    print(f"\n🔐 RECEIPT HASHES ({len(hashes)} records):")
    if not hashes:
        print("   (No hashes recorded)")
    for idx, h in enumerate(hashes, 1):
        sha = h.get('text_fingerprint_sha256') or ""
        print(f"  [{idx}] Hash ID   : {h.get('id')}")
        print(f"      Receipt ID: {h.get('receipt_id')}")
        print(f"      pHash     : {h.get('phash_64')}")
        print(f"      SHA256    : {sha}")
        print(f"      Created At: {h.get('created_at')}")
        print()
except Exception as e:
    print("Error querying receipt_hashes:", e)

print("=" * 70)
