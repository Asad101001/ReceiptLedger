<div align="center">

# ReceiptLedger / Dataset & Samples

**Ground-Truth Receipt Repository & Domain Normalization Seed Dictionary.**

[![Target Sample](https://img.shields.io/badge/Target-50%2B%20Receipts-10B981?style=flat-square)](#)
[![Format](https://img.shields.io/badge/Format-JPEG%20%7C%20PNG-3B82F6?style=flat-square)](#)
[![Classes](https://img.shields.io/badge/Classes-Printed%20%26%20Handwritten-8B5CF6?style=flat-square)](#)

</div>

---

## Directory Overview

```text
data/
├── samples/
│   ├── printed/           # Organized supermarket & retail receipts
│   └── handwritten/       # Informal small-shop (kiryana) slips
└── dictionary/
    └── local_taxonomy.json # Local grocery aliases and unit hierarchies
```

---

## Receipt Collection Guidelines

To rigorously evaluate our OCR pipelines against the Statement of Work (SoW) acceptance criteria ($\ge 90\%$ printed, $\ge 70\%$ handwritten), every team member collects **10–15 real physical receipts** following these standards:

### 1. Printed Receipts (`data/samples/printed/`)
* **Sources:** Supermarkets (Imtiaz, Carrefour, Naheed), fuel stations, pharmacies, fast-food outlets.
* **Criteria:** Clear printed line items with visible item descriptions, unit rates, quantities, and totals. Include thermal receipts with mild fading to test contrast recovery.

### 2. Handwritten Slips (`data/samples/handwritten/`)
* **Sources:** Local neighborhood grocery stores (*kiryana*), milk shops, butcher shops, vegetable vendors.
* **Criteria:** Legible handwritten items written in Urdu-English shorthand (*e.g., "Atta 5kg 700", "Dalda 1kg"*) to test our EasyOCR and fuzzy matching pipelines.

---

## Photography Standards

* **Lighting:** Photograph under flat, diffused overhead lighting to minimize harsh drop shadows.
* **Orientation:** Place the paper slip flat on a contrasting surface (dark table for white paper).
* **Frame Coverage:** Ensure all 4 receipt corners are fully visible within the camera viewfinder with a 10% margin.
* **Resolution:** Minimum $1280 \times 720$ px; avoid blurry or motion-degraded captures.
