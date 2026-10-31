<div align="center">

# ReceiptLedger / Web Operations Console

**High-Density React Operations Console, Audit Ledger, and Human-in-the-Loop Review Desk.**

[![Framework](https://img.shields.io/badge/Framework-React%2018%20%7C%20TypeScript-20232A?style=flat-square&logo=react&logoColor=61DAFB)](#)
[![Bundler](https://img.shields.io/badge/Bundler-Vite%205-646CFF?style=flat-square&logo=vite&logoColor=white)](#)
[![Styling](https://img.shields.io/badge/Styling-Tailwind%20CSS-38B2AC?style=flat-square&logo=tailwind-css&logoColor=white)](#)
[![State](https://img.shields.io/badge/State-Zustand%20%2B%20TanStack%20Query-FF4154?style=flat-square)](#)
[![Deployment](https://img.shields.io/badge/Deploy-Vercel%20Ready-000000?style=flat-square&logo=vercel&logoColor=white)](#)

</div>

---

## Overview

The `web/` dashboard is the enterprise desktop command center for **ReceiptLedger**. Built with React 18, TypeScript, Vite, and Tailwind CSS, it provides operators and auditors with high-density review workflows, telemetry monitoring, and financial audit capabilities.

---

## Core Workspaces & Capabilities

1. **Workspace A: Review Desk (Human-in-the-Loop):**
   - Side-by-side verification pairing cropped receipt image bounding boxes with candidate extraction fields.
   - 1-tap keyboard hotkeys (`Enter` to confirm, `S` to skip, numbers to re-categorize).
   - Real-time confidence scores and OCR discrepancy highlights.

2. **Workspace B: Audit Ledger:**
   - Full historical ledger with multi-column sorting, filtering by verification status, merchant search, and category tags.
   - Slide-out transaction details drawer with itemized breakdowns and original image preview.

3. **KPI Metrics & Velocity Ribbon:**
   - Real-time calculation of total monthly expenditure, verified confidence averages, and processing velocity.
   - Bottom telemetry ribbon displaying pipeline latency (p95), OCR accuracy benchmarks, and run logs.

4. **Operations Console:**
   - Live backend health status, Supabase cloud sync indicators, and deduplication audit metrics.

---

## Directory Structure

```text
web/
├── package.json              # Dependencies and build scripts
├── vite.config.ts            # Vite bundler configuration & local API proxy
├── tailwind.config.js        # Design system tokens (Forest & Sage palette)
├── tsconfig.json             # TypeScript compiler settings
├── vercel.json               # Vercel deployment & SPA routing rewrites
├── .env.example              # Client environment variables template
├── src/
│   ├── main.tsx              # Application entrypoint
│   ├── App.tsx               # Root app layout & keyboard shortcuts
│   ├── api/                  # Typed API client, authentication & error handling
│   ├── components/           # Reusable UI primitives (Badges, Cards, Modals, Drawers)
│   ├── features/
│   │   ├── audit-ledger/     # Workspace B: Searchable transaction ledger
│   │   ├── review-desk/      # Workspace A: Human-in-the-loop verification
│   │   ├── console/          # System operations console & pipeline health
│   │   ├── kpi/              # Executive KPI metrics row
│   │   └── telemetry/        # Bottom telemetry run log ribbon
│   ├── hooks/                # Custom React hooks (hotkeys, auth)
│   ├── store/                # Zustand client state management
│   ├── lib/                  # Formatters, currency conversion & data adapters
│   └── test/                 # Vitest & Mock Service Worker (MSW) test suites
└── public/                   # Static assets & favicon
```

---

## Deploy to Vercel (1-Click Ready)

The web dashboard is fully configured for deployment on Vercel with zero setup issues.

### Method 1: Via Vercel Web Dashboard (Recommended)

1. Go to [vercel.com](https://vercel.com) and log in with your GitHub account.
2. Click **"Add New..."** → **"Project"**.
3. Import your **`Asad101001/ReceiptLedger`** repository.
4. In the **Configure Project** screen:
   - **Framework Preset:** `Vite` (auto-detected)
   - **Root Directory:** Click *Edit* and select **`web`** *(or leave default; root `vercel.json` will route to `web` automatically)*
   - **Build Command:** `npm run build`
   - **Output Directory:** `dist`
5. **Environment Variables:**
   - Add `VITE_API_BASE_URL` with your backend URL:
     - *If using Cloudflare tunnel:* `https://<your-subdomain>.trycloudflare.com/api/v1`
     - *If using deployed backend:* `https://<your-backend-domain>/api/v1`
6. Click **Deploy**. Vercel will build and launch your dashboard with free global CDN and HTTPS!

### Method 2: Via Vercel CLI

From your terminal inside the `ReceiptLedger` folder:

```bash
cd web
npx vercel
```
Follow the prompts to link and deploy in seconds.

---

## Local Development

### 1. Install Dependencies
```bash
cd web
npm install
```

### 2. Configure Environment
Create `.env` from `.env.example`:
```bash
cp .env.example .env
```
Ensure `VITE_API_BASE_URL` points to your running FastAPI backend:
```env
VITE_API_BASE_URL=http://localhost:8000/api/v1
```

### 3. Start Development Server
```bash
npm run dev
```
Open [http://localhost:5173](http://localhost:5173) in your browser.

### 4. Run Tests & Validation
```bash
# Run unit & component test suite
npm run test

# Check TypeScript types
npm run lint

# Build production bundle
npm run build
```
