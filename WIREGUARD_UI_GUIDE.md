# WireGuard UI - Already Available!

## Summary
The WireGuard management interface **already exists** in NanoKVM! It's fully functional and accessible through the desktop menu.

## How to Access

1. Open NanoKVM web interface
2. Click the **menu icon** in the top-left of the desktop view
3. Navigate to **Settings** → **WireGuard**

## Features Available

### Status Tab
- View connection status (Running/Stopped/Connected)
- See interface details (wg0)
- View public key
- Monitor peers and their status
- See data transfer statistics
- Start/Stop/Restart buttons

### Configuration Tab
- **Upload configuration file** (.conf file)
- **Edit configuration** in text editor
- **Generate keypair** button
- **Load template** with example config
- **Save configuration** button
- Syntax highlighting and validation

## Backend API Endpoints

The following endpoints are already implemented and working:

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/extensions/wireguard/status` | Get WireGuard status |
| POST | `/api/extensions/wireguard/start` | Start WireGuard |
| POST | `/api/extensions/wireguard/stop` | Stop WireGuard |
| POST | `/api/extensions/wireguard/restart` | Restart WireGuard |
| POST | `/api/extensions/wireguard/up` | Bring interface up |
| POST | `/api/extensions/wireguard/down` | Bring interface down |
| GET | `/api/extensions/wireguard/config` | Get configuration |
| POST | `/api/extensions/wireguard/config` | Save configuration |
| POST | `/api/extensions/wireguard/genkey` | Generate keypair |
| GET | `/api/extensions/wireguard/peers` | Get peer list |

## Quick Start Guide

### Method 1: Upload Configuration File

1. Get your WireGuard configuration file (`.conf`) from your VPN provider or server
2. Open NanoKVM → Settings → WireGuard
3. Click **"Upload Config File"** button
4. Select your `.conf` file
5. Click **"Save Configuration"**
6. Go to Status tab and click **"Start"**

### Method 2: Manual Configuration

1. Open NanoKVM → Settings → WireGuard
2. Go to Configuration tab
3. Click **"Generate Keys"** to create a new keypair (save the keys!)
4. Click **"Load Template"** to get a starter configuration
5. Edit the configuration:
   - Replace `YOUR_PRIVATE_KEY_HERE` with your generated private key
   - Replace `SERVER_PUBLIC_KEY_HERE` with your VPN server's public key
   - Update `Endpoint` with your server address (e.g., `vpn.example.com:51820`)
   - Adjust `Address` if needed (your VPN IP)
   - Update `AllowedIPs` as needed
6. Click **"Save Configuration"**
7. Go to Status tab and click **"Start"**

### Method 3: Paste Configuration

1. Copy your WireGuard configuration from your VPN provider
2. Open NanoKVM → Settings → WireGuard → Configuration tab
3. Paste the configuration into the text editor
4. Click **"Save Configuration"**
5. Go to Status tab and click **"Start"**

## Example Configuration

```ini
[Interface]
# Private key for this NanoKVM device
PrivateKey = YOUR_PRIVATE_KEY_HERE
# IP address for this device on the VPN network
Address = 10.0.0.2/24
# DNS servers (optional)
DNS = 1.1.1.1

[Peer]
# Public key of your VPN server
PublicKey = SERVER_PUBLIC_KEY_HERE
# Endpoint address and port of your VPN server
Endpoint = vpn.example.com:51820
# Which IP addresses to route through VPN (0.0.0.0/0 = all traffic)
AllowedIPs = 0.0.0.0/0, ::/0
# Keep connection alive through NAT (optional, in seconds)
PersistentKeepalive = 25
```

## File Locations

### Frontend Components
- Main component: `web/src/pages/desktop/menu/settings/wireguard/index.tsx`
- Configuration editor: `web/src/pages/desktop/menu/settings/wireguard/config.tsx`
- Device/status view: `web/src/pages/desktop/menu/settings/wireguard/device.tsx`
- Header controls: `web/src/pages/desktop/menu/settings/wireguard/header.tsx`
- API client: `web/src/api/extensions/wireguard.ts`

### Backend Code
- Service: `server/service/extensions/wireguard/service.go`
- CLI wrapper: `server/service/extensions/wireguard/cli.go`
- Config manager: `server/service/extensions/wireguard/config.go`
- Router: `server/router/extensions.go`

### Configuration Files
- WireGuard config: `/etc/wireguard/wg0.conf` (created when you save)

## Translations

The UI is fully translated in 3 languages:
- English (`web/src/i18n/locales/en.ts`)
- Chinese (`web/src/i18n/locales/zh.ts`)
- Japanese (`web/src/i18n/locales/ja.ts`)

## Technical Notes

### Native WireGuard Support
- NanoKVM has WireGuard kernel module **built-in**
- The `wg` utility (v1.0.20210914) is **pre-installed** at `/usr/bin/wg`
- No need to install wireguard-go or additional binaries
- Uses standard `wg-quick` commands for management

### Architecture
```
Web UI (React + Ant Design)
    ↓
REST API (/api/extensions/wireguard/...)
    ↓
Go Backend Service
    ↓
wg-quick utility
    ↓
Linux Kernel WireGuard Module
```

## Troubleshooting

### Configuration Won't Save
- Check that the configuration has `[Interface]` section
- Ensure `PrivateKey` is present in `[Interface]`
- Verify the configuration syntax

### Won't Start
- Check that configuration file exists at `/etc/wireguard/wg0.conf`
- Verify the endpoint address is reachable
- Check that the private key is valid

### No Connection to Peers
- Verify the server's public key is correct
- Check that the endpoint (server address:port) is reachable
- Ensure `AllowedIPs` includes the ranges you want to route
- Check firewall rules on both sides

### View Logs
You can check WireGuard status and logs:
```bash
# Check interface status
wg show

# Check if interface is up
ip link show wg0

# View configuration
cat /etc/wireguard/wg0.conf
```

## Next Steps

1. **Test the existing UI** - Open the desktop menu and navigate to Settings → WireGuard
2. **Upload your config** - Use the upload button to add your VPN configuration
3. **Generate keys if needed** - Use the "Generate Keys" button for new setups
4. **Start the connection** - Click the Start button on the Status tab
5. **Monitor connection** - Watch the peer status and data transfer

## Important Notes

- The UI is **already fully functional** - no additional development needed!
- Configuration file location: `/etc/wireguard/wg0.conf`
- Backend uses native kernel WireGuard (no userspace implementation)
- All the code you need is already in place and working
- The interface supports standard WireGuard .conf files

## Additional Features Implemented

- ✅ Real-time status updates
- ✅ Peer monitoring with handshake times
- ✅ Data transfer statistics (sent/received bytes)
- ✅ Key generation utility
- ✅ Configuration file upload
- ✅ Configuration templates
- ✅ Multi-language support (EN/ZH/JA)
- ✅ Start/Stop/Restart controls
- ✅ Interface up/down control
- ✅ Configuration validation
