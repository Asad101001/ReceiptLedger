import sys, os, re
sys.path.insert(0, os.path.abspath('backend'))
from app.services.normalizer import _extract_prices

sample_lines = [
    "19:32:35 Total: 593.10",
    "TOTAL RM 14.10",
    "Total Sales (Inclusive of GST) 64.60\"",
    "Round::d :d Total (RM); 9.60",
    "Total 9,00",
]

for s in sample_lines:
    # 1. Clean decimal comma
    c = re.sub(r"(\d+),(\d{2})\b", r"\1.\2", s)
    # 2. Strip timestamps like 19:32:35 or 12:06:00
    c = re.sub(r"\b\d{1,2}:\d{2}(?::\d{2})?\b", " ", c)
    # 3. Strip currency
    c_norm = re.sub(r"\b(?:RM|CHF|EUR|USD|\$|PKR|Rs\.?)\b", " ", c, flags=re.IGNORECASE)
    
    # Check Pass 0
    m = re.search(r"(?:total|tole|totl|ٹوٹل|کل)[\s=:_;]+(?P<total>\d+(?:\.\d{1,2})?)\b|\b=\s*(?P<total2>\d+(?:\.\d{1,2})?)\s*[=:]?|(?P<total3>\d{2,6})\s*=\s*(?:total|کل|ٹوٹل)", c_norm, re.IGNORECASE)
    if m:
        val = float(m.group("total") or m.group("total2") or m.group("total3"))
        print(f"'{s}' -> Pass 0 matched: {val}")
    else:
        # Check Pass 1
        prices = _extract_prices(c_norm)
        print(f"'{s}' -> Pass 1 prices: {prices}")
