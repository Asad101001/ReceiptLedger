import urllib.request
import urllib.error

# Test candidate URLs from SROIE
candidates = [
    f"https://raw.githubusercontent.com/zzzDavid/ICDAR-2019-SROIE/master/data/img/{i:03d}.jpg"
    for i in [2, 3, 4, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 24, 25, 30, 40, 60, 70, 80, 90, 110, 120, 150]
]

valid_sroie = []
for url in candidates:
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            if response.status == 200:
                valid_sroie.append(url)
                print(f"Found SROIE: {url}")
    except Exception as e:
        pass

print(f"\nTotal valid SROIE found: {len(valid_sroie)}")
