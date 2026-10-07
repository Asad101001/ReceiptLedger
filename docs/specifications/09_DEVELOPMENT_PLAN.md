# Comprehensive Technical Development Plan

### Project: ReceiptLedger
* **Document Version:** 1.0.0
* **Target Audience:** Team Lead & Technical Core
* **Cadence:** 3-Week Compressed Agile Scrum Lifecycle
* **Status:** Working Engineering Blueprint (Local Document — Not Pushed)

---

## 1. System Engineering Objectives & Operational Constraints

### 1.1 Performance & Accuracy SLAs
* **Inference Pipeline Latency:** End-to-end receipt extraction (Image ingestion $\rightarrow$ Preprocessing $\rightarrow$ OCR $\rightarrow$ Normalization $\rightarrow$ Persistence) must complete in $\le 3.5$ seconds for printed slips and $\le 5.0$ seconds for handwritten slips on standard broadband.
* **Dashboard Query Latency:** Analytics endpoints (`/api/v1/analytics/monthly`) must respond in $< 800$ ms for datasets up to 2,000 receipts.
* **Accuracy Thresholds (SMART Criteria):**
  * **Printed Receipt OCR:** $\ge 90\%$ character/token accuracy.
  * **Handwritten Receipt OCR:** $\ge 70\%$ word accuracy post-domain dictionary correction.
  * **Rule-Based Categorization:** $\ge 85\%$ correct classification without user correction.
  * **Duplicate Detection:** Zero false negatives on re-scanned slips; false-positive rate $\le 2\%$.

### 1.2 Free-Tier Operational Constraints
* **Google Cloud Vision API:** Strictly capped at $\le 1,000$ units/month. Implement proactive request counters and failover routing to local Tesseract 5.
* **Supabase (PostgreSQL):** Free tier limit (500 MB database, 1 GB storage). Keep image blobs optimized (JPEG quality $85\%$, max resolution $1920 \times 1080$, file size $\le 1.2$ MB).
* **Compute Footprint:** Backend workloads must run within standard CPU bounds without requiring CUDA GPU hardware.

---

## 2. Technical Architecture & Component Specifications

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION TIER                               │
│  [Mobile Client - Flutter]                [Web Dashboard - React/Vite] │
│  - Camera Stream & Edge Guide             - Monthly Spend Cards        │
│  - Client-side Image Compression          - Category Donut / Trend Line│
│  - Multipart Upload Payload               - Review Queue Slice Viewer  │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │ HTTPS / REST
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      INGESTION & GATEWAY TIER                          │
│  [FastAPI API Gateway]                                                 │
│  - Request Validation (Pydantic v2)       - CORS Middleware            │
│  - Multipart File Streaming               - Rate Limiting & Auth       │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                    COMPUTER VISION PIPELINE (OpenCV)                   │
│  1. Grayscale & Gaussian Blur (k=5)                                    │
│  2. Canny Edge Detection (T_low=75, T_high=200)                        │
│  3. Contour Extraction & Douglas-Peucker Approx (4-point polygon)      │
│  4. Perspective Warp Transform (cv2.warpPerspective)                   │
│  5. Adaptive Contrast Enhancement (CLAHE + Otsu Binarization)          │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     OCR DECISION & ROUTING ENGINE                      │
│  ┌───────────────────────────────┬──────────────────────────────────┐  │
│  │ Path A: Google Cloud Vision   │ Path B: EasyOCR CRNN Engine      │  │
│  │ - TEXT_DETECTION endpoint     │ - PyTorch CPU inference          │  │
│  │ - Bounding vertices & words   │ - Token-level confidence scoring │  │
│  │ - Fallback: Tesseract 5       │ - Diffing with Tesseract digits  │  │
│  └───────────────────────────────┴──────────────────────────────────┘  │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│              SPATIAL RECONSTRUCTION & GEOMETRY CLUSTERING              │
│  - Sweep-line vertical baseline clustering (|y_i - y_j| <= delta_y)    │
│  - Horizontal sorting by x_min                                         │
│  - Line reconstruction: [Item Tokens] [Qty/Unit] [Price/Amount]        │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                    NLP NORMALIZATION & MATCHING                        │
│  - Regex Parsers for Quantities (\d+(\.\d+)?) & Units (kg|g|ltr|pcs)   │
│  - Currency & Price Normalization (Rs / PKR / Float)                   │
│  - Levenshtein Distance Matcher against Local Dictionary (ratio >= 0.8)│
│  - Canonical Entity Mapping & Metric Unit Conversion                   │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                  DEDUPLICATION & RULE CATEGORIZATION                   │
│  - 64-bit DCT Perceptual Hashing (pHash, Hamming Distance <= 4)        │
│  - Text Fingerprint: SHA-256(merchant_slug + date_iso + amount_cents)  │
│  - Priority Rule-Based Categorizer (Keyword heuristics)                │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     DATA PERSISTENCE (Supabase)                        │
│  - PostgreSQL 3NF Schema: receipts, line_items, receipt_hashes         │
│  - Conditional Review Queue: flag items where confidence < 0.85        │
│  - Materialized Aggregate Views for Instant Dashboard Rendering        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Subsystem Implementation Specifications

