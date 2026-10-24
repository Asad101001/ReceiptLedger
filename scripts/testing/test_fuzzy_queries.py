import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "backend"))

from app.services.normalizer import fuzzy_match

test_queries = [
    'chakki atta', 'chki ata', 'aata', 'fine atta',
    'super basmati rice', 'chawal', 'sela chawal',
    'dalda cooking oil', 'cokin oil', 'ghee', 'asli ghee',
    'sugar 1kg', 'cheeni', 'chini', 'gur',
    'national iodized salt', 'lahori namak',
    'daal chana', 'deal chana', 'daal masoor', 'dal mash',
    'zeera', 'haldi', 'lal mirch', 'garam masala', 'shan biryani masala',
    'adrak lehsan paste', 'palak', 'spinach per kg',
    'tamatar', 'pyaz', 'aloo', 'kela', 'seb', 'aam',
    'milkpak 1l', 'doodh', 'dahi', 'makhan', 'andey 1dz',
    'dawn bread', 'roti', 'chicken boneless', 'mutton', 'beef qeema',
    'surf excel', 'lemon max bar', 'harpic', 'rose petal tissue',
    'lux soap', 'head and shoulders shampoo', 'colgate toothpaste', 'pampers',
    'panadol extra', 'disprin', 'arinac', 'sancos syrup', 'eno',
    'pepsi 1.5l', 'coca cola', 'tapal danedar tea', 'aquafina water',
    'lays chips', 'sooper biscuits', 'tuc crackers',
    'electricity bill', 'topup'
]

print(f"Testing {len(test_queries)} diverse domain queries against taxonomy:")
passed = 0
for q in test_queries:
    m = fuzzy_match(q)
    if m:
        passed += 1
        print(f"  [PASS] '{q}' -> '{m.canonical_name}' ({m.category})")
    else:
        print(f"  [FAIL] '{q}' -> None")

print(f"\nTotal passed: {passed}/{len(test_queries)} ({passed/len(test_queries)*100:.1f}%)")
