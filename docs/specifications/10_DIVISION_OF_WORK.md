# Team Division of Work & Operational Protocols

### Project: ReceiptLedger
* **Document Version:** 1.0.0
* **Course:** Software Project Management (SPM-458)
* **Institution:** Department of Computer Science, University of Karachi
* **Framework:** Agile Scrum (Compressed 3-Week Delivery Lifecycle)
* **Reference Source:** [`docs/project-management/ReceiptLedger_Division_of_Work.pdf`](../project-management/ReceiptLedger_Division_of_Work.pdf)
* **Status:** Finalized & Approved Baseline

---

## 1. Purpose & Framework

To ensure maximum development velocity under a compressed **3-week sprint cadence**, project responsibilities are divided into six clearly bounded roles based on project needs. Work is structured to eliminate single-point dependencies and protect the critical technical path while meeting all academic PMBOK and course grading criteria for SPM-458.

---

## 2. Official Role Assignments

| # | Role | Assigned To | Primary Focus & Tooling |
|:---:|:---|:---|:---|
| **01** | **Lead Architect & Core Backend** | **Muhammad Asad Khan** | FastAPI gateway, OpenCV pipeline, Dual OCR router, Normalization, Deduplication, Tunnel hosting |
| **02** | **SPM & Operations Co-Lead** | **Arish Ahmed Khan** | Jira board, sprint planning, burndown tracking, risk register, PMBOK process groups, final reporting |
| **03** | **QA, Testing & Acceptance** | **Syed Aun Shamsi** | Ground truth benchmarking, accuracy calculation, bug tickets, UAT testing, regression suites |
| **04** | **Web Dashboard Developer** | **Iman Hussain** | React + Vite client, Chart.js cards, historical ledger table, Review Queue visual interface |
| **05** | **UI/UX Designer (Google Stitch)** | **Aazmeer Sarfaraz Faridy** | Google Stitch mockups, design system, mobile capture wireframes, slide deck diagrams, presentation graphics |
| **06** | **Data Collection & Ground Truth** | **Zainab Hashmi** | Field collection of 60+ physical receipts, ground truth spreadsheet transcription, local taxonomy dictionary expansion |

---

## 3. In-Depth Role Breakdown & Deliverables

### 3.1 Lead Architect & Core Backend — Muhammad Asad Khan
* **Responsibilities:**
  * Design and implement the FastAPI REST backend and API schemas.
  * Build the OpenCV perspective transform, deskew, and CLAHE contrast enhancement pipeline.
  * Implement the Dual-OCR router (Google Cloud Vision API + EasyOCR + Tesseract 5 fallback).
  * Build the Levenshtein fuzzy string matcher and 64-bit pHash deduplication engine.
  * Configure Supabase database migrations and host backend via Cloudflare Tunnel for live testing.
* **Why it matters:** Heaviest technical load and the primary critical path; all other subsystems depend on the ingestion and normalization engine.

---

### 3.2 SPM & Operations Co-Lead — Arish Ahmed Khan
* **Responsibilities:**
  * Configure and manage the Jira Scrum board, sprint backlogs, story point estimations, and burndown charts.
  * Track daily standup participation and document sprint retrospectives.
  * Maintain the living Risk Register (`R1`–`R6`) and ensure compliance with course deliverables.
  * Lead compilation of the final SPM project report and submission presentation slides.
* **Why it matters:** Course evaluation by instructor Humera Azam grades PMBOK rigor and Jira tooling; offloads administrative overhead from the technical lead.

---

### 3.3 QA, Testing & Acceptance — Syed Aun Shamsi
* **Responsibilities:**
  * Execute test suites comparing OCR outputs against human-verified ground-truth datasets.
  * Measure and verify the four core SoW acceptance criteria:
    * Printed receipt OCR word accuracy $\ge 90\%$
    * Handwritten receipt OCR word accuracy $\ge 70\%$ post-correction
    * Categorization accuracy $\ge 85\%$ without manual correction
    * Duplicate detection: 0 false negatives on re-uploaded test receipts
  * File and track structured bug tickets on Jira with reproduction steps and cropped image samples.
  * Execute User Acceptance Testing (UAT) and regression passes across extreme edge cases (faded thermal paper, crumpled slips).
