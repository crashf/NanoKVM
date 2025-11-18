# WireGuard RISC-V64 Binaries for NanoKVM

## Contents
- wireguard-go: WireGuard userspace implementation
- wg: WireGuard configuration utility
- wg-quick: Helper script for interface management

## Installation on NanoKVM

1. Upload this archive to your NanoKVM device
2. Extract: `tar xzf wireguard-riscv64.tar.gz`
3. Install: `mv wireguard-go wg wg-quick /usr/bin/`
4. Set permissions: `chmod +x /usr/bin/wireguard-go /usr/bin/wg /usr/bin/wg-quick`
5. Verify: `wireguard-go --version` and `wg --version`

## Usage

Start WireGuard interface:
```bash
wireguard-go wg0
wg setconf wg0 /etc/wireguard/wg0.conf
ip link set wg0 up
```

Or use wg-quick:
```bash
wg-quick up wg0
```

## Building from Source

See build-wireguard-riscv64.sh or build-wireguard-riscv64.ps1

## Architecture
- Built for: linux/riscv64
- Target device: NanoKVM (LicheeRV Nano, SG2002)
