# Building WireGuard Binaries for NanoKVM (RISC-V64)

This guide explains how to build WireGuard binaries for the NanoKVM device, which uses a RISC-V64 architecture (SG2002 chip).

## Required Components

You need to build three components:
1. **wireguard-go** - WireGuard userspace implementation (Go)
2. **wg** - WireGuard configuration utility (C)
3. **wg-quick** - Helper script for interface management (Bash script)

## Prerequisites

### On Windows (Recommended: Use WSL)
```powershell
# Install WSL if not already installed
wsl --install

# Inside WSL, install required packages
sudo apt update
sudo apt install -y golang git gcc-riscv64-linux-gnu make
```

### On Linux
```bash
sudo apt update
sudo apt install -y golang git gcc-riscv64-linux-gnu make
```

### On macOS
```bash
brew install go git
# Note: Building wg for RISC-V on macOS is more complex
# Consider using a Linux VM or Docker
```

## Building Methods

### Method 1: Quick Build (Windows PowerShell)

This builds wireguard-go only (the most important component):

```powershell
cd C:\Users\Wayne\Documents\GitHub\NanoKVM
.\build-wireguard-riscv64.ps1
```

**Note:** This PowerShell script only builds wireguard-go. You'll need to build `wg` separately using WSL or download a pre-compiled binary.

### Method 2: Complete Build (Linux/WSL) - RECOMMENDED

This builds all three components:

```bash
cd /mnt/c/Users/Wayne/Documents/GitHub/NanoKVM  # If using WSL
# or
cd ~/NanoKVM  # If on Linux

chmod +x build-wireguard-riscv64.sh
./build-wireguard-riscv64.sh
```

This will create `wireguard-riscv64-YYYYMMDD.tar.gz` with all binaries.

### Method 3: Manual Build Steps

If you prefer to build manually:

#### Step 1: Build wireguard-go
```bash
# Set environment for cross-compilation
export GOOS=linux
export GOARCH=riscv64
export CGO_ENABLED=0

# Clone and build
git clone https://git.zx2c4.com/wireguard-go
cd wireguard-go
go build -v -o wireguard-go

# Verify
file wireguard-go
# Should show: ELF 64-bit LSB executable, UCB RISC-V, ...
```

#### Step 2: Build wg utility
```bash
# Clone wireguard-tools
git clone https://git.zx2c4.com/wireguard-tools
cd wireguard-tools/src

# Build with RISC-V cross-compiler
make CC=riscv64-linux-gnu-gcc LDFLAGS="-static"

# Verify
file wg
# Should show: ELF 64-bit LSB executable, UCB RISC-V, ...
```

#### Step 3: Get wg-quick script
```bash
# Copy the script
cp wireguard-tools/src/wg-quick/linux.bash wg-quick
chmod +x wg-quick
```

#### Step 4: Package
```bash
# Create directory
mkdir wireguard-riscv64
cp wireguard-go wg wg-quick wireguard-riscv64/

# Create tarball
tar czf wireguard-riscv64.tar.gz -C wireguard-riscv64 .

# Verify contents
tar tzf wireguard-riscv64.tar.gz
```

## Alternative: Download Pre-built Binaries

If building is too complex, you can download pre-built binaries:

### Option A: Use Alpine Linux Packages
Alpine Linux provides RISC-V packages. Extract `wireguard-tools` package:
```bash
# Download Alpine RISC-V package
wget https://dl-cdn.alpinelinux.org/alpine/edge/main/riscv64/wireguard-tools-1.0.20210914-r3.apk

# Extract
tar xzf wireguard-tools-*.apk
# Binary will be in usr/bin/wg
```

### Option B: Build in Docker
```bash
docker run --rm -it -v $(pwd):/work riscv64/alpine:edge sh
# Inside container:
apk add --no-cache wireguard-tools-wg wireguard-go
cp /usr/bin/wg /usr/bin/wireguard-go /work/
```

## Verification

Before uploading, verify the binaries:

```bash
# Check architecture
file wireguard-go wg
# Should show "RISC-V" for both

# Check if they're executable
ls -lh wireguard-go wg wg-quick

# Optional: Test on QEMU RISC-V emulator
qemu-riscv64 -L /usr/riscv64-linux-gnu ./wireguard-go --version
```

## Testing on NanoKVM

1. **Upload to NanoKVM:**
```bash
scp wireguard-riscv64.tar.gz root@nanokvm-ip:/tmp/
```

2. **Install on NanoKVM:**
```bash
ssh root@nanokvm-ip
cd /tmp
tar xzf wireguard-riscv64.tar.gz
mv wireguard-go wg wg-quick /usr/bin/
chmod +x /usr/bin/wireguard-go /usr/bin/wg /usr/bin/wg-quick
```

3. **Verify installation:**
```bash
wireguard-go --version
wg --version
which wg-quick
```

4. **Test basic functionality:**
```bash
# Generate keys
wg genkey | tee privatekey | wg pubkey > publickey

# Create test config
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $(cat privatekey)
Address = 10.0.0.2/24
ListenPort = 51820
EOF

# Try to start (will fail without peer, but tests binary)
wireguard-go wg0
wg show
```

## Hosting Binaries

Once built and tested, host the tarball:

### Option 1: GitHub Releases
1. Create a release in your NanoKVM fork
2. Upload `wireguard-riscv64.tar.gz`
3. Get download URL
4. Update URL in `server/service/extensions/wireguard/install.go`

### Option 2: Your Own Server
```bash
# Upload to your server
scp wireguard-riscv64.tar.gz user@yourserver.com:/var/www/downloads/

# Update URL in install.go to:
# https://yourserver.com/downloads/wireguard-riscv64.tar.gz
```

### Option 3: GitHub Raw
```bash
# Add to your repo
git add wireguard-riscv64.tar.gz
git commit -m "Add WireGuard RISC-V64 binaries"
git push

# Use raw.githubusercontent.com URL in install.go
```

## Update Installation Code

After hosting, update `server/service/extensions/wireguard/install.go`:

```go
func (s *Service) getDownloadURL() string {
    // Replace this with your actual hosted URL
    return "https://github.com/YOUR_USERNAME/NanoKVM/releases/download/v1.0/wireguard-riscv64.tar.gz"
}
```

## Troubleshooting

### Build fails with "gcc: command not found"
```bash
sudo apt install gcc-riscv64-linux-gnu
```

### Binary shows wrong architecture
```bash
# Ensure environment variables are set
echo $GOOS $GOARCH $CGO_ENABLED
# Should be: linux riscv64 0
```

### wg binary too large
```bash
# Build with static linking and strip
make CC=riscv64-linux-gnu-gcc LDFLAGS="-static -s"
```

### Cannot test on NanoKVM
- Check SSH connectivity
- Ensure enough space: `df -h`
- Check memory: `free -h`
- Verify architecture: `uname -m` (should show riscv64)

## Expected Binary Sizes

Approximate sizes after building:
- wireguard-go: ~8-10 MB
- wg: ~100-200 KB (static build)
- wg-quick: ~15 KB (bash script)
- Total tarball: ~8-10 MB compressed

## Security Notes

- Always verify checksums of downloaded binaries
- Build from official WireGuard repositories
- Keep binaries up to date with latest security patches
- Test thoroughly before deploying to production

## Next Steps

After building and hosting binaries:
1. ✅ Build binaries for RISC-V64
2. ✅ Test on NanoKVM device
3. ✅ Host on GitHub releases or server
4. ✅ Update download URL in install.go
5. ✅ Test installation through web UI
6. ✅ Document usage for users

## References

- [WireGuard Official Site](https://www.wireguard.com/)
- [wireguard-go Repository](https://git.zx2c4.com/wireguard-go/)
- [wireguard-tools Repository](https://git.zx2c4.com/wireguard-tools/)
- [RISC-V Cross Compilation Guide](https://github.com/riscv-collab/riscv-gnu-toolchain)