### 3.1 Subsystem 1: Computer Vision Preprocessing (`backend/app/services/preprocessor.py`)

#### Pipeline Logic:
1. **Color Conversion & Noise Filtering:**
   ```python
   gray = cv2.cvtColor(image_np, cv2.COLOR_BGR2GRAY)
   blurred = cv2.GaussianBlur(gray, (5, 5), 0)
   ```
2. **Edge Map Computation:**
   ```python
   edged = cv2.Canny(blurred, 75, 200)
   ```
3. **Corner Detection & Sorting:**
   * Extract external contours via `cv2.findContours(edged, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)`.
   * Sort contours by area descending and select the largest candidate.
   * Compute polygon perimeter: `peri = cv2.arcLength(c, True)`.
   * Approximate polygon: `approx = cv2.approxPolyDP(c, 0.02 * peri, True)`.
   * If `len(approx) == 4`, extract the 4 coordinate points. Otherwise, crop to the centered $90\%$ bounding box.
   * Coordinate order: `[top-left, top-right, bottom-right, bottom-left]` calculated using $(x + y)$ and $(y - x)$ extremal sums.
4. **Warp Perspective Transformation:**
   * Compute destination rectangle dimensions ($w_{\text{max}}, h_{\text{max}}$).
   * Calculate transformation matrix: `M = cv2.getPerspectiveTransform(src_rect, dst_rect)`.
   * Apply transform: `warped = cv2.warpPerspective(gray, M, (w_max, h_max))`.
5. **Contrast Enhancement & Binarization:**
   * Apply CLAHE to resolve shadows:
     ```python
     clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
     enhanced = clahe.apply(warped)
     ```
   * Apply Otsu thresholding or adaptive Gaussian thresholding (`cv2.adaptiveThreshold(enhanced, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2)`).

---

### 3.2 Subsystem 2: Dual OCR Pipeline & Quota Manager (`backend/app/services/ocr_router.py`)

#### Module Responsibilities:
* **Router Logic:** Classifies incoming image as printed retail slip or handwritten note using heuristic edge density and font stroke variance, or mobile UI toggle.
* **Google Cloud Vision Client (`cloud_vision_client.py`):**
  * Invokes `google.cloud.vision_v1.ImageAnnotatorClient.text_detection`.
  * Parses `response.text_annotations`:
    * Index `0`: Full aggregated text string.
    * Indices `1..n`: Individual word tokens with 4-point bounding polygons and UTF-8 bounding boxes.
* **Quota Sentinel:**
  * Increments atomic Redis/PostgreSQL counter per API invocation.
  * If counter $> 950$ within the billing period, automatically diverts printed extraction traffic to local Tesseract 5.
