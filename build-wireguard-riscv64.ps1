# Build WireGuard-go for RISC-V64 (NanoKVM)
# Run this script on Windows with Go installed

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "WireGuard-go RISC-V64 Build Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$BuildDir = ".\wireguard-build"
$OutputDir = ".\wireguard-riscv64"

# Architecture settings
$env:GOOS = "linux"
$env:GOARCH = "riscv64"
$env:CGO_ENABLED = "0"

Write-Host "Build configuration:" -ForegroundColor Yellow
Write-Host "  GOOS: $env:GOOS"
Write-Host "  GOARCH: $env:GOARCH"
Write-Host "  CGO_ENABLED: $env:CGO_ENABLED"
Write-Host ""

# Create directories
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Push-Location $BuildDir

###########################################
# 1. Build wireguard-go
###########################################
Write-Host "[1/3] Building wireguard-go..." -ForegroundColor Green

if (-not (Test-Path "wireguard-go")) {
    Write-Host "  Cloning wireguard-go..."
    git clone https://git.zx2c4.com/wireguard-go
}

Push-Location wireguard-go

Write-Host "  Fetching latest version..."
git fetch --tags 2>&1 | Out-Null

Write-Host "  Compiling wireguard-go for RISC-V64..."
go build -v -o wireguard-go

if ($LASTEXITCODE -eq 0) {
    Copy-Item "wireguard-go" "..\..\$OutputDir\"
    Write-Host "  ✓ wireguard-go built successfully" -ForegroundColor Green
} else {
    Write-Host "  ✗ Failed to build wireguard-go" -ForegroundColor Red
    Pop-Location
    Pop-Location
    exit 1
}

Pop-Location

###########################################
# 2. Download wg utility (pre-built)
###########################################
Write-Host ""
Write-Host "[2/3] Getting wg utility..." -ForegroundColor Green
Write-Host "  Note: Cross-compiling C code on Windows is complex."
Write-Host "  Options:" -ForegroundColor Yellow
Write-Host "    A) Use WSL to build with build-wireguard-riscv64.sh"
Write-Host "    B) Download pre-compiled wg binary for RISC-V64"
Write-Host "    C) Build on a Linux system with RISC-V toolchain"
Write-Host ""

# Check for pre-built wg binary
$wgUrl = "https://github.com/WireGuard/wireguard-tools/releases"
Write-Host "  You can find pre-built binaries at: $wgUrl" -ForegroundColor Cyan
Write-Host ""

###########################################
# 3. Download wg-quick script
###########################################
Write-Host "[3/3] Downloading wg-quick script..." -ForegroundColor Green

if (-not (Test-Path "wireguard-tools")) {
    Write-Host "  Cloning wireguard-tools (for wg-quick script)..."
    git clone https://git.zx2c4.com/wireguard-tools
}

if (Test-Path "wireguard-tools\src\wg-quick\linux.bash") {
    Copy-Item "wireguard-tools\src\wg-quick\linux.bash" "..\$OutputDir\wg-quick"
    Write-Host "  ✓ wg-quick script copied" -ForegroundColor Green
} else {
    Write-Host "  ⚠ wg-quick script not found" -ForegroundColor Yellow
}

Pop-Location

###########################################
# 4. Summary
###########################################
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Build Status" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$outputPath = $OutputDir
Write-Host "Built files in ${outputPath}:" -ForegroundColor Yellow
Get-ChildItem $OutputDir | Format-Table Name, Length, LastWriteTime

Write-Host ""
Write-Host "✓ wireguard-go: BUILT" -ForegroundColor Green
Write-Host "⚠ wg: NEEDS MANUAL BUILD (see note above)" -ForegroundColor Yellow
Write-Host "✓ wg-quick: DOWNLOADED" -ForegroundColor Green

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Build 'wg' utility using one of these methods:"
Write-Host "     - Use WSL: wsl ./build-wireguard-riscv64.sh"
Write-Host "     - Build on Linux with: sudo apt install gcc-riscv64-linux-gnu"
Write-Host "     - Download pre-compiled binary from WireGuard releases"
Write-Host ""
Write-Host "  2. Once you have all 3 files (wireguard-go, wg, wg-quick):"
Write-Host "     - Create tarball: tar czf wireguard-riscv64.tar.gz *"
Write-Host "     - Upload to GitHub releases or hosting"
Write-Host "     - Update URL in server/service/extensions/wireguard/install.go"
Write-Host ""
Write-Host "  3. Test on NanoKVM device:"
Write-Host "     tar xzf wireguard-riscv64.tar.gz"
Write-Host "     mv wireguard-go wg wg-quick /usr/bin/"
Write-Host "     chmod +x /usr/bin/wireguard-go /usr/bin/wg /usr/bin/wg-quick"
Write-Host ""

# Create a README
$readmeContent = @"
# WireGuard RISC-V64 Binaries for NanoKVM

## Contents
- wireguard-go: WireGuard userspace implementation
- wg: WireGuard configuration utility
- wg-quick: Helper script for interface management

## Installation on NanoKVM

1. Upload this archive to your NanoKVM device
2. Extract: ``tar xzf wireguard-riscv64.tar.gz``
3. Install: ``mv wireguard-go wg wg-quick /usr/bin/``
4. Set permissions: ``chmod +x /usr/bin/wireguard-go /usr/bin/wg /usr/bin/wg-quick``
5. Verify: ``wireguard-go --version`` and ``wg --version``

## Usage

Start WireGuard interface:
``````bash
wireguard-go wg0
wg setconf wg0 /etc/wireguard/wg0.conf
ip link set wg0 up
``````

Or use wg-quick:
``````bash
wg-quick up wg0
``````

## Building from Source

See build-wireguard-riscv64.sh or build-wireguard-riscv64.ps1

## Architecture
- Built for: linux/riscv64
- Target device: NanoKVM (LicheeRV Nano, SG2002)
"@

Set-Content -Path "$OutputDir\README.md" -Value $readmeContent

Write-Host "Created README.md in $OutputDir" -ForegroundColor Green
Write-Host ""
