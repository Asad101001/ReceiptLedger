import re

def test_line(line):
    # Strip leading 3-6 digit SKU/PLU code if followed by letters
    c = re.sub(r"^\s*\d{3,6}\s+([A-Za-z])", r"\1", line)
    print(f"'{line}' -> '{c}'")

test_line("2504 YORCCHUN LOKAM LOKAN MNORN S nH62.50 RM62.00 RM6 z")
test_line("2508 YONGCHUN ait wk LOKAM HNDRN M = -RN79.90 2")
test_line("1317 TRILLIUM 56 BESI")
test_line("9066468 CLEANER 1X 8.02 8.02")
test_line("1 COLGATE DENTAL 1 95 95")
test_line("5kg Chakki Atta 700")
