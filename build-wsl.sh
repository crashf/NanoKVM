#!/bin/bash
# NanoKVM Backend Build Script for WSL
# This script sets up the RISC-V toolchain and builds the NanoKVM server

set -e  # Exit on error

echo "============================================"
echo "NanoKVM Backend Builder for WSL"
echo "============================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TOOLCHAIN_URL="https://sophon-file.sophon.cn/sophon-prod-s3/drive/23/03/07/16/host-tools.tar.gz"
TOOLCHAIN_DIR="$HOME/riscv-toolchain"
TOOLCHAIN_BIN="$TOOLCHAIN_DIR/host-tools/gcc/riscv64-linux-musl-x86_64/bin"

# Step 1: Check if we're in WSL
echo -e "${YELLOW}[1/7] Checking environment...${NC}"
if ! grep -qi microsoft /proc/version; then
    echo -e "${RED}ERROR: This script must be run in WSL (Windows Subsystem for Linux)${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Running in WSL${NC}"
echo ""

# Step 2: Install dependencies
echo -e "${YELLOW}[2/7] Installing dependencies...${NC}"
sudo apt-get update -qq
sudo apt-get install -y wget tar patchelf golang-go build-essential > /dev/null 2>&1 || true
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Step 3: Check/Install Go
echo -e "${YELLOW}[3/7] Checking Go version...${NC}"
if command -v go &> /dev/null; then
    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    echo "Go version: $GO_VERSION"
    
    # Check if version is >= 1.23
    MIN_VERSION="1.23"
    if [ "$(printf '%s\n' "$MIN_VERSION" "$GO_VERSION" | sort -V | head -n1)" = "$MIN_VERSION" ]; then
        echo -e "${GREEN}✓ Go version is sufficient${NC}"
    else
        echo -e "${YELLOW}⚠ Go version is too old, need 1.23+${NC}"
        echo "Installing Go 1.23..."
        wget -q https://go.dev/dl/go1.23.4.linux-amd64.tar.gz
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf go1.23.4.linux-amd64.tar.gz
        rm go1.23.4.linux-amd64.tar.gz
        export PATH=$PATH:/usr/local/go/bin
        echo -e "${GREEN}✓ Go 1.23 installed${NC}"
    fi
else
    echo "Go not found, installing..."
    wget -q https://go.dev/dl/go1.23.4.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.23.4.linux-amd64.tar.gz
    rm go1.23.4.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo -e "${GREEN}✓ Go installed${NC}"
fi
echo ""

# Step 4: Download and setup RISC-V toolchain
echo -e "${YELLOW}[4/7] Setting up RISC-V toolchain...${NC}"
if [ ! -d "$TOOLCHAIN_BIN" ]; then
    echo "Downloading RISC-V toolchain (this may take a while)..."
    mkdir -p "$TOOLCHAIN_DIR"
    cd "$TOOLCHAIN_DIR"
    
    if [ ! -f "host-tools.tar.gz" ]; then
        wget -q --show-progress "$TOOLCHAIN_URL" -O host-tools.tar.gz
    fi
    
    echo "Extracting toolchain..."
    tar -xzf host-tools.tar.gz
    echo -e "${GREEN}✓ Toolchain installed${NC}"
else
    echo -e "${GREEN}✓ Toolchain already installed${NC}"
fi

# Add toolchain to PATH
export PATH="$TOOLCHAIN_BIN:$PATH"

# Verify toolchain
if command -v riscv64-unknown-linux-musl-gcc &> /dev/null; then
    echo "Toolchain version: $(riscv64-unknown-linux-musl-gcc --version | head -n1)"
    echo -e "${GREEN}✓ RISC-V toolchain ready${NC}"
else
    echo -e "${RED}ERROR: RISC-V toolchain not found in PATH${NC}"
    exit 1
fi
echo ""

# Step 5: Navigate to server directory
echo -e "${YELLOW}[5/7] Preparing build...${NC}"
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd "$SCRIPT_DIR/server"

# Install Go dependencies
echo "Installing Go dependencies..."
go mod tidy
echo -e "${GREEN}✓ Dependencies ready${NC}"
echo ""

# Step 6: Build the server
echo -e "${YELLOW}[6/7] Building NanoKVM server for RISC-V...${NC}"
echo "This may take a few minutes..."
echo ""

CGO_ENABLED=1 \
GOOS=linux \
GOARCH=riscv64 \
CC=riscv64-unknown-linux-musl-gcc \
CGO_CFLAGS="-mcpu=c906fdv -march=rv64imafdcv0p7xthead -mcmodel=medany -mabi=lp64d" \
go build -v -o NanoKVM-Server

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build successful!${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
echo ""

# Step 7: Fix RPATH
echo -e "${YELLOW}[7/7] Fixing RPATH...${NC}"
if command -v patchelf &> /dev/null; then
    patchelf --add-rpath \$ORIGIN/dl_lib NanoKVM-Server
    echo -e "${GREEN}✓ RPATH configured${NC}"
else
    echo -e "${YELLOW}⚠ patchelf not found, skipping RPATH fix${NC}"
    echo "Install with: sudo apt install patchelf"
fi
echo ""

# Show results
echo "============================================"
echo -e "${GREEN}BUILD COMPLETE!${NC}"
echo "============================================"
echo ""
echo "Output file: $(pwd)/NanoKVM-Server"
echo "Size: $(du -h NanoKVM-Server | cut -f1)"
echo "Type: $(file NanoKVM-Server)"
echo ""
echo "To deploy to NanoKVM:"
echo "1. Enable SSH on your NanoKVM (Settings → SSH)"
echo "2. Run: scp NanoKVM-Server root@10.24.69.63:/kvmapp/server/"
echo "3. SSH to NanoKVM: ssh root@10.24.69.63"
echo "4. Restart service: /etc/init.d/S95nanokvm restart"
echo ""
echo "The binary is also available in Windows at:"
echo "$(wslpath -w $(pwd))/NanoKVM-Server"
echo ""
