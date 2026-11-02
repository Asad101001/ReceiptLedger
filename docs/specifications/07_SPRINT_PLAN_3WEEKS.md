# 3-Week Sprint Execution Plan

### Project: ReceiptLedger
* **Document Version:** 1.0.0
* **Course:** Software Project Management (SPM-458)
* **Institution:** Department of Computer Science, University of Karachi
* **Framework:** Agile Scrum (Compressed 3-Week Delivery Cadence)
* **Team Leadership:** Syed Aun Shamsi (Project Manager) & Muhammad Asad Khan (Lead Architect)

---

## 1. Executive Summary & Cadence

To meet course deliverables while ensuring high software quality, the earlier 6-sprint timeline has been consolidated into a **3-Week Sprint Plan** (1-week sprints). 

Lightweight daily standups and Jira burndown tracking ensure that scope drift is identified within 24 hours. The OCR accuracy checkpoint between printed and handwritten workflows occurs at the end of Week 1 / start of Week 2.

```mermaid
gantt
    title ReceiptLedger 3-Week Compressed Delivery Timeline
    dateFormat  YYYY-MM-DD
    section Sprint 1: Ingestion & Baseline OCR
    Repo, CI & Slack/Jira Tooling Setup   :crit, s1_1, 2026-10-06, 2d
    Receipt Dataset Collection (50+ real) :s1_2, 2026-10-06, 5d
    Mobile Camera Capture UI (Flutter)    :s1_3, 2026-10-07, 4d
    Printed OCR Path (Cloud Vision)       :s1_4, 2026-10-08, 4d
    Sprint 1 Review & OCR Checkpoint #1   :crit, s1_5, 2026-10-12, 1d
    section Sprint 2: Core Logic & Handwriting
    Handwritten OCR Pipeline (EasyOCR)    :crit, s2_1, 2026-10-13, 5d
    Domain Dictionary & Fuzzy Matcher     :s2_2, 2026-10-14, 4d
    Rule-Based Expense Categorizer        :s2_3, 2026-10-15, 4d
    pHash & Text Duplicate Detection      :s2_4, 2026-10-16, 3d
    Sprint 2 Review & Integration Test    :s2_5, 2026-10-19, 1d
    section Sprint 3: Dashboard & Finalization
    React Spending Dashboard Views        :s3_1, 2026-10-20, 5d
    Human-in-the-Loop Review Queue        :s3_2, 2026-10-21, 4d
    End-to-End System Integration         :crit, s3_3, 2026-10-22, 4d
    UAT Verification & Acceptance Audit   :s3_4, 2026-10-25, 2d
    Final Demo & Documentation Packaging  :s3_5, 2026-10-26, 1d
```

---

## 2. Sprint-by-Sprint Breakdown

### Sprint 1: Setup, Data Collection, Mobile Capture & Printed OCR
* **Timeline:** Week 1 (Days 1 – 7)
* **Goal:** Establish team infrastructure, build mobile capture screen, collect ground-truth receipts, and validate printed OCR accuracy.

| Issue Key | Subsystem | Story Description | Priority | Assignee |
|:---|:---|:---|:---:|:---:|
| `RL-101` | Infrastructure | Configure GitHub repository, branch protection, and Slack webhook alerts | High | Muhammad Asad Khan |
| `RL-102` | Infrastructure | Configure Jira Scrum board, backlog epics, and burndown chart | High | Syed Aun Shamsi (PM) |
| `RL-103` | Data Collection | Collect and label initial dataset of 50+ printed and handwritten receipts | High | Zainab Hashmi |
| `RL-104` | Mobile Client | Build mobile receipt camera capture screen & Google Stitch mockups | High | Aazmeer Sarfaraz Faridy |
| `RL-105` | Ingestion API | Implement multipart image upload endpoint and OpenCV deskewing | High | Muhammad Asad Khan |
| `RL-106` | OCR Engine | Integrate Google Cloud Vision API for printed retail receipts | High | Muhammad Asad Khan |
| `RL-107` | OCR Engine | Implement local Tesseract 5 fallback for quota overflow protection | Medium | Muhammad Asad Khan |

* **Sprint 1 Exit Criteria:**
  - Working repository, Jira board, and Slack integrations active.
  - Mobile client successfully captures and uploads receipt images.
  - Printed OCR path demonstrates $\ge 90\%$ accuracy on sample printed receipts.
  - Checkpoint #1: Assess sample difficulty for handwritten receipts before Sprint 2 kickoff.

---

