import os, sys, cv2
sys.path.insert(0, os.path.abspath('backend'))

from app.services.preprocessor import preprocess_image

path = "data/real_web_receipts/wikimedia_badly_scanned.jpg"
with open(path, "rb") as f:
    b = f.read()

proc_img, proc_bytes = preprocess_image(b)
cv2.imwrite("scratch/proc_badly_scanned.jpg", proc_img)
print(f"Saved scratch/proc_badly_scanned.jpg, shape={proc_img.shape}")
