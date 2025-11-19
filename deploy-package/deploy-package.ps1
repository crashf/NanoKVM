# NanoKVM Package Deployer
# NOTE: This script will prompt for SSH password multiple times
# To avoid password prompts, set up SSH key authentication first

param(
    [string]$DeviceIP
)

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host " NanoKVM Package Deployer            " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

if (-not $DeviceIP) {
    $DeviceIP = Read-Host "Enter NanoKVM device IP address (e.g., 10.24.69.63)"
    if ([string]::IsNullOrWhiteSpace($DeviceIP)) {
        Write-Host "[!] ERROR: Device IP is required" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Target Device: $DeviceIP" -ForegroundColor Cyan
Write-Host ""

# Test connection
Write-Host "[*] Testing connection..." -ForegroundColor Cyan
$pingResult = Test-Connection -ComputerName $DeviceIP -Count 1 -Quiet -ErrorAction SilentlyContinue
if ($pingResult) {
    Write-Host "[+] Device is reachable" -ForegroundColor Green
} else {
    Write-Host "[!] Device not responding to ping (continuing anyway)" -ForegroundColor Yellow
}

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Check package contents
Write-Host ""
Write-Host "[*] Verifying package contents..." -ForegroundColor Cyan
if (-not (Test-Path "$ScriptDir\web")) {
    Write-Host "[!] ERROR: Frontend files not found" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path "$ScriptDir\server\NanoKVM-Server")) {
    Write-Host "[!] ERROR: Backend binary not found" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path "$ScriptDir\wireguard\wireguard-go")) {
    Write-Host "[!] ERROR: WireGuard binary not found" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path "$ScriptDir\wireguard\S40wireguard")) {
    Write-Host "[!] ERROR: WireGuard init script not found" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Package contents verified" -ForegroundColor Green

Write-Host ""
Write-Host "Ready to deploy to $DeviceIP" -ForegroundColor Cyan
Write-Host "NOTE: You will be prompted for the SSH password multiple times" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Continue with deployment? (Y/n)"
if ($confirm -eq "n" -or $confirm -eq "N") {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

# Deploy frontend
Write-Host ""
Write-Host "[*] Deploying frontend (20 files)..." -ForegroundColor Cyan
Write-Host "[*] Enter password when prompted..." -ForegroundColor Yellow
scp -r "$ScriptDir\web\*" "root@${DeviceIP}:/kvmapp/server/web/"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] ERROR: Frontend deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Frontend deployed" -ForegroundColor Green

# Deploy backend
Write-Host ""
Write-Host "[*] Deploying backend binary..." -ForegroundColor Cyan
Write-Host "[*] Enter password when prompted..." -ForegroundColor Yellow
scp "$ScriptDir\server\NanoKVM-Server" "root@${DeviceIP}:/kvmapp/server/"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] ERROR: Backend deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Backend deployed" -ForegroundColor Green

# Deploy WireGuard binary
Write-Host ""
Write-Host "[*] Deploying WireGuard binary..." -ForegroundColor Cyan
Write-Host "[*] Enter password when prompted..." -ForegroundColor Yellow
scp "$ScriptDir\wireguard\wireguard-go" "root@${DeviceIP}:/usr/bin/"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] ERROR: WireGuard binary deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "[+] WireGuard binary deployed" -ForegroundColor Green

# Deploy WireGuard init script
Write-Host ""
Write-Host "[*] Deploying WireGuard init script..." -ForegroundColor Cyan
Write-Host "[*] Enter password when prompted..." -ForegroundColor Yellow
scp "$ScriptDir\wireguard\S40wireguard" "root@${DeviceIP}:/etc/init.d/"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] ERROR: WireGuard init script deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "[+] WireGuard init script deployed" -ForegroundColor Green

# Set permissions and create resolvconf stub
Write-Host ""
Write-Host "[*] Setting permissions and creating resolvconf stub..." -ForegroundColor Cyan
Write-Host "[*] Enter password when prompted..." -ForegroundColor Yellow
ssh "root@$DeviceIP" "chmod +x /kvmapp/server/NanoKVM-Server && chmod +x /usr/bin/wireguard-go && chmod +x /etc/init.d/S40wireguard && echo '#!/bin/sh' > /usr/bin/resolvconf && echo 'exit 0' >> /usr/bin/resolvconf && chmod +x /usr/bin/resolvconf"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] ERROR: Permission setting failed" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Permissions set and resolvconf stub created" -ForegroundColor Green

# Restart NanoKVM service
Write-Host ""
Write-Host "[*] Restarting NanoKVM service..." -ForegroundColor Cyan
Write-Host "[*] Enter password when prompted..." -ForegroundColor Yellow
ssh "root@$DeviceIP" "/etc/init.d/S95nanokvm restart"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] WARNING: Service restart may have failed" -ForegroundColor Yellow
} else {
    Write-Host "[+] NanoKVM service restarted" -ForegroundColor Green
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host " Deployment Complete!                " -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Open browser to http://$DeviceIP" -ForegroundColor White
Write-Host "2. Hard refresh (Ctrl+F5) to clear cache" -ForegroundColor White
Write-Host "3. Verify all 7 menu items appear in Settings" -ForegroundColor White
Write-Host "4. Configure WireGuard and reboot to test autostart" -ForegroundColor White
Write-Host ""
