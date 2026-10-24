import os, sys, cv2, numpy as np
sys.path.insert(0, os.path.abspath('backend'))
sys.stdout.reconfigure(encoding='utf-8')

from app.services.tesseract_client import extract_tokens
from app.services.ocr_router import reassemble_lines

img = cv2.imread("scratch/proc_badly_scanned.jpg", cv2.IMREAD_GRAYSCALE)

# Illumination flattening using morphological close or large blur division
kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (35, 35))
background = cv2.morphologyEx(img, cv2.MORPH_CLOSE, kernel)
# Divide img by background to flatten shadows
division = np.float32(img) / (np.float32(background) + 1e-5)
normalized = np.uint8(np.clip(division * 255.0, 0, 255))

cv2.imwrite("scratch/illum_norm.jpg", normalized)

# Upscale by 1.8x
upscaled = cv2.resize(normalized, (0, 0), fx=1.8, fy=1.8, interpolation=cv2.INTER_CUBIC)
tokens = extract_tokens(upscaled, lang="eng")
lines = reassemble_lines(tokens)
print(f"Illumination Normalized ({len(tokens)} tokens, {len(lines)} lines):")
for l in lines:
    print("  |", " ".join(t.text for t in l))
