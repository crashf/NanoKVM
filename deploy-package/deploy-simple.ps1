# NanoKVM Simple Package Deployer
# This version uses standard SCP/SSH - you will be prompted for password multiple times
param([string]$DeviceIP)

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host " NanoKVM Simple Package Deployer    " -ForegroundColor Cyan
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
Write-Host "NOTE: You will be prompted for SSH password multiple times" -ForegroundColor Yellow
Write-Host "      This is normal - just enter the password when asked" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Continue with deployment? (Y/n)"
if ($confirm -eq "n" -or $confirm -eq "N") {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Deploy frontend
Write-Host ""
Write-Host "[*] Deploying frontend (password prompt #1)..." -ForegroundColor Cyan
scp -r "$ScriptDir\web\*" "root@${DeviceIP}:/kvmapp/server/web/"
if ($LASTEXITCODE -ne 0) { 
    Write-Host "[!] ERROR: Frontend deployment failed" -ForegroundColor Red
    exit 1 
}
Write-Host "[+] Frontend deployed" -ForegroundColor Green

# Deploy backend
Write-Host ""
Write-Host "[*] Deploying backend (password prompt #2 - large file, may take 30-60 seconds)..." -ForegroundColor Cyan
scp "$ScriptDir\server\NanoKVM-Server" "root@${DeviceIP}:/kvmapp/server/"
if ($LASTEXITCODE -ne 0) { 
    Write-Host "[!] ERROR: Backend deployment failed" -ForegroundColor Red
    exit 1 
}
Write-Host "[+] Backend deployed" -ForegroundColor Green

# Deploy WireGuard binary
Write-Host ""
Write-Host "[*] Deploying WireGuard binary (password prompt #3)..." -ForegroundColor Cyan
scp "$ScriptDir\wireguard\wireguard-go" "root@${DeviceIP}:/usr/bin/"
if ($LASTEXITCODE -ne 0) { 
    Write-Host "[!] ERROR: WireGuard binary deployment failed" -ForegroundColor Red
    exit 1 
}
Write-Host "[+] WireGuard binary deployed" -ForegroundColor Green

# Deploy WireGuard init script
Write-Host ""
Write-Host "[*] Deploying WireGuard init script (password prompt #4)..." -ForegroundColor Cyan
scp "$ScriptDir\wireguard\S40wireguard" "root@${DeviceIP}:/etc/init.d/"
if ($LASTEXITCODE -ne 0) { 
    Write-Host "[!] ERROR: WireGuard init script deployment failed" -ForegroundColor Red
    exit 1 
}
Write-Host "[+] WireGuard init script deployed" -ForegroundColor Green

# Set permissions
Write-Host ""
Write-Host "[*] Setting permissions (password prompt #5)..." -ForegroundColor Cyan
ssh "root@${DeviceIP}" "chmod +x /usr/bin/wireguard-go && chmod +x /etc/init.d/S40wireguard"
if ($LASTEXITCODE -ne 0) { 
    Write-Host "[!] WARNING: Permission setting may have failed" -ForegroundColor Yellow
}
Write-Host "[+] Permissions set" -ForegroundColor Green

# Create resolvconf stub
Write-Host ""
Write-Host "[*] Creating resolvconf stub (password prompt #6)..." -ForegroundColor Cyan
ssh "root@${DeviceIP}" "if [ ! -f /usr/bin/resolvconf ]; then echo '#!/bin/sh' > /usr/bin/resolvconf && echo 'exit 0' >> /usr/bin/resolvconf && chmod +x /usr/bin/resolvconf; fi"
if ($LASTEXITCODE -ne 0) { 
    Write-Host "[!] WARNING: Resolvconf stub may have failed" -ForegroundColor Yellow
}
Write-Host "[+] Resolvconf stub created" -ForegroundColor Green

# Restart service
Write-Host ""
Write-Host "[*] Restarting NanoKVM service (password prompt #7)..." -ForegroundColor Cyan
ssh "root@${DeviceIP}" "/etc/init.d/S95nanokvm restart"
Start-Sleep -Seconds 3

# Verify
Write-Host ""
Write-Host "[*] Verifying service (password prompt #8)..." -ForegroundColor Cyan
$psOutput = ssh "root@${DeviceIP}" "ps | grep NanoKVM-Server | grep -v grep"
if ($psOutput) {
    Write-Host "[+] NanoKVM service is running" -ForegroundColor Green
} else {
    Write-Host "[!] Could not verify service status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host " DEPLOYMENT COMPLETE!                " -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access: http://${DeviceIP}" -ForegroundColor Cyan
Write-Host "Remember to hard refresh (Ctrl+F5) in your browser" -ForegroundColor Yellow
Write-Host ""