* **Local Tesseract 5 Engine (`tesseract_client.py`):**
  * Invokes `pytesseract.image_to_data(image, output_type=Output.DICT, config='--oem 1 --psm 6')`.
  * Extracts words, line numbers, bounding coordinates, and confidence ratings.
* **EasyOCR Engine (`easyocr_client.py`):**
  * Initialized once as a singleton: `reader = easyocr.Reader(['en'], gpu=False)`.
  * Executes CRNN inference returning `(bbox, text, confidence)`.
  * Secondary token voting: Compares isolated numeric tokens against Tesseract digit-only whitelist (`--psm 10 -c tessedit_char_whitelist=0123456789.`) to resolve price misidentifications.

---

### 3.3 Subsystem 3: Spatial Line Reassembly Algorithm

Raw OCR engines output unstructured bounding box lists. To reconstruct structured line items:

```python
def reassemble_lines(tokens: list[dict], y_tolerance: int = 15) -> list[list[dict]]:
    """
    Groups word tokens into logical horizontal text lines using a sweep-line algorithm.
    """
    # 1. Sort tokens primarily by vertical top coordinate
    sorted_tokens = sorted(tokens, key=lambda t: t['bounding_box']['y_min'])
    lines = []
    current_line = []
    
    for token in sorted_tokens:
        if not current_line:
            current_line.append(token)
            continue
            
        # Compute vertical center overlap
        curr_y = token['bounding_box']['y_center']
        line_y_avg = sum(t['bounding_box']['y_center'] for t in current_line) / len(current_line)
        
        if abs(curr_y - line_y_avg) <= y_tolerance:
            current_line.append(token)
        else:
            # Sort completed line left-to-right by x_min coordinate
            lines.append(sorted(current_line, key=lambda t: t['bounding_box']['x_min']))
            current_line = [token]
            
    if current_line:
        lines.append(sorted(current_line, key=lambda t: t['bounding_box']['x_min']))
        
    return lines
```

---

### 3.4 Subsystem 4: NLP Normalization & Fuzzy Matching (`backend/app/services/normalizer.py`)

#### 1. Regex Extraction Patterns:
```regex
# Quantity & Unit Pattern
(?P<qty>\d+(?:\.\d+)?)\s*(?P<unit>kg|g|gm|gram|ltr|liter|litre|ml|pkt|packet|pcs|pc|dzn|dozen)?

# Price / Amount Pattern
(?:Rs\.?|PKR\s*)?(?P<price>\d+(?:,\d+)*(?:\.\d{2})?)
```

#### 2. Fuzzy String Distance Normalization:
* Dictionary stored in memory as an indexed inverted list:
  ```json
  {
    "canonical_name": "Wheat Flour (Atta)",
    "category": "Groceries & Food",
    "standard_unit": "kg",
    "aliases": ["atta", "chakki atta", "fine atta", "flour", "chki ata", "ata"]
  }
  ```
* Compute normalized Levenshtein ratio:
  $$\text{Score}(s_{\text{raw}}, s_{\text{alias}}) = 1.0 - \frac{\text{levenshtein\_distance}(s_{\text{raw}}, s_{\text{alias}})}{\max(|s_{\text{raw}}|, |s_{\text{alias}}|)}$$
* If $\text{Score} \ge 0.80$, normalize the item name and standard base unit.
* If no alias exceeds $0.80$, retain verbatim raw string and flag `is_normalized = false`.

---

### 3.5 Subsystem 5: Deduplication Engine (`backend/app/services/dedup.py`)

1. **Perceptual Image Hashing:**
   * Compute 64-bit Discrete Cosine Transform (DCT) pHash on the preprocessed image using `imagehash.phash(Image.fromarray(warped))`.
   * Compare against database index of existing receipt hashes:
     ```sql
     -- Query matching hashes within Hamming distance of 4
     SELECT receipt_id, phash_64 FROM receipt_hashes;
     ```
   * If $\text{HammingDistance}(\text{pHash}_{\text{new}}, \text{pHash}_{\text{stored}}) \le 4$, flag receipt as visual duplicate.
