import sys, os, cv2, asyncio
sys.path.insert(0, os.path.abspath('backend'))
sys.stdout.reconfigure(encoding='utf-8')

from app.services.preprocessor import preprocess_image
from app.services.ocr_router import classify_receipt_type, route_and_extract, reassemble_lines

targets = [
    "wikimedia_badly_scanned.jpg",
    "sroie_050.jpg",
    "sroie_020.jpg",
    "sroie_000.jpg",
    "sroie_010.jpg"
]

async def main():
    for name in targets:
        path = os.path.join("data", "real_web_receipts", name)
        print("=" * 80)
        print(f"RAW OCR INSPECTION: {name}")
        print("=" * 80)
        with open(path, "rb") as f:
            img_bytes = f.read()
        
        proc_img, proc_bytes = preprocess_image(img_bytes)
        print(f"Processed shape: {proc_img.shape}")
        
        rtype = classify_receipt_type(proc_img)
        print(f"Receipt type: {rtype}")
        
        tokens, engine = await route_and_extract(proc_img, proc_bytes, rtype)
        print(f"Engine used: {engine} | Total tokens: {len(tokens)}")
        
        lines = reassemble_lines(tokens)
        print(f"Reassembled lines ({len(lines)}):")
        for l in lines:
            txt = " ".join(t.text for t in l)
            print(f"  | {txt}")
        print()

if __name__ == "__main__":
    asyncio.run(main())