* **Why it matters:** The Statement of Work defines strict measurable success criteria; verifiable metrics are required for project sign-off.

---

### 3.4 Web Dashboard Developer — Iman Hussain
* **Responsibilities:**
  * Build the React + Vite frontend dashboard consuming the backend REST API endpoints.
  * Implement summary analytics cards (Total Monthly Spend, Previous Month Delta, Receipt Count).
  * Build interactive Chart.js visualization components (Category Donut Chart, Multi-Month Spend Velocity Line Chart).
  * Implement the **Review Queue Interface**: Fetch line items with confidence $< 0.85$, display the cropped receipt image snippet, and provide 1-click confirmation or editing.
  * Implement the searchable, paginated historical receipt ledger.
* **Why it matters:** Delivers the primary user-facing stakeholder interface demonstrating automated financial visibility.

---

### 3.5 UI/UX Designer — Aazmeer Sarfaraz Faridy
* **Responsibilities:**
  * Produce high-fidelity interface wireframes and interactive mockups using **Google Stitch** / Material Design 3.
  * Design the mobile camera capture user journey, including viewfinder edge guides and blur warnings.
  * Design the web analytics dashboard layout, stat cards, and Review Queue confirmation flows.
  * Establish the project design token system (color palettes, typography scale, iconography).
  * Generate polished UI graphics, flowcharts, and screenshots for repository documentation and final evaluation slides.
* **Why it matters:** Gives frontend and mobile development clear, pre-approved visual targets to prevent redesign cycles.

---

### 3.6 Data Collection & Ground Truth — Zainab Hashmi
* **Responsibilities:**
  * Collect, catalog, and photograph 60+ real physical receipts (30+ printed retail and 30+ handwritten *kiryana* slips) adhering to standardized photography guidelines.
  * Transcribe a master ground-truth verification spreadsheet (`receipt_id`, `actual_merchant`, `actual_date`, `actual_items`, `actual_prices`).
  * Populate and maintain image files under `data/samples/printed/` and `data/samples/handwritten/`.
  * Expand the local retail vocabulary in `data/dictionary/local_taxonomy.json` with vernacular item terms, brand names, and regional units.
* **Why it matters:** Computer vision and OCR models cannot be evaluated or tuned without real, rigorously labeled training and test samples.

---

## 4. Suggested Working Streams & Collaboration Pairs

To prevent communication bottlenecks, team members work in three synchronized parallel streams:

```
┌────────────────────────────────────────────────────────────────────────┐
│ STREAM A: Core Engineering & User Interface                            │
│ Backend Lead (Asad)  ◄────────────────────────►  Web Developer (Iman)  │
│ • Backend defines API contracts and mock JSON schemas.                 │
│ • Frontend builds dashboard views against contracts until live tunnel. │
├────────────────────────────────────────────────────────────────────────┤
│ STREAM B: Empirical Testing & Data Validation                          │
│ Data Lead (Zainab)   ◄────────────────────────►  QA Lead (Aun)         │
│ • Data supplies physical receipt photos and ground-truth spreadsheets. │
│ • QA runs OCR test harness and computes mathematical accuracy targets. │
├────────────────────────────────────────────────────────────────────────┤
│ STREAM C: Operations, Product Design & Governance                      │
│ UI Designer (Aazmeer)◄────────────────────────►  SPM Co-Lead (Arish)   │
│ • Designer produces Google Stitch mockups and presentation visuals.    │
│ • SPM Co-Lead incorporates assets into Jira tickets, SoW, and reports. │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Team Governance & Rituals

1. **Daily Standup:**
   * **Where:** Slack `#all-receipt-ledger`
   * **Cadence:** Daily by 12:00 PM
   * **Format:**
     1. *What did I complete yesterday?*
     2. *What am I working on today?*
     3. *Are there any blockers preventing progress?*
2. **Jira Sprint Cycles:**
   * Every ticket must carry an Epic link, Story Point estimate, and Acceptance Criteria.
   * Moving a ticket to `Done` requires code review / QA verification.
3. **Escalation Protocol:**
   * If any task falls behind schedule by $> 24$ hours, the stream lead flags it immediately to Asad and Arish during daily standup for scope trimming.
