<div align="center">

# ReceiptLedger / Backend Service

**FastAPI Core Engine for Receipt Preprocessing, Dual OCR Routing, and Expense Normalization.**

[![Runtime](https://img.shields.io/badge/Python-3.11%20%7C%203.12-3776AB?style=flat-square&logo=python&logoColor=white)](#)
[![Framework](https://img.shields.io/badge/Framework-FastAPI-009688?style=flat-square&logo=fastapi&logoColor=white)](#)
[![Computer Vision](https://img.shields.io/badge/CV-OpenCV-5C3EE8?style=flat-square&logo=opencv&logoColor=white)](#)
[![Cloud OCR](https://img.shields.io/badge/OCR-Google%20Vision-4285F4?style=flat-square&logo=googlecloud&logoColor=white)](#)
[![Local OCR](https://img.shields.io/badge/OCR-EasyOCR%20%2B%20Tesseract-7C3AED?style=flat-square)](#)
[![Database](https://img.shields.io/badge/Persistence-Supabase%20%2F%20PostgreSQL-3ECF8E?style=flat-square&logo=supabase&logoColor=white)](#)

</div>

---

## Overview

The `backend` service orchestrates receipt image ingestion, perspective correction, text extraction, fuzzy dictionary mapping, duplicate prevention, and transactional persistence.

```
Incoming Image ──► OpenCV Deskew ──► Dual OCR Router ──► Normalizer ──► Deduplication ──► PostgreSQL
```

---

## Directory Structure

```text
backend/
├── Dockerfile             # Container definition with Tesseract & OpenCV libs
├── .dockerignore          # Docker build exclusion rules
├── .env.example           # Environment template (API keys, DB URLs)
├── requirements.txt       # Production dependencies
└── app/
    ├── __init__.py
    ├── main.py            # FastAPI application entrypoint
    ├── api/               # API routers (/upload, /analytics, /review)
    ├── core/              # Config, security, and logging
    └── services/          # OpenCV deskew, OCR engines, normalizer, dedup
```

---

## Local Development Setup

### 1. Python Virtual Environment

```powershell
# Create virtual environment
python -m venv .venv

# Activate on Windows PowerShell
.\.venv\Scripts\Activate.ps1

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt
```

### 2. Configure Environment

Copy `.env.example` to `.env`:
```powershell
cp .env.example .env
```
Populate your Google Cloud service account path and Supabase credentials.

### 3. Launch the Server

```powershell
uvicorn app.main:app --reload --port 8000
```
API Documentation will be live at:
* Swagger UI: `http://localhost:8000/docs`
* ReDoc: `http://localhost:8000/redoc`

---

## Containerized Execution (Docker)

```bash
docker build -t receiptledger-backend .
docker run -p 8000:8000 --env-file .env receiptledger-backend
```

---

## Key Interfaces

| Endpoint | Method | Description |
|:---|:---:|:---|
| `/api/v1/health` | `GET` | Health check and engine status |
| `/api/v1/receipts/upload` | `POST` | Multipart receipt photo ingestion and parsing |
| `/api/v1/analytics/monthly` | `GET` | Aggregated monthly spend and category rollups |
| `/api/v1/review-queue` | `GET` | Items with confidence $< 0.85$ requiring confirmation |
| `/api/v1/review-queue/{id}` | `PATCH` | Human-in-the-loop verification resolution |
