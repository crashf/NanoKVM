# NanoKVM Deployment Package

This package contains everything you need to build and deploy NanoKVM to your device.

## Quick Start

### 1. Basic Deployment (Most Common)

```powershell
.\deploy.ps1
```

This will:
- ✓ Build the frontend
- ✓ Build the backend 
- ✓ Deploy both to the device
- ✓ Restart the service

**You will be prompted for:**
- Device IP address (default: 10.24.69.63)
- SSH password (3 times - for frontend, backend, and restart)

### 2. Deploy to Different IP

```powershell
.\deploy.ps1 -DeviceIP 192.168.1.100
```

### 3. Deploy Only (Skip Building)

If you already have built binaries and just want to deploy:

```powershell
.\deploy.ps1 -DeployOnly
```

### 4. Skip Frontend Build

```powershell
.\deploy.ps1 -SkipFrontend
```

### 5. Skip Backend Build

```powershell
.\deploy.ps1 -SkipBackend
```

## Prerequisites

Before running the deployment script, ensure you have:

### Required Software

1. **Windows 10/11** with PowerShell 5.1 or later
2. **WSL (Windows Subsystem for Linux)** with Ubuntu distribution
3. **Node.js** (v18 or later) and **pnpm**
4. **OpenSSH Client** (usually pre-installed on Windows 10/11)

### Network Requirements

- NanoKVM device must be accessible on the network
- SSH access enabled on the device (port 22)
- Default credentials: `root` / device password

### Installation Check

Run this to verify prerequisites:

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Check WSL
wsl --list --verbose

# Check Node.js and pnpm
node --version
pnpm --version

# Check SSH
ssh -V
scp
```

## What the Script Does

### Phase 1: Prerequisites Check
- ✓ Verifies pnpm is installed
- ✓ Verifies WSL is available
- ✓ Verifies SSH/SCP commands exist
- ✓ Verifies repository structure
- ✓ Tests network connectivity to device

### Phase 2: Build (unless -DeployOnly)
- ✓ **Frontend Build**: Runs `pnpm run build` in `web/` folder
  - Compiles TypeScript
  - Bundles with Vite
  - Creates optimized production build
  - Output: `web/dist/` folder
  
- ✓ **Backend Build**: Runs `build-wsl.sh` in WSL
  - Downloads RISC-V toolchain (first run only)
  - Installs Go 1.23+ if needed
  - Cross-compiles for RISC-V64 architecture
  - Configures shared library paths
  - Output: `server/NanoKVM-Server` binary (19MB)

### Phase 3: Deploy
- ✓ **Frontend Deploy**: Copies all files from `web/dist/` to device `/kvmapp/server/web/`
  - HTML files
  - JavaScript bundles
  - CSS stylesheets
  - Images and icons
  
- ✓ **Backend Deploy**: Copies `NanoKVM-Server` binary to device `/kvmapp/server/`

### Phase 4: Restart
- ✓ Stops existing NanoKVM-Server process
- ✓ Restarts the service via init script
- ✓ Verifies service is running
- ✓ Displays process ID

## Expected Output

### Successful Run

```
╔═══════════════════════════════════════════╗
║     NanoKVM Build & Deploy Script        ║
╚═══════════════════════════════════════════╝

Target Device: 10.24.69.63

→ Testing connection to 10.24.69.63...
✓ Device is reachable

═══ Checking Prerequisites ═══
✓ pnpm found
✓ WSL found
✓ scp found
✓ ssh found
✓ Repository structure verified

═══ Building Frontend ═══
→ Running pnpm build...
✓ Frontend built successfully

═══ Building Backend ═══
→ Running WSL build script...
→ This may take 2-3 minutes...
✓ Backend built successfully (Size: 18.9 MB)

═══ Deploying Frontend ═══
→ Copying frontend files to root@10.24.69.63:/kvmapp/server/web/...
root@10.24.69.63's password: ****
✓ Frontend deployed successfully

═══ Deploying Backend ═══
→ Copying server binary to root@10.24.69.63:/kvmapp/server/...
root@10.24.69.63's password: ****
✓ Backend deployed successfully

