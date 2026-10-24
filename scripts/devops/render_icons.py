import subprocess
import os
from PIL import Image

def main():
    svg_path = r"C:\Users\Asad\Desktop\ReceiptLedger\UI mockups\Icons\app icon.svg"
    with open(svg_path, "r", encoding="utf-8") as f:
        svg_content = f.read()

    # Create HTML templates for square and round icons
    os.makedirs(r"C:\Users\Asad\Desktop\ReceiptLedger\scratch", exist_ok=True)
    
    html_square = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{
    width: 512px; height: 512px;
    display: flex; align-items: center; justify-content: center;
    background: transparent;
  }}
  .icon-box {{
    width: 512px; height: 512px;
    background: #FFFFFF;
    border-radius: 112px;
    display: flex; align-items: center; justify-content: center;
  }}
  svg {{
    width: 380px; height: 380px;
  }}
</style>
</head>
<body>
  <div class="icon-box">
    {svg_content}
  </div>
</body>
</html>"""

    html_round = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{
    width: 512px; height: 512px;
    display: flex; align-items: center; justify-content: center;
    background: transparent;
  }}
  .icon-box {{
    width: 512px; height: 512px;
    background: #FFFFFF;
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    overflow: hidden;
  }}
  svg {{
    width: 370px; height: 370px;
  }}
</style>
</head>
<body>
  <div class="icon-box">
    {svg_content}
  </div>
</body>
</html>"""

    sq_html_path = r"C:\Users\Asad\Desktop\ReceiptLedger\scratch\icon_sq.html"
    rd_html_path = r"C:\Users\Asad\Desktop\ReceiptLedger\scratch\icon_rd.html"
    with open(sq_html_path, "w", encoding="utf-8") as f:
        f.write(html_square)
    with open(rd_html_path, "w", encoding="utf-8") as f:
        f.write(html_round)

    chrome_path = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
    sq_png_path = r"C:\Users\Asad\Desktop\ReceiptLedger\scratch\icon_sq_512.png"
    rd_png_path = r"C:\Users\Asad\Desktop\ReceiptLedger\scratch\icon_rd_512.png"

    cmd1 = [
        chrome_path,
        "--headless",
        "--disable-gpu",
        f"--screenshot={sq_png_path}",
        "--window-size=512,512",
        "--default-background-color=00000000",
        sq_html_path
    ]
    subprocess.run(cmd1, check=True)

    cmd2 = [
        chrome_path,
        "--headless",
        "--disable-gpu",
        f"--screenshot={rd_png_path}",
        "--window-size=512,512",
        "--default-background-color=00000000",
        rd_html_path
    ]
    subprocess.run(cmd2, check=True)

    print("512x512 renders created successfully.")

    # Now downsample using PIL with LANCZOS for crystal-clear icons
    sq_base = Image.open(sq_png_path).convert("RGBA")
    rd_base = Image.open(rd_png_path).convert("RGBA")

    # Mipmap targets:
    # mdpi: 48
    # hdpi: 72
    # xhdpi: 96
    # xxhdpi: 144
    # xxxhdpi: 192
    res_map = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }

    base_res_dir = r"C:\Users\Asad\Desktop\ReceiptLedger\mobile\android\app\src\main\res"
    for folder, size in res_map.items():
        out_dir = os.path.join(base_res_dir, folder)
        os.makedirs(out_dir, exist_ok=True)
        
        sq_resized = sq_base.resize((size, size), Image.Resampling.LANCZOS)
        sq_resized.save(os.path.join(out_dir, "ic_launcher.png"), "PNG")

        rd_resized = rd_base.resize((size, size), Image.Resampling.LANCZOS)
        rd_resized.save(os.path.join(out_dir, "ic_launcher_round.png"), "PNG")
        print(f"Saved {folder} ({size}x{size})")

    # Also save to mobile/assets/icons/app_icon.png and app_icon_round.png
    assets_icons = r"C:\Users\Asad\Desktop\ReceiptLedger\mobile\assets\icons"
    sq_base.save(os.path.join(assets_icons, "app_icon.png"), "PNG")
    rd_base.save(os.path.join(assets_icons, "app_icon_round.png"), "PNG")
    print("Saved 512x512 to assets/icons")

if __name__ == "__main__":
    main()
