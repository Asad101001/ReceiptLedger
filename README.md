# ReceiptLedger

> **Turning phone photos of any paper receipt into structured, categorized spending data.**

<p align="left">
  <img src="https://img.shields.io/badge/Course-SPM--458-4F46E5?style=for-the-badge" alt="Course SPM-458" />
  <img src="https://img.shields.io/badge/Institution-University%20of%20Karachi-0D9488?style=for-the-badge" alt="University of Karachi" />
  <img src="https://img.shields.io/badge/Semester-4th%20Semester-0284C7?style=for-the-badge" alt="Semester 4" />
  <img src="https://img.shields.io/badge/Management-Jira-0052CC?style=for-the-badge&logo=jira&logoColor=white" alt="Jira" />
</p>

---

## Overview

Managing personal and household expenses is often complicated by a mix of paper receipts—from printed supermarket receipts to informal handwritten receipts from local neighborhood shops (*kiryana* stores). Manual tracking is time-consuming, resulting in untracked daily cash expenses.

**ReceiptLedger** streamlines this workflow by enabling users to photograph receipts directly from their smartphones. The system automatically reads purchase items, cleans up names, groups purchases into everyday spending categories, checks for duplicates, and presents financial insights via an interactive dashboard.

---

## Core Capabilities

| Capability | Focus Area | Description |
|:---|:---:|:---|
| ![Capture](https://img.shields.io/badge/Capture-Mobile%20Flow-2563EB?style=flat-square) | Receipt Acquisition | Supports single or multi-receipt image capture directly from smartphone cameras. |
| ![Reading](https://img.shields.io/badge/Extraction-Dual%20Reading-7C3AED?style=flat-square) | Dual OCR Path | Processes both organized retail printed receipts and handwritten small-shop slips. |
| ![Normalization](https://img.shields.io/badge/Processing-Normalization-D97706?style=flat-square) | Item Standardization | Maps varied colloquial item names and quantities into unified standard units. |
| ![Categorization](https://img.shields.io/badge/Analytics-Categorization-059669?style=flat-square) | Spending Buckets | Automatically categorizes items into everyday spending groups (groceries, essentials, etc.). |
| ![Deduplication](https://img.shields.io/badge/Validation-Deduplication-DC2626?style=flat-square) | Fraud & Error Check | Identifies previously scanned receipts via visual and textual matching to avoid double counting. |
| ![Dashboard](https://img.shields.io/badge/Visualization-Dashboard-0891B2?style=flat-square) | Visibility | Offers month-over-month trend charts, category breakdowns, and a review queue. |

---

## Project Scope

### ![In Scope](https://img.shields.io/badge/Scope-In--Scope-10B981?style=for-the-badge)

- **Mobile Capture:** Camera interface for photographing single or multiple paper receipts.
- **Dual Text Extraction:** Handling both printed supermarket receipts and informal handwritten slips.
- **Item Standardization:** Converting varied item naming and unit notations into uniform formats.
- **Rule-Based Categorization:** Sorting items into standard local spending categories.
- **Duplicate Detection:** Flagging duplicate receipts using image and text verification.
- **Visual Spending Dashboard:**
  - Monthly overall spend and delta versus prior periods
  - Category-by-category breakdown charts
  - Multi-month trend tracking
  - Searchable receipt and line-item history
  - Review queue for low-confidence item confirmations

### ![Out of Scope](https://img.shields.io/badge/Scope-Out--of--Scope-EF4444?style=for-the-badge)

- Bank account linking or credit card statement reconciliation.
- Tax filings, corporate accounting, or formal tax invoice generation.
- Categorization structures beyond common consumer and household shopping.
- Custom machine learning model training from scratch.

---

## Technical Specifications & Artifacts

All formal software engineering and project management specifications are organized under the [`docs/`](docs/) directory:

| Document | Description | Format |
|:---|:---|:---:|
| [Product Requirements Document (PRD)](docs/specifications/01_PRD.md) | High-level vision, personas, journeys, and functional matrix | Markdown |
| [Software Requirements Specification (SRS)](docs/specifications/02_SRS.md) | IEEE 830 standard requirements, API endpoints, and NFRs | Markdown |
| [Software Design Specification (SDS)](docs/specifications/03_SDS.md) | Modular architecture, subsystem design, and sequence diagrams | Markdown |
| [Data Flow Diagrams (DFD)](docs/specifications/04_DFD.md) | Level 0 Context Diagram and Level 1 Functional Decomposition | Mermaid |
| [Entity Relationship Diagram (ERD)](docs/specifications/05_ERD.md) | Database relational schema and 3NF model (PostgreSQL / Supabase) | Mermaid |
| [Semantic Networks](docs/specifications/06_SEMANTIC_NETS.md) | Domain knowledge graphs, local item taxonomies, and unit hierarchies | Mermaid |
| [3-Week Sprint Execution Plan](docs/specifications/07_SPRINT_PLAN_3WEEKS.md) | Compressed 3-week sprint breakdown, epics, and exit criteria | Markdown |

---

## Project Members

| # | Student Name | Roll Number |
|:---:|:---|:---:|
| 01 | **Aazmeer Sarfaraz Faridy** | `B24110006002` |
| 02 | **Arish Ahmed Khan** | `B24110006026` |
| 03 | **Iman Hussain** | `B24110006054` |
| 04 | **Muhammad Asad Khan** | `B24110006087` |
| 05 | **Syed Aun Shamsi** | `B24110006134` |
| 06 | **Zainab Hashmi** | `B24110006162` |

---

<div align="center">
  <sub>Department of Computer Science • University of Karachi</sub>
</div>
