# WireGuard Integration - Complete Modification Guide

This document details all modifications made to add WireGuard VPN support to NanoKVM.

## Date: November 18-19, 2025
## Device: NanoKVM (RISC-V SG2002) at 10.24.69.63

---

## Overview

Added complete WireGuard VPN integration to NanoKVM with:
- Full backend API for WireGuard management
- Frontend UI for configuration and status monitoring
- Auto-start on boot functionality
- Keyboard input fixes for text areas
- Improved human-readable labels

---

## BACKEND CHANGES

### 1. WireGuard Service Implementation

**File: `server/service/extensions/wireguard/cli.go`**
- **Status**: CREATED (New File)
- **Purpose**: CLI wrapper for WireGuard commands
- **Key Features**:
  - Uses `/usr/bin/bash` to run `wg-quick` (required by the script)
  - Sets `RESOLVCONF=:` environment variable (NanoKVM doesn't have resolvconf)
  - Sets `PATH=/usr/bin:/bin:/usr/sbin:/sbin` for all commands
  - Full paths to binaries: `/usr/bin/wg-quick`, `/sbin/ip`, `/usr/bin/wg`

**Critical Code Sections**:
```go
// Start function - lines 38-51
func (c *Cli) Start() error {
    // Ensure config directory exists
    if err := os.MkdirAll(ConfigDir, 0o700); err != nil {
        return err
    }

    // Use wg-quick to bring up the interface
    // wg-quick requires bash and needs RESOLVCONF to be set to prevent DNS errors
    command := fmt.Sprintf("/usr/bin/wg-quick up %s", DefaultInterface)
    cmd := exec.Command("/usr/bin/bash", "-c", command)
    cmd.Env = append(os.Environ(), 
        "PATH=/usr/bin:/bin:/usr/sbin:/sbin",
        "RESOLVCONF=:", // Disable resolvconf (not available on NanoKVM)
    )
    return cmd.Run()
}
```

**Methods**:
- `Start()` - Start WireGuard VPN
- `Stop()` - Stop WireGuard VPN
- `Restart()` - Restart VPN connection
- `Status()` - Get connection status, peers, handshake info
- `GenerateKeypair()` - Generate new WireGuard keys
- `Up()/Down()` - Interface control

**File: `server/service/extensions/wireguard/service.go`**
- **Status**: CREATED
- **Purpose**: HTTP API handlers for WireGuard operations
- **Key Methods**:
  - `GetStatus()` - Returns VPN status and peer information
  - `GetConfig()` - Returns WireGuard configuration file
  - `SaveConfig()` - Saves WireGuard configuration to `/etc/wireguard/wg0.conf`
  - `Start()/Stop()/Restart()` - VPN control endpoints
  - `GenerateKeys()` - Key pair generation

**File: `server/service/extensions/wireguard/config.go`**
- **Status**: CREATED
- **Purpose**: Configuration constants
- **Values**:
  - `ConfigDir = "/etc/wireguard"`
  - `DefaultInterface = "wg0"`

**File: `server/router/extensions.go`**
- **Status**: CREATED
- **Purpose**: Route registration for WireGuard API
- **Endpoints**:
  - `GET /api/extensions/wireguard/status` - Get VPN status
  - `GET /api/extensions/wireguard/config` - Get configuration
  - `POST /api/extensions/wireguard/config` - Save configuration
  - `POST /api/extensions/wireguard/start` - Start VPN
  - `POST /api/extensions/wireguard/stop` - Stop VPN
  - `POST /api/extensions/wireguard/restart` - Restart VPN
  - `POST /api/extensions/wireguard/keys/generate` - Generate key pair

**File: `server/router/router.go`**
- **Modification**: Add extensions router
```go
import (
    // ... existing imports
    "NanoKVM-Server/router/extensions"
)

func RegisterRoutes(r *gin.Engine) {
    // ... existing routes
    extensions.RegisterRoutes(r)
}
```

---

## FRONTEND CHANGES

### 2. WireGuard UI Components

**File: `web/src/pages/desktop/menu/settings/wireguard/index.tsx`**
- **Status**: MODIFIED
- **Changes**:
  - Removed `Install` component import
  - Removed `notInstall` state handling
  - Always shows `ConfigEditor` (no install check needed)

**File: `web/src/pages/desktop/menu/settings/wireguard/header.tsx`**
- **Status**: MODIFIED
- **Changes**:
  - Removed `Uninstall` button (45 lines removed)
  - Kept Start, Stop, Restart buttons
  - Removed unused `onUninstall` function

**File: `web/src/pages/desktop/menu/settings/wireguard/config.tsx`**
- **Status**: MODIFIED
- **Changes**:
  - Added keyboard event handlers to TextArea:
    ```tsx
    <Input.TextArea
        value={config}
        onChange={(e) => setConfig(e.target.value)}
        onKeyDown={(e) => e.stopPropagation()}
        onKeyUp={(e) => e.stopPropagation()}
        onKeyPress={(e) => e.stopPropagation()}
        placeholder={getDefaultConfig()}
        rows={15}
        className="font-mono text-sm"
        disabled={isLoading}
        autoComplete="off"
        spellCheck={false}
    />
    ```

**File: `web/src/pages/desktop/menu/settings/wireguard/device.tsx`**
- **Status**: MODIFIED
- **Changes**: Removed unused `Popconfirm` import

### 3. Keyboard Input Fix

**File: `web/src/pages/desktop/keyboard/index.tsx`**
- **Status**: MODIFIED
- **Problem**: Global keyboard handler was capturing ALL keystrokes
- **Solution**: Added check to ignore events from input fields

**Added function (line ~18)**:
```typescript
// Check if the event target is an input element that should receive keyboard input
function shouldIgnoreEvent(event: KeyboardEvent): boolean {
    const target = event.target as HTMLElement;
    const tagName = target.tagName.toLowerCase();
    
    // Allow typing in input fields, textareas, and contenteditable elements
    return (
        tagName === 'input' ||
        tagName === 'textarea' ||
        target.isContentEditable ||
        target.getAttribute('contenteditable') === 'true'
    );
}
```

**Modified handleKeyDown (line ~26)**:
```typescript
function handleKeyDown(event: KeyboardEvent) {
    // Don't intercept if user is typing in an input field
    if (shouldIgnoreEvent(event)) {
        return;
    }
    disableEvent(event);
    // ... rest of function
}
```

**Modified handleKeyUp (line ~49)**:
```typescript
function handleKeyUp(event: KeyboardEvent) {
    // Don't intercept if user is typing in an input field
    if (shouldIgnoreEvent(event)) {
        return;
    }
    disableEvent(event);
    // ... rest of function
}
```

### 4. Improved Translation Labels

**File: `web/src/i18n/locales/en.ts`**
- **Status**: MODIFIED
- **Section**: `settings.wireguard`

**Changed labels (lines ~278-380)**:
```typescript
wireguard: {
    // Buttons and dialogs
    start: 'Start VPN Connection?',
    startDesc: 'This will start the WireGuard VPN tunnel.',
    restart: 'Restart VPN Connection?',
    restartDesc: 'This will restart the WireGuard VPN tunnel.',
    stop: 'Stop VPN Connection?',
    stopDesc: 'This will disconnect the WireGuard VPN tunnel.',
    
    status: {
        title: 'Connection Status',
        notConfigured: 'WireGuard is not configured yet. Please add a configuration in the Configuration tab.',
        interface: 'Interface Name',
        status: 'Connection Status',
        state: 'Connection State',
        running: 'Connected',
        notRunning: 'Disconnected',
        started: 'WireGuard VPN started successfully',
        stoppedSuccess: 'WireGuard VPN stopped successfully',
        restarted: 'WireGuard VPN restarted successfully',
        peers: 'Connected Peers',
        endpoint: 'Server Endpoint',
        allowedIPs: 'Allowed IP Ranges',
        latestHandshake: 'Last Handshake',
        transfer: 'Data Transfer',
        sent: 'Uploaded',
        received: 'Downloaded',
        address: 'IP Address',
        configure: 'Configure VPN'
    },
    
    config: {
        saveConfig: 'Save Configuration',
        configSaved: 'Configuration saved successfully',
        generateKeys: 'Generate New Keys',
        keysGenerated: 'Keys generated successfully',
        loadTemplate: 'Load Example Template',
        templateLoaded: 'Template loaded successfully',
        interface: 'WireGuard Interface',
        configHelp: 'Edit your WireGuard configuration below. Use "Load Example Template" button for a starter configuration, or "Generate New Keys" to create a new key pair.'
    }
}
```

### 5. API Integration

**File: `web/src/api/extensions/wireguard.ts`**
- **Status**: CREATED (if not existing) or VERIFIED
- **Exports**:
  - `getStatus(interfaceName)`
  - `getConfig(interfaceName)`
  - `saveConfig(config, interfaceName)`
  - `start(interfaceName)`
  - `stop(interfaceName)`
  - `restart(interfaceName)`
  - `generateKeys()`

---

## SYSTEM CHANGES

### 6. Auto-Start Script

**File: `kvmapp/system/init.d/S40wireguard`**
- **Status**: CREATED
- **Purpose**: Auto-start WireGuard on boot if config exists
- **Location on Device**: `/etc/init.d/S40wireguard`
- **Permissions**: `chmod +x /etc/init.d/S40wireguard`
- **Run Order**: S40 (after network S30eth, before NanoKVM S95nanokvm)

**Full script**:
```bash
#!/bin/sh
#
# Start WireGuard VPN
#

DAEMON="wg-quick"
CONFIG_DIR="/etc/wireguard"
INTERFACE="wg0"
CONFIG_FILE="$CONFIG_DIR/$INTERFACE.conf"

start() {
    # Check if config exists
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "WireGuard config not found: $CONFIG_FILE"
        return 0
    fi

    # Check if interface is already up
    if ip link show "$INTERFACE" >/dev/null 2>&1; then
        echo "WireGuard interface $INTERFACE already exists"
        return 0
    fi

    echo "Starting WireGuard interface $INTERFACE..."
    
    # Set environment to disable resolvconf (not available on NanoKVM)
    export RESOLVCONF=:
    export PATH=/usr/bin:/bin:/usr/sbin:/sbin
    
    # Use bash to run wg-quick (it requires bash, not sh)
    if /usr/bin/bash /usr/bin/wg-quick up "$INTERFACE" 2>&1; then
        echo "WireGuard interface $INTERFACE started successfully"
        return 0
    else
        echo "Failed to start WireGuard interface $INTERFACE"
        return 1
    fi
}

stop() {
    # Check if interface exists
    if ! ip link show "$INTERFACE" >/dev/null 2>&1; then
        echo "WireGuard interface $INTERFACE is not running"
        return 0
    fi

    echo "Stopping WireGuard interface $INTERFACE..."
    
    export RESOLVCONF=:
    export PATH=/usr/bin:/bin:/usr/sbin:/sbin
    
    if /usr/bin/bash /usr/bin/wg-quick down "$INTERFACE" 2>&1; then
        echo "WireGuard interface $INTERFACE stopped successfully"
        return 0
    else
        echo "Failed to stop WireGuard interface $INTERFACE"
        return 1
    fi
}

restart() {
    stop
    sleep 1
    start
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart|reload)
        restart
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac

exit $?
```

### 7. Device Configuration

**Files Created on NanoKVM**:
- `/etc/wireguard/wg0.conf` - WireGuard configuration (created via UI)
- `/usr/bin/resolvconf` - Dummy script to prevent DNS errors
- `/etc/init.d/S40wireguard` - Auto-start script

**Dummy resolvconf script** (on device):
```bash
#!/bin/sh
exit 0
```
Permissions: `chmod +x /usr/bin/resolvconf`

**Line ending fixes** (required due to Windows development):
```bash
sed -i 's/\r$//' /usr/bin/wg-quick
sed -i 's/\r$//' /etc/init.d/S40wireguard
```

---

## BUILD PROCESS

### 8. Build Scripts

**File: `build-wsl.sh`**
- **Status**: CREATED
- **Purpose**: Cross-compile backend for RISC-V using WSL
- **Location**: Project root directory

**Key Fix (line 102-103)**:
```bash
# Changed from bash-specific syntax to POSIX-compliant
# OLD: SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
# NEW:
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
```

**Build Steps**:
1. Check WSL environment
2. Install dependencies (curl, wget, tar, patchelf)
3. Upgrade Go to 1.23+ (required)
4. Download RISC-V toolchain (840MB from Sophon)
5. Extract toolchain to `~/riscv-toolchain/`
6. Build with CGO cross-compilation:
   ```bash
   CGO_ENABLED=1 \
   GOOS=linux \
   GOARCH=riscv64 \
   CC="${TOOLCHAIN_PATH}/bin/riscv64-unknown-linux-musl-gcc" \
   CGO_CFLAGS="-mcpu=c906fdv -march=rv64imafdcv0p7xthead" \
   CGO_LDFLAGS="-L${PROJECT_ROOT}/dl_lib -Wl,-rpath=/kvmapp/server/dl_lib" \
   go build -o NanoKVM-Server
   ```
7. Fix RPATH with patchelf

**Output**: `server/NanoKVM-Server` (19MB RISC-V binary)

### 9. Frontend Build

**Commands**:
```bash
cd web
pnpm build
```

**Output**: `web/dist/` (production-ready static files)

---

## DEPLOYMENT

### 10. Deployment Commands

**Backend Deployment**:
```powershell
scp server/NanoKVM-Server root@10.24.69.63:/kvmapp/server/
```

**Frontend Deployment**:
```powershell
scp -r web/dist/* root@10.24.69.63:/kvmapp/server/web/dist/
```

**Init Script Deployment**:
```powershell
scp kvmapp/system/init.d/S40wireguard root@10.24.69.63:/etc/init.d/S40wireguard
ssh root@10.24.69.63 "chmod +x /etc/init.d/S40wireguard && sed -i 's/\r$//' /etc/init.d/S40wireguard"
```

**Service Restart**:
```powershell
ssh root@10.24.69.63 "/etc/init.d/S95nanokvm restart"
```

---

## ISSUES RESOLVED

### 11. Problems & Solutions

**Problem 1: WireGuard buttons didn't work**
- **Cause**: Go `exec.Command` doesn't inherit PATH environment
- **Solution**: Set PATH explicitly and use full binary paths

**Problem 2: wg-quick not found**
- **Cause**: wg-quick requires bash, but system was using sh
- **Solution**: Use `/usr/bin/bash` explicitly instead of `sh`

**Problem 3: resolvconf errors**
- **Cause**: NanoKVM doesn't have resolvconf installed
- **Solution**: Create dummy resolvconf script and set `RESOLVCONF=:` environment variable

**Problem 4: Windows line endings**
- **Cause**: Scripts edited on Windows have CRLF endings
- **Solution**: Run `sed -i 's/\r$//' filename` on all scripts

**Problem 5: Cannot type in text areas**
- **Cause**: Global keyboard handler capturing all keystrokes for KVM control
- **Solution**: Check if target is input/textarea and skip interception

**Problem 6: Routing broke SSH**
- **Cause**: WireGuard `AllowedIPs = 0.0.0.0/0` routed all traffic through VPN
- **Solution**: User modified WireGuard config to use specific routes

**Problem 7: Build failed on Windows**
- **Cause**: Cannot cross-compile RISC-V with CGO on Windows
- **Solution**: Use WSL2 with Ubuntu for cross-compilation

---

## TESTING CHECKLIST

### 12. Verification Steps

After deploying to a fresh NanoKVM installation:

**Backend Tests**:
- [ ] SSH to device works
- [ ] API endpoints respond: `curl http://10.24.69.63/api/extensions/wireguard/status`
- [ ] WireGuard interface can start: `ssh root@10.24.69.63 "wg show"`
- [ ] Config can be saved to `/etc/wireguard/wg0.conf`

**Frontend Tests**:
- [ ] WireGuard menu item appears in Settings
- [ ] Can type in configuration text area
- [ ] "Generate New Keys" button works
- [ ] "Load Example Template" button works
- [ ] "Save Configuration" button saves config
- [ ] Start/Stop/Restart buttons function properly
- [ ] Status shows "Connected" when running
- [ ] Peer information displays correctly

**Auto-Start Tests**:
- [ ] Reboot NanoKVM
- [ ] WireGuard starts automatically if config exists
- [ ] Interface `wg0` is up after boot
- [ ] `wg show` displays active connection

**UI Tests**:
- [ ] All labels are human-readable
- [ ] Button text makes sense
- [ ] Status indicators are clear
- [ ] No TypeScript errors in console

---

## FILES TO MODIFY ON FRESH INSTALL

### 13. Quick Reference Checklist

When updating to a new NanoKVM version from GitHub:

**New Files to Create**:
1. `server/service/extensions/wireguard/cli.go`
2. `server/service/extensions/wireguard/service.go`
3. `server/service/extensions/wireguard/config.go`
4. `server/router/extensions.go`
5. `kvmapp/system/init.d/S40wireguard`
6. `build-wsl.sh` (project root)

**Existing Files to Modify**:
1. `server/router/router.go` - Add extensions router import
2. `web/src/pages/desktop/menu/settings/wireguard/index.tsx` - Remove install logic
3. `web/src/pages/desktop/menu/settings/wireguard/header.tsx` - Remove uninstall button
4. `web/src/pages/desktop/menu/settings/wireguard/config.tsx` - Add keyboard handlers
5. `web/src/pages/desktop/menu/settings/wireguard/device.tsx` - Clean imports
6. `web/src/pages/desktop/keyboard/index.tsx` - Add shouldIgnoreEvent function
7. `web/src/i18n/locales/en.ts` - Update WireGuard translations

**Files to Check**:
- `web/src/api/extensions/wireguard.ts` - Should already exist

---

## CONFIGURATION EXAMPLE

### 14. Sample WireGuard Configuration

**Example `wg0.conf`**:
```ini
[Interface]
PrivateKey = <your-private-key>
Address = 10.8.0.8/24
DNS = 1.1.1.1

[Peer]
PublicKey = <server-public-key>
PresharedKey = <optional-preshared-key>
AllowedIPs = 10.8.0.0/24
Endpoint = wireguard.example.com:51820
PersistentKeepalive = 25
```

**Important Notes**:
- Use specific IP ranges in `AllowedIPs` to avoid routing issues
- `DNS` line is optional (resolvconf disabled anyway)
- `PersistentKeepalive` recommended for NAT traversal

---

## ADDITIONAL NOTES

### 15. Important Details

**Device Specifications**:
- CPU: RISC-V SG2002 (c906fdv core)
- RAM: 256MB
- OS: Buildroot Linux with BusyBox
- Shell: sh (symlink to busybox), bash available at `/usr/bin/bash`

**WireGuard Tools on Device**:
- `/usr/bin/wg` - WireGuard configuration utility
- `/usr/bin/wg-quick` - Interface management script (requires bash)
- Kernel module: Built-in (no wireguard-go needed)

**Build Environment**:
- Host: Windows 11 with WSL2 (Ubuntu)
- Go Version: 1.23.4 (upgraded from 1.22.2)
- Toolchain: riscv64-unknown-linux-musl-gcc 10.2.0
- Node/pnpm: For frontend build

**Port/Protocol**:
- Backend API: HTTP/HTTPS on port 80/443
- WireGuard: UDP on configured port (default 51820)

**Security Considerations**:
- Config file permissions: 0600 (read/write owner only)
- Config directory: /etc/wireguard (mode 0700)
- No password required for wg commands (root access)

---

## KNOWN LIMITATIONS

### 16. Current Constraints

1. **Single Interface Only**: Only supports `wg0` interface
2. **No DNS Management**: resolvconf disabled (not available)
3. **Manual Config**: No automatic server connection wizard
4. **No QR Code**: Cannot generate mobile config QR codes
5. **Limited Validation**: Minimal config syntax checking
6. **No Backup**: No automatic config backup/restore
7. **English Only**: Translations only updated for English locale

---

## FUTURE ENHANCEMENTS

### 17. Potential Improvements

- [ ] Support multiple WireGuard interfaces (wg1, wg2, etc.)
- [ ] Add config validation before saving
- [ ] Implement config backup/restore
- [ ] Add connection statistics graphs
- [ ] QR code generation for mobile clients
- [ ] Config wizard for common providers
- [ ] Add translations for other languages
- [ ] Traffic statistics and bandwidth monitoring
- [ ] Connection logs viewer
- [ ] Automatic key rotation

---

## TROUBLESHOOTING

### 18. Common Issues

**Issue**: Interface won't start
- Check: `/usr/bin/wg-quick` has execute permission
- Check: Config file exists at `/etc/wireguard/wg0.conf`
- Check: No syntax errors in config
- Test: `ssh root@10.24.69.63 "/usr/bin/bash /usr/bin/wg-quick up wg0"`

**Issue**: Cannot type in config editor
- Check: Frontend deployed correctly
- Check: Browser cache cleared
- Check: Console for JavaScript errors

**Issue**: Auto-start not working
- Check: `/etc/init.d/S40wireguard` exists and is executable
- Check: Script has Unix line endings (not Windows)
- Test: `ssh root@10.24.69.63 "/etc/init.d/S40wireguard start"`

**Issue**: Buttons do nothing
- Check: Backend deployed and running
- Check: NanoKVM service restarted after backend deployment
- Check: Browser network tab for API errors

**Issue**: "Failed to start WireGuard"
- Check: bash is available: `which bash`
- Check: resolvconf dummy script exists
- Check: Endpoint is reachable
- Check: Firewall allows UDP on WireGuard port

---

## VERSION HISTORY

**v1.0 - November 19, 2025**
- Initial WireGuard integration
- Full backend API implementation
- Frontend UI with config editor
- Auto-start functionality
- Keyboard input fix
- Improved translations

---

## CONTACT & SUPPORT

If issues arise after applying these modifications:
1. Check logs: `ssh root@10.24.69.63 "dmesg | grep wireguard"`
2. Verify backend: `ssh root@10.24.69.63 "ps aux | grep NanoKVM-Server"`
3. Test manually: `ssh root@10.24.69.63 "wg show"`
4. Review this document for missed steps

---

**End of Modification Guide**