### Sprint 2: Handwritten OCR, Normalization, Categorization & Deduplication
* **Timeline:** Week 2 (Days 8 – 14)
* **Goal:** Solve extraction for handwritten receipts, build dictionary-based item normalization, implement rule categorization, and enable duplicate detection.

| Issue Key | Subsystem | Story Description | Priority | Assignee |
|:---|:---|:---|:---:|:---:|
| `RL-201` | OCR Engine | Implement EasyOCR pipeline with preprocessing for handwritten notes | High | Muhammad Asad Khan |
| `RL-202` | Normalization | Build local retail dictionary and Levenshtein fuzzy-matching engine | High | Muhammad Asad Khan |
| `RL-203` | Normalization | Implement regex parsers for item quantities, units, and line totals | High | Muhammad Asad Khan |
| `RL-204` | Categorization | Implement rule-based classification engine for spending taxonomy | High | Muhammad Asad Khan |
| `RL-205` | Deduplication | Implement 64-bit perceptual image hashing (pHash) comparator | Medium | Muhammad Asad Khan |
| `RL-206` | Deduplication | Implement textual metadata fingerprinting (`store + date + amount`) | Medium | Muhammad Asad Khan |
| `RL-207` | Persistence | Configure Supabase/PostgreSQL schema and database migrations | High | Muhammad Asad Khan |

* **Sprint 2 Exit Criteria:**
  - Handwritten receipt OCR achieves $\ge 70\%$ word accuracy post-domain correction.
  - Rule-based categorization maps $\ge 85\%$ of standard items without user intervention.
  - System reliably detects intentionally re-uploaded duplicate receipts.
  - Normalization engine delivers clean JSON outputs into the database.

---

### Sprint 3: Analytics Dashboard, End-to-End Integration, UAT & Demo Prep
* **Timeline:** Week 3 (Days 15 – 21)
* **Goal:** Deliver interactive spending dashboard, integrate the complete pipeline, perform User Acceptance Testing (UAT), and prepare the project demo.

| Issue Key | Subsystem | Story Description | Priority | Assignee |
|:---|:---|:---|:---:|:---:|
| `RL-301` | Dashboard UI | Build monthly spending summary card and delta vs. previous month | High | Iman Hussain |
| `RL-302` | Dashboard UI | Build category-wise breakdown chart (donut/bar) with drill-down | High | Iman Hussain |
| `RL-303` | Dashboard UI | Implement multi-month spending trend visualization | Medium | Iman Hussain |
| `RL-304` | Dashboard UI | Implement searchable receipt historical ledger with item view | Medium | Iman Hussain |
| `RL-305` | Review Queue | Build human-in-the-loop review queue for low-confidence scans | High | Iman Hussain |
| `RL-306` | Integration | Hardening and end-to-end integration (Mobile $\rightarrow$ Pipeline $\rightarrow$ DB $\rightarrow$ Web) | High | Muhammad Asad Khan |
| `RL-307` | Quality & Acceptance | Execute UAT testing against acceptance criteria defined in SoW | High | Syed Aun Shamsi (PM) |
| `RL-308` | Risk & Governance | Risk register audit, documentation packaging, and submission readiness | High | Arish Ahmed Khan (Risk Lead) |

* **Sprint 3 Exit Criteria:**
  - Complete round-trip workflow verified: Photo taken $\rightarrow$ items digitized $\rightarrow$ visible in dashboard.
  - Review queue enables quick verification of low-confidence items.
  - All SMART acceptance criteria verified on test dataset.
  - Final documentation and live demonstration ready for evaluation by Humera Azam.

---

## 3. Team Rituals & Slack Collaboration Topology

Team coordination and event-driven notifications operate through the dedicated Slack workspace **`receipt-ledger`** (`https://receipt-ledger.slack.com`):

| Channel Name | Purpose | Integration / Bot Trigger | Cadence |
|:---|:---|:---|:---:|
| **`#daily-standup`** | Asynchronous daily Scrum standups | Team members post reports (or via `notify_slack.py`) | Daily by 12:00 PM |
| **`#jira`** | Automated Jira issue and sprint notifications | Atlassian Jira Cloud Slack App (`receipt-ledger.atlassian.net`) | Real-time on status change |
| **`#github-builds`** | Automated CI/CD build & APK release alerts | GitHub Actions (`build-and-release.yml` Slack step) | On push to `main` |
| **`#all-receipt-ledger`**| General team announcements & milestone sign-offs | Manual / PM broadcasts | Ad-hoc |

### Daily Standup Report Format:
1. *What did I complete yesterday?*
2. *What will I work on today?*
3. *Any blockers or impediments?*

