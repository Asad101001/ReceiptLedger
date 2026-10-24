import sys, os, asyncio
sys.path.insert(0, os.path.abspath('backend'))
sys.stdout.reconfigure(encoding='utf-8')

from app.services.preprocessor import preprocess_image
from app.services.ocr_router import route_and_extract, classify_receipt_type, reassemble_lines
import cv2

async def check():
    path = r'data\sample_receipts\handwritten_receipt_challenging.jpg'
    img = cv2.imread(path)
    with open(path, 'rb') as f:
        img_bytes = f.read()
    prep, _ = preprocess_image(img_bytes)
    rtype = classify_receipt_type(prep)
    print("Classified type:", rtype)
    tokens, eng = await route_and_extract(prep, img_bytes, rtype)
    print(f"Tokens ({len(tokens)}) via {eng}:")
    lines = reassemble_lines(tokens)
    print(f"Reassembled {len(lines)} lines:")
    for idx, line in enumerate(lines):
        line_str = " ".join(t.text for t in line)
        print(f"  [{idx}] {line_str}")

asyncio.run(check())
