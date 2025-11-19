# NanoKVM Package Script
# Creates a deployment package from current builds

param(
    [string]$OutputDir = ".\deploy-package"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoPath = $ScriptDir

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host " NanoKVM Package Builder             " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if builds exist
Write-Host "[*] Checking for required files..." -ForegroundColor Cyan

if (-not (Test-Path "$RepoPath\web\dist")) {
    Write-Host "[!] ERROR: Frontend build not found" -ForegroundColor Red
    Write-Host "    Run: cd web && pnpm run build" -ForegroundColor Yellow
    exit 1
}
Write-Host "[+] Frontend build found" -ForegroundColor Green

if (-not (Test-Path "$RepoPath\server\NanoKVM-Server")) {
    Write-Host "[!] ERROR: Backend binary not found" -ForegroundColor Red
    Write-Host "    Run: wsl -d Ubuntu -e bash build-wsl.sh" -ForegroundColor Yellow
    exit 1
}
Write-Host "[+] Backend binary found" -ForegroundColor Green

if (-not (Test-Path "$RepoPath\wireguard-riscv64\wireguard-go")) {
    Write-Host "[!] ERROR: WireGuard binary not found" -ForegroundColor Red
    Write-Host "    Path: wireguard-riscv64\wireguard-go" -ForegroundColor Yellow
    exit 1
}
Write-Host "[+] WireGuard binary found" -ForegroundColor Green

if (-not (Test-Path "$RepoPath\kvmapp\system\init.d\S40wireguard")) {
    Write-Host "[!] ERROR: WireGuard init script not found" -ForegroundColor Red
    Write-Host "    Path: kvmapp\system\init.d\S40wireguard" -ForegroundColor Yellow
    exit 1
}
Write-Host "[+] WireGuard init script found" -ForegroundColor Green

# Create output directory
Write-Host ""
Write-Host "[*] Creating package directory..." -ForegroundColor Cyan
if (Test-Path $OutputDir) {
    Remove-Item -Recurse -Force $OutputDir
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputDir\web" -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputDir\server" -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputDir\wireguard" -Force | Out-Null
Write-Host "[+] Package directory created" -ForegroundColor Green

# Copy frontend
Write-Host ""
Write-Host "[*] Packaging frontend..." -ForegroundColor Cyan
Copy-Item -Path "$RepoPath\web\dist\*" -Destination "$OutputDir\web\" -Recurse -Force
$frontendFiles = (Get-ChildItem -Path "$OutputDir\web" -Recurse -File).Count
Write-Host "[+] Packaged $frontendFiles frontend files" -ForegroundColor Green

# Copy backend
Write-Host ""
Write-Host "[*] Packaging backend..." -ForegroundColor Cyan
Copy-Item -Path "$RepoPath\server\NanoKVM-Server" -Destination "$OutputDir\server\" -Force
$backendSize = [math]::Round((Get-Item "$OutputDir\server\NanoKVM-Server").Length / 1MB, 1)
Write-Host "[+] Packaged backend binary ($backendSize MB)" -ForegroundColor Green

# Copy WireGuard
Write-Host ""
Write-Host "[*] Packaging WireGuard..." -ForegroundColor Cyan
Copy-Item -Path "$RepoPath\wireguard-riscv64\wireguard-go" -Destination "$OutputDir\wireguard\" -Force

# Copy and convert line endings for init script
$initScriptContent = Get-Content -Path "$RepoPath\kvmapp\system\init.d\S40wireguard" -Raw
$initScriptContent = $initScriptContent -replace "`r`n", "`n"
Set-Content -Path "$OutputDir\wireguard\S40wireguard" -Value $initScriptContent -NoNewline -Encoding ASCII

$wgSize = [math]::Round((Get-Item "$OutputDir\wireguard\wireguard-go").Length / 1MB, 1)
Write-Host "[+] Packaged WireGuard binary and init script ($wgSize MB)" -ForegroundColor Green

# Create deployment script using separate file to avoid escaping issues
Write-Host ""
Write-Host "[*] Creating deployment script..." -ForegroundColor Cyan

# Create the deploy script content in a file
$deployScript = @'
# NanoKVM Package Deployer
param(
    [string]$DeviceIP,
    [string]$Password
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

if (-not $Password) {
    $SecurePassword = Read-Host "Enter SSH password for root@${DeviceIP}" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
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
Write-Host ""

$confirm = Read-Host "Continue with deployment? (Y/n)"
if ($confirm -eq "n" -or $confirm -eq "N") {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

# Helper function to run SSH commands with password
function Invoke-SSHCommand {
    param(
        [string]$Command,
        [string]$IP,
        [string]$Pass
    )
    
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "ssh"
    $psi.Arguments = "root@$IP `"$Command`""
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $process.Start() | Out-Null
    
    # Send password if prompted
    Start-Sleep -Milliseconds 500
    $process.StandardInput.WriteLine($Pass)
    $process.StandardInput.Close()
    
    $output = $process.StandardOutput.ReadToEnd()
    $error = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    
    return @{
        ExitCode = $process.ExitCode
        Output = $output
        Error = $error
    }
}

# Helper function to run SCP with password
function Invoke-SCPCopy {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Pass,
        [switch]$Recursive
    )
    
    $args = if ($Recursive) { "-r" } else { "" }
    
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "scp"
    $psi.Arguments = "$args `"$Source`" `"$Destination`""
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $process.Start() | Out-Null
    
    # Send password if prompted
    Start-Sleep -Milliseconds 500
    $process.StandardInput.WriteLine($Pass)
    $process.StandardInput.Close()
    
    $output = $process.StandardOutput.ReadToEnd()
    $error = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    
    return $process.ExitCode
}

# Deploy frontend
Write-Host ""
Write-Host "[*] Deploying frontend..." -ForegroundColor Cyan
$exitCode = Invoke-SCPCopy -Source "$ScriptDir\web\*" -Destination "root@${DeviceIP}:/kvmapp/server/web/" -Pass $Password -Recursive
if ($exitCode -ne 0) {
    Write-Host "[!] ERROR: Frontend deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Frontend deployed" -ForegroundColor Green

# Deploy backend
Write-Host ""
Write-Host "[*] Deploying backend..." -ForegroundColor Cyan
$exitCode = Invoke-SCPCopy -Source "$ScriptDir\server\NanoKVM-Server" -Destination "root@${DeviceIP}:/kvmapp/server/" -Pass $Password
if ($exitCode -ne 0) {
    Write-Host "[!] ERROR: Backend deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Backend deployed" -ForegroundColor Green

# Deploy WireGuard
Write-Host ""
Write-Host "[*] Deploying WireGuard..." -ForegroundColor Cyan
$exitCode = Invoke-SCPCopy -Source "$ScriptDir\wireguard\wireguard-go" -Destination "root@${DeviceIP}:/usr/bin/" -Pass $Password
if ($exitCode -ne 0) {
    Write-Host "[!] ERROR: WireGuard binary deployment failed" -ForegroundColor Red
    exit 1
}

$exitCode = Invoke-SCPCopy -Source "$ScriptDir\wireguard\S40wireguard" -Destination "root@${DeviceIP}:/etc/init.d/" -Pass $Password
if ($exitCode -ne 0) {
    Write-Host "[!] ERROR: WireGuard init script deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "[*] Setting permissions..." -ForegroundColor Cyan
$result = Invoke-SSHCommand -Command "chmod +x /usr/bin/wireguard-go && chmod +x /etc/init.d/S40wireguard" -IP $DeviceIP -Pass $Password

Write-Host "[*] Creating resolvconf stub..." -ForegroundColor Cyan
$result = Invoke-SSHCommand -Command "if [ ! -f /usr/bin/resolvconf ]; then echo '#!/bin/sh' > /usr/bin/resolvconf && echo 'exit 0' >> /usr/bin/resolvconf && chmod +x /usr/bin/resolvconf; fi" -IP $DeviceIP -Pass $Password

Write-Host "[+] WireGuard deployed and configured for autostart" -ForegroundColor Green

# Restart service
Write-Host ""
Write-Host "[*] Restarting service..." -ForegroundColor Cyan
Write-Host "[!] Service restart may show warnings - this is normal" -ForegroundColor Yellow
$result = Invoke-SSHCommand -Command "/etc/init.d/S95nanokvm restart" -IP $DeviceIP -Pass $Password

Start-Sleep -Seconds 3

$result = Invoke-SSHCommand -Command "ps | grep NanoKVM-Server | grep -v grep" -IP $DeviceIP -Pass $Password
if ($result.Output -and $result.Output.Trim()) {
    Write-Host "[+] Service restarted successfully" -ForegroundColor Green
    $pid = ($result.Output -split '\s+')[0]
    Write-Host "[+] Service running with PID: $pid" -ForegroundColor Green
} else {
    Write-Host "[!] Could not verify service is running" -ForegroundColor Yellow
}

# Success
Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host " DEPLOYMENT SUCCESSFUL!              " -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access your NanoKVM at: http://${DeviceIP}" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open http://${DeviceIP} in browser" -ForegroundColor White
Write-Host "  2. Hard refresh (Ctrl+F5)" -ForegroundColor White
Write-Host "  3. Login and verify features" -ForegroundColor White
Write-Host ""
'@

Set-Content -Path "$OutputDir\deploy-package.ps1" -Value $deployScript -Encoding UTF8
Write-Host "[+] Deployment script created" -ForegroundColor Green

# Create README
Write-Host ""
Write-Host "[*] Creating README..." -ForegroundColor Cyan
$readme = @"
# NanoKVM Deployment Package

## Contents

- web/: Frontend files
- server/NanoKVM-Server: Backend binary
- wireguard/wireguard-go: WireGuard binary
- deploy-package.ps1: Deployment script

## Quick Deploy

``````powershell
.\deploy-package.ps1 -DeviceIP 10.24.69.63
``````

You will be prompted for SSH password (4 times is normal).

## Package Info

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Frontend files: $frontendFiles
Backend size: $backendSize MB
WireGuard size: $wgSize MB

## After Deployment

1. Access: http://<device-ip>
2. Hard refresh: Ctrl+F5
3. Login and test

## WireGuard Commands

Start: ssh root@<ip> "/usr/bin/wg-quick up wg0"
Stop: ssh root@<ip> "/usr/bin/wg-quick down wg0"
Status: ssh root@<ip> "wg show"
"@

Set-Content -Path "$OutputDir\README.md" -Value $readme -Encoding UTF8
Write-Host "[+] README created" -ForegroundColor Green

# Create version info
$versionInfo = @{
    PackageDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    FrontendFiles = $frontendFiles
    BackendSize = "$backendSize MB"
    WireGuardSize = "$wgSize MB"
    GitCommit = (git rev-parse --short HEAD 2>$null)
    GitBranch = (git branch --show-current 2>$null)
}
$versionInfo | ConvertTo-Json | Set-Content -Path "$OutputDir\version.json" -Encoding UTF8

# Summary
Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host " PACKAGE CREATED SUCCESSFULLY!       " -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Package location: $OutputDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Package contents:" -ForegroundColor Cyan
Write-Host "  - Frontend: $frontendFiles files" -ForegroundColor White
Write-Host "  - Backend: $backendSize MB" -ForegroundColor White
Write-Host "  - WireGuard: $wgSize MB" -ForegroundColor White
Write-Host ""
Write-Host "To deploy:" -ForegroundColor Cyan
Write-Host "  cd $OutputDir" -ForegroundColor White
Write-Host "  .\deploy-package.ps1 -DeviceIP 10.24.69.63" -ForegroundColor White
Write-Host ""
Write-Host "To create ZIP:" -ForegroundColor Cyan
Write-Host "  Compress-Archive -Path '$OutputDir' -DestinationPath 'nanokvm-package.zip'" -ForegroundColor White
Write-Host ""
