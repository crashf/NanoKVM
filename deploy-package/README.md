# NanoKVM Deployment Package

This package contains pre-built binaries ready for deployment to your NanoKVM device.

## Package Contents

- **web/** - Frontend files (React app built with Vite)
- **server/** - Backend binary (NanoKVM-Server for RISC-V64)
- **wireguard/** - WireGuard userspace binary and init script
- **deploy-package.ps1** - Deployment script

## Quick Start

1. Connect to same network as your NanoKVM device
2. Run deployment script:
   ```powershell
   .\deploy-package.ps1 -DeviceIP 10.24.69.63
   ```
3. Enter SSH password when prompted (will be asked 6 times)
4. Wait for deployment to complete

## SSH Password Prompts

The deployment script will prompt for your SSH password 6 times:
- Frontend deployment (1x)
- Backend deployment (1x)
- WireGuard binary deployment (1x)
- WireGuard init script deployment (1x)
- Permission setting (1x)
- Service restart (1x)

## What Gets Deployed

| Component | Source | Destination | Purpose |
|-----------|--------|-------------|---------|
| Frontend | web/* | /kvmapp/server/web/ | Web interface |
| Backend | server/NanoKVM-Server | /kvmapp/server/ | Main server binary |
| WireGuard | wireguard/wireguard-go | /usr/bin/ | WireGuard userspace |
| Init Script | wireguard/S40wireguard | /etc/init.d/ | WireGuard autostart |
| resolvconf | (created) | /usr/bin/ | Stub for wg-quick |

## Verification Steps

After deployment:

1. **Check web interface**: http://[device-ip]
   - Hard refresh (Ctrl+F5)
   - Open Settings menu
   - Verify 7 tabs: About, Appearance, Device, Tailscale, WireGuard, Update, Account

2. **Check WireGuard**:
   ```bash
   ssh root@[device-ip]
   which wireguard-go  # Should show /usr/bin/wireguard-go
   /etc/init.d/S40wireguard start
   wg show  # Should show interface wg0
   ```

3. **Test autostart**:
   ```bash
   reboot
   # After reboot
   wg show  # Should show interface wg0 is up
   ```

## Troubleshooting

**Deployment hangs**: 
- Make sure device is accessible via SSH
- Try manual connection first: ssh root@[device-ip]
- Check firewall isn't blocking SSH port 22

**Permission denied**:
- Verify SSH password is correct
- Check device IP is correct

**WireGuard won't start**:
- Check init script has Unix line endings: ssh root@[device-ip] "sed -n 'l' /etc/init.d/S40wireguard | head -5"
- Should NOT see \r characters
- If you see \r, repackage with package.ps1

**Frontend not updating**:
- Hard refresh browser (Ctrl+F5)
- Clear browser cache
- Check deployment copied files: ssh root@[device-ip] "ls -lh /kvmapp/server/web/"

## Package Creation

This package was created with:
```powershell
.\package-simple.ps1 -OutputDir .\deploy-package
```

To create a new package after rebuilding:
```powershell
# Rebuild frontend
cd web
pnpm run build

# Rebuild backend
cd ..\server
bash build-wsl.sh

# Create new package
cd ..
.\package-simple.ps1
```

## Support

For issues or questions, see BUILD_AND_DEPLOY.md for detailed build and deployment instructions.