2. **Text Fingerprint:**
   * Normalize store name string (lowercase alphanumeric only), ISO date string (`YYYY-MM-DD`), and total bill amount in integer cents.
   * Compute SHA-256 hash:
     $$\text{Fingerprint} = \text{SHA256}(\text{merchant\_slug} \parallel \text{date\_iso} \parallel \text{total\_cents})$$
   * Enforce unique constraint in database.

---

### 3.6 Subsystem 6: Database & Persistence Layer (PostgreSQL / Supabase)

#### Schema Architecture:
* `receipts`: Header information (`id`, `user_id`, `merchant_name`, `receipt_date`, `total_amount`, `receipt_type`, `status`, `ocr_confidence`, `created_at`).
* `line_items`: Itemized rows (`id`, `receipt_id`, `category_id`, `raw_text`, `item_name`, `quantity`, `unit`, `unit_price`, `total_price`, `confidence_score`, `is_verified`).
* `receipt_hashes`: Fingerprint records (`id`, `receipt_id`, `phash_64`, `text_fingerprint_sha256`).
* `review_queue`: Flagged items (`id`, `line_item_id`, `candidate_text`, `model_confidence`, `review_status`, `bounding_box_json`, `flagged_at`).

#### Materialized Rollup View for Dashboard:
```sql
CREATE OR REPLACE VIEW view_monthly_category_spend AS
SELECT 
    r.user_id,
    TO_CHAR(r.receipt_date, 'YYYY-MM') AS spend_period,
    c.name AS category_name,
    c.color_hex AS category_color,
    SUM(li.total_price) AS category_total,
    COUNT(li.id) AS item_count
FROM line_items li
JOIN receipts r ON li.receipt_id = r.id
JOIN categories c ON li.category_id = c.id
WHERE r.status = 'PROCESSED'
GROUP BY r.user_id, spend_period, c.name, c.color_hex;
```

---

## 4. 3-Week Technical Implementation Sequence

### 📅 Week 1: Ingestion API, OpenCV Preprocessing & Printed OCR Baseline

| Day | Focus Area | Technical Deliverable | Acceptance Verification |
|:---:|:---|:---|:---|
| **Day 1** | Scaffolding | Git branch protection, FastAPI skeleton, Docker configuration | Docker container builds and `/api/v1/health` responds 200 OK |
| **Day 2** | Preprocessing | `preprocessor.py` (Canny, contour approximation, 4-point warp transform) | Deskew algorithm flattens receipts rotated up to $45^\circ$ |
| **Day 3** | Contrast Pipeline | CLAHE contrast enhancement & adaptive thresholding | Eliminates shadow gradients across unevenly lit smartphone photos |
| **Day 4** | Cloud Vision API | `cloud_vision_client.py` payload formatting and authentication | Successfully extracts structured JSON from sample printed receipts |
| **Day 5** | Fallback OCR | Tesseract 5 wrapper with custom page segmentation mode (`--psm 6`) | Fallback activates seamlessly if Cloud Vision credentials disabled |
| **Day 6** | Line Clustering | Sweep-line geometric clustering grouping words into line items | Horizontal token alignment correctly groups $> 90\%$ of line items |
| **Day 7** | Checkpoint #1 | Run test harness against initial dataset of 25 printed receipts | **Validation: Character accuracy $\ge 90\%$ on printed ground truth** |

---

### 📅 Week 2: EasyOCR Pipeline, NLP Normalization, Deduplication & DB

