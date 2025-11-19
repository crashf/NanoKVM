#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Package NanoKVM builds for deployment

.DESCRIPTION
    Creates a deployment package containing:
    - Frontend (web/dist)
    - Backend server (NanoKVM-Server)
    - WireGuard binary (wireguard-go)
    - Deployment script

.PARAMETER OutputDir
    Directory to create the package (default: .\deploy-package)

.EXAMPLE
    .\package.ps1
    
.EXAMPLE
    .\package.ps1 -OutputDir C:\Deployments\NanoKVM
#>

param(
    [string]$OutputDir = ".\deploy-package"
)

# Colors
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoPath = $ScriptDir

function Show-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $SuccessColor
}

function Show-Info {
    param([string]$Message)
    Write-Host "→ $Message" -ForegroundColor $InfoColor
}

function Exit-WithError {
    param([string]$Message)
    Write-Host "✗ ERROR: $Message" -ForegroundColor $ErrorColor
    exit 1
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════════╗" -ForegroundColor $InfoColor
Write-Host "║     NanoKVM Package Builder               ║" -ForegroundColor $InfoColor
Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor $InfoColor
Write-Host ""

# Check if builds exist
Show-Info "Checking for required files..."

if (-not (Test-Path "$RepoPath\web\dist")) {
    Exit-WithError "Frontend build not found. Run 'cd web && pnpm run build' first"
}
Show-Success "Frontend build found"

if (-not (Test-Path "$RepoPath\server\NanoKVM-Server")) {
    Exit-WithError "Backend binary not found. Run 'wsl -d Ubuntu -e bash build-wsl.sh' first"
}
Show-Success "Backend binary found"

if (-not (Test-Path "$RepoPath\wireguard-riscv64\wireguard-go")) {
    Exit-WithError "WireGuard binary not found at wireguard-riscv64\wireguard-go"
}
Show-Success "WireGuard binary found"

# Create output directory
Show-Info "Creating package directory..."
if (Test-Path $OutputDir) {
    Remove-Item -Recurse -Force $OutputDir
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputDir\web" -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputDir\server" -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputDir\wireguard" -Force | Out-Null
Show-Success "Package directory created"

# Copy frontend
Show-Info "Packaging frontend..."
Copy-Item -Path "$RepoPath\web\dist\*" -Destination "$OutputDir\web\" -Recurse -Force
$frontendFiles = (Get-ChildItem -Path "$OutputDir\web" -Recurse -File).Count
Show-Success "Packaged $frontendFiles frontend files"

# Copy backend
Show-Info "Packaging backend..."
Copy-Item -Path "$RepoPath\server\NanoKVM-Server" -Destination "$OutputDir\server\" -Force
$backendSize = [math]::Round((Get-Item "$OutputDir\server\NanoKVM-Server").Length / 1MB, 1)
Show-Success "Packaged backend binary ($backendSize MB)"

# Copy WireGuard
Show-Info "Packaging WireGuard..."
Copy-Item -Path "$RepoPath\wireguard-riscv64\wireguard-go" -Destination "$OutputDir\wireguard\" -Force
$wgSize = [math]::Round((Get-Item "$OutputDir\wireguard\wireguard-go").Length / 1MB, 1)
Show-Success "Packaged WireGuard binary ($wgSize MB)"

# Create deployment script
Show-Info "Creating deployment script..."
$deployScriptContent = @'
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy NanoKVM package to device

.PARAMETER DeviceIP
    IP address of the NanoKVM device

.PARAMETER Password
    SSH password (optional, will prompt if not provided)

.EXAMPLE
    .\deploy-package.ps1 -DeviceIP 10.24.69.63
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$DeviceIP,
    [string]$Password
)

$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

function Show-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $SuccessColor
}

function Show-Info {
    param([string]$Message)
    Write-Host "→ $Message" -ForegroundColor $InfoColor
}

function Show-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor $WarningColor
}