═══ Restarting NanoKVM Service ═══
→ Connecting to device...
⚠ Service restart may show some warnings - this is normal
root@10.24.69.63's password: ****
→ Verifying service is running...
✓ Service restarted successfully
→ Service is running with PID: 1234

╔═══════════════════════════════════════════╗
║         DEPLOYMENT SUCCESSFUL! 🎉         ║
╚═══════════════════════════════════════════╝

Access your NanoKVM at: http://10.24.69.63

Next steps:
  1. Open http://10.24.69.63 in your browser
  2. Hard refresh (Ctrl+F5) to clear cache
  3. Login and verify all features work

Tip: Check logs with:
  ssh root@10.24.69.63 'tail -f /var/log/messages'
```

## Time Expectations

- **Prerequisites check**: 5 seconds
- **Frontend build**: 10-15 seconds
- **Backend build**: 
  - First time: 10-15 minutes (downloads toolchain)
  - Subsequent: 2-3 minutes
- **Deployment**: 10-15 seconds
- **Service restart**: 5-10 seconds

**Total time (after first run): ~3-5 minutes**

## Troubleshooting

### "pnpm not found"

**Solution:**
```powershell
# Install Node.js from https://nodejs.org
# Then install pnpm globally
npm install -g pnpm
```

### "WSL not found"

**Solution:**
```powershell
# Install WSL
wsl --install

# Then install Ubuntu
wsl --install -d Ubuntu
```

### "Connection refused" or "No route to host"

**Solutions:**
1. Verify device IP: `ping 10.24.69.63`
2. Check device is powered on
3. Verify you're on the same network
4. Try accessing web UI: `http://10.24.69.63`

### "Permission denied (publickey,password)"

**Solutions:**
1. Verify SSH is enabled on device (Settings → SSH in web UI)
2. Check you're using correct password
3. Try manual SSH: `ssh root@10.24.69.63`

### "Frontend build failed"

**Common causes:**
- TypeScript errors in code
- Missing dependencies

**Solution:**
```powershell
cd web
pnpm install
pnpm run build
```

Check output for specific errors.

### "Backend build failed"

**Common causes:**
- Go version too old
- Toolchain not installed
- Missing WSL dependencies

**Solution:**
```powershell
# Check WSL has required packages
wsl -d Ubuntu -e bash -c "which go gcc"

# Try building manually
wsl -d Ubuntu -e bash build-wsl.sh
```

### "Service not running after restart"

**Check logs:**
```powershell
ssh root@10.24.69.63 "tail -50 /var/log/messages"
```

**Common issues:**
- Binary has wrong architecture (not RISC-V)
- Missing shared libraries
- Configuration file errors

### Script hangs during build

**Solution:**
- Press Ctrl+C to cancel
- Check WSL is responding: `wsl -d Ubuntu -e bash -c "echo test"`
- Try building components separately:
  ```powershell
  # Frontend only
  .\deploy.ps1 -SkipBackend
  
  # Backend only  
  .\deploy.ps1 -SkipFrontend
  ```

## Advanced Usage

### Environment Variables

Set default device IP:
```powershell
$env:NANOKVM_IP = "192.168.1.100"
.\deploy.ps1 -DeviceIP $env:NANOKVM_IP
```

### Using SSH Keys (No Password Prompts)

1. Generate SSH key:
   ```powershell
   ssh-keygen -t ed25519
   ```

2. Copy to device:
   ```powershell
   type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh root@10.24.69.63 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
   ```

3. Now deployment won't ask for password!

### Automated Deployment (CI/CD)

```powershell
# Non-interactive mode (requires SSH keys)
.\deploy.ps1 -DeviceIP 10.24.69.63 -DeployOnly
```

### Multiple Devices

Create a devices config:
```powershell
# devices.txt
10.24.69.63
10.24.69.64
10.24.69.65
```

