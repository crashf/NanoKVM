# Quick Setup: WireGuard for NanoKVM

## Current Status

✅ **wireguard-go** - BUILT (4.7 MB, RISC-V64)
✅ **wg-quick** - DOWNLOADED (bash script)
⚠️ **wg** - NEEDS TO BE OBTAINED

## Option 1: Download Pre-built wg Binary (EASIEST)

Since building C code for RISC-V on Windows is complex, the easiest option is to use a pre-built binary:

### From Alpine Linux Packages
```powershell
# Download Alpine RISC-V wireguard-tools package
Invoke-WebRequest -Uri "https://dl-cdn.alpinelinux.org/alpine/edge/community/riscv64/wireguard-tools-wg-1.0.20210914-r4.apk" -OutFile "wg-tools.apk"

# Extract (it's a tar.gz archive)
tar -xzf wg-tools.apk
# Binary will be in usr/bin/wg

# Copy to wireguard-riscv64 directory
Copy-Item "usr\bin\wg" "wireguard-riscv64\"
```

### From Debian RISC-V Packages
```powershell
# Download Debian RISC-V wireguard-tools package
wget http://ftp.ports.debian.org/debian-ports/pool-riscv64/main/w/wireguard/wireguard-tools_1.0.20210914-1+b1_riscv64.deb

# Extract using 7-Zip or similar
# Then copy usr/bin/wg to wireguard-riscv64/
```

## Option 2: Build in Docker (if Docker Desktop installed)

```powershell
# Pull RISC-V Alpine image and extract binaries
docker run --rm -v ${PWD}:/output riscv64/alpine:edge sh -c "apk add --no-cache wireguard-tools-wg && cp /usr/bin/wg /output/wireguard-riscv64/"
```

## Option 3: Build on Linux System

If you have access to a Linux system (physical or VM):

```bash
# Install cross-compiler
sudo apt update
sudo apt install gcc-riscv64-linux-gnu make git

# Build
git clone https://git.zx2c4.com/wireguard-tools
cd wireguard-tools/src
make CC=riscv64-linux-gnu-gcc LDFLAGS="-static"

# Copy to Windows machine
scp wg your-windows-machine:/path/to/NanoKVM/wireguard-riscv64/
```

## Option 4: Use Existing NanoKVM Build Tools

If the NanoKVM project already has RISC-V build tools:

```bash
# Check if NanoKVM has a build environment
cd support/sg2002
# Use their toolchain to build wg
```

## After Getting wg Binary

Once you have all three files in `wireguard-riscv64/` directory:

```powershell
# 1. Verify files
Get-ChildItem wireguard-riscv64
# Should show: wireguard-go, wg, wg-quick, README.md

# 2. Create tarball
cd wireguard-riscv64
tar -czf ../wireguard-riscv64.tar.gz *
cd ..

# 3. Verify tarball
tar -tzf wireguard-riscv64.tar.gz
```

## Testing Without Building wg

Actually, you can test most functionality with just wireguard-go! The `wg` utility is mainly for configuration, which can also be done via:
- Direct interface configuration with `ip` commands
- Configuration files parsed by wg-quick
- Our web UI (which uses the Go backend)

So you could:
1. Upload wireguard-go and wg-quick to NanoKVM
2. Test basic functionality
3. Add `wg` utility later for full command-line management

## Upload to NanoKVM for Testing

```powershell
# If you want to test now with just wireguard-go and wg-quick:
cd wireguard-riscv64
scp wireguard-go wg-quick root@YOUR_NANOKVM_IP:/tmp/

# On NanoKVM:
ssh root@YOUR_NANOKVM_IP
mv /tmp/wireguard-go /usr/bin/
mv /tmp/wg-quick /usr/bin/
chmod +x /usr/bin/wireguard-go /usr/bin/wg-quick

# Test
wireguard-go --version
```

## Recommended: Use Alpine Package

The easiest and most reliable way is to use the Alpine Linux package:

```powershell
# 1. Download Alpine wireguard-tools
$url = "https://dl-cdn.alpinelinux.org/alpine/edge/community/riscv64/wireguard-tools-wg-1.0.20210914-r4.apk"
Invoke-WebRequest -Uri $url -OutFile "wg-tools.apk"

# 2. Extract (apk files are tar.gz)
mkdir temp-extract
tar -xzf wg-tools.apk -C temp-extract

# 3. Copy wg binary
Copy-Item "temp-extract\usr\bin\wg" "wireguard-riscv64\"

# 4. Clean up
Remove-Item -Recurse temp-extract
Remove-Item wg-tools.apk

# 5. Verify
file wireguard-riscv64\wg  # Should show RISC-V

# 6. Create final package
cd wireguard-riscv64
tar -czf ..\wireguard-riscv64.tar.gz *
cd ..

Write-Host "✓ Complete! Package ready: wireguard-riscv64.tar.gz"
```

## Next Steps After Package is Complete

1. **Test on NanoKVM:**
   - Upload tarball
   - Extract and install to /usr/bin/
   - Test basic functionality

2. **Host Package:**
   - Create GitHub release
   - Upload wireguard-riscv64.tar.gz
   - Get download URL

3. **Update Code:**
   - Edit `server/service/extensions/wireguard/install.go`
   - Replace placeholder URL with actual download URL

4. **Test Web UI:**
   - Start backend server
   - Open web UI
   - Test installation from settings

Would you like me to help with any of these steps?
