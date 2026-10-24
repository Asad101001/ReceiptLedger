import sys, os
sys.path.insert(0, os.path.abspath('backend'))
sys.stdout.reconfigure(encoding='utf-8')

from app.services.normalizer import fuzzy_match, _parse_single_line, _extract_prices, _extract_qty_unit
from app.services.ingestion import _extract_merchant, _extract_date, _compute_total
from app.core.models import OCRToken, BoundingBox

print("=" * 70)
print("VERIFYING NLP & HEURISTIC IMPROVEMENTS")
print("=" * 70)

# ── 1. Area B: Semantic Normalization (Rapidfuzz Token-Set & Token-Sort) ─────
print("\n[Area B] Testing Semantic Normalization (Token-Set & Partial Matching):")
test_cases_b = [
    # (query, expected_canonical, expected_match)
    ("Guard Super Kernel Basmati Rice 5kg", "Basmati Rice", True),
    ("Chakki Atta Rozana Fine", "Wheat Flour (Atta)", True),
    ("Shan Biryani Masala Special", "Spices & Recipe Mix", True),
    ("Dalda Cooking Oil 1Ltr", "Cooking Oil", True),
    ("National Iodized Salt 800g", "Salt", True),
    ("Double Sided Tissue Tape 18mm", "Tissue Paper & Paper Towels", False), # Safeguard against false positive!
    ("Aloo 2kg", "Potatoes (Aloo)", True),
    ("Pyaz 1kg", "Onions (Pyaz)", True),
]

for query, expected_name, should_match in test_cases_b:
    match = fuzzy_match(query)
    name = match.canonical_name if match else None
    if should_match:
        success = (name == expected_name)
        status = "PASSED" if success else "FAILED"
        print(f"  [{status}] '{query}' -> Matched: {name} (Expected: {expected_name})")
    else:
        # False positive safeguard
        success = (name != expected_name)
        status = "PASSED (Rejected FP)" if success else "FAILED (False Positive Occurred!)"
        print(f"  [{status}] '{query}' -> Got: {name} (Should NOT match: {expected_name})")

# ── 2. Area A: Dimensional Specs & Multi-Line Continuation ───────────────────
print("\n[Area A] Testing Dimensional Filtering & Noise Separation:")
test_cases_a = [
    ("CHOPPING BOARO 35.5x25.5CM 803M#", "Chopping Boaro", 0.0), # 803M# and 35.5x25.5CM should not be price
    ("BOPP TAPE 48MM*100M CLEAR", "Bopp Tape Clear", 0.0),       # 48MM and 100M should not be price
    ("YE30 BK 7W WW LED TRACK LIGHT", "Ye Bk Ww Led Track Light", 0.0), # 7W should not be price
    ("DOUBLE SIDED TISSUE TAPE 18MM", "Double Sided Tissue Tape", 0.0), # 18MM should not be price
]

for line, expected_name, expected_price in test_cases_a:
    prices = _extract_prices(line)
    qty, unit = _extract_qty_unit(line)
    print(f"  Line: '{line}'")
    print(f"    Extracted prices: {prices} | Qty: {qty} {unit}")

# ── 3. Area C: Key Information Extraction (Total, Date, Merchant) ────────────
print("\n[Area C] Testing Robust Key Information Extraction:")
sample_totals = [
    "TOTAL RM 14.10",
    "TOTAL RM 33,92",
    "Total Sales (Inclusive of GST) 64.60\"",
    "Total Rounded RM 33.90",
    "Amount Payable : 1450.00",
    "Round::d :d Total (RM); 9.60",
]
from app.core.models import LineItemCreate
for st in sample_totals:
    tokens = [OCRToken(text=st, confidence=0.95, bounding_box=BoundingBox(x_min=0, y_min=0, x_max=100, y_max=20))]
    tot = _compute_total([[t for t in tokens]], [])
    print(f"  '{st}' -> Total Extracted: {tot}")

print("\n" + "=" * 70)
