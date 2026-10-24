import urllib.request, json

titles = [
    "File:Grocery Store Receipt in Vienna.jpg",
    "File:Family Dollar store receipt.jpg",
    "File:Receipt.jpg",
    "File:Sample Product Receipt.jpg",
    "File:Receipt RWP.jpg"
]

api_url = "https://commons.wikimedia.org/w/api.php?action=query&titles=" + "|".join(titles).replace(" ", "%20") + "&prop=imageinfo&iiprop=url&format=json"

req = urllib.request.Request(api_url, headers={'User-Agent': 'ReceiptLedgerBot/1.0 (contact: test@example.com)'})
try:
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        pages = data.get("query", {}).get("pages", {})
        for pid, page in pages.items():
            title = page.get("title")
            ii = page.get("imageinfo", [])
            if ii:
                print(f"{title}: {ii[0].get('url')}")
            else:
                print(f"{title}: No imageinfo")
except Exception as e:
    print(f"Error: {e}")
