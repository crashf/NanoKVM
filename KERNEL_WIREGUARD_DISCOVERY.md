# IMPORTANT DISCOVERY: NanoKVM Has Native WireGuard Support!

## Discovery Date: November 18, 2025

## What We Found

When running `wireguard-go --help` on NanoKVM, we got this message:

```
┌──────────────────────────────────────────────────────┐
│                                                      │
│   Running wireguard-go is not required because this  │
│   kernel has first class support for WireGuard. For  │
│   information on installing the kernel module,       │
│   please visit:                                      │
│         https://www.wireguard.com/install/          │
│                                                      │
└──────────────────────────────────────────────────────┘
```

## What This Means

**The NanoKVM kernel has native WireGuard support built-in!**

This is MUCH better than using wireguard-go because:
- ✅ **Better Performance** - Kernel module is faster than userspace
- ✅ **Lower Memory Usage** - No separate process needed
- ✅ **More Stable** - Kernel implementation is battle-tested
- ✅ **Simpler Setup** - Just use `ip link` and `wg` commands

## What We Need Instead

We only need **2 tools** (not 3):

1. ~~**wireguard-go**~~ ❌ NOT NEEDED - kernel has it!
2. **wg** ✅ REQUIRED - Configuration utility
3. **wg-quick** ✅ HELPFUL - Helper script (still useful)

## Revised Installation Approach

### Option 1: Use Kernel Module + wg + wg-quick

```bash
# Check if kernel module is available
modprobe wireguard
lsmod | grep wireguard

# Only need wg and wg-quick tools
# wg - for configuration
# wg-quick - for easy interface management
```

### Option 2: Check if wg is already installed

```bash
# Check if wg is already on the system
which wg
wg --version

# Check if wg-quick exists
which wg-quick
```

## Next Steps

1. **Check NanoKVM for existing WireGuard tools:**
   ```bash
   which wg
   which wg-quick
   lsmod | grep wireguard
   ```

2. **If wg exists:** We're done! Just use it.

3. **If wg doesn't exist:** We need to get only the `wg` utility (much smaller!)

## Impact on Our Implementation

### Backend Code - STILL VALID ✅
- Our Go backend code is still correct
- It uses `wg` commands, not `wireguard-go`
- No changes needed!

### Installation Script - NEEDS UPDATE ⚠️
- Don't need to download wireguard-go
- Only need wg utility
- Much smaller package (~200KB vs 4.7MB)

### CLI Wrapper - STILL VALID ✅
- Our `cli.go` already uses `wg` commands
- It will work with kernel module
- No changes needed!

### Init Script - MAY NEED ADJUSTMENT ⚠️
- Don't start wireguard-go process
- Just use `wg-quick up wg0`
- Much simpler!

## Revised Package Contents

**OLD (what we built):**
- wireguard-go (4.7 MB) ❌ Not needed
- wg-quick (14 KB) ✅ Still useful
- wg (missing) ⚠️ Need this

**NEW (what we actually need):**
- wg (~200 KB) ✅ REQUIRED
- wg-quick (14 KB) ✅ HELPFUL

Total: ~215 KB instead of 4.7 MB! 🎉

## Testing Commands

```bash
# 1. Check kernel module
lsmod | grep wireguard
# If not loaded:
modprobe wireguard

# 2. Create interface using kernel
ip link add wg0 type wireguard

# 3. Configure with wg command
wg setconf wg0 /etc/wireguard/wg0.conf

# 4. Bring up interface
ip link set wg0 up

# OR use wg-quick for all of the above:
wg-quick up wg0
```

## Updated Init Script Approach

Instead of starting wireguard-go, the init script should:

```bash
#!/bin/sh

case "$1" in
    start)
        # Load kernel module
        modprobe wireguard
        
        # Start with wg-quick
        wg-quick up wg0
        ;;
    stop)
        wg-quick down wg0
        ;;
    restart)
        $0 stop
        $0 start
        ;;
esac
```

## Action Items

- [ ] Check if wg utility is already installed on NanoKVM
- [ ] Check if wg-quick is already installed
- [ ] Verify kernel module is available: `modprobe wireguard`
- [ ] Test creating interface: `ip link add wg0 type wireguard`
- [ ] If wg is missing, obtain just the wg binary (~200KB)
- [ ] Update init script to use kernel module
- [ ] Update backend install.go to not install wireguard-go
- [ ] Test with kernel module instead

## Priority

**FIRST: Check what's already available on NanoKVM**

Run these commands:
```bash
# Check for wg
which wg
wg --version

# Check for wg-quick
which wg-quick

# Check kernel module
lsmod | grep wireguard
modprobe wireguard && echo "Module loaded!"

# Try creating interface
ip link add wg0 type wireguard && echo "Kernel support confirmed!"
ip link del wg0  # Clean up
```

This will tell us exactly what we need to provide!
