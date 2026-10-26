@echo off
echo ========================================================
echo        ReceiptLedger Backend & Cloudflare Tunnel Status
echo ========================================================
echo.
powershell -Command "$urlFile = 'c:\Users\Asad\Desktop\ReceiptLedger\scripts\current_tunnel_url.txt'; if (Test-Path $urlFile) { $url = Get-Content $urlFile; Write-Host 'Live Public Tunnel URL:' $url -ForegroundColor Green; try { $r = Invoke-RestMethod -Uri \"$url/api/v1/health\" -TimeoutSec 10; Write-Host 'Health Status:         ' $r.status -ForegroundColor Green; Write-Host 'Gemini Engine:         ' $r.engines.gemini -ForegroundColor Cyan; Write-Host 'Database:              ' $r.engines.database -ForegroundColor Cyan; } catch { Write-Host 'Tunnel unreachable or starting up.' -ForegroundColor Yellow; } } else { Write-Host 'Tunnel has not generated URL yet. Run start_backend first.' -ForegroundColor Red; }"
echo.
echo Local API Port 8000:
netstat -ano | findstr :8000
echo.
pause
