#!/usr/bin/env pwsh
<#
.SYNOPSIS
    NanoKVM Build and Deployment Script

.DESCRIPTION
    This script builds the NanoKVM frontend and backend, then deploys them to your device.
    It will prompt for the device IP address and SSH password.

.PARAMETER DeviceIP
    IP address of the NanoKVM device (default: 10.24.69.63)

.PARAMETER SkipFrontend
    Skip building the frontend

.PARAMETER SkipBackend
    Skip building the backend

.PARAMETER DeployOnly
    Skip building, only deploy existing binaries

.EXAMPLE
    .\deploy.ps1
    
.EXAMPLE
    .\deploy.ps1 -DeviceIP 192.168.1.100
    
.EXAMPLE
    .\deploy.ps1 -DeployOnly
#>

param(
    [string]$DeviceIP = "10.24.69.63",
    [switch]$SkipFrontend,
    [switch]$SkipBackend,
    [switch]$DeployOnly
)

# Colors
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoPath = $ScriptDir

# Banner
function Show-Banner {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════╗" -ForegroundColor $InfoColor
    Write-Host "║     NanoKVM Build & Deploy Script        ║" -ForegroundColor $InfoColor
    Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor $InfoColor
    Write-Host ""
}

# Error handler
function Exit-WithError {
    param([string]$Message)
    Write-Host "✗ ERROR: $Message" -ForegroundColor $ErrorColor
    Write-Host ""
    exit 1
}

# Success message
function Show-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $SuccessColor
}

# Info message
function Show-Info {
    param([string]$Message)
    Write-Host "→ $Message" -ForegroundColor $InfoColor
}

# Warning message
function Show-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor $WarningColor
}

# Step header
function Show-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "═══ $Message ═══" -ForegroundColor $InfoColor
}

# Check prerequisites
function Test-Prerequisites {
    Show-Step "Checking Prerequisites"
    
    # Check pnpm
    if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
        Exit-WithError "pnpm not found. Please install Node.js and pnpm first."
    }
    Show-Success "pnpm found"
    
    # Check WSL
    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        Exit-WithError "WSL not found. Please install Windows Subsystem for Linux."
    }
    Show-Success "WSL found"
    
    # Check SCP (part of SSH)
    if (-not (Get-Command scp -ErrorAction SilentlyContinue)) {
        Exit-WithError "scp not found. Please install OpenSSH client."
    }
    Show-Success "scp found"
    
    # Check SSH
    if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
        Exit-WithError "ssh not found. Please install OpenSSH client."
    }
    Show-Success "ssh found"
    
    # Check directories
    if (-not (Test-Path "$RepoPath\web")) {
        Exit-WithError "Frontend directory not found at $RepoPath\web"
    }
    if (-not (Test-Path "$RepoPath\server")) {
        Exit-WithError "Backend directory not found at $RepoPath\server"
    }
    if (-not (Test-Path "$RepoPath\build-wsl.sh")) {
        Exit-WithError "Build script not found at $RepoPath\build-wsl.sh"
    }
    Show-Success "Repository structure verified"
}

# Build frontend
function Build-Frontend {
    Show-Step "Building Frontend"
    
    Push-Location "$RepoPath\web"
    try {
        Show-Info "Running pnpm build..."
        pnpm run build
        if ($LASTEXITCODE -ne 0) {
            Exit-WithError "Frontend build failed with exit code $LASTEXITCODE"
        }
        
        if (-not (Test-Path "dist")) {
            Exit-WithError "Build completed but dist folder not found"
        }
        
        Show-Success "Frontend built successfully"
    }
    finally {
        Pop-Location
    }
}

# Build backend
function Build-Backend {
    Show-Step "Building Backend"
    
    Push-Location $RepoPath
    try {
        Show-Info "Running WSL build script..."
        Show-Info "This may take 2-3 minutes (or 10-15 minutes on first run)..."
        
        wsl -d Ubuntu -e bash build-wsl.sh
        if ($LASTEXITCODE -ne 0) {
            Exit-WithError "Backend build failed with exit code $LASTEXITCODE"
        }
        
        if (-not (Test-Path "$RepoPath\server\NanoKVM-Server")) {
            Exit-WithError "Build completed but NanoKVM-Server binary not found"
        }
        
        $size = (Get-Item "$RepoPath\server\NanoKVM-Server").Length / 1MB
        Show-Success "Backend built successfully (Size: $([math]::Round($size, 1)) MB)"
    }
    finally {
        Pop-Location
    }
}

