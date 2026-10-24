# ReceiptLedger – Comprehensive Backend Adversarial Stress & Vulnerability Test Report

**Document ID:** `RL-QA-RPT-2026-003`  
**Execution Date:** 2026-10-24  
**Author / Lead Tester:** Muhammad Asad Khan (Lead Architect & Core Backend)  
**Reviewed By:** Syed Aun Shamsi (Project Manager & QA Lead), Arish Ahmed Khan (Risk Management Lead)  
**Course & Project:** SPM-458 (Software Project Management) – University of Karachi  
**Target Environment:** FastAPI 0.115+ / Python 3.14.7 / Supabase PostgreSQL & Storage / Google Cloud Vision & Gemini Vision  

---

## 1. Executive Summary

To guarantee system resilience, security, and data integrity under hostile or abnormal operating conditions, the ReceiptLedger backend was subjected to an exhaustive, multi-vector adversarial stress and boundary testing campaign. 

The test harness attacked 7 critical backend subsystems across **28 distinct boundary and vulnerability vectors**:
1. **File Ingestion & Stream Parsing:** Zero-byte files, oversized buffers (>10 MB), MIME header spoofing, corrupted JPEG magic bytes, 1x1 micro-resolutions, extreme aspect ratios (20:1500), and flat-color/zero-variance blank photos.
2. **Deduplication Engine Boundaries:** Bit-level Hamming distance thresholds ($\text{dist} \le 4$ vs. $\text{dist} = 5$), corrupted hex strings, and 1-cent variance textual fingerprint discrimination.
3. **NLP Normalization & Price Parsing:** Complex Pakistani retail currency formats (`Rs.`, `PKR`, `/-`, `/=`, `0.00`), barcode/phone number false-positive rejection, packaging units (`kg`, `g`, `ltr`, `dzn`, `pack`), and 10,000-character Roman Urdu stress strings.
4. **Analytics & Query Security:** Calendar boundary enforcement (month 0, 13; year 2019, 2100), rolling trend windows, pagination overflow (`page=999999`), 5 distinct SQL Injection & Cross-Site Scripting (XSS) vectors, and CSV streaming headers.
5. **Review Queue & Crop Workflow:** Non-existent UUIDs (`404`), adversarial resolution payloads (negative prices, zero quantity), and negative/extreme crop bounding-box padding.
6. **Authentication Guardrails:** Malformed email validation (`422`), invalid credential rejection (`401`), and forged/tampered JWT bearer tokens.
7. **Dashboard & Health Observability:** Aggregated KPI calculations, category palette schema compliance, and multi-engine health check probes (`cloud_vision`, `tesseract`, `easyocr`, `gemini`, `database`).

### Execution Summary Metrics
* **Total Adversarial Tests Executed:** 28
* **Passed Tests:** 28 (100.0%)
* **Failed Tests:** 0 (0.0%)
* **Core CLI Regression Suites:** 35 Passed / 0 Failed (100.0%)
* **Discovered Vulnerabilities & Architectural Defects:** 6 identified and immediately mitigated.

---

## 2. Identified Vulnerabilities, Defects & Immediate Mitigations

During initial test execution, 6 defects and vulnerability gaps were identified, analyzed, and mitigated in the backend codebase:

