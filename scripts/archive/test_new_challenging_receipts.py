import sys, os, asyncio
sys.path.insert(0, os.path.abspath('backend'))
sys.stdout.reconfigure(encoding='utf-8')

from app.services.ingestion import ingest_receipt

new_samples = [
    ("Pharmacy Thermal (Fazal Din)", "data/sample_receipts/challenging_pharmacy_receipt.jpg"),
    ("Carbon-Copy Karyana (Subhan Allah)", "data/sample_receipts/challenging_carbon_copy_karyana.jpg"),
    ("Greengrocer Marble (Chaudhry Sabzi)", "data/sample_receipts/challenging_greengrocer_marble.jpg"),
    ("POS Creased Roll (Naheed Supermarket)", "data/sample_receipts/challenging_pos_creased_roll.jpg"),
]

async def run():
    print("=" * 65)
    print("TESTING 4 NEW DIVERSE & CHALLENGING BENCHMARK RECEIPTS")
    print("=" * 65)
    for label, path in new_samples:
        print(f"\n>>> [{label}]")
        with open(path, "rb") as f:
            b = f.read()
        res = await ingest_receipt(b)
        d = res.model_dump()
        print(f"Merchant     : {d.get('merchant_name')}")
        print(f"Date         : {d.get('receipt_date')}")
        print(f"Total Amount : Rs. {d.get('total_amount')}")
        print(f"Receipt Type : {d.get('receipt_type')}")
        items = d.get('line_items', [])
        print(f"Extracted Items ({len(items)}):")
        for it in items:
            raw = it.get('raw_text')
            name = it.get('canonical_name')
            qty = it.get('quantity')
            unit = it.get('unit')
            tot = it.get('total_price')
            cat = it.get('category')
            print(f"  - '{raw}' --> {name} ({qty} {unit}) = Rs. {tot} [{cat}]")

asyncio.run(run())
