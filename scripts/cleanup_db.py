import os
import sys
import io
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

print("=" * 65)
print("             RECEIPTLEDGER - DATABASE CLEANUP")
print("=" * 65 + "\n")

all_receipts = httpx.get(f"{SUPABASE_URL}/rest/v1/receipts?select=*&order=created_at.asc", headers=headers).json()

to_delete = []
to_keep = []

for r in all_receipts:
    r_id = r["id"]
    name = r.get("merchant_name") or ""
    conf = float(r.get("ocr_confidence") or 0)
    created = r.get("created_at") or ""
    
    # 1. ALWAYS protect the user's real uploaded receipt
    if r_id == "335ebf2e-e9c0-4702-8fae-b2f15faeb6fb" or "ARISH" in name.upper():
        to_keep.append(r)
        continue
        
    # 2. "Worst data": Low confidence (< 0.70) or pending review dummy items
    if conf < 0.70 or r.get("status") == "PENDING_REVIEW":
        to_delete.append((r, f"Low confidence ({conf:.0%}) / Pending mock item"))
        continue
        
    # 3. "Oldest data": Duplicate test batches generated earlier in testing
    if created < "2026-10-26T12:50:00":
        to_delete.append((r, f"Old duplicate test batch from {created[:16]}"))
        continue
        
    to_keep.append(r)

print(f"🗑️ Found {len(to_delete)} receipts to clean up:")
for r, reason in to_delete:
    print(f"   [-] Deleting {r['id'][:8]} | {r.get('merchant_name')} (Rs. {r.get('total_amount')}) -> {reason}")

print(f"\n✨ Preserving {len(to_keep)} clean, high-confidence receipts:")
for r in to_keep:
    print(f"   [+] Keeping {r['id'][:8]} | {r.get('merchant_name')} (Rs. {r.get('total_amount')}) | Conf: {float(r.get('ocr_confidence') or 0):.0%}")

# Perform cascading deletion from receipts
deleted_count = 0
for r, _ in to_delete:
    del_res = httpx.delete(f"{SUPABASE_URL}/rest/v1/receipts?id=eq.{r['id']}", headers=headers)
    if del_res.status_code in (200, 204):
        deleted_count += 1
    else:
        print(f"Failed to delete {r['id']}: {del_res.status_code} {del_res.text}")

print(f"\n✅ Cleaned up {deleted_count} receipts successfully!")
print("=" * 65)