### Defect 1: Review Queue Accepted Negative Item Prices
* **Severity:** **Medium / Data Integrity Vulnerability**
* **Location:** [`backend/app/core/models.py`](file:///c:/Users/Asad/Desktop/ReceiptLedger/backend/app/core/models.py) – `ReviewQueueResolveRequest`
* **Finding:** When resolving a flagged line item via `PATCH /api/v1/review-queue/{id}`, the API accepted negative values (e.g. `confirmed_unit_price: -50.0`, `confirmed_total_price: -50.0`) without raising a validation error (`HTTP 200 OK`). This permitted ledger poisoning and inaccurate analytics totals.
* **Mitigation:** Applied Pydantic `Field(default=None, ge=0.0)` validation constraints to `confirmed_quantity`, `confirmed_unit_price`, and `confirmed_total_price`. Submitting negative values now immediately triggers `HTTP 422 Unprocessable Entity`.

### Defect 2: Missing `color` Key in Dashboard Category Spend Schema
* **Severity:** **Medium / Frontend Crash Risk**
* **Location:** [`backend/app/api/dashboard.py`](file:///c:/Users/Asad/Desktop/ReceiptLedger/backend/app/api/dashboard.py) & [`backend/app/services/store.py`](file:///c:/Users/Asad/Desktop/ReceiptLedger/backend/app/services/store.py)
* **Finding:** The endpoint `GET /api/v1/dashboard/categories` returned category objects with `color_hex` and `category_name`, but consumer clients (React Web Dashboard and Chart.js legends) expected `color` and `name`. Querying the endpoint caused key lookup exceptions (`KeyError: 'color'`).
* **Mitigation:** Updated `CategorySpendDetail` in [`models.py`](file:///c:/Users/Asad/Desktop/ReceiptLedger/backend/app/core/models.py) with `model_post_init` aliases and updated `store.get_categories_detailed()` to return both `color` and `color_hex`, as well as `name` and `category_name`.

### Defect 3: Email Format Validation Bypass in Authentication
* **Severity:** **Low / Input Sanitization Defect**
* **Location:** [`backend/app/core/auth.py`](file:///c:/Users/Asad/Desktop/ReceiptLedger/backend/app/core/auth.py) – `LoginRequest` & `RegisterRequest`
* **Finding:** `LoginRequest.email` was typed as a plain `str`. Submitting malformed email strings (e.g. `"not-an-email"`) passed request validation and reached `authenticate_user()`, returning generic `401 Unauthorized` rather than failing schema validation at the HTTP boundary (`422`).
* **Mitigation:** Implemented a zero-dependency RFC-compliant regex `@field_validator("email")` that enforces valid email syntax and standardizes emails to lowercase, stripping surrounding whitespace and rejecting malformed inputs with `HTTP 422 Unprocessable Entity`.

### Defect 4: Cloud OCR Quota Wastage on Blank / Micro Images
* **Severity:** **Medium / Cost & Quota Risk**
* **Location:** [`backend/app/services/ingestion.py`](file:///c:/Users/Asad/Desktop/ReceiptLedger/backend/app/services/ingestion.py)
* **Finding:** Uploading a 1x1 image or a flat solid grey image (Laplacian variance $= 0.0$) logged a warning but proceeded through the full OCR pipeline, invoking Cloud Vision / Gemini Vision API calls and creating empty receipts in the database.
* **Mitigation:** Introduced fast-fail validation guards in `ingest_receipt`:
  * Images with dimensions under 50px (`w_orig < 50 or h_orig < 50`) immediately raise `ValueError("Image resolution is too small to be a legible receipt.")`.
  * Featureless or solid-color images with blur variance under 5.0 (`blur_score < 5.0`) immediately raise `ValueError("Image is too blurry or featureless...")`.
  * Both conditions return clean `HTTP 422 Unprocessable Entity` before invoking cloud AI services.

### Defect 5: Free / Promotional Items with `0.00` Price Dropped by Normalizer
* **Severity:** **Low / Functional Boundary Defect**
* **Location:** [`backend/app/services/normalizer.py`](file:///c:/Users/Asad/Desktop/ReceiptLedger/backend/app/services/normalizer.py) – `_extract_prices`
* **Finding:** Price regex filter checked `if 0 < val <= 50000.0:`, which strictly excluded `0.00`. Receipts containing zero-amount lines (promotional items, loyalty discounts, subtotal: 0.00) returned empty price lists.
* **Mitigation:** Adjusted the numeric bounds to `if 0.0 <= val <= 50000.0:`, allowing exact zero prices to be extracted and associated with item line entries.

### Defect 6: Unit Normalization Gap for `pack` Syntax
* **Severity:** **Low / NLP Extraction Defect**
* **Location:** [`backend/app/services/normalizer.py`](file:///c:/Users/Asad/Desktop/ReceiptLedger/backend/app/services/normalizer.py) – `_QTY_WITH_UNIT_RE` & `_normalise_unit`
* **Finding:** Retail receipt lines with "pack" or "pk" (e.g. "3 pack soap") failed quantity unit extraction because the regex only checked for `pkt` and `packet`.
* **Mitigation:** Added `pack` and `pk` to `_QTY_WITH_UNIT_RE`, `_QTY_UNIT_PRICE_RE`, `_QTY_UNIT_RE`, and registered them in `_normalise_unit` mapping to canonical `pkt`.

---

## 3. Comprehensive Test Results Matrix

| # | Test Name | Subsystem Category | Status | Latency | Test Vector & Assertion Details |
|:---:|:---|:---:|:---:|:---:|:---|
| 01 | `test_01_upload_empty_file` | Ingestion Boundary | ✅ PASS | 49.0 ms | 0-byte upload safely rejected with HTTP 422. |
| 02 | `test_02_upload_oversized_file` | Ingestion Boundary | ✅ PASS | 54.6 ms | Payload exceeding 10 MB (10,486,784 B) rejected with HTTP 413. |
| 03 | `test_03_upload_mime_spoofing` | Ingestion Security | ✅ PASS | 109.8 ms | HTML disguised as JPEG caught and rejected with HTTP 422. |
| 04 | `test_04_upload_corrupt_jpeg_magic_bytes` | Ingestion Security | ✅ PASS | 6.4 ms | Valid JPEG header followed by garbage bytes caught cleanly by cv2. |
| 05 | `test_05_upload_tiny_1x1_image` | Ingestion Boundary | ✅ PASS | 267.9 ms | 1x1 image rejected with HTTP 422 before OCR invocation. |
| 06 | `test_06_upload_extreme_aspect_ratios` | Ingestion Boundary | ✅ PASS | 28.9 ms | 20x1500 ultra-narrow image handled gracefully without crash. |
| 07 | `test_07_upload_pure_flat_color_blur_filter` | Ingestion Security | ✅ PASS | 40.3 ms | 0-variance solid grey image rejected by Laplacian threshold (422). |
| 08 | `test_08_upload_timestamp_variants` | Ingestion Boundary | ✅ PASS | 8152.2 ms | Robust handling of corrupt timestamp strings and +14:00 TZ offsets. |
| 09 | `test_09_dedup_phash_hamming_boundaries` | Deduplication | ✅ PASS | 0.8 ms | Hamming distance boundary: dist $\le 4 \to$ MATCH; dist $= 5 \to$ UNIQUE. |
| 10 | `test_10_dedup_corrupted_hash_handling` | Deduplication | ✅ PASS | 0.3 ms | Corrupted non-hex string falls back to 999 without exception. |
| 11 | `test_11_dedup_text_fingerprint_normalization_stress` | Deduplication | ✅ PASS | 0.2 ms | Whitespace/punctuation invariant; strictly distinguishes 1-cent delta. |
| 12 | `test_12_normalizer_price_extraction_stress` | Normalization / NLP | ✅ PASS | 0.3 ms | All 6 complex PKR price patterns extracted (including 0.00). |
| 13 | `test_13_normalizer_phone_and_barcode_false_positives` | Normalization / NLP | ✅ PASS | 0.2 ms | Verified that 11-digit phone numbers and barcodes are filtered. |
| 14 | `test_14_normalizer_quantity_and_pack_units` | Normalization / NLP | ✅ PASS | 1.5 ms | Verified `kg`, `g`, `ltr`, `dzn`, `pkt` unit parsing and aliases. |
| 15 | `test_15_normalizer_extreme_fuzzy_matching` | Normalization / NLP | ✅ PASS | 46.2 ms | Severe Roman Urdu typos and 10,000-char input parsed without lag. |
| 16 | `test_16_analytics_monthly_boundary_checks` | Analytics / Query | ✅ PASS | 744.5 ms | Month bounds (1-12) and year bounds (2020-2099) strictly enforced. |
| 17 | `test_17_analytics_trends_bounds` | Analytics / Query | ✅ PASS | 227.1 ms | Rolling trend month window strictly enforced between 1 and 12. |
| 18 | `test_18_analytics_pagination_out_of_bounds` | Analytics / Query | ✅ PASS | 307.3 ms | `page=0` rejected (422); `page=999999` returns clean empty dataset. |
| 19 | `test_19_analytics_security_sql_injection_vectors` | Analytics / Security | ✅ PASS | 713.0 ms | 5 SQLi/XSS attack vectors neutralized across search filters. |
| 20 | `test_20_analytics_export_streaming` | Analytics / Export | ✅ PASS | 224.2 ms | CSV streams valid headers; invalid formats (e.g. PDF) return 400. |
| 21 | `test_21_review_queue_non_existent_item_404` | Review Queue | ✅ PASS | 450.0 ms | Non-existent UUIDs return clean 404 for both resolve and crop. |
| 22 | `test_22_review_queue_adversarial_resolution_payloads` | Review Queue | ✅ PASS | 178.2 ms | Negative price payloads rejected with HTTP 422 by Pydantic validator. |
| 23 | `test_23_review_queue_crop_extreme_padding` | Review Queue | ✅ PASS | 1415.4 ms | Safe coordinate clamping under negative (-0.5) and huge (5.0) padding. |
| 24 | `test_24_auth_invalid_credentials` | Auth Guardrails | ✅ PASS | 29.1 ms | Wrong passwords and non-existent users rejected with HTTP 401. |
| 25 | `test_25_auth_malformed_email` | Auth Guardrails | ✅ PASS | 16.5 ms | Non-RFC email formats rejected with HTTP 422 at request boundary. |
| 26 | `test_26_auth_jwt_tampering_and_expired_tokens` | Auth Guardrails | ✅ PASS | 59.0 ms | Tampered signatures, empty tokens, and forged headers rejected. |
| 27 | `test_27_dashboard_overview_and_categories` | Dashboard API | ✅ PASS | 1354.6 ms | Verified KPI aggregations, category item counts, and hex color tokens. |
| 28 | `test_28_health_check_comprehensive` | Observability | ✅ PASS | 21424.1 ms | All 5 engine probes validated (`cloud_vision`, `tesseract`, `easyocr`, `gemini`, `database`). |

---

## 4. Subsystem Security & Robustness Analysis

### 4.1 Ingestion & Preprocessing Resilience
The FastAPI multipart file receiver now enforces defense-in-depth:
1. **Size check:** Blocks payloads larger than 10MB (`413 Payload Too Large`) before reading entire chunks into heap memory.
2. **Format validation:** Uses file header inspection (magic bytes for JPEG `\xff\xd8\xff`, PNG `\x89PNG`, WEBP `RIFF...WEBP`) to prevent malicious executables or scripts disguised as `.jpg`.
3. **OpenCV sanity checks:** Degenerate dimensions ($<50\text{ px}$) or zero-variance images (Laplacian variance $<5.0$) are rejected with `422 Unprocessable Entity`.

### 4.2 Deduplication Engine Isolation
1. **pHash 64-bit Hamming Distance:** Exact boundary test confirms that a distance $\le 4$ flags a receipt as duplicate (`409 Conflict`), while a distance $\ge 5$ allows scanning.
2. **Text Fingerprinting:** The SHA-256 fingerprint generated from `(merchant_name, date, total_amount)` normalizes away spaces, punctuation, and case, while strictly discriminating 1-cent differences (`1500.00` vs `1500.01`).
3. **Corrupted Input Safety:** Non-hex strings or invalid hashes safely return distance `999` rather than raising uncaught Python exceptions.

### 4.3 Query Parameter & Injection Neutralization
All search and filter parameters passed into `/api/v1/analytics/receipts` were subjected to SQL injection and XSS payloads:
* Escape sequences: `' OR '1'='1`
* Schema destruction: `'; DROP TABLE receipts; --`
* Union leakage: `UNION SELECT null, username, password FROM auth.users--`
* Script tags: `<script>alert('XSS')</script>`
* Null bytes: `%00`

Because ReceiptLedger uses Supabase PostgREST parameter binding and prepared statements, all injection strings were treated strictly as literal string queries, resulting in safe empty result sets (`HTTP 200 OK`) with zero database errors.

---

## 5. Stakeholder Sign-Off

This report confirms that the ReceiptLedger backend has passed all adversarial stress, security, boundary, and regression tests with **100% test pass rate (28/28 stress tests, 35/35 core CLI tests)**. All discovered defects have been mitigated.

| Role | Name | Status | Date |
|:---|:---|:---:|:---:|
| **Lead Architect & Core Backend** | Muhammad Asad Khan | Approved & Signed | 2026-10-24 |
| **Project Manager & QA Lead** | Syed Aun Shamsi | Verified & Approved | 2026-10-24 |
| **Risk Management Lead** | Arish Ahmed Khan | Reviewed & Accepted | 2026-10-24 |
| **Course Instructor** | Humera Azam | Submitted for Review | 2026-10-24 |