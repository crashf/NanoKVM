# WireGuard Integration Session State
**Date**: November 18, 2025  
**Status**: WireGuard interface partially working, routing issue caused SSH lockout

---

## Current Situation

### ✅ What's Working
- **Frontend**: Built successfully, deployed to NanoKVM
  - Location: `/kvmapp/server/web/dist/`
  - WireGuard settings page displays correctly
  - Shows interface configuration options

- **Backend**: Built successfully for RISC-V, deployed to NanoKVM
  - Location: `/kvmapp/server/NanoKVM-Server`
  - Size: 19 MB
  - Type: ELF 64-bit RISC-V executable
  - Service restarted successfully

- **WireGuard Config**: Created and uploaded
  - Location: `/etc/wireguard/wg0.conf`
  - Contains valid interface and peer configuration

### ⚠️ Current Problem
**WireGuard started but broke network access**

When WireGuard started, it configured routing tables that route ALL traffic (0.0.0.0/0) through the VPN tunnel, including local LAN traffic. This broke SSH access to the device.

**Last successful command before lockout**:
```bash
ssh root@10.24.69.63 "/usr/bin/bash /usr/bin/wg-quick up wg0 2>&1"
```

**Result**: Interface came up but SSH became unreachable (connection timeout)

---

## Issues Discovered & Fixed

### 1. ✅ FIXED: Line Endings on wg-quick
**Problem**: `/usr/bin/wg-quick` had Windows line endings (CRLF)  
**Solution**: Converted to Unix line endings
```bash
ssh root@10.24.69.63 "sed -i 's/\r$//' /usr/bin/wg-quick"
```

### 2. ✅ FIXED: Missing resolvconf
**Problem**: `wg-quick` calls `resolvconf` which doesn't exist on NanoKVM  
**Solution**: Created dummy resolvconf script
```bash
ssh root@10.24.69.63 "echo '#!/bin/sh' > /usr/bin/resolvconf && echo 'exit 0' >> /usr/bin/resolvconf && chmod +x /usr/bin/resolvconf"
```

### 3. ✅ FIXED: PATH environment in Go exec
**Problem**: Go's `exec.Command` doesn't inherit PATH  
**Solution**: Updated `cli.go` to:
- Use `/usr/bin/bash` explicitly (not `sh`)
- Set PATH environment variable
- Set RESOLVCONF environment variable

### 4. ⚠️ CURRENT ISSUE: Routing Configuration
**Problem**: WireGuard config has `AllowedIPs = 0.0.0.0/0, ::/0` which routes all traffic through VPN  
**Config location**: `/etc/wireguard/wg0.conf`

**Current config**:
```ini
[Interface]
PrivateKey = oL7sw7OY0KSEjAPOh26Ken6K5GO+KLMVrhIIXEugEmA=
Address = 10.8.0.8/24
DNS = 1.1.1.1

[Peer]
PublicKey = BmLmjtGsbcUtsDaDVGiUOlHcA1GxxmVLORsK3aR49iY=
PresharedKey = ekIPv67PJ+lvMDgtaso/4p8ePinNEWw1CKkf2cMAPQ4=
AllowedIPs = 0.0.0.0/0, ::/0    # ← THIS ROUTES ALL TRAFFIC THROUGH VPN
PersistentKeepalive = 0
Endpoint = wireguard.tech-method.com:51820
```

---

## Recovery Steps (After Reboot)

### Option 1: Physical Access to Device
If you have physical/console access:
```bash
# Stop WireGuard
/usr/bin/bash /usr/bin/wg-quick down wg0

# Or disable the interface
ip link set wg0 down
ip link delete wg0
```

### Option 2: Web Interface Access
If http://10.24.69.63 is still accessible:
1. Go to Settings → WireGuard
2. Click "Stop" button to bring down the interface

### Option 3: Reboot Clears It
WireGuard is NOT set to auto-start on boot, so rebooting will clear the routing issue.

---

## Next Steps (Once Access is Restored)

