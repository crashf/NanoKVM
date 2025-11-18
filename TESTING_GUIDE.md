# Testing WireGuard on NanoKVM - Quick Start Guide

## Package Information

**File:** `wireguard-riscv64-partial.tar.gz` (2.6 MB)
**Contents:**
- wireguard-go (4.7 MB) - WireGuard VPN implementation
- wg-quick (14 KB) - Interface management script
- README.md - Documentation

**Note:** This is a partial package without the `wg` utility. The `wg` command is used for advanced CLI configuration, but the core functionality works without it. You can add it later.

## Prerequisites

1. **NanoKVM device** running and accessible via SSH
2. **Network connectivity** to NanoKVM
3. **Root access** to NanoKVM
4. **Basic Linux knowledge**

## Step 1: Upload Package to NanoKVM

### Method A: Using SCP (Recommended)
```powershell
# From Windows PowerShell (adjust IP address)
scp wireguard-riscv64-partial.tar.gz root@192.168.1.100:/tmp/
```

### Method B: Using Web Interface
If NanoKVM has a file upload feature:
1. Open NanoKVM web interface
2. Navigate to file upload
3. Upload `wireguard-riscv64-partial.tar.gz`

### Method C: Using USB Drive
1. Copy file to USB drive
2. Insert USB into NanoKVM
3. Mount and copy file

## Step 2: Install on NanoKVM

SSH into your NanoKVM:
```bash
ssh root@192.168.1.100
# Default password may be: admin or nanokvm (check documentation)
```

Extract and install:
```bash
# Go to tmp directory
cd /tmp

# Extract package (BusyBox tar - use -a for auto-decompression)
tar -xaf wireguard-riscv64-partial.tar.gz

# Verify files
ls -lh wireguard-go wg-quick

# Check architecture (should show RISC-V)
file wireguard-go

# Move to system directory
mv wireguard-go /usr/bin/
mv wg-quick /usr/bin/

# Set executable permissions
chmod +x /usr/bin/wireguard-go /usr/bin/wg-quick

# Verify installation
which wireguard-go
which wg-quick

# Test execution
wireguard-go --help
```

## Step 3: Create WireGuard Configuration Directory

```bash
# Create config directory
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard
```

## Step 4: Generate Keys

Since we don't have the `wg` utility yet, we'll use openssl or generate keys manually:

### Option A: Using OpenSSL (if available)
```bash
# Generate private key
umask 077
openssl rand -base64 32 > /etc/wireguard/privatekey

# Generate public key (requires base64 and some scripting)
# This is complex without wg utility
```

### Option B: Wait for Backend
The NanoKVM backend we built has key generation built-in! You can:
1. Start the NanoKVM backend server
2. Use the web UI to generate keys
3. Keys will be generated via the Go backend API

### Option C: Generate on Another System
If you have WireGuard installed on Windows/Linux/Mac:
```bash
# On your PC (with WireGuard installed)
wg genkey | tee privatekey | wg pubkey > publickey

# Copy these keys to NanoKVM config
```

## Step 5: Create Basic Configuration

Create a test configuration file:
```bash
cat > /etc/wireguard/wg0.conf << 'EOF'
[Interface]
PrivateKey = YOUR_PRIVATE_KEY_HERE
Address = 10.0.0.2/24
ListenPort = 51820

# Optional: DNS
# DNS = 1.1.1.1

# Optional: Route all traffic through VPN
# Table = auto

[Peer]
PublicKey = SERVER_PUBLIC_KEY_HERE
Endpoint = your-vpn-server.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

# Secure the config file
chmod 600 /etc/wireguard/wg0.conf
```

## Step 6: Test WireGuard Manually

### Test 1: Start wireguard-go
```bash
# Start WireGuard interface (foreground for testing)
wireguard-go -f wg0
# Press Ctrl+C to stop

# Or run in background
wireguard-go wg0
```

### Test 2: Configure Interface (without wg utility)
Since we don't have `wg` yet, we can still test basic functionality:

```bash
# Start wireguard-go
wireguard-go wg0

# Check if interface was created
ip link show wg0

# Manually assign IP (from your config)
ip addr add 10.0.0.2/24 dev wg0
ip link set wg0 up

# Check status
ip addr show wg0

# Test connectivity (if you have a peer configured)
ping 10.0.0.1
```

### Test 3: Using wg-quick (Easier)
```bash
# This requires proper config in /etc/wireguard/wg0.conf
wg-quick up wg0

# Check status
ip addr show wg0

# Bring down
wg-quick down wg0
```

## Step 7: Test with NanoKVM Backend

Now test the integration with your NanoKVM backend:

### Start Backend Server
```bash
cd /path/to/nanokvm/server
./server  # Or however the server is started
```

