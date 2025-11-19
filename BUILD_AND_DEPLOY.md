# NanoKVM Build and Deployment Guide

This guide covers the complete process of building and deploying the NanoKVM application to your device.

## Prerequisites

- Windows with WSL (Ubuntu) installed
- RISC-V toolchain installed in WSL (handled by build script)
- Node.js and pnpm installed on Windows
- SSH access to your NanoKVM device
- Go 1.23+ in WSL (handled by build script)

## Quick Build and Deploy

### Step 1: Build Frontend

```powershell
cd C:\Users\Wayne\Documents\GitHub\NanoKVM\web
pnpm run build
```

**Expected Output:**
- Build completes successfully in ~10-15 seconds
- Creates `dist/` folder with compiled assets
- No TypeScript errors

### Step 2: Build Backend Server

```powershell
cd C:\Users\Wayne\Documents\GitHub\NanoKVM
wsl -d Ubuntu -e bash build-wsl.sh
```

**What the script does:**
1. Checks WSL environment
2. Installs dependencies (wget, tar, patchelf, golang)
3. Checks/installs Go 1.23+ if needed
4. Downloads RISC-V toolchain (if not present, ~840MB)
5. Builds the server with CGO for RISC-V64
6. Configures RPATH for shared libraries

**Expected Output:**
```
============================================
BUILD COMPLETE!
============================================

Output file: /mnt/c/Users/Wayne/Documents/GitHub/NanoKVM/server/NanoKVM-Server
Size: 19M
Type: NanoKVM-Server: ELF 64-bit LSB executable, UCB RISC-V...
```

**Note:** You may see a warning about `libopencv_video.so.409` - this is normal and doesn't affect functionality.

### Step 3: Deploy Frontend to Device

```powershell
scp -r C:\Users\Wayne\Documents\GitHub\NanoKVM\web\dist\* root@10.24.69.63:/kvmapp/server/web/
```

**What gets deployed:**
- `index.html` - Main HTML file
- `assets/*.js` - JavaScript bundles
- `assets/*.css` - Stylesheets
- `mockServiceWorker.js` - Service worker
- `sipeed.ico` - Favicon

### Step 4: Deploy Backend Server

```powershell
scp C:\Users\Wayne\Documents\GitHub\NanoKVM\server\NanoKVM-Server root@10.24.69.63:/kvmapp/server/
```

### Step 5: Restart NanoKVM Service

```powershell
ssh root@10.24.69.63 "/etc/init.d/S95nanokvm restart"
```

**Expected Output:**
- Service stops existing processes
- Loads kernel modules (may show some "File exists" warnings - normal)
- Initializes video capture system
- Starts NanoKVM-Server on ports 80/443

**Note:** You may see errors like "failed to read kvm image: -1" - these are normal when no video source is connected.

### Step 6: Verify Deployment

1. **Check web interface:**
   - Open browser to `http://10.24.69.63`
   - Hard refresh (Ctrl+F5) to clear cache
   - Login and test functionality

2. **Check server is running:**
   ```powershell
   ssh root@10.24.69.63 "ps | grep NanoKVM-Server"
   ```

## WireGuard Installation (If Needed)

If WireGuard doesn't start after deployment, you may need to reinstall the binaries:

### Step 1: Upload WireGuard Binaries

```powershell
scp C:\Users\Wayne\Documents\GitHub\NanoKVM\wireguard-riscv64\wireguard-go root@10.24.69.63:/usr/bin/
```

### Step 2: Make Executable

```powershell
ssh root@10.24.69.63 "chmod +x /usr/bin/wireguard-go"
```

### Step 3: Create Dummy resolvconf (If Missing)

```powershell
ssh root@10.24.69.63 "echo '#!/bin/sh' > /usr/bin/resolvconf && echo 'exit 0' >> /usr/bin/resolvconf && chmod +x /usr/bin/resolvconf"
```

### Step 4: Upload Init Script

```powershell
scp C:\Users\Wayne\Documents\GitHub\NanoKVM\kvmapp\system\init.d\S40wireguard root@10.24.69.63:/etc/init.d/
ssh root@10.24.69.63 "chmod +x /etc/init.d/S40wireguard"
```

### Step 5: Start WireGuard

```powershell
ssh root@10.24.69.63 "/usr/bin/wg-quick up wg0"
```

### Step 6: Verify WireGuard

```powershell
ssh root@10.24.69.63 "wg show"
```

**Expected Output:**
```
interface: wg0
  public key: ...
  private key: (hidden)
  listening port: ...
  
peer: ...
  endpoint: ...
  allowed ips: ...
```

