@echo off
title ReceiptLedger All-In-One Launcher
echo ============================================================
echo   ReceiptLedger - Unified Monorepo Launcher
echo ============================================================
echo.
echo [*] Launching FastAPI Backend (Port 8000)...
start "ReceiptLedger Backend [Port 8000]" cmd /c "run_backend.bat"

echo [*] Launching Web Operations Console (Port 5173)...
start "ReceiptLedger Web Console [Port 5173]" cmd /c "run_web.bat"

echo.
echo [OK] Both services launched successfully:
echo      • Web Dashboard:  http://localhost:5173
echo      • API Gateway:    http://localhost:8000/api/v1
echo      • Swagger UI:     http://localhost:8000/docs
echo ============================================================