### Test API Endpoints

From another terminal or using curl:

```bash
# Check WireGuard status
curl -X GET http://localhost:8080/api/extensions/wireguard/status

# Generate keys via API
curl -X POST http://localhost:8080/api/extensions/wireguard/genkey

# Start WireGuard
curl -X POST http://localhost:8080/api/extensions/wireguard/start
```

### Test Web UI
1. Open NanoKVM web interface
2. Navigate to Settings → WireGuard
3. Should see WireGuard settings page
4. Try generating keys via UI
5. Try saving configuration
6. Try starting/stopping service

## Step 8: Verify Installation

Check that everything is working:

```bash
# 1. Check if wireguard-go is running
ps aux | grep wireguard-go

# 2. Check interface status
ip link show wg0

# 3. Check if init script is installed
ls -l /etc/init.d/S97wireguard

# 4. Check logs (if any)
logread | grep -i wireguard

# 5. Memory usage
free -h
ps aux | grep wireguard-go | awk '{print $6}'
```

## Troubleshooting

### Issue: "Permission denied" when running wireguard-go
```bash
chmod +x /usr/bin/wireguard-go
```

### Issue: "Cannot create TUN device"
```bash
# Check if TUN module is loaded
lsmod | grep tun

# Load TUN module if needed
modprobe tun
```

### Issue: Interface doesn't start
```bash
# Check if interface already exists
ip link show wg0

# Remove existing interface
ip link del wg0

# Try again
wireguard-go wg0
```

### Issue: Out of memory
```bash
# Check available memory
free -h

# Set memory limit (as mentioned in backend code)
export GOMEMLIMIT=75MiB
wireguard-go wg0
```

### Issue: Cannot connect to peer
```bash
# Check firewall
iptables -L

# Check if packets are being sent/received
tcpdump -i wg0

# Check routing
ip route
```

## Adding wg Utility Later

When you obtain the `wg` binary:

```bash
# Upload and install
scp wg root@nanokvm:/tmp/
ssh root@nanokvm
mv /tmp/wg /usr/bin/
chmod +x /usr/bin/wg

# Test
wg --version

# Now you can use wg commands:
wg show
wg show wg0
wg set wg0 peer PUBLIC_KEY endpoint 1.2.3.4:51820
```

## Performance Testing

Once running, test performance:

```bash
# 1. Bandwidth test (if you have iperf)
iperf3 -c 10.0.0.1

# 2. Latency test
ping -c 10 10.0.0.1

# 3. Memory usage over time
watch -n 5 'free -h && ps aux | grep wireguard'

# 4. CPU usage
top -b -n 1 | grep wireguard
```

## Expected Results

### Successful Installation:
- ✅ wireguard-go runs without errors
- ✅ wg0 interface is created
- ✅ Memory usage stays under 100MB
- ✅ Can ping through VPN tunnel
- ✅ Web UI shows WireGuard status

### Known Limitations (without wg utility):
- ⚠️ Cannot use `wg show` commands
- ⚠️ Cannot dynamically add/remove peers via CLI
- ⚠️ Cannot view handshake status via CLI
- ✅ BUT: All of this works through the web UI!

## Next Steps After Successful Test

1. **Host the Package:**
   - Create GitHub release in your fork
   - Upload wireguard-riscv64-partial.tar.gz
   - Get download URL

2. **Update Backend Code:**
   - Edit `server/service/extensions/wireguard/install.go`
   - Update `getDownloadURL()` function with real URL

3. **Enable Auto-Install:**
   - Test installation through web UI
   - Verify automatic installation works
   - Test uninstall feature

4. **Add wg Utility:**
   - Obtain wg binary (via Docker/Alpine/build)
   - Create complete package
   - Update hosted file

5. **Production Testing:**
   - Test on fresh NanoKVM device
   - Test with real VPN server
   - Verify auto-start on boot
   - Monitor memory usage over time

## Support & Documentation

- **Backend API:** See `server/service/extensions/wireguard/`
- **Frontend UI:** See `web/src/pages/desktop/menu/settings/wireguard/`
- **Init Script:** See `kvmapp/system/init.d/S97wireguard`
- **Build Guide:** See `BUILDING_WIREGUARD.md`
- **Integration Doc:** See `WIREGUARD_INTEGRATION.md`

## Questions to Answer During Testing

- [ ] Does wireguard-go start successfully?
- [ ] Is the wg0 interface created?
- [ ] What is the memory footprint?
- [ ] Can you establish a VPN connection?
- [ ] Does the web UI work correctly?
- [ ] Does auto-start on boot work?
- [ ] Are there any error messages?
- [ ] What is the performance like?

---

**Ready to test!** Upload the package to your NanoKVM and follow these steps. Report back with results!