Deploy to all:
```powershell
Get-Content devices.txt | ForEach-Object {
    Write-Host "Deploying to $_"
    .\deploy.ps1 -DeviceIP $_ -DeployOnly
}
```

## File Structure

```
NanoKVM/
├── deploy.ps1                  # This deployment script
├── DEPLOY_README.md           # This file
├── BUILD_AND_DEPLOY.md        # Detailed manual instructions
├── build-wsl.sh               # WSL build script
├── web/                       # Frontend source
│   ├── src/                   # React/TypeScript code
│   ├── dist/                  # Built files (created by script)
│   └── package.json
├── server/                    # Backend source
│   ├── main.go               # Go server code
│   ├── NanoKVM-Server        # Built binary (created by script)
│   └── go.mod
└── wireguard-riscv64/        # WireGuard binaries
    ├── wireguard-go
    └── wg-quick
```

## Script Options Reference

| Option | Description | Example |
|--------|-------------|---------|
| `-DeviceIP` | Target device IP address | `-DeviceIP 192.168.1.100` |
| `-SkipFrontend` | Don't build frontend | `-SkipFrontend` |
| `-SkipBackend` | Don't build backend | `-SkipBackend` |
| `-DeployOnly` | Skip all builds, just deploy | `-DeployOnly` |

## Best Practices

### Before Deploying
1. ✓ Commit changes to git
2. ✓ Test locally if possible
3. ✓ Backup device configuration
4. ✓ Verify device is accessible

### After Deploying
1. ✓ Hard refresh browser (Ctrl+F5)
2. ✓ Test all menu items
3. ✓ Check server logs for errors
4. ✓ Verify video stream works
5. ✓ Test keyboard/mouse control

### Regular Workflow
```powershell
# 1. Make changes to code
# 2. Test locally
# 3. Commit to git
git add .
git commit -m "Description of changes"

# 4. Deploy
.\deploy.ps1

# 5. Test on device
# 6. Push to GitHub
git push
```

## Getting Help

### Check Logs on Device
```powershell
ssh root@10.24.69.63 "tail -f /var/log/messages"
```

### Check Service Status
```powershell
ssh root@10.24.69.63 "ps | grep NanoKVM-Server"
```

### Manual Service Control
```powershell
# Stop
ssh root@10.24.69.63 "/etc/init.d/S95nanokvm stop"

# Start
ssh root@10.24.69.63 "/etc/init.d/S95nanokvm start"

# Restart
ssh root@10.24.69.63 "/etc/init.d/S95nanokvm restart"
```

### Rollback to Previous Version

If deployment causes issues:

1. **Restore from backup:**
   ```powershell
   scp -r C:\Backups\nanokvm\* root@10.24.69.63:/kvmapp/server/
   ssh root@10.24.69.63 "/etc/init.d/S95nanokvm restart"
   ```

2. **Or use git to restore files and rebuild:**
   ```powershell
   git restore .
   .\deploy.ps1
   ```

## Security Notes

⚠️ **Important:**
- Never commit passwords to git
- Use SSH keys instead of passwords when possible
- Keep `server.yaml` secure (contains JWT secrets)
- Don't expose NanoKVM directly to internet without VPN
- Use strong passwords for web interface
- Keep WireGuard configs private (`.conf` files)

## Support

- **Documentation:** See `BUILD_AND_DEPLOY.md` for detailed manual steps
- **WireGuard Setup:** See `BUILDING_WIREGUARD.md`
- **Official Wiki:** https://wiki.sipeed.com/nanokvm
- **GitHub Issues:** https://github.com/sipeed/NanoKVM/issues

## Quick Reference

### Most Common Commands

```powershell
# Standard deployment
.\deploy.ps1

# Different device
.\deploy.ps1 -DeviceIP 192.168.1.100

# Just deploy (already built)
.\deploy.ps1 -DeployOnly

# Check device
ssh root@10.24.69.63 "wg show"
ssh root@10.24.69.63 "ps | grep NanoKVM"

# View logs
ssh root@10.24.69.63 "tail -f /var/log/messages"
```

---

**Happy Deploying! 🚀**
