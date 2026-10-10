<div align="center">

# ReceiptLedger / Project Documentation & Governance

**Official Academic Deliverables, PMBOK Artifacts, and Technical Specifications.**

[![Course](https://img.shields.io/badge/Course-SPM--458-4F46E5?style=flat-square)](course-materials/assignments/)
[![Evaluator](https://img.shields.io/badge/Instructor-Humera%20Azam-0D9488?style=flat-square)](https://uok.edu.pk/)
[![Lifecycle](https://img.shields.io/badge/Lifecycle-3--Week%20Sprints-F59E0B?style=flat-square)](specifications/07_SPRINT_PLAN_3WEEKS.md)

</div>

---

## Documentation Structure

```text
docs/
├── course-materials/              # Academic reference materials
│   ├── assignments/               # Assignments 1, 2, 3 & Lab Activity 4
│   └── lectures/                  # Lecture slides (Weeks 2, 3, 4)
│
├── project-management/            # Approved SPM Governance Documents
│   ├── ReceiptLedger_Project_Charter.pdf
│   ├── ReceiptLedger_SoW.pdf
│   ├── ReceiptLedger_SoW_v3.pdf   # Latest approved baseline (6-sprint compressed)
│   └── ReceiptLedger_Division_of_Work.pdf # Approved team work division
│
└── specifications/                # Complete Technical Specification Suite
    ├── 01_PRD.md                  # Product Requirements Document
    ├── 02_SRS.md                  # Software Requirements Specification (IEEE 830)
    ├── 03_SDS.md                  # Software Design Specification (Architecture)
    ├── 04_DFD.md                  # Data Flow Diagrams (Context & Level 1)
    ├── 05_ERD.md                  # Entity Relationship Diagram & 3NF Schema
    ├── 06_SEMANTIC_NETS.md        # Semantic Networks (Domain Taxonomies)
    ├── 07_SPRINT_PLAN_3WEEKS.md   # 3-Week Sprint Execution Plan
    ├── 08_ENVIRONMENT_SETUP.md    # Developer Workstation Setup Guide
    ├── 09_DEVELOPMENT_PLAN.md     # In-Depth Engineering Implementation Plan
    └── 10_DIVISION_OF_WORK.md     # Official Team Roles & Working Streams
```

---

## Specification Index

| Document | Focus Area | Standard |
|:---|:---|:---:|
| [**PRD**](specifications/01_PRD.md) | Problem statement, user personas, journeys, functional matrix | Agile PRD |
| [**SRS**](specifications/02_SRS.md) | Formal system requirements, API endpoints, quality attributes | IEEE 830-1998 |
| [**SDS**](specifications/03_SDS.md) | Subsystem decomposition, sequence diagrams, failure modes | Architecture |
| [**DFD**](specifications/04_DFD.md) | Level 0 Context Model and Level 1 Functional Decomposition | Gane-Sarson / Mermaid |
| [**ERD**](specifications/05_ERD.md) | 3NF relational schema, PostgreSQL / Supabase DDL migrations | Relational / Mermaid |
| [**Semantic Networks**](specifications/06_SEMANTIC_NETS.md) | Domain knowledge graphs, local retail taxonomies, unit graphs | Knowledge Representation |
| [**3-Week Sprint Plan**](specifications/07_SPRINT_PLAN_3WEEKS.md) | 3-week delivery schedule, backlog user stories, exit criteria | Agile Scrum |
| [**Environment Setup**](specifications/08_ENVIRONMENT_SETUP.md) | Prerequisites, local virtualenv, Node, Flutter, and Docker setup | Developer Guide |
| [**Development Plan**](specifications/09_DEVELOPMENT_PLAN.md) | Deep technical implementation plan, algorithms, and day-by-day tasks | Engineering Plan |
| [**Division of Work**](specifications/10_DIVISION_OF_WORK.md) | Official 6-role allocations, responsibilities, and pairing streams | Team Governance |
| [**Backend Operations Guide**](BACKEND_SETUP_AND_OPERATIONS_GUIDE.md) | Comprehensive cloud service setup, OCR matrix, local dev mode, and cURL reference | Operations & API Guide |
