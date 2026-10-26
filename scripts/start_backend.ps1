# ReceiptLedger - Background Service Runner
$ErrorActionPreference = "SilentlyContinue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$BackendDir = Join-Path $ProjectRoot "backend"
$LogPath = Join-Path $ScriptDir "tunnel.log"
$UrlFile = Join-Path $ScriptDir "current_tunnel_url.txt"
$CloudflaredPath = "C:\Program Files (x86)\cloudflared\cloudflared.exe"

# 1. Start Python Uvicorn Backend on port 8000 if not already listening
$portCheck = Test-NetConnection -ComputerName 127.0.0.1 -Port 8000 -InformationLevel Quiet
if (-not $portCheck) {
    Start-Process -FilePath "python" -ArgumentList "-m uvicorn app.main:app --host 127.0.0.1 --port 8000" -WorkingDirectory $BackendDir -WindowStyle Hidden
    Start-Sleep -Seconds 3
}

# 2. Start Cloudflare Tunnel if not already running
$cfProc = Get-Process cloudflared -ErrorAction SilentlyContinue
if (-not $cfProc) {
    Start-Process -FilePath $CloudflaredPath -ArgumentList "tunnel --url http://127.0.0.1:8000" -RedirectStandardError $LogPath -WindowStyle Hidden
}

# 3. Wait and extract live trycloudflare URL
Start-Sleep -Seconds 5
if (Test-Path $LogPath) {
    $content = Get-Content $LogPath -Raw
    if ($content -match "https://[a-zA-Z0-9\-]+\.trycloudflare\.com") {
        $tunnelUrl = $Matches[0]
        Set-Content -Path $UrlFile -Value $tunnelUrl
    }
}
