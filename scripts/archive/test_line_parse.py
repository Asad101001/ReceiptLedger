import sys, os
sys.path.insert(0, os.path.abspath('backend'))
sys.stdout.reconfigure(encoding='utf-8')

from app.services.normalizer import _parse_single_line, fuzzy_match

madina_lines = [
    'Atta loka “t4oo 610 LT |',
    'Chawal 2ka 2kq 450 262 Joe',
    'Cheeni_3kq_ 420 63 (5%',
    'Daal Chana 1kg 260 981 tzJb',
    'Ghee tke 500 61',
]

bismillah_lines = [
    'Bismillah General Store',
    'Date: 10/10/23',
    'ae Doodh 2kg #6 roo. Fae',
    'BA2 Dahi if 1 tke BA ip Ge',
    'Anday 1dz',
    'Cheeni tke # \\\\ Us',
    'BS Bread small 40 ee AS,',
    'Bread small 90',
    'Total = 1230 = کل',
]

print('=== MADINA ===')
for l in madina_lines:
    item = _parse_single_line(l, 0.8)
    print(l)
    if item:
        print(f"  -> {item.item_name} {item.quantity} {item.unit} price={item.total_price}")
    else:
        print("  -> None")

print('\n=== BISMILLAH ===')
for l in bismillah_lines:
    item = _parse_single_line(l, 0.8)
    print(l)
    if item:
        print(f"  -> {item.item_name} {item.quantity} {item.unit} price={item.total_price}")
    else:
        print("  -> None")
