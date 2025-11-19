# NanoKVM Package & Deploy Workflow

This is the simplified workflow for creating and deploying NanoKVM packages.

## Overview

1. **Build once** (when code changes)
2. **Package** (creates deployment bundle)
3. **Deploy** (to device(s))

## Step 1: Build (When Code Changes)

Build the frontend and backend **only when you make code changes**:

### Build Frontend
```powershell
cd C:\Users\Wayne\Documents\GitHub\NanoKVM\web
pnpm run build
```

### Build Backend
```powershell
cd C:\Users\Wayne\Documents\GitHub\NanoKVM
wsl -d Ubuntu -e bash build-wsl.sh
```

**Note:** You only need to do this when you modify the code!

## Step 2: Package (Creates Deployment Bundle)

Creates a portable deployment package containing all binaries:

```powershell
cd C:\Users\Wayne\Documents\GitHub\NanoKVM
.\package.ps1
```

**What it does:**
- ✓ Collects frontend build (web/dist)
- ✓ Collects backend binary (NanoKVM-Server)
- ✓ Collects WireGuard binary (wireguard-go)
- ✓ Creates deployment script
- ✓ Packages everything in `deploy-package/` folder

**Output:**
```
deploy-package/
├── web/                    # Frontend files
├── server/
│   └── NanoKVM-Server     # Backend binary
├── wireguard/
│   └── wireguard-go       # WireGuard binary
├── deploy-package.ps1     # Deployment script
├── README.md              # Package instructions
└── version.json           # Build info
```

## Step 3: Deploy (To Device)

Deploy the package to your device(s):

```powershell
cd deploy-package
.\deploy-package.ps1 -DeviceIP 10.24.69.63
```

**You will be prompted for:**
- SSH password (4 times - this is normal)

**What it deploys:**
1. Frontend → `/kvmapp/server/web/`
2. Backend → `/kvmapp/server/NanoKVM-Server`
3. WireGuard → `/usr/bin/wireguard-go`
4. Restarts NanoKVM service

## Complete Example

### Scenario: You made code changes and want to deploy

```powershell
# 1. Build frontend (if you changed web code)
cd C:\Users\Wayne\Documents\GitHub\NanoKVM\web
pnpm run build

# 2. Build backend (if you changed server code)
cd C:\Users\Wayne\Documents\GitHub\NanoKVM
wsl -d Ubuntu -e bash build-wsl.sh

# 3. Create package
.\package.ps1

# 4. Deploy to device
cd deploy-package
.\deploy-package.ps1 -DeviceIP 10.24.69.63
```

### Scenario: You just want to re-deploy existing builds

```powershell
# Just package and deploy (no building)
cd C:\Users\Wayne\Documents\GitHub\NanoKVM
.\package.ps1
cd deploy-package
.\deploy-package.ps1 -DeviceIP 10.24.69.63
```

### Scenario: Deploy to multiple devices

```powershell
# Create package once
cd C:\Users\Wayne\Documents\GitHub\NanoKVM
.\package.ps1

# Deploy to multiple devices
cd deploy-package
.\deploy-package.ps1 -DeviceIP 10.24.69.63
.\deploy-package.ps1 -DeviceIP 10.24.69.64
.\deploy-package.ps1 -DeviceIP 10.24.69.65
```

## Creating a Portable ZIP

Want to share the package or deploy from another computer?

```powershell
# Create package
cd C:\Users\Wayne\Documents\GitHub\NanoKVM
.\package.ps1

# Create ZIP
Compress-Archive -Path '.\deploy-package' -DestinationPath 'nanokvm-package.zip'
```

Then copy `nanokvm-package.zip` to any Windows computer, extract, and run:
```powershell
.\deploy-package.ps1 -DeviceIP <your-device-ip>
```

## Package Contents

### Frontend (web/)
All web interface files:
- `index.html`
- JavaScript bundles (`*.js`)
- Stylesheets (`*.css`)
- Assets and icons
- Service worker

### Backend (server/NanoKVM-Server)
- 19MB RISC-V64 binary
- Compiled with CGO
- Includes shared library paths

### WireGuard (wireguard/wireguard-go)
- 4-5MB RISC-V64 binary
- Userspace WireGuard implementation
- Required for VPN functionality

## When to Build vs Package

### Build (Rebuild required):
- ✓ Modified frontend code (web/src/)
- ✓ Modified backend code (server/)
- ✓ Changed dependencies
- ✓ Updated configurations

### Package (No rebuild):
- ✓ Want to deploy to new device
- ✓ Want to re-deploy same version
- ✓ Creating backup
- ✓ Sharing with others

## Verification After Deployment

```powershell
# Check web interface
Start-Process "http://10.24.69.63"

# Verify service is running
ssh root@10.24.69.63 "ps | grep NanoKVM-Server"

# Check WireGuard
ssh root@10.24.69.63 "which wireguard-go"

# View logs
ssh root@10.24.69.63 "tail -f /var/log/messages"
```

## Troubleshooting

### "Frontend build not found"
**Solution:** Run `cd web && pnpm run build`

### "Backend binary not found"
**Solution:** Run `wsl -d Ubuntu -e bash build-wsl.sh`

### "WireGuard binary not found"
**Solution:** Check `wireguard-riscv64/wireguard-go` exists in repo

### "Deployment failed"
**Common causes:**
- Wrong IP address
- Wrong password
- SSH not enabled on device
- Network connectivity issues

**Check connection:**
```powershell
ping 10.24.69.63
ssh root@10.24.69.63
```

## Quick Command Reference

```powershell
# Package current builds
.\package.ps1

# Deploy to default device
cd deploy-package
.\deploy-package.ps1 -DeviceIP 10.24.69.63

# Create ZIP for sharing
Compress-Archive -Path '.\deploy-package' -DestinationPath 'nanokvm-package.zip'

# Full rebuild and package
cd web && pnpm run build
cd ..
wsl -d Ubuntu -e bash build-wsl.sh
.\package.ps1

# Deploy to multiple devices
cd deploy-package
$devices = @("10.24.69.63", "10.24.69.64", "10.24.69.65")
$devices | ForEach-Object { .\deploy-package.ps1 -DeviceIP $_ }
```

## Best Practices

1. **Version Control**: Commit code before building
   ```powershell
   git add .
   git commit -m "Description"
   ```

2. **Test Locally**: Test changes before packaging

3. **Backup**: Keep old packages as backups
   ```powershell
   # Archive with date
   $date = Get-Date -Format "yyyyMMdd"
   Compress-Archive -Path '.\deploy-package' -DestinationPath "nanokvm-$date.zip"
   ```

4. **Document Changes**: Update version.json or create changelog

5. **Verify Deployment**: Always check web UI and logs after deploying

## Time Expectations

- **Packaging**: 2-5 seconds
- **Deployment**: 10-15 seconds
- **Service restart**: 5-10 seconds
- **Total**: ~30 seconds per device

**Building (when needed):**
- Frontend: 10-15 seconds
- Backend: 2-3 minutes (first time: 10-15 minutes)

## Advantages of This Workflow

✅ **Fast**: Package once, deploy many times
✅ **Portable**: Share packages as ZIP files
✅ **Consistent**: Same binaries to all devices
✅ **Simple**: No build tools needed on deployment machine
✅ **Verifiable**: Includes version info and checksums

---

**Need the old build-and-deploy script?** Use `deploy.ps1` instead (builds every time)
