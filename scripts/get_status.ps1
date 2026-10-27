$ErrorActionPreference = "SilentlyContinue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$UrlFile = Join-Path $ScriptDir "current_tunnel_url.txt"
$EnvFile = Join-Path $ProjectRoot "mobile\.env"

# 1. Check Local Loopback
Write-Host "--- 1. Local Python API Server (Port 8000) ---" -ForegroundColor Cyan
try {
    $localResp = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/health" -TimeoutSec 3 -ErrorAction Stop
    Write-Host " [OK] Loopback http://127.0.0.1:8000 is UP" -ForegroundColor Green
    Write-Host ("      Status: {0} | Version: {1}" -f $localResp.status, $localResp.version) -ForegroundColor Gray
    Write-Host ("      Gemini: {0} | Database: {1}" -f $localResp.engines.gemini, $localResp.engines.database) -ForegroundColor Magenta
} catch {
    Write-Host " [X]  Port 8000 unreachable. Backend is not running." -ForegroundColor Red
    Write-Host "      Run: powershell -ExecutionPolicy Bypass -File scripts\start_backend.ps1" -ForegroundColor Yellow
}

# 2. Check LAN Wi-Fi Route
Write-Host ""
Write-Host "--- 2. Direct Wi-Fi LAN Address (Zero-Latency) ---" -ForegroundColor Cyan
$lanIp = "127.0.0.1"
try {
    $route = Find-NetRoute -RemoteIPAddress "8.8.8.8" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($route -and $route.IPAddress) { $lanIp = $route.IPAddress }
} catch {}

try {
    $lanResp = Invoke-RestMethod -Uri "http://${lanIp}:8000/api/v1/health" -TimeoutSec 3 -ErrorAction Stop
    Write-Host (" [OK] Wi-Fi LAN http://{0}:8000 is UP" -f $lanIp) -ForegroundColor Green
    Write-Host "      Physical Android/iOS devices on same Wi-Fi can connect directly." -ForegroundColor Gray
} catch {
    Write-Host (" [!]  Wi-Fi LAN http://{0}:8000 did not respond." -f $lanIp) -ForegroundColor Yellow
}

# 3. Check Public HTTPS Tunnel
Write-Host ""
Write-Host "--- 3. Public HTTPS Tunnel & Mobile Sync ---" -ForegroundColor Cyan
if (Test-Path $UrlFile) {
    $tunnelUrl = (Get-Content $UrlFile -Raw).Trim()
    Write-Host (" Recorded Tunnel URL: {0}" -f $tunnelUrl) -ForegroundColor Green
    try {
        $tResp = Invoke-RestMethod -Uri "${tunnelUrl}/api/v1/health" -Headers @{'Bypass-Tunnel-Reminder'='true'} -TimeoutSec 5 -ErrorAction Stop
        Write-Host (" [OK] Public Tunnel is UP and reachable from internet ({0})" -f $tResp.status) -ForegroundColor Green
    } catch {
        Write-Host " [!]  Public Tunnel did not respond to health check." -ForegroundColor Yellow
    }
} else {
    Write-Host " [!]  No current_tunnel_url.txt recorded yet." -ForegroundColor Yellow
}

if (Test-Path $EnvFile) {
    $envContent = Get-Content $EnvFile | Where-Object { $_ -match '^API_BASE_URL=' }
    Write-Host (" mobile\.env Config : {0}" -f $envContent) -ForegroundColor DarkYellow
}
