# Development Environment Setup Guide

### Project: ReceiptLedger
* **Document Version:** 1.0.0
* **Course:** Software Project Management (SPM-458)
* **Institution:** Department of Computer Science, University of Karachi

---

## 1. Prerequisites

Ensure you have the following installed on your development workstation:
* **Git:** [git-scm.com](https://git-scm.com/)
* **Python:** 3.10+ (Recommended: 3.11 or 3.12)
* **Node.js:** v18+ (LTS) & `npm`
* **Flutter SDK:** 3.x+ (for Mobile Capture development)
* **Docker & Docker Compose:** *(Optional, for containerized local execution)*

---

## 2. Repository Clone & Setup

```bash
git clone https://github.com/Asad101001/ReceiptLedger.git
cd ReceiptLedger
```

---

## 3. Backend Environment (Python / FastAPI)

### Option A: Local Virtual Environment (Recommended)

1. Navigate to the `backend/` directory:
   ```bash
   cd backend
   ```
2. Create and activate a virtual environment:
   * **Windows (PowerShell):**
     ```powershell
     python -m venv .venv
     .\.venv\Scripts\Activate.ps1
     ```
   * **macOS / Linux:**
     ```bash
     python3 -m venv .venv
     source .venv/bin/activate
     ```
3. Install dependencies:
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```
4. Configure environment variables:
   * Copy `.env.example` to `.env`:
     ```bash
     cp .env.example .env
     ```
5. Run the development server:
   ```bash
   uvicorn app.main:app --reload --port 8000
   ```

### Option B: Dockerized Environment

From the project root:
```bash
docker compose up --build
```
The backend API will be available at `http://localhost:8000`.

---

## 4. Web Dashboard Environment (React + Vite)

1. Navigate to the `web/` directory:
   ```bash
   cd web
   ```
2. Install node dependencies:
   ```bash
   npm install
   ```
3. Configure environment variables:
   ```bash
   cp .env.example .env
   ```
4. Start the Vite development server:
   ```bash
   npm run dev
   ```
The dashboard will be available at `http://localhost:5173`.

---

## 5. Mobile App Environment (Flutter)

1. Navigate to the `mobile/` directory:
   ```bash
   cd mobile
   ```
2. Fetch Dart dependencies:
   ```bash
   flutter pub get
   ```
3. Verify connected devices or emulator:
   ```bash
   flutter devices
   ```
4. Launch the application:
   ```bash
   flutter run
   ```

---

## 6. Real Receipts Data Collection

Drop collected physical receipt photos into the respective directories:
* Clean printed retail slips $\rightarrow$ `data/samples/printed/`
* Informal handwritten slips $\rightarrow$ `data/samples/handwritten/`
