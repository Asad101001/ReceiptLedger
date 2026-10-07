<div align="center">

# ReceiptLedger / Web Dashboard

**React Spending Analytics Dashboard and Human-in-the-Loop Review Queue.**

[![Framework](https://img.shields.io/badge/Framework-React%2018-20232A?style=flat-square&logo=react&logoColor=61DAFB)](#)
[![Bundler](https://img.shields.io/badge/Bundler-Vite%205-646CFF?style=flat-square&logo=vite&logoColor=white)](#)
[![Charts](https://img.shields.io/badge/Visualization-Chart.js-FF6384?style=flat-square&logo=chartdotjs&logoColor=white)](#)
[![Database](https://img.shields.io/badge/Data-Supabase%20Client-3ECF8E?style=flat-square&logo=supabase&logoColor=white)](#)

</div>

---

## Overview

The `web` dashboard gives users total clarity over their expenditures. It renders real-time financial metrics, monthly category distributions, multi-month spending velocity, and a human-in-the-loop **Review Queue** allowing instant confirmation of ambiguous OCR scans.

---

## Dashboard Capabilities

1. **Monthly Spend Metric:** Total expenditure for the selected month with delta vs. prior month.
2. **Category Breakdown:** Interactive donut and bar charts showing expense distribution across groceries, utilities, household, and personal care.
3. **Multi-Month Trends:** Historical spending curves tracking category inflation and purchase habits.
4. **Historical Receipt Log:** Searchable, paginated data grid with item drill-down.
5. **Review Queue:** Side-by-side verification interface pairing cropped receipt image bounding boxes with candidate text fields.

---

## Directory Structure

```text
web/
├── package.json           # Dependencies and build scripts
├── vite.config.js         # Vite configuration
├── .env.example           # Client-side environment template
├── src/
│   ├── main.jsx           # Root entrypoint
│   ├── App.jsx            # App shell & routing
│   ├── components/        # Charts, ReviewQueue, Navbar, StatCard
│   ├── services/          # API client & Supabase connector
│   └── styles/            # Minimalist styling tokens
└── public/                # Static assets & favicon
```

---

## Local Development Setup

### 1. Install Dependencies

```bash
cd web
npm install
```

### 2. Configure Environment

Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Ensure `VITE_API_URL` points to your backend instance (`http://localhost:8000`).

### 3. Start Development Server

```bash
npm run dev
```
Dashboard will be accessible at: `http://localhost:5173`

### 4. Build for Production

```bash
npm run build
npm run preview
```
