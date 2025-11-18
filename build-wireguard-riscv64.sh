#!/bin/bash
# Build WireGuard binaries for RISC-V64 (NanoKVM)
# Run this script on a Linux system or WSL with Go and build tools installed

set -e

echo "=========================================="
echo "WireGuard RISC-V64 Build Script"
echo "=========================================="
echo ""

# Configuration
BUILD_DIR="./wireguard-build"
OUTPUT_DIR="./wireguard-riscv64"
WIREGUARD_GO_VERSION="0.0.20230223"  # Update to latest stable
WIREGUARD_TOOLS_VERSION="v1.0.20210914"  # Update to latest stable

# Architecture settings
export GOOS=linux
export GOARCH=riscv64
export CGO_ENABLED=0

echo "Build configuration:"
echo "  GOOS: $GOOS"
echo "  GOARCH: $GOARCH"
echo "  CGO_ENABLED: $CGO_ENABLED"
echo ""

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

cd "$BUILD_DIR"

###########################################
# 1. Build wireguard-go
###########################################
echo "[1/3] Building wireguard-go..."

if [ ! -d "wireguard-go" ]; then
    echo "  Cloning wireguard-go..."
    git clone https://git.zx2c4.com/wireguard-go
fi

cd wireguard-go
git fetch --tags
# Optionally checkout a specific version: git checkout "$WIREGUARD_GO_VERSION"

echo "  Compiling wireguard-go for RISC-V64..."
make

# Copy binary
cp wireguard-go "../../$OUTPUT_DIR/"
echo "  ✓ wireguard-go built successfully"

cd ..

###########################################
# 2. Build wireguard-tools (wg utility)
###########################################
echo ""
echo "[2/3] Building wireguard-tools (wg)..."

if [ ! -d "wireguard-tools" ]; then
    echo "  Cloning wireguard-tools..."
    git clone https://git.zx2c4.com/wireguard-tools
fi

cd wireguard-tools/src
git fetch --tags
# Optionally checkout a specific version: git checkout "$WIREGUARD_TOOLS_VERSION"

echo "  Compiling wg utility for RISC-V64..."
# Cross-compile requires proper toolchain
# For RISC-V, we need to use a cross-compiler
if command -v riscv64-linux-gnu-gcc &> /dev/null; then
    echo "  Using riscv64-linux-gnu-gcc toolchain..."
    make CC=riscv64-linux-gnu-gcc LDFLAGS="-static"
else
    echo "  WARNING: riscv64-linux-gnu-gcc not found!"
    echo "  Attempting to build with default toolchain (may fail)..."
    make LDFLAGS="-static" || true
fi

# Copy binary
if [ -f "wg" ]; then
    cp wg "../../../$OUTPUT_DIR/"
    echo "  ✓ wg built successfully"
else
    echo "  ⚠ wg binary not found - cross-compilation may have failed"
    echo "  You may need to install riscv64-linux-gnu-gcc:"
    echo "    Ubuntu/Debian: sudo apt install gcc-riscv64-linux-gnu"
    echo "    Or download pre-built wg binary for riscv64"
fi

cd ../..

###########################################
# 3. Copy wg-quick script
###########################################
echo ""
echo "[3/3] Copying wg-quick script..."

if [ -f "wireguard-tools/src/wg-quick/linux.bash" ]; then
    cp wireguard-tools/src/wg-quick/linux.bash "../$OUTPUT_DIR/wg-quick"
    chmod +x "../$OUTPUT_DIR/wg-quick"
    echo "  ✓ wg-quick script copied"
else
    echo "  ⚠ wg-quick script not found"
fi

cd ..

###########################################
# 4. Create package
###########################################
echo ""
echo "[4/4] Creating package..."

cd "$OUTPUT_DIR"

# Verify binaries
echo ""
echo "Built binaries:"
ls -lh

# Check if binaries are RISC-V
if command -v file &> /dev/null; then
    echo ""
    echo "Binary verification:"
    for bin in wireguard-go wg wg-quick; do
        if [ -f "$bin" ]; then
            file "$bin"
        fi
    done
fi

# Create tarball
cd ..
TARBALL="wireguard-riscv64-$(date +%Y%m%d).tar.gz"
tar czf "$TARBALL" -C "$OUTPUT_DIR" .

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo ""
echo "Package created: $TARBALL"
echo "Files included:"
tar tzf "$TARBALL"
echo ""
echo "Next steps:"
echo "  1. Test the binaries on your NanoKVM device"
echo "  2. Upload to GitHub releases or hosting service"
echo "  3. Update download URL in server/service/extensions/wireguard/install.go"
echo ""
echo "Installation on NanoKVM:"
echo "  tar xzf $TARBALL"
echo "  mv wireguard-go wg wg-quick /usr/bin/"
echo "  chmod +x /usr/bin/wireguard-go /usr/bin/wg /usr/bin/wg-quick"
echo ""
