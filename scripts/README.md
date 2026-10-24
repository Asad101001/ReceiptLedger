# ReceiptLedger Automation & Development Scripts

This directory houses all engineering, verification, data engineering, and DevOps scripts for the ReceiptLedger project. All scratch scripts have been consolidated, categorized, and cleaned up into dedicated subdirectories.

---

## Directory Catalog

```text
scripts/
├── README.md                      # Catalog of all development scripts (this document)
├── devops/                        # Startup runners, tunnels, and environment scripts
│   ├── run_backend.bat            # Standard local FastAPI backend launcher (Port 8000)
│   ├── start_tunneled_backend.bat # 100% Free Public HTTPS tunnel launcher (Cloudflare / Pinggy)
│   ├── tunnel_server.py           # Cross-platform zero-dependency HTTPS tunnel manager
│   └── render_icons.py            # Android & Web raster icon generator
├── testing/                       # Integration, benchmark, and regression test suites
│   ├── vigorous_backend_stress_test.py # 100% endpoint coverage & concurrency stress test
│   ├── test_pipeline_v2.py        # OCR extraction and normalization pipeline validator
│   ├── run_full_diagnostics.py    # Fast backend health and schema diagnostic runner
│   ├── test_batch_receipts.py     # Batch evaluation across real-world receipt images
│   ├── test_upgraded_logic.py     # Taxonomy classification and total parsing verifier
│   ├── test_nlp_areas.py          # Line item NLP extraction & bounding-box test
│   └── test_fuzzy_queries.py      # Merchant fuzzy query and duplicate detection test
├── data/                          # Dataset generation and taxonomy management tools
│   ├── gen_taxonomy.py            # Primary financial category & merchant taxonomy generator
│   ├── expand_taxonomy.py         # Advanced multi-merchant classification expansion
│   ├── download_receipts.py       # Sample receipt dataset downloader
│   ├── check_sroie_urls.py        # Validation probe for SROIE dataset endpoints
│   └── fetch_wikimedia_urls.py    # Public domain sample receipt fetcher
└── archive/                       # Historical research & one-off diagnostic scripts
    ├── test_illum.py
    ├── test_line_parse.py
    ├── test_metro_tokens.py
    ├── test_ocr_scale.py
    ├── test_sku_strip.py
    └── test_total_regex.py
```

---

## 1. DevOps & Tunneling Scripts

### A. Free Public HTTPS Tunnel (`scripts/devops/tunnel_server.py`)
- **Cost**: **$0.00 / month forever**.
- **Credit Card**: **None required**.
- **Usage**:
  ```bash
  python scripts/devops/tunnel_server.py
  # OR double-click run_tunneled_backend.bat in repository root
  ```
- **What it does**:
  1. Starts the FastAPI backend process on `http://127.0.0.1:8000`.
  2. Creates a secure, public HTTPS tunnel using Cloudflare Quick Tunnels (`*.trycloudflare.com`) or fallback OpenSSH Pinggy tunnel (`*.a.pinggy.link`).
  3. Automatically updates `mobile/.env` with `API_BASE_URL=https://...` so mobile and web clients connect immediately without manual configuration.

### B. Local Backend Server (`scripts/devops/run_backend.bat`)
- Boots the local FastAPI backend on `http://localhost:8000` with auto-detected Tesseract OCR and LAN IP resolution.
- Usage: double-click `run_backend.bat` in the repository root.

---

## 2. Testing & Verification Suites

### A. Vigorous Backend Stress Test (`scripts/testing/vigorous_backend_stress_test.py`)
- Executes exhaustive end-to-end tests across 100% of backend endpoints:
  - Authentication (Registration, Login, JWT tokens)
  - Receipt uploads (multipart/form-data, OCR engines)
  - Review queue (listing, triage, confirmation, line item editing)
  - Analytics & monthly summaries
  - Duplicate detection & deduplication checks
  - Concurrent payload stress testing

---

## 3. Data & Taxonomy Tools

### A. Taxonomy Generator (`scripts/data/gen_taxonomy.py`)
- Generates categorized merchant classification dictionaries, SKU normalization rules, and tax pattern matchers across groceries, fuel, dining, utilities, and pharmacy.