## Complete Deployment Script

Here's a PowerShell script that does everything:

```powershell
# Complete NanoKVM Build and Deploy Script
$DEVICE_IP = "10.24.69.63"
$REPO_PATH = "C:\Users\Wayne\Documents\GitHub\NanoKVM"

Write-Host "=== Building Frontend ===" -ForegroundColor Cyan
cd "$REPO_PATH\web"
pnpm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "Frontend build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Building Backend ===" -ForegroundColor Cyan
cd $REPO_PATH
wsl -d Ubuntu -e bash build-wsl.sh
if ($LASTEXITCODE -ne 0) {
    Write-Host "Backend build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Deploying Frontend ===" -ForegroundColor Cyan
scp -r "$REPO_PATH\web\dist\*" "root@${DEVICE_IP}:/kvmapp/server/web/"

Write-Host "`n=== Deploying Backend ===" -ForegroundColor Cyan
scp "$REPO_PATH\server\NanoKVM-Server" "root@${DEVICE_IP}:/kvmapp/server/"

Write-Host "`n=== Restarting Service ===" -ForegroundColor Cyan
ssh "root@${DEVICE_IP}" "/etc/init.d/S95nanokvm restart"

Write-Host "`n=== Deployment Complete! ===" -ForegroundColor Green
Write-Host "Access your NanoKVM at: http://${DEVICE_IP}" -ForegroundColor Green
```

Save as `deploy.ps1` and run:
```powershell
.\deploy.ps1
```

## Troubleshooting

### Frontend Build Errors

**Problem:** TypeScript errors about missing imports

**Solution:** Check that all required imports are present in the file:
```typescript
import * as api from '@/api/application';
import * as ls from '@/lib/localstorage';
import { Tailscale as TailscaleIcon } from '@/components/icons/tailscale';
import { Tailscale } from './tailscale';
import { Update } from './update';
```

### Backend Build Errors

**Problem:** `riscv64-unknown-linux-musl-gcc: command not found`

**Solution:** The toolchain isn't installed. Let the build script download it (requires ~840MB download).

**Problem:** `Go version is too old`

**Solution:** The build script will automatically install Go 1.23+.

### Deployment Issues

**Problem:** Web interface shows old version after deployment

**Solution:** 
1. Clear browser cache (Ctrl+Shift+Delete)
2. Hard refresh (Ctrl+F5)
3. Try incognito/private browsing mode

**Problem:** Service won't start

**Solution:** Check logs:
```powershell
ssh root@10.24.69.63 "tail -50 /var/log/messages"
```

**Problem:** "symbol not found" errors

**Solution:** Rebuild with fresh toolchain:
```powershell
wsl -d Ubuntu -e bash -c "cd /mnt/c/Users/Wayne/Documents/GitHub/NanoKVM && rm -rf ~/riscv-toolchain && bash build-wsl.sh"
```

### WireGuard Issues

**Problem:** WireGuard interface won't start

**Solution:** Check that all components are installed:
```powershell
ssh root@10.24.69.63 "which wireguard-go wg wg-quick resolvconf"
```

If missing, follow the WireGuard Installation section above.

**Problem:** `resolvconf: command not found`

**Solution:** Create dummy resolvconf script (see WireGuard Installation Step 3).

**Problem:** Permission errors on config file

**Solution:** Fix permissions:
```powershell
ssh root@10.24.69.63 "chmod 600 /etc/wireguard/wg0.conf"
```

## File Locations on Device

### NanoKVM Application Files
- **Server binary:** `/kvmapp/server/NanoKVM-Server`
- **Web files:** `/kvmapp/server/web/`
- **Shared libraries:** `/kvmapp/server/dl_lib/`
- **Configuration:** `/etc/kvm/server.yaml`

### WireGuard Files
- **Binaries:** `/usr/bin/wireguard-go`, `/usr/bin/wg`, `/usr/bin/wg-quick`
- **Configuration:** `/etc/wireguard/wg0.conf`
- **Init script:** `/etc/init.d/S40wireguard`

### System Files
- **Init scripts:** `/etc/init.d/S95nanokvm`
- **Kernel modules:** `/mnt/system/ko/*.ko`
- **Sensor config:** `/mnt/data/sensor_cfg.ini`

## Development Workflow

### Making Frontend Changes

1. Edit files in `web/src/`
2. Test locally: `cd web && pnpm run dev`
3. Build: `pnpm run build`
4. Deploy: `scp -r dist/* root@10.24.69.63:/kvmapp/server/web/`
5. Hard refresh browser (Ctrl+F5)

### Making Backend Changes

1. Edit files in `server/`
2. Build: `wsl -d Ubuntu -e bash build-wsl.sh`
3. Deploy: `scp server/NanoKVM-Server root@10.24.69.63:/kvmapp/server/`
4. Restart: `ssh root@10.24.69.63 "/etc/init.d/S95nanokvm restart"`

### Testing Changes

1. **Always test both frontend and backend together**
2. **Check browser console for errors** (F12)
3. **Check server logs** on device
4. **Test all menu items** (About, Appearance, Device, Tailscale, WireGuard, Update, Account)

## Version Control

### Before Major Changes

```powershell
cd C:\Users\Wayne\Documents\GitHub\NanoKVM
git status
git add .
git commit -m "Description of changes"
```

### Reverting Changes

**Using Git:**
```powershell
git restore <filename>  # Revert single file
git restore .          # Revert all files
```

**Using VS Code Timeline:**
1. Right-click file in Explorer
2. Select "Open Timeline"
3. Click on previous version
4. Click "Restore" button

## Performance Notes

- **Frontend build:** ~10-15 seconds
- **Backend build:** ~2-3 minutes (first time: 10-15 minutes with toolchain download)
- **Deployment:** ~5-10 seconds total
- **Service restart:** ~30 seconds

## Security Notes

1. **Always use SSH for deployment** (already using SCP/SSH)
2. **Keep WireGuard configs secure** (chmod 600)
3. **Don't commit private keys to git**
4. **Use strong passwords** for NanoKVM web interface
5. **Keep server.yaml secure** (contains JWT secrets)

## Next Steps After Deployment

1. ✅ Login to web interface
2. ✅ Verify all menu items appear correctly
3. ✅ Test WireGuard connection (if using VPN)
4. ✅ Check video stream works
5. ✅ Test keyboard/mouse control
6. ✅ Verify settings persist after reboot
7. ✅ Create backup of working configuration

## Backup and Recovery

### Create Backup

```powershell
$BACKUP_DATE = Get-Date -Format "yyyyMMdd-HHmmss"
$BACKUP_DIR = "C:\Users\Wayne\Documents\NanoKVM-Backups\$BACKUP_DATE"

mkdir $BACKUP_DIR
scp -r root@10.24.69.63:/kvmapp/server/* "$BACKUP_DIR\server\"
scp -r root@10.24.69.63:/etc/wireguard "$BACKUP_DIR\wireguard\"
scp root@10.24.69.63:/etc/kvm/server.yaml "$BACKUP_DIR\"
```

### Restore from Backup

```powershell
$BACKUP_DIR = "C:\Users\Wayne\Documents\NanoKVM-Backups\<backup-date>"

scp -r "$BACKUP_DIR\server\*" root@10.24.69.63:/kvmapp/server/
scp -r "$BACKUP_DIR\wireguard\*" root@10.24.69.63:/etc/wireguard/
scp "$BACKUP_DIR\server.yaml" root@10.24.69.63:/etc/kvm/
ssh root@10.24.69.63 "/etc/init.d/S95nanokvm restart"
```

## Support and Resources

- **NanoKVM Wiki:** https://wiki.sipeed.com/nanokvm
- **GitHub Repository:** https://github.com/sipeed/NanoKVM
- **Your Fork:** https://github.com/crashf/NanoKVM
- **WireGuard Documentation:** See `BUILDING_WIREGUARD.md` in repo
- **Build Script:** `build-wsl.sh` in repo root

## Quick Reference Commands

```powershell
# Full rebuild and deploy
cd C:\Users\Wayne\Documents\GitHub\NanoKVM\web && pnpm run build
cd C:\Users\Wayne\Documents\GitHub\NanoKVM && wsl -d Ubuntu -e bash build-wsl.sh
scp -r C:\Users\Wayne\Documents\GitHub\NanoKVM\web\dist\* root@10.24.69.63:/kvmapp/server/web/
scp C:\Users\Wayne\Documents\GitHub\NanoKVM\server\NanoKVM-Server root@10.24.69.63:/kvmapp/server/
ssh root@10.24.69.63 "/etc/init.d/S95nanokvm restart"

# Check service status
ssh root@10.24.69.63 "ps | grep NanoKVM-Server"

# View logs
ssh root@10.24.69.63 "tail -f /var/log/messages"

# WireGuard control
ssh root@10.24.69.63 "/usr/bin/wg-quick up wg0"    # Start
ssh root@10.24.69.63 "/usr/bin/wg-quick down wg0"  # Stop
ssh root@10.24.69.63 "wg show"                      # Status

# Reboot device
ssh root@10.24.69.63 "reboot"
```
