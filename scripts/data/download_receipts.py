import urllib.request
import os

os.makedirs("data/real_web_receipts", exist_ok=True)

test_urls = [
    # bhimrazy receipt-ocr sample
    ("bhimrazy_receipt.jpg", "https://raw.githubusercontent.com/bhimrazy/receipt-ocr/main/images/receipt.jpg"),
    ("bhimrazy_receipt_master.jpg", "https://raw.githubusercontent.com/bhimrazy/receipt-ocr/master/images/receipt.jpg"),
    # SROIE real receipts
    ("sroie_002_retail.jpg", "https://raw.githubusercontent.com/zzzDavid/ICDAR-2019-SROIE/master/data/img/002.jpg"),
    ("sroie_003_market.jpg", "https://raw.githubusercontent.com/zzzDavid/ICDAR-2019-SROIE/master/data/img/003.jpg"),
    ("sroie_004_pharmacy.jpg", "https://raw.githubusercontent.com/zzzDavid/ICDAR-2019-SROIE/master/data/img/004.jpg"),
    ("sroie_007_convenience.jpg", "https://raw.githubusercontent.com/zzzDavid/ICDAR-2019-SROIE/master/data/img/007.jpg"),
    ("sroie_012_restaurant.jpg", "https://raw.githubusercontent.com/zzzDavid/ICDAR-2019-SROIE/master/data/img/012.jpg"),
    ("sroie_015_groceries.jpg", "https://raw.githubusercontent.com/zzzDavid/ICDAR-2019-SROIE/master/data/img/015.jpg"),
    ("sroie_018_cafe.jpg", "https://raw.githubusercontent.com/zzzDavid/ICDAR-2019-SROIE/master/data/img/018.jpg"),
    ("sroie_025_stationery.jpg", "https://raw.githubusercontent.com/zzzDavid/ICDAR-2019-SROIE/master/data/img/025.jpg"),
    ("sroie_040_bakery.jpg", "https://raw.githubusercontent.com/zzzDavid/ICDAR-2019-SROIE/master/data/img/040.jpg"),
    ("sroie_070_fuel.jpg", "https://raw.githubusercontent.com/zzzDavid/ICDAR-2019-SROIE/master/data/img/070.jpg"),
    ("sroie_120_supermarket.jpg", "https://raw.githubusercontent.com/zzzDavid/ICDAR-2019-SROIE/master/data/img/120.jpg"),
    ("sroie_150_express.jpg", "https://raw.githubusercontent.com/zzzDavid/ICDAR-2019-SROIE/master/data/img/150.jpg"),
]

for filename, url in test_urls:
    dest = os.path.join("data", "real_web_receipts", filename)
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            if resp.status == 200:
                content = resp.read()
                with open(dest, "wb") as f:
                    f.write(content)
                print(f"Downloaded {filename} ({len(content)/1024:.1f} KB)")
    except Exception as e:
        print(f"Failed {filename}: {e}")
