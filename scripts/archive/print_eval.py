import json

data = json.loads(open("backend/gemini_eval_results.json", encoding="utf-8").read())
print(f"Total Receipts Evaluated: {len(data)}\n")

for idx, r in enumerate(data, 1):
    g = r["gemini"]
    l = r["local"]
    fn = r["filename"]
    print(f"[{idx:02d}] {fn}")
    m = g["merchant_name"]
    d = g["receipt_date"]
    st = g["stated_total"]
    sm = g["items_sum"]
    el = g["elapsed"]
    oq = g["ocr_quality"]
    notes = g["notes"]
    print(f"     Merchant: {m} | Date: {d} | Stated: {st} | Sum: {sm} | Latency: {el}s")
    print(f"     OCR Quality: {oq} | Notes: {notes}")
    print(f"     Gemini Items ({len(g['items'])}):")
    for it in g["items"]:
        print(f"       - {it['item_name']:<32} ({it['category']:<22}) {it['quantity']:>5.2f} {it['unit']:<4} @ {it['unit_price']:>7.2f} = {it['total_price']:>8.2f}")
    print(f"     Local Items ({len(l['items'])}):")
    for it in l["items"]:
        print(f"       - {it['item_name']:<32} ({it['category']:<22}) {it['quantity']:>5.2f} {it['unit']:<4} @ {it['unit_price']:>7.2f} = {it['total_price']:>8.2f}")
    print()
