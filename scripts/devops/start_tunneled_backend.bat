@echo off
title ReceiptLedger Free Tunneled Backend
cd /d "%~dp0..\.."

echo ======================================================================
echo  Launching ReceiptLedger Zero-Cost Tunneled Backend
echo  (No Credit Cards, No Cloud Bills, 100%% Free)
echo ======================================================================
echo.

if exist "backend\.venv\Scripts\python.exe" (
    backend\.venv\Scripts\python.exe scripts\devops\tunnel_server.py
) else (
    python scripts\devops\tunnel_server.py
)

pause
