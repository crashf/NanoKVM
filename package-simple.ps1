# NanoKVM Package Creator
# Creates a deployment package with pre-built binaries

param(
    [string]$OutputDir = ".\deploy-package"
)

$ErrorActionPreference = "Stop"

# Get repo root
$RepoPath = Split-Path -Parent $MyInvocation.MyCommand.Path

function Exit-WithError {
    param([string]$Message)
    Write-Host "[!] ERROR: $Message" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host " NanoKVM Package Creator             " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "[*] Checking prerequisites..." -ForegroundColor Cyan

if (-not (Test-Path "$RepoPath\web\dist")) {
    Exit-WithError "Frontend build not found at web\dist. Run: cd web && pnpm run build"
}

if (-not (Test-Path "$RepoPath\server\NanoKVM-Server")) {
    Exit-WithError "Backend binary not found at server\NanoKVM-Server. Run: cd server && bash build-wsl.sh"
}

if (-not (Test-Path "$RepoPath\wireguard-riscv64\wireguard-go")) {
    Exit-WithError "WireGuard binary not found at wireguard-riscv64\wireguard-go"
}

if (-not (Test-Path "$RepoPath\kvmapp\system\init.d\S40wireguard")) {
    Exit-WithError "WireGuard init script not found at kvmapp\system\init.d\S40wireguard"
}

Write-Host "[+] All prerequisites found" -ForegroundColor Green

# Create output directory
Write-Host ""
Write-Host "[*] Creating package directory..." -ForegroundColor Cyan
if (Test-Path $OutputDir) {
    Remove-Item -Path $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Path "$OutputDir\web" | Out-Null
New-Item -ItemType Directory -Path "$OutputDir\server" | Out-Null
New-Item -ItemType Directory -Path "$OutputDir\wireguard" | Out-Null
Write-Host "[+] Created $OutputDir" -ForegroundColor Green

# Package frontend
Write-Host ""
Write-Host "[*] Packaging frontend..." -ForegroundColor Cyan
Copy-Item -Path "$RepoPath\web\dist\*" -Destination "$OutputDir\web\" -Recurse -Force
$webFiles = (Get-ChildItem -Path "$OutputDir\web" -Recurse -File).Count
$webSize = [math]::Round((Get-ChildItem -Path "$OutputDir\web" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
Write-Host "[+] Packaged frontend: $webFiles files ($webSize MB)" -ForegroundColor Green

# Package backend
Write-Host ""
Write-Host "[*] Packaging backend..." -ForegroundColor Cyan
Copy-Item -Path "$RepoPath\server\NanoKVM-Server" -Destination "$OutputDir\server\" -Force
Copy-Item -Path "$RepoPath\server\dl_lib" -Destination "$OutputDir\server\" -Recurse -Force
$serverSize = [math]::Round((Get-Item "$OutputDir\server\NanoKVM-Server").Length / 1MB, 1)
Write-Host "[+] Packaged backend binary and libraries ($serverSize MB)" -ForegroundColor Green

# Package WireGuard
Write-Host ""
Write-Host "[*] Packaging WireGuard..." -ForegroundColor Cyan
Copy-Item -Path "$RepoPath\wireguard-riscv64\wireguard-go" -Destination "$OutputDir\wireguard\" -Force

# Copy and convert line endings for init script (CRITICAL: Unix LF only)
$initScriptContent = Get-Content -Path "$RepoPath\kvmapp\system\init.d\S40wireguard" -Raw
$initScriptContent = $initScriptContent -replace "`r`n", "`n"
Set-Content -Path "$OutputDir\wireguard\S40wireguard" -Value $initScriptContent -NoNewline -Encoding ASCII

$wgSize = [math]::Round((Get-Item "$OutputDir\wireguard\wireguard-go").Length / 1MB, 1)
Write-Host "[+] Packaged WireGuard binary and init script ($wgSize MB)" -ForegroundColor Green

# Create simplified deployment script (no password automation - let SSH/SCP prompt normally)
Write-Host ""
Write-Host "[*] Creating deployment script..." -ForegroundColor Cyan

$deployScript = @'
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
'@

Set-Content -Path "$OutputDir\deploy-package.ps1" -Value $deployScript -Encoding UTF8

Write-Host "[+] Created deploy-package.ps1" -ForegroundColor Green

# Create README
$readme = @"
# NanoKVM Deployment Package

This package contains pre-built binaries ready for deployment to your NanoKVM device.

## Package Contents

- **web/** - Frontend files (React app built with Vite)
- **server/** - Backend binary (NanoKVM-Server for RISC-V64)
- **wireguard/** - WireGuard userspace binary and init script
- **deploy-package.ps1** - Deployment script

## Quick Start

1. Connect to same network as your NanoKVM device
2. Run deployment script:
   ``````powershell
   .\deploy-package.ps1 -DeviceIP 10.24.69.63
   ``````
3. Enter SSH password when prompted (will be asked 6 times)
4. Wait for deployment to complete

## SSH Password Prompts

The deployment script will prompt for your SSH password 6 times:
- Frontend deployment (1x)
- Backend deployment (1x)
- WireGuard binary deployment (1x)
- WireGuard init script deployment (1x)
- Permission setting (1x)
- Service restart (1x)

**To avoid password prompts**, set up SSH key authentication first:
``````powershell
ssh-keygen -t rsa -b 4096
Get-Content ~\.ssh\id_rsa.pub | ssh root@10.24.69.63 "cat >> ~/.ssh/authorized_keys"
``````

## What Gets Deployed

| Component | Source | Destination | Purpose |
|-----------|--------|-------------|---------|
| Frontend | web/* | /kvmapp/server/web/ | Web interface |
| Backend | server/NanoKVM-Server | /kvmapp/server/ | Main server binary |
| WireGuard | wireguard/wireguard-go | /usr/bin/ | WireGuard userspace |
| Init Script | wireguard/S40wireguard | /etc/init.d/ | WireGuard autostart |
| resolvconf | (created) | /usr/bin/ | Stub for wg-quick |

## Verification Steps

After deployment:

1. **Check web interface**: http://[device-ip]
   - Hard refresh (Ctrl+F5)
   - Open Settings menu
   - Verify 7 tabs: About, Appearance, Device, Tailscale, WireGuard, Update, Account

2. **Check WireGuard**:
   ``````bash
   ssh root@[device-ip]
   which wireguard-go  # Should show /usr/bin/wireguard-go
   /etc/init.d/S40wireguard start
   wg show  # Should show interface wg0
   ``````

3. **Test autostart**:
   ``````bash
   reboot
   # After reboot
   wg show  # Should show interface wg0 is up
   ``````

## Troubleshooting

**Deployment hangs**: 
- Make sure device is accessible via SSH
- Try manual connection first: `ssh root@[device-ip]`
- Check firewall isn't blocking SSH port 22

**Permission denied**:
- Verify SSH password is correct
- Check device IP is correct

**WireGuard won't start**:
- Check init script has Unix line endings: `ssh root@[device-ip] "sed -n 'l' /etc/init.d/S40wireguard | head -5"`
- Should NOT see `\r` characters
- If you see `\r`, repackage with package.ps1

**Frontend not updating**:
- Hard refresh browser (Ctrl+F5)
- Clear browser cache
- Check deployment copied files: `ssh root@[device-ip] "ls -lh /kvmapp/server/web/"`

## Package Creation

This package was created with:
``````powershell
.\package-simple.ps1 -OutputDir .\deploy-package
``````

To create a new package after rebuilding:
``````powershell
# Rebuild frontend
cd web
pnpm run build

# Rebuild backend
cd ..\server
bash build-wsl.sh

# Create new package
cd ..
.\package-simple.ps1
``````

## Support

For issues or questions, see BUILD_AND_DEPLOY.md for detailed build and deployment instructions.
"@

Set-Content -Path "$OutputDir\README.md" -Value $readme -Encoding UTF8
Write-Host "[+] Created README.md" -ForegroundColor Green

# Create version file
$version = @{
    packageDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    frontend = @{
        files = $webFiles
        sizeMB = $webSize
    }
    backend = @{
        sizeMB = $serverSize
    }
    wireguard = @{
        sizeMB = $wgSize
    }
} | ConvertTo-Json -Depth 3

Set-Content -Path "$OutputDir\version.json" -Value $version -Encoding UTF8
Write-Host "[+] Created version.json" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host " Package Created Successfully!       " -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Package location: $OutputDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Contents:" -ForegroundColor Cyan
Write-Host "  - Frontend: $webFiles files ($webSize MB)" -ForegroundColor White
Write-Host "  - Backend: $serverSize MB" -ForegroundColor White
Write-Host "  - WireGuard: $wgSize MB" -ForegroundColor White
Write-Host ""
Write-Host "To deploy:" -ForegroundColor Cyan
Write-Host "  cd $OutputDir" -ForegroundColor White
Write-Host "  .\deploy-package.ps1 -DeviceIP 10.24.69.63" -ForegroundColor White
Write-Host ""
Write-Host "NOTE: You will be prompted for SSH password 6 times during deployment" -ForegroundColor Yellow
Write-Host "      To avoid this, set up SSH key authentication (see README.md)" -ForegroundColor Yellow
Write-Host ""