# Deploy frontend
function Deploy-Frontend {
    param([string]$IP)
    
    Show-Step "Deploying Frontend"
    
    if (-not (Test-Path "$RepoPath\web\dist")) {
        Exit-WithError "Frontend dist folder not found. Run build first or use without -DeployOnly"
    }
    
    Show-Info "Copying frontend files to root@${IP}:/kvmapp/server/web/..."
    scp -r "$RepoPath\web\dist\*" "root@${IP}:/kvmapp/server/web/"
    
    if ($LASTEXITCODE -ne 0) {
        Exit-WithError "Frontend deployment failed. Check SSH credentials and network connection."
    }
    
    Show-Success "Frontend deployed successfully"
}

# Deploy backend
function Deploy-Backend {
    param([string]$IP)
    
    Show-Step "Deploying Backend"
    
    if (-not (Test-Path "$RepoPath\server\NanoKVM-Server")) {
        Exit-WithError "Backend binary not found. Run build first or use without -DeployOnly"
    }
    
    Show-Info "Copying server binary to root@${IP}:/kvmapp/server/..."
    scp "$RepoPath\server\NanoKVM-Server" "root@${IP}:/kvmapp/server/"
    
    if ($LASTEXITCODE -ne 0) {
        Exit-WithError "Backend deployment failed. Check SSH credentials and network connection."
    }
    
    Show-Success "Backend deployed successfully"
}

# Restart service
function Restart-Service {
    param([string]$IP)
    
    Show-Step "Restarting NanoKVM Service"
    
    Show-Info "Connecting to device..."
    Show-Warning "Service restart may show some warnings - this is normal"
    
    # Use Start-Process to run in background and capture output
    $output = ssh "root@${IP}" "/etc/init.d/S95nanokvm restart" 2>&1
    
    # Check if service restarted (exit code may be non-zero due to warnings)
    Start-Sleep -Seconds 3
    
    Show-Info "Verifying service is running..."
    $psOutput = ssh "root@${IP}" "ps | grep NanoKVM-Server | grep -v grep" 2>&1
    
    if ($psOutput) {
        Show-Success "Service restarted successfully"
        Write-Host ""
        Show-Info "Service is running with PID: $($psOutput -split '\s+' | Select-Object -First 1)"
    } else {
        Show-Warning "Service may not be running. Check device logs."
    }
}

# Main execution
function Main {
    Show-Banner
    
    # Prompt for device IP if not provided
    if (-not $DeviceIP) {
        $DeviceIP = Read-Host "Enter NanoKVM device IP address (default: 10.24.69.63)"
        if ([string]::IsNullOrWhiteSpace($DeviceIP)) {
            $DeviceIP = "10.24.69.63"
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
    
    # Check prerequisites
    Test-Prerequisites
    
    # Build phase
    if (-not $DeployOnly) {
        if (-not $SkipFrontend) {
            Build-Frontend
        } else {
            Show-Warning "Skipping frontend build"
        }
        
        if (-not $SkipBackend) {
            Build-Backend
        } else {
            Show-Warning "Skipping backend build"
        }
    } else {
        Show-Warning "Skipping build phase (deploy only mode)"
    }
    
    # Deploy phase
    Write-Host ""
    Show-Info "Ready to deploy to $DeviceIP"
    Write-Host "You will be prompted for the SSH password (typically 3 times)." -ForegroundColor $WarningColor
    Write-Host ""
    
    $confirm = Read-Host "Continue with deployment? (Y/n)"
    if ($confirm -eq "n" -or $confirm -eq "N") {
        Write-Host "Deployment cancelled." -ForegroundColor $WarningColor
        exit 0
    }
    
    Deploy-Frontend -IP $DeviceIP
    Deploy-Backend -IP $DeviceIP
    Restart-Service -IP $DeviceIP
    
    # Success summary
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
    Write-Host "Tip: Check logs with:" -ForegroundColor $InfoColor
    Write-Host "  ssh root@${DeviceIP} 'tail -f /var/log/messages'" -ForegroundColor White
    Write-Host ""
}

# Run main
Main