function Exit-WithError {
    param([string]$Message)
    Write-Host "✗ ERROR: $Message" -ForegroundColor $ErrorColor
    exit 1
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════════╗" -ForegroundColor $InfoColor
Write-Host "║     NanoKVM Package Deployer              ║" -ForegroundColor $InfoColor
Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor $InfoColor
Write-Host ""

# Get device IP if not provided
if (-not $DeviceIP) {
    $DeviceIP = Read-Host "Enter NanoKVM device IP address"
    if ([string]::IsNullOrWhiteSpace($DeviceIP)) {
        Exit-WithError "Device IP is required"
    }
}

Write-Host "Target Device: $DeviceIP" -ForegroundColor $InfoColor
Write-Host ""

# Test connection
Show-Info "Testing connection to $DeviceIP..."
$pingResult = Test-Connection -ComputerName $DeviceIP -Count 1 -Quiet
if (-not $pingResult) {
    Show-Warning "Device not responding to ping. Continuing anyway..."
} else {
    Show-Success "Device is reachable"
}

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Check package contents
Show-Info "Verifying package contents..."
if (-not (Test-Path "$ScriptDir\web")) {
    Exit-WithError "Frontend files not found in package"
}
if (-not (Test-Path "$ScriptDir\server\NanoKVM-Server")) {
    Exit-WithError "Backend binary not found in package"
}
if (-not (Test-Path "$ScriptDir\wireguard\wireguard-go")) {
    Exit-WithError "WireGuard binary not found in package"
}
Show-Success "Package contents verified"

Write-Host ""
Show-Info "Ready to deploy to $DeviceIP"
Write-Host "You will be prompted for the SSH password multiple times." -ForegroundColor $WarningColor
Write-Host ""

$confirm = Read-Host "Continue with deployment? (Y/n)"
if ($confirm -eq "n" -or $confirm -eq "N") {
    Write-Host "Deployment cancelled." -ForegroundColor $WarningColor
    exit 0
}

# Deploy frontend
Write-Host ""
Write-Host "═══ Deploying Frontend ═══" -ForegroundColor $InfoColor
Show-Info "Copying frontend files to device..."
scp -r "$ScriptDir\web\*" "root@${DeviceIP}:/kvmapp/server/web/"
if ($LASTEXITCODE -ne 0) {
    Exit-WithError "Frontend deployment failed"
}
Show-Success "Frontend deployed"

# Deploy backend
Write-Host ""
Write-Host "═══ Deploying Backend ═══" -ForegroundColor $InfoColor
Show-Info "Copying server binary to device..."
scp "$ScriptDir\server\NanoKVM-Server" "root@${DeviceIP}:/kvmapp/server/"
if ($LASTEXITCODE -ne 0) {
    Exit-WithError "Backend deployment failed"
}
Show-Success "Backend deployed"

# Deploy WireGuard
Write-Host ""
Write-Host "═══ Deploying WireGuard ═══" -ForegroundColor $InfoColor
Show-Info "Copying WireGuard binary to device..."
scp "$ScriptDir\wireguard\wireguard-go" "root@${DeviceIP}:/usr/bin/"
if ($LASTEXITCODE -ne 0) {
    Exit-WithError "WireGuard deployment failed"
}

Show-Info "Setting executable permissions..."
ssh "root@${DeviceIP}" "chmod +x /usr/bin/wireguard-go"
if ($LASTEXITCODE -ne 0) {
    Show-Warning "Failed to set WireGuard permissions"
}
Show-Success "WireGuard deployed"

# Restart service
Write-Host ""
Write-Host "═══ Restarting NanoKVM Service ═══" -ForegroundColor $InfoColor
Show-Info "Restarting service..."
Show-Warning "Service restart may show some warnings - this is normal"
ssh "root@${DeviceIP}" "/etc/init.d/S95nanokvm restart" 2>&1 | Out-Null

Start-Sleep -Seconds 3

Show-Info "Verifying service is running..."
$psOutput = ssh "root@${DeviceIP}" "ps | grep NanoKVM-Server | grep -v grep" 2>&1
if ($psOutput) {
    Show-Success "Service restarted successfully"
    $pid = ($psOutput -split '\s+')[0]
    Show-Info "Service running with PID: $pid"
} else {
    Show-Warning "Could not verify service is running"
}

# Success
Write-Host ""
Write-Host "╔═══════════════════════════════════════════╗" -ForegroundColor $SuccessColor
Write-Host "║         DEPLOYMENT SUCCESSFUL! 🎉         ║" -ForegroundColor $SuccessColor
Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor $SuccessColor
Write-Host ""
Write-Host "Access your NanoKVM at: http://${DeviceIP}" -ForegroundColor $SuccessColor
Write-Host ""
Write-Host "Next steps:" -ForegroundColor $InfoColor
Write-Host "  1. Open http://${DeviceIP} in your browser" -ForegroundColor White
Write-Host "  2. Hard refresh (Ctrl+F5) to clear cache" -ForegroundColor White
Write-Host "  3. Login and verify all features work" -ForegroundColor White
Write-Host ""
Write-Host "WireGuard control:" -ForegroundColor $InfoColor
Write-Host "  Start:  ssh root@${DeviceIP} '/usr/bin/wg-quick up wg0'" -ForegroundColor White
Write-Host "  Stop:   ssh root@${DeviceIP} '/usr/bin/wg-quick down wg0'" -ForegroundColor White
Write-Host "  Status: ssh root@${DeviceIP} 'wg show'" -ForegroundColor White
Write-Host ""
'@

Set-Content -Path "$OutputDir\deploy-package.ps1" -Value $deployScriptContent -Encoding UTF8
Show-Success "Deployment script created"

# Create README
Show-Info "Creating package README..."
$readmeContent = @"
# NanoKVM Deployment Package

This package contains pre-built NanoKVM binaries ready for deployment.

## Package Contents

- **web/**: Frontend build (HTML, CSS, JS)
- **server/NanoKVM-Server**: Backend server binary (RISC-V64)
- **wireguard/wireguard-go**: WireGuard userspace implementation
- **deploy-package.ps1**: Deployment script

## Quick Deploy

``````powershell
.\deploy-package.ps1 -DeviceIP 10.24.69.63
``````

You will be prompted for the SSH password (typically 4 times).

## What Gets Deployed

1. **Frontend** → /kvmapp/server/web/
   - All web interface files
   - JavaScript bundles
   - Stylesheets and assets

2. **Backend** → /kvmapp/server/NanoKVM-Server
   - Main server binary
   - Handles API requests
   - Manages video streaming

3. **WireGuard** → /usr/bin/wireguard-go
   - VPN binary
   - Enables secure remote access

## After Deployment

1. Access web UI: http://<device-ip>
2. Hard refresh browser (Ctrl+F5)
3. Login and test functionality

## WireGuard Commands

Start WireGuard:
``````powershell
ssh root@<device-ip> "/usr/bin/wg-quick up wg0"
``````

Stop WireGuard:
``````powershell
ssh root@<device-ip> "/usr/bin/wg-quick down wg0"
``````

Check status:
``````powershell
ssh root@<device-ip> "wg show"
``````

## Requirements

- Windows 10/11 with PowerShell
- SSH/SCP commands available
- Network access to device
- SSH enabled on device

## Troubleshooting

**Connection failed:**
- Verify device IP: ``ping <device-ip>``
- Check SSH is enabled on device
- Verify password is correct

**Service not starting:**
- Check logs: ``ssh root@<device-ip> "tail -50 /var/log/messages"``
- Verify binary architecture: ``ssh root@<device-ip> "file /kvmapp/server/NanoKVM-Server"``

**Old version showing:**
- Clear browser cache
- Hard refresh (Ctrl+F5)
- Try incognito mode

## Package Information

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Frontend files: $frontendFiles
Backend size: $backendSize MB
WireGuard size: $wgSize MB

## Support

For issues or questions, refer to the main repository documentation.
"@

Set-Content -Path "$OutputDir\README.md" -Value $readmeContent -Encoding UTF8
Show-Success "README created"

# Create version info
Show-Info "Creating version info..."
$versionInfo = @{
    PackageDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    FrontendFiles = $frontendFiles
    BackendSize = "$backendSize MB"
    WireGuardSize = "$wgSize MB"
    GitCommit = (git rev-parse --short HEAD 2>$null)
    GitBranch = (git branch --show-current 2>$null)
}
$versionInfo | ConvertTo-Json | Set-Content -Path "$OutputDir\version.json" -Encoding UTF8
Show-Success "Version info created"

# Summary
Write-Host ""
Write-Host "╔═══════════════════════════════════════════╗" -ForegroundColor $SuccessColor
Write-Host "║         PACKAGE CREATED! 📦               ║" -ForegroundColor $SuccessColor
Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor $SuccessColor
Write-Host ""
Write-Host "Package location: $OutputDir" -ForegroundColor $InfoColor
Write-Host ""
Write-Host "Package contents:" -ForegroundColor $InfoColor
Write-Host "  • Frontend: $frontendFiles files" -ForegroundColor White
Write-Host "  • Backend: $backendSize MB" -ForegroundColor White
Write-Host "  • WireGuard: $wgSize MB" -ForegroundColor White
Write-Host ""
Write-Host "To deploy:" -ForegroundColor $InfoColor
Write-Host "  cd $OutputDir" -ForegroundColor White
Write-Host "  .\deploy-package.ps1 -DeviceIP 10.24.69.63" -ForegroundColor White
Write-Host ""
Write-Host "To create a ZIP archive:" -ForegroundColor $InfoColor
Write-Host "  Compress-Archive -Path '$OutputDir' -DestinationPath 'nanokvm-package.zip'" -ForegroundColor White
Write-Host ""
