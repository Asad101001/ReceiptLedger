import sys, os, asyncio, glob
sys.path.insert(0, os.path.abspath('backend'))
sys.stdout.reconfigure(encoding='utf-8')

from app.services.ingestion import ingest_receipt

new_files = [
    "bhimrazy_receipt.jpg",
    "sroie_002_retail.jpg",
    "sroie_003_market.jpg",
    "sroie_004_pharmacy.jpg",
    "sroie_007_convenience.jpg",
    "sroie_012_restaurant.jpg",
    "sroie_015_groceries.jpg",
    "sroie_018_cafe.jpg",
    "sroie_025_stationery.jpg",
    "sroie_040_bakery.jpg",
    "sroie_070_fuel.jpg",
    "sroie_120_supermarket.jpg",
    "sroie_150_express.jpg",
]

async def run():
    print("=" * 80)
    print(f"RUNNING OCR ON {len(new_files)} NEW AUTHENTIC REAL-WORLD RECEIPTS")
    print("=" * 80)
    
    for idx, filename in enumerate(new_files, 1):
        path = os.path.join("data", "real_web_receipts", filename)
        if not os.path.exists(path):
            continue
        size_kb = os.path.getsize(path) / 1024
        print(f"\n[{idx}/{len(new_files)}] === {filename} ({size_kb:.1f} KB) ===")
        try:
            with open(path, "rb") as f:
                content = f.read()
            res = await ingest_receipt(content)
            d = res.model_dump()
            print(f"  Merchant     : {d.get('merchant_name')}")
            print(f"  Date         : {d.get('receipt_date')}")
            print(f"  Total Amount : {d.get('total_amount')}")
            print(f"  Receipt Type : {d.get('receipt_type')}")
            items = d.get('line_items', [])
            print(f"  Extracted Line Items ({len(items)}):")
            for it in items[:8]:
                raw = it.get('raw_text')
                name = it.get('canonical_name')
                qty = it.get('quantity')
                unit = it.get('unit')
                tot = it.get('total_price')
                cat = it.get('category')
                print(f"    * '{raw}' -> {name} | Qty: {qty} {unit} | Price: {tot} | Cat: {cat}")
            if len(items) > 8:
                print(f"    ... and {len(items) - 8} more items")
        except Exception as e:
            import traceback
            print(f"  ERROR processing {filename}: {e}")
            traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(run())
