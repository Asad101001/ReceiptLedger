import sys, os, asyncio
sys.path.insert(0, os.path.abspath('backend'))
sys.stdout.reconfigure(encoding='utf-8')

from app.services.ingestion import ingest_receipt

files = [
    ('Al-Madina (printed)', r'data\sample_receipts\printed_receipt_sample.jpg'),
    ('Imtiaz (printed challenging)', r'data\sample_receipts\printed_receipt_challenging.jpg'),
    ('Madina Karyana (handwritten)', r'data\sample_receipts\handwritten_receipt_sample.jpg'),
    ('Bismillah (handwritten challenging)', r'data\sample_receipts\handwritten_receipt_challenging.jpg'),
]

async def run():
    for label, path in files:
        with open(path, 'rb') as f:
            img_bytes = f.read()
        print('========================================================')
        print('TESTING:', label)
        print('========================================================')
        result = await ingest_receipt(img_bytes)
        d = result.model_dump()
        print('Merchant:', d.get('merchant_name'))
        print('Date:', d.get('receipt_date'))
        print('Total:', d.get('total_amount'))
        print('Type:', d.get('receipt_type'))
        items = d.get('line_items', [])
        print('Items count:', len(items))
        for it in items:
            raw = repr(it.get('raw_text'))
            name = repr(it.get('canonical_name'))
            qty = it.get('quantity')
            unit = it.get('unit')
            tot = it.get('total_price')
            cat = it.get('category')
            print(f'  - {raw} --> {name} {qty} {unit} Total:{tot} [{cat}]')
        print()

asyncio.run(run())
