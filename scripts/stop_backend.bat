@echo off
echo Stopping ReceiptLedger backend and cloudflared tunnel...
taskkill /F /IM cloudflared.exe 2>nul
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000') do (
    taskkill /F /PID %%a 2>nul
)
echo ReceiptLedger services stopped.
pause
