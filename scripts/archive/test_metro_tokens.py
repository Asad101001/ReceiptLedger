import sys
import re
from pathlib import Path
sys.path.insert(0, str(Path("backend").resolve()))

from app.services.preprocessor import preprocess_image
from app.services.tesseract_client import extract_tokens
from app.services.ocr_router import reassemble_lines
from app.services.normalizer import _TAXONOMY, _load_taxonomy

print(f"Taxonomy loaded: {len(_TAXONOMY)} items")

# Test Metro image
metro_path = Path("data/sample_receipts/metro_safari_park_sample.png")
if metro_path.exists():
    img_bytes = metro_path.read_bytes()
    p_img, p_bytes = preprocess_image(img_bytes)
    tokens = extract_tokens(p_img)
    lines = reassemble_lines(tokens)
    print(f"Extracted {len(lines)} lines from Metro receipt")
    for idx, l in enumerate(lines):
        txt = " ".join(t.text for t in l)
        print(f"[{idx:02d}] {txt}")
