@echo off
title ReceiptLedger Free Tunneled Backend
cd /d "%~dp0"

echo ======================================================================
echo  ReceiptLedger Zero-Cost Public HTTPS Tunnel & Backend
echo  Cost: $0.00 / mo ^| No Credit Card ^| No Cloud Subscriptions
echo ======================================================================
echo.

if exist "backend\.venv\Scripts\python.exe" (
    backend\.venv\Scripts\python.exe scripts\devops\tunnel_server.py
) else (
    python scripts\devops\tunnel_server.py
)

pause