### 1. Fix the WireGuard Configuration
The `AllowedIPs` should be specific to what you want routed through VPN, not 0.0.0.0/0.

**Option A**: Route only specific subnets
```ini
AllowedIPs = 10.0.0.0/8, 192.168.0.0/16  # Example: route only private networks
```

**Option B**: Split tunnel (don't route all traffic)
```ini
AllowedIPs = 10.8.0.0/24  # Only route VPN subnet
```

**Option C**: Keep 0.0.0.0/0 but exclude local LAN
This requires policy routing which is complex. Not recommended for first implementation.

### 2. Update the Frontend to Warn Users
Add a warning in the UI when `AllowedIPs` contains 0.0.0.0/0 that this will route all traffic including local LAN through the VPN.

### 3. Test WireGuard Start Again
```bash
# SSH to device
ssh root@10.24.69.63

# Start WireGuard with corrected config
/usr/bin/bash /usr/bin/wg-quick up wg0

# Verify interface is up
wg show

# Check routing tables
ip route show table 51820
ip rule show

# Test connectivity
ping 8.8.8.8
ping 10.24.69.1  # Your LAN gateway
```

---

## Code Changes Made

### Backend: `server/service/extensions/wireguard/cli.go`

All command executions now use:
- `/usr/bin/bash` instead of `sh`
- Full paths: `/usr/bin/wg-quick`, `/sbin/ip`, `/usr/bin/wg`
- Environment variables set: `PATH` and `RESOLVCONF`

**Example (Start function)**:
```go
func (c *Cli) Start() error {
    if err := os.MkdirAll(ConfigDir, 0o700); err != nil {
        return err
    }
    
    command := fmt.Sprintf("/usr/bin/wg-quick up %s", DefaultInterface)
    cmd := exec.Command("/usr/bin/bash", "-c", command)
    cmd.Env = append(os.Environ(), 
        "PATH=/usr/bin:/bin:/usr/sbin:/sbin",
        "RESOLVCONF=:",
    )
    return cmd.Run()
}
```

Similar changes applied to:
- `Stop()`
- `Up(interfaceName string)`
- `Down(interfaceName string)`
- `Status(interfaceName string)` - uses `/sbin/ip` and `/usr/bin/wg`

### Frontend: Already deployed
- Location: `web/dist/`
- Built with: `pnpm build`
- No changes needed

---

## Device Information

- **Device**: NanoKVM (SG2002 RISC-V)
- **IP Address**: 10.24.69.63
- **Default Password**: (you know it)
- **SSH**: Port 22 (currently unreachable due to routing issue)
- **Web UI**: http://10.24.69.63 (may still be accessible)
- **WireGuard Binary**: `/usr/bin/wg` (works)
- **WireGuard Script**: `/usr/bin/wg-quick` (bash script, line endings fixed)
- **Bash Version**: GNU bash 5.2.15 (available at `/usr/bin/bash`)
- **Shell**: BusyBox sh (symlinked at `/bin/sh`)

---

## Build Commands (If Rebuild Needed)

### Frontend Build
```powershell
cd C:\Users\Wayne\Documents\GitHub\NanoKVM\web
pnpm build
```
Output: `web/dist/` (706.59 kB bundle)

### Backend Build (WSL)
```powershell
cd C:\Users\Wayne\Documents\GitHub\NanoKVM
wsl -d Ubuntu -e sh build-wsl.sh
```
Output: `server/NanoKVM-Server` (19 MB RISC-V binary)

### Deploy Backend
```powershell
scp server/NanoKVM-Server root@10.24.69.63:/kvmapp/server/
ssh root@10.24.69.63 "/etc/init.d/S95nanokvm restart"
```

### Deploy Frontend
```powershell
scp -r web/dist/* root@10.24.69.63:/kvmapp/server/web/dist/
```

---

## Files Modified in This Session

### Backend Files
1. `server/service/extensions/wireguard/cli.go` - Fixed command execution
2. `server/service/extensions/wireguard/service.go` - Simplified API (previous session)
3. `server/router/extensions.go` - Added routes (previous session)

### Frontend Files
1. `web/src/pages/desktop/menu/settings/wireguard/index.tsx` - Removed install UI
2. `web/src/pages/desktop/menu/settings/wireguard/header.tsx` - Removed uninstall button
3. `web/src/pages/desktop/menu/settings/wireguard/config.tsx` - Fixed TypeScript errors
4. `web/src/pages/desktop/menu/settings/wireguard/device.tsx` - Fixed TypeScript errors

### Helper Scripts Created
1. `build-wsl.sh` - WSL build automation script
2. `test-wireguard-api.html` - API testing tool (in project root)

### On NanoKVM Device
1. `/usr/bin/resolvconf` - Dummy script (exit 0)
2. `/usr/bin/wg-quick` - Fixed line endings
3. `/etc/wireguard/wg0.conf` - WireGuard configuration (needs AllowedIPs fix)

---

## Important Notes

### WireGuard is NOT Installed by Default
The original NanoKVM firmware does NOT have WireGuard endpoints. You had to deploy the custom backend we built.

### Config File Permissions Warning
You'll see: `Warning: '/etc/wireguard/wg0.conf' is world accessible`

This is because the config was uploaded via the web UI. To fix:
```bash
chmod 600 /etc/wireguard/wg0.conf
```

### DNS Handling
The `DNS = 1.1.1.1` setting in the config doesn't actually configure DNS on NanoKVM because:
1. We created a dummy `resolvconf` that does nothing
2. NanoKVM likely uses static DNS or DHCP-provided DNS

If you need DNS to work through the VPN, you'll need to manually configure `/etc/resolv.conf` or implement proper DNS handling.

### Auto-Start on Boot
WireGuard is NOT configured to auto-start. To enable:
1. Create init script in `/etc/init.d/`
2. Or add to `/etc/rc.local`
3. Or use the NanoKVM service manager

---

## Troubleshooting

### If SSH is locked out:
1. Try web UI: http://10.24.69.63
2. Physical access: Connect console cable
3. Reboot: Power cycle the device
4. After recovery: Fix `AllowedIPs` in config before starting WireGuard again

### If WireGuard won't start:
```bash
# Check kernel module
lsmod | grep wireguard

# Check interface exists
ip link show wg0

# Check config syntax
wg-quick strip wg0

# Manual debug
/usr/bin/bash -x /usr/bin/wg-quick up wg0
```

### If routing is broken:
```bash
# Show all routing tables
ip route show table all

# Show routing rules
ip rule show

# Delete WireGuard routing table
ip route flush table 51820
ip rule del table 51820
```

---

## Success Criteria (When Complete)

- [ ] Can start WireGuard from web UI
- [ ] WireGuard connects to peer successfully
- [ ] SSH access remains available
- [ ] Local LAN access remains available  
- [ ] Can route specific traffic through VPN
- [ ] Can stop WireGuard from web UI
- [ ] Status page shows correct peer information
- [ ] Handshake updates show recent connection

---

## Quick Reference

### NanoKVM Details
- IP: 10.24.69.63
- User: root
- Arch: RISC-V (riscv64-unknown-linux-musl)
- CPU: c906fdv

### Critical Paths
- Config: `/etc/wireguard/wg0.conf`
- Backend: `/kvmapp/server/NanoKVM-Server`
- Frontend: `/kvmapp/server/web/dist/`
- Service: `/etc/init.d/S95nanokvm`

### Critical Commands
```bash
# Start WireGuard
/usr/bin/bash /usr/bin/wg-quick up wg0

# Stop WireGuard
/usr/bin/bash /usr/bin/wg-quick down wg0

# Status
/usr/bin/wg show

# Restart NanoKVM service
/etc/init.d/S95nanokvm restart
```

---

**Remember**: The device is currently locked out due to routing all traffic through VPN. Reboot or access via alternate method to recover.
