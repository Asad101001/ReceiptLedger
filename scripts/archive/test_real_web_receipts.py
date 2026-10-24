import sys, os, asyncio, glob
sys.path.insert(0, os.path.abspath('backend'))
sys.stdout.reconfigure(encoding='utf-8')

from app.services.ingestion import ingest_receipt

async def run():
    files = sorted(glob.glob("data/real_web_receipts/*.jpg"))
    print("=" * 80)
    print(f"RUNNING OCR ON {len(files)} REAL WEB RECEIPTS")
    print("=" * 80)
    
    for idx, path in enumerate(files, 1):
        filename = os.path.basename(path)
        size_kb = os.path.getsize(path) / 1024
        print(f"\n[{idx}/{len(files)}] === {filename} ({size_kb:.1f} KB) ===")
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
            print(f"  Line Items ({len(items)}):")
            for it in items[:10]:  # limit to first 10 for readability
                raw = it.get('raw_text')
                name = it.get('canonical_name')
                qty = it.get('quantity')
                unit = it.get('unit')
                tot = it.get('total_price')
                cat = it.get('category')
                print(f"    * '{raw}' -> {name} | Qty: {qty} {unit} | Price: {tot} | Cat: {cat}")
            if len(items) > 10:
                print(f"    ... and {len(items) - 10} more items")
        except Exception as e:
            import traceback
            print(f"  ERROR processing {filename}: {e}")
            traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(run())