| Day | Focus Area | Technical Deliverable | Acceptance Verification |
|:---:|:---|:---|:---|
| **Day 8** | Handwriting OCR | `easyocr_client.py` with PyTorch CPU inference pipeline | Generates token bounding boxes and text from handwritten slips |
| **Day 9** | Digit Diffing | Dual-pass character voting between EasyOCR and Tesseract digits | Corrects ambiguous handwritten digits (`0` vs `8`, `1` vs `7`) |
| **Day 10** | Regex Extraction | Regex parser extracting `(quantity, unit, unit_price, line_total)` | Correctly parses diverse local notations (`5kg`, `500g`, `1.5 ltr`) |
| **Day 11** | Fuzzy Matcher | `normalizer.py` Levenshtein distance matcher against dictionary | Normalizes colloquial terms (`"chki ata"` $\rightarrow$ `"Wheat Flour"`) |
| **Day 12** | Categorization | Deterministic priority rule engine mapping items to categories | Classifies $\ge 85\%$ of test items into correct spending buckets |
| **Day 13** | Deduplication | `dedup.py` implementing 64-bit DCT pHash and SHA-256 fingerprint | Re-uploaded identical image returns HTTP 409 Conflict / duplicate flag |
| **Day 14** | Database Setup | Deploy PostgreSQL schema, triggers, and foreign keys on Supabase | End-to-end receipt upload inserts into `receipts` and `line_items` |

---

### 📅 Week 3: Dashboard Views, Review Queue, Integration & UAT

| Day | Focus Area | Technical Deliverable | Acceptance Verification |
|:---:|:---|:---|:---|
| **Day 15** | REST Endpoints | Implement analytics endpoints (`/monthly`, `/trends`, `/review-queue`) | Endpoints return aggregated SQL views within $< 500$ ms |
| **Day 16** | Dashboard UI | React + Vite client displaying total spend card and delta indicators | Renders monthly spend total matching manually calculated sum |
| **Day 17** | Charts Integration | Chart.js / Recharts donut chart (categories) and trend line graph | Renders interactive breakdown matching database view |
| **Day 18** | Review Queue UI | Human-in-the-loop review queue showing cropped receipt bounding box | User confirms low-confidence item with 1-click update to DB |
| **Day 19** | Flutter Client | Connect Flutter mobile camera capture app to FastAPI backend | End-to-end photo snap on phone transmits and processes in $< 5$s |
| **Day 20** | UAT & Audit | Run full regression and accuracy benchmarks across complete test set | Verify printed $\ge 90\%$, handwritten $\ge 70\%$, categorizer $\ge 85\%$ |
| **Day 21** | Polish & Handover | Freeze codebase, package demo walkthrough, verify all exit criteria | System fully verified for final presentation and instructor demo |

---

## 5. Technical Risks, Failure Modes & Edge Case Mitigations

| Failure Mode | Root Cause | Architectural Mitigation |
|:---|:---|:---|
| **Cloud Vision Quota Exhaustion** | Reaching free tier limit of 1,000 monthly units | Proactive counter intercepts call at 950 units and automatically falls back to local Tesseract 5 without raising runtime exceptions. |
| **Excessive Perspective Tilt ($> 60^\circ$)** | User photographs receipt from extreme steep angle | OpenCV contour approximation fails to resolve 4 distinct vertices; system detects non-convex geometry and falls back to centered bounding box with a user warning to retake photo if confidence $< 0.60$. |
| **Severe Thermal Paper Fading** | Faded thermal ink on supermarket slips | CLAHE contrast enhancement dynamically redistributes local histogram peaks before thresholding, pulling low-contrast text strokes out of paper background. |
| **Handwritten OCR Word Fragmentation** | Broken pen strokes or cursive ligatures in small-shop slips | Sweep-line horizontal distance tolerance $\Delta x$ merges adjacent character clusters, followed by Levenshtein fuzzy matching against known vocabulary. |
| **Double-Entry via Re-upload** | User submits the same paper receipt on consecutive days | 64-bit pHash Hamming distance ($\le 4$) and SHA-256 fingerprint identify exact visual/semantic match and prevent duplicate ledger commitment. |
| **CPU Memory Saturation under EasyOCR** | Concurrent multi-image uploads | FastAPI limits concurrent heavy OCR tasks via Python `asyncio.Semaphore(2)`, queuing requests to prevent memory spikes on CPU environments. |