* **Sprint Review & Demo:** Held at the conclusion of each sprint to review working software increments.
* **Scope Protection Rule:** Under the 3-week cadence, if an issue slips past 48 hours, its scope is trimmed immediately rather than pushing back the final delivery deadline.

---

## 4. Live Jira Scrum Board Cross-Reference & Traceability Matrix

The engineering implementation on the live Atlassian Jira board (`https://aunshamsi2005-1791564053187.atlassian.net/jira/software/projects/SCRUM`) decomposes the project into **8 Epics** and **64 tracking issues**.

### 4.1 Epic Structure & Deliverable Scope

| Epic Key | Epic Title | Owner / Lead | Jira Status | Delivered Scope Summary |
|:---|:---|:---|:---:|:---|
| **`SCRUM-5`** | `BACKEND AND API` | Muhammad Asad Khan | In Progress | FastAPI core, OpenCV deskewing, dual OCR routing, Gemini 3.5 Flash, Supabase DDL, deduplication |
| **`SCRUM-6`** | `UI/UX DESIGN` | Aazmeer Sarfaraz Faridy | Done / Baseline | Google Stitch wireframes, Scandinavian botanical design system, mobile screen specs |
| **`SCRUM-7`** | `Dashboard` | Iman Hussain | In Progress | React 18 + Vite operations console, KPI metric strip, category donut, review triage desk |
| **`SCRUM-8`** | `Frontend Development` | Muhammad Asad Khan | In Progress | Flutter 3.x cross-platform client, camera capture, sparkline velocity chart, settings |
| **`SCRUM-10`** | `QA, Integration & Documentation` | Syed Aun Shamsi (PM) | In Progress | 37-test CLI suite, 28-vector adversarial stress test, IEEE 830 documentation suite |
| **`SCRUM-11`** | `Risk Management and Mitigation` | Arish Ahmed Khan | In Review | PMBOK risk register, OCR degradation fallbacks, zero-cost cloud budget protections |
| **`SCRUM-33`** | `Receipt Dataset & Ground Truth` | Zainab Hashmi | In Progress | 50+ printed & handwritten Pakistani receipts, ground-truth labels, local item taxonomy |
| **`SCRUM-46`** | `Project Management And Sprint Tracking`| Syed Aun Shamsi (PM) | In Progress | Jira backlog grooming, sprint burndowns, division of work, Slack integration |

### 4.2 Requirements Traceability Matrix (RTM: SRS Requirements $\rightarrow$ Jira Tickets $\rightarrow$ Implementation)

| Req ID | Requirement Description | Jira Issue Key | Subsystem / File | Status |
|:---|:---|:---:|:---|:---:|
| `FR-001` | Mobile camera capture & batch mode | `SCRUM-28`, `SCRUM-66` | `mobile/lib/screens/upload_screen.dart` | ✅ Done |
| `FR-002` | OpenCV edge detection & perspective deskew | `SCRUM-18`, `SCRUM-59` | `backend/app/services/preprocessor.py` | ✅ Done |
| `FR-003` | Printed receipt OCR (Cloud Vision / Tesseract) | `SCRUM-18`, `SCRUM-61` | `backend/app/services/ocr_router.py` | ✅ Done |
| `FR-004` | Handwritten receipt OCR (EasyOCR / Gemini) | `SCRUM-18`, `SCRUM-61` | `backend/app/services/gemini_client.py` | ✅ Done |
| `FR-005` | Dictionary-based item & unit normalization | `SCRUM-18`, `SCRUM-62` | `backend/app/services/normalizer.py` | ✅ Done |
| `FR-006` | Rule-based spending classification | `SCRUM-18`, `SCRUM-62` | `backend/app/services/normalizer.py` | ✅ Done |
| `FR-007` | Deduplication (64-bit pHash + SHA-256) | `SCRUM-19`, `SCRUM-63..65` | `backend/app/services/dedup.py` | ✅ Done |
| `FR-008` | Monthly spend aggregation & MoM deltas | `SCRUM-23`, `SCRUM-55` | `backend/app/api/analytics.py` | ✅ Done |
| `FR-009` | Category spend distribution & velocity charts | `SCRUM-24`, `SCRUM-55` | `web/src/features/kpi/KpiMetricsRow.tsx` | ✅ Done |
| `FR-010` | Searchable historical transaction ledger | `SCRUM-25`, `SCRUM-54` | `web/src/features/audit-ledger/` | ✅ Done |
| `FR-011` | Human-in-the-loop review queue & crop viewer | `SCRUM-26`, `SCRUM-56` | `web/src/features/review-desk/` | ✅ Done |
