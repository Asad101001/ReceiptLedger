# Product Requirements Document (PRD)

## Project: ReceiptLedger
* **Document Version:** 1.0.0
* **Course:** Software Project Management (SPM-458)
* **Institution:** Department of Computer Science, University of Karachi
* **Sprint Cycle:** 3-Week Compressed Delivery Cadence
* **Document Status:** Baseline Approved

---

## 1. Executive Summary & Vision

### 1.1 Vision Statement
ReceiptLedger automates the translation of unstructured paper receipts—ranging from standard printed retail receipts to informal handwritten small-shop (*kiryana*) slips—into standardized, categorized, and structured spending intelligence accessible via an interactive dashboard.

### 1.2 Problem Statement
Consumers and small businesses regularly collect physical paper receipts. Due to the high friction of manual data entry into spreadsheets or expense tracking apps, receipts are quickly lost, discarded, or stored indefinitely without reconciliation. Consequently, users lose visibility into their actual cash expenditures and category-wise spending patterns.

### 1.3 Solution Approach
ReceiptLedger provides an end-to-end receipt extraction and analytics pipeline:
1. **Camera Ingestion:** Mobile photo capture supporting single-shot and multi-receipt capture.
2. **Dual-Engine OCR:** A bifurcated processing pipeline handling clean printed retail text and irregular handwritten slips.
3. **Item Normalization:** Rule- and dictionary-based canonical standardization of messy merchant descriptions, colloquial units, and local pack sizes.
4. **Local Categorization:** Automatic mapping to common household and neighborhood retail spend categories.
5. **Duplicate Prevention:** Cryptographic image hashing combined with text similarity scoring to eliminate duplicate entries.
6. **Analytics Dashboard:** Clear month-over-month comparisons, category breakdown visualizations, item-level historical search, and a human-in-the-loop review queue for low-confidence scans.

---

## 2. Target Personas & User Journeys

### 2.1 Primary Personas

#### Persona A: Household Budget Manager (Farhan, 28)
* **Profile:** Young urban professional managing household monthly expenses.
* **Pain Points:** 60% of daily transactions occur in cash at neighborhood bakeries, marts, and butcher shops. Receipts are crumpled in pockets or wallets and never entered into budgeting apps.
* **Goal:** Snap pictures of paper slips at the end of the day and automatically receive a monthly summary of grocery vs. utility vs. snack spending.

#### Persona B: Neighborhood Mart Owner / Sole Proprietor (Tariq, 45)
* **Profile:** Runs a small corner retail store handling daily wholesale procurement slips and cash supplier receipts.
* **Pain Points:** Many supplier receipts are handwritten invoices with shorthand terminology (*e.g., "5kg Chakki Atta", "1 ctn Dalda"*). Reconciling purchases takes hours each weekend.
* **Goal:** Quickly scan batches of procurement receipts to verify itemized monthly spend without manual bookkeeping.

### 2.2 User Journeys

#### Journey 1: Photographing & Ingesting a Mixed Batch of Receipts
1. User opens the ReceiptLedger mobile client.
2. User selects camera capture mode and photographs a printed supermarket slip and a handwritten corner-store invoice.
3. App performs client-side edge detection, deskews the images, and uploads them to the ingestion service.
4. Server parses both receipts through their respective OCR paths.
5. Items are parsed into: Item Name, Quantity, Unit Price, Total Amount, and Merchant/Date.
6. Items with OCR confidence $\ge 85\%$ are committed directly to the database. Items below threshold are placed into the **Review Queue**.

#### Journey 2: Review Queue Confirmation & Monthly Spend Review
1. User logs into the ReceiptLedger web dashboard.
2. An alert highlights 2 items in the **Review Queue** with low OCR confidence.
3. User reviews cropped snippet of the original receipt alongside extracted candidate text, confirms or edits the values with one click.
4. Dashboard instantly recalculates monthly category totals and delta comparisons.

---

## 3. Product Scope & Functional Requirements

### 3.1 Functional Requirements Matrix

| Requirement ID | Module | Feature Description | Priority | Target Sprint |
|:---|:---|:---|:---:|:---:|
| `FR-001` | Mobile Client | Single-shot and multi-shot camera capture interface | High | Sprint 1 |
| `FR-002` | Mobile Client | Image preview, crop, and deskew adjustment | High | Sprint 1 |
| `FR-003` | OCR Engine | Printed receipt text extraction via cloud/local OCR | High | Sprint 1 |
| `FR-004` | OCR Engine | Handwritten receipt extraction via layered open-source OCR | High | Sprint 2 |
| `FR-005` | Normalization | Dictionary-based item name and unit standardization | High | Sprint 2 |
| `FR-006` | Categorization | Rule-based classifier mapping items to local taxonomy | High | Sprint 2 |
| `FR-007` | Deduplication | Perceptual image hashing (pHash) and text similarity deduplication | Medium | Sprint 2 |
| `FR-008` | Dashboard | Monthly spend aggregation and delta vs. previous month | High | Sprint 3 |
| `FR-009` | Dashboard | Visual spending breakdown by category (charts/graphs) | High | Sprint 3 |
| `FR-010` | Dashboard | Searchable historical receipt ledger and item-level filter | Medium | Sprint 3 |
| `FR-011` | Dashboard | Human-in-the-loop Review Queue for low-confidence entries | High | Sprint 3 |

### 3.2 Out-of-Scope Boundaries
* Automated bank account feeds, credit card syncing, or open-banking APIs.
* Tax computation, GST/sales tax filing, or formal corporate invoice generation.
* Generic global taxonomy beyond common consumer and small-shop retail spending.
* Training deep neural networks or proprietary handwriting recognition models from scratch.

---

## 4. Non-Functional Requirements (NFRs)

### 4.1 Performance & Throughput
* **OCR Response Latency:** Receipt extraction and normalization must complete in $< 5.0$ seconds per single receipt on a standard broadband connection.
* **Dashboard Load Time:** Primary dashboard views and charts must render in $< 1.5$ seconds for datasets up to 1,000 receipts.

### 4.2 Accuracy & Reliability
* **Printed OCR Accuracy:** Minimum 90% character/word accuracy on clean printed receipts.
* **Handwritten OCR Accuracy:** Minimum 70% word accuracy post-domain correction on legible handwritten slips.
* **Categorization Precision:** Minimum 85% correct categorization without user correction.
* **Deduplication:** Zero false negatives on identical re-uploaded receipts; false positive rate $< 2\%$.

### 4.3 Usability & Device Support
* Mobile client tested on standard Android devices (API Level 26+).
* Responsive web dashboard rendering seamlessly on desktop browsers (Chrome, Firefox, Edge).

---

## 5. Success Metrics & Key Performance Indicators (KPIs)

1. **Extraction Accuracy Rate:** Percentage of extracted line items matching the physical receipt ground truth.
2. **Review Queue Clearance Speed:** Time required for a user to verify low-confidence items (target: $< 15$ seconds per receipt).
3. **End-to-End Processing Success Rate:** $> 95\%$ of submitted images successfully parsed into structured records without unhandled exceptions.
4. **Sprint Delivery Reliability:** 100% of defined core stories delivered within the 3-week timeline.
