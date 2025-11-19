# NanoKVM Deployment Package

## Contents

- web/: Frontend files
- server/NanoKVM-Server: Backend binary
- wireguard/wireguard-go: WireGuard binary
- deploy-package.ps1: Deployment script

## Quick Deploy

```powershell
.\deploy-package.ps1 -DeviceIP 10.24.69.63
```

You will be prompted for SSH password (4 times is normal).

## Package Info

Generated: 2025-11-19 14:26:32
Frontend files: 20
Backend size: 18.8 MB
WireGuard size: 4.5 MB

## After Deployment

1. Access: http://<device-ip>
2. Hard refresh: Ctrl+F5
3. Login and test

## WireGuard Commands

Start: ssh root@<ip> "/usr/bin/wg-quick up wg0"
Stop: ssh root@<ip> "/usr/bin/wg-quick down wg0"
Status: ssh root@<ip> "wg show"
