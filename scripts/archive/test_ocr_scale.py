import os, sys, cv2
sys.path.insert(0, os.path.abspath('backend'))
sys.stdout.reconfigure(encoding='utf-8')

from app.services.tesseract_client import extract_tokens
from app.services.ocr_router import reassemble_lines

img = cv2.imread("scratch/proc_badly_scanned.jpg", cv2.IMREAD_GRAYSCALE)
print(f"Original shape: {img.shape}")

# Test 1: Native
tokens_1 = extract_tokens(img, lang="eng")
lines_1 = reassemble_lines(tokens_1)
print(f"\n--- Native 1x ({len(tokens_1)} tokens, {len(lines_1)} lines) ---")
for l in lines_1:
    print("  |", " ".join(t.text for t in l))

# Test 2: 2.0x upscale
upscaled = cv2.resize(img, (0, 0), fx=2.0, fy=2.0, interpolation=cv2.INTER_CUBIC)
tokens_2 = extract_tokens(upscaled, lang="eng")
lines_2 = reassemble_lines(tokens_2)
print(f"\n--- Upscaled 2.0x ({len(tokens_2)} tokens, {len(lines_2)} lines) ---")
for l in lines_2:
    print("  |", " ".join(t.text for t in l))

# Test 3: Upscaled with gentle unsharp mask
gaussian_3 = cv2.GaussianBlur(upscaled, (0, 0), 2.0)
unsharp = cv2.addWeighted(upscaled, 1.5, gaussian_3, -0.5, 0)
tokens_3 = extract_tokens(unsharp, lang="eng")
lines_3 = reassemble_lines(tokens_3)
print(f"\n--- Upscaled + Unsharp ({len(tokens_3)} tokens, {len(lines_3)} lines) ---")
for l in lines_3:
    print("  |", " ".join(t.text for t in l))
