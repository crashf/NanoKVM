# NanoKVM BusyBox Quick Reference for WireGuard

## Important: NanoKVM uses BusyBox tar

NanoKVM uses BusyBox's simplified `tar` command which has different options than GNU tar.

### ❌ WRONG (GNU tar):
```bash
tar -xzf wireguard-riscv64-partial.tar.gz  # BusyBox doesn't recognize -z
```

### ✅ CORRECT (BusyBox tar):
```bash
tar -xaf wireguard-riscv64-partial.tar.gz  # Use -a for auto-detect compression
```

## BusyBox tar Options

```
Usage: tar c|x|t [-ahvokO] [-f TARFILE] [-C DIR] [FILE]...

Key options:
  c       Create archive
  x       Extract archive
  t       List contents
  -f      Specify file
  -a      Auto-detect compression based on extension
  -v      Verbose output
  -C      Change directory before operation
```

## Complete Installation Commands for NanoKVM

```bash
# Upload file to NanoKVM first:
# scp wireguard-riscv64-partial.tar.gz root@NANOKVM_IP:/tmp/

# Then on NanoKVM:
cd /tmp
tar -xaf wireguard-riscv64-partial.tar.gz
ls -lh  # Verify: wireguard-go, wg-quick, README.md
mv wireguard-go /usr/bin/
mv wg-quick /usr/bin/
chmod +x /usr/bin/wireguard-go /usr/bin/wg-quick
wireguard-go --version  # Test installation
```

## Other BusyBox Differences to Note

### File Operations
```bash
# Create directory
mkdir -p /etc/wireguard

# Set permissions
chmod 700 /etc/wireguard
chmod 600 /etc/wireguard/wg0.conf

# Check file type
file wireguard-go  # May not show as much detail as GNU file
```

### Network Commands
```bash
# Interface management
ip link show wg0
ip addr add 10.0.0.2/24 dev wg0
ip link set wg0 up

# Check routing
ip route
```

### Process Management
```bash
# Check if running
ps aux | grep wireguard-go

# Kill process
killall wireguard-go
# or
kill $(pidof wireguard-go)
```

### System Info
```bash
# Check architecture
uname -m  # Should show: riscv64

# Check memory
free -h

# Check storage
df -h
```

## Testing Commands

```bash
# 1. Test wireguard-go
wireguard-go --help

# 2. Create test config
mkdir -p /etc/wireguard
cat > /etc/wireguard/wg0.conf << 'EOF'
[Interface]
PrivateKey = YOUR_KEY_HERE
Address = 10.0.0.2/24
ListenPort = 51820
EOF
chmod 600 /etc/wireguard/wg0.conf

# 3. Test interface creation
wireguard-go -f wg0  # Foreground mode, Ctrl+C to stop

# 4. Or use wg-quick
wg-quick up wg0      # Bring interface up
ip addr show wg0     # Verify
wg-quick down wg0    # Bring interface down
```

## Troubleshooting BusyBox Issues

### Issue: "tar: unrecognized option"
**Solution:** Use `-a` instead of `-z`, `-j`, or `-J`
```bash
tar -xaf file.tar.gz   # Good
tar -xzf file.tar.gz   # Bad - won't work
```

### Issue: Command not found
**Solution:** Check BusyBox built-ins
```bash
busybox --list  # Show all available commands
```

### Issue: Limited command options
**Solution:** Check help for available options
```bash
tar --help
ip --help
ps --help
```

### Issue: Need full-featured tools
**Solution:** Install from opkg if available
```bash
opkg update
opkg install tar  # Might install GNU tar
```

## Useful BusyBox Commands

```bash
# System info
busybox | head -n 1        # Show BusyBox version
uname -a                    # System information

# File operations
ls -lah                     # List files with details
du -sh /usr/bin/wireguard-go  # Check file size
md5sum wireguard-go         # Verify file integrity

# Network
ifconfig                    # Show interfaces (or use 'ip addr')
netstat -tulpn             # Show listening ports
ping -c 4 10.0.0.1         # Ping with count

# Processes
top                         # Resource monitor
ps                          # Process list
pidof wireguard-go         # Get PID of process

# Logs
logread                     # System log (if available)
dmesg                       # Kernel messages
```

## Package Creation (for reference)

When creating packages for NanoKVM, use `.tar.gz` extension:

```bash
# On build machine (Windows/Linux):
tar -czf wireguard-riscv64.tar.gz wireguard-go wg wg-quick

# BusyBox will auto-detect .gz compression with -a flag
```

## Summary

**Key Takeaway:** Always use `tar -xaf` on NanoKVM BusyBox!

```bash
# Good practice - always works:
tar -xaf archive.tar.gz
tar -xaf archive.tar.bz2
tar -xaf archive.tar.xz

# Bad practice - won't work:
tar -xzf archive.tar.gz   # ❌ No -z option
tar -xjf archive.tar.bz2  # ❌ No -j option
```
