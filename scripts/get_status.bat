@echo off
setlocal
echo ======================================================================
echo          ReceiptLedger Backend ^& Network Connectivity Status
echo ======================================================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0get_status.ps1"

echo.
echo ======================================================================
echo Port 8000 Listener:
netstat -ano | findstr :8000
echo ======================================================================
echo.
pause
