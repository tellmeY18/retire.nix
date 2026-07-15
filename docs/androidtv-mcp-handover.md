# Android TV MCP — Session Handover

## What's set up

The OpenClaw gateway on **chopper** (`100.107.213.17`) runs an Android TV MCP
server that gives tinaku full remote control over a **Motorola Android TV** at
`192.168.1.3`.

### Architecture

```
Signal/Channel → OpenClaw Gateway (chopper:18789)
                    ↓ spawns stdio MCP
                 uvx androidtvmcp serve
                    ↓ androidtvremote2 protocol (port 6466)
                 Motorola Android TV (192.168.1.3)
                    ↓ ADB over WiFi (port 5555)
                 Full system control (input switching, shell, etc.)
```

### Working capabilities (via remote protocol)

- Navigation (DPAD, home, back, select)
- Volume control
- Media playback (play/pause/stop/ff/rw)
- App launching
- Text input
- Power on/off
- Chromecast/casting
- Arbitrary keycode sending (`atv_send_key`)
- Device discovery + pairing

### Working capabilities (via ADB — manual only, not yet in MCP)

- **Input switching** (HDMI 1/2, Composite, Component, Tuner, VGA)
- Shell commands
- App install/uninstall
- Screenshots
- Intent launching

## Key files

| File | Purpose |
|------|---------|
| `hosts/chopper/parts/services.nix` | OpenClaw gateway config with `mcp.servers.androidtv` |
| `hosts/chopper/parts/network.nix` | Firewall (UDP 5353 for mDNS discovery) |

### MCP server config (in services.nix)

```nix
mcp.servers.androidtv = {
  command = "uvx";
  args = [
    "--from"
    "androidtvmcp @ https://github.com/tellmeY18/androidtvmcp/archive/refs/heads/main.zip"
    "androidtvmcp"
    "serve"
  ];
  env = {
    UV_PYTHON_PREFERENCE = "only-system";
    C_INCLUDE_PATH = "${pkgs.linuxHeaders}/include";
  };
};
```

### Service PATH includes

- `pkgs.uv` — uvx for running the MCP server
- `pkgs.python3` — system Python (NixOS can't run downloaded FHS binaries)
- `pkgs.gcc` — C compiler for native extensions (evdev, one-time build)

## Device details

| Property | Value |
|----------|-------|
| TV brand | Motorola (MediaTek SoC) |
| IP | 192.168.1.3 |
| Remote protocol port | 6466 |
| ADB port | 5555 (authorized) |
| Device ID | `320039b6713342d87339b5971a1488d3` |
| Current app (typical) | `com.google.android.tvlauncher` |

## TV Input IDs (MediaTek)

| Friendly name | ADB input ID |
|---------------|-------------|
| HDMI 1 | `com.mediatek.tvinput/.hdmi.HDMIInputService/HW6` |
| HDMI 2 | `com.mediatek.tvinput/.hdmi.HDMIInputService/HW5` |
| Composite | `com.mediatek.tvinput/.composite.CompositeInputService/HW2` |
| Tuner 1 | `com.mediatek.tvinput/.tuner.TunerInputService/HW0` |
| Tuner 2 | `com.mediatek.tvinput/.tuner.TunerInputService/HW1` |
| Component | `com.mediatek.tvinput/.component.ComponentInputService` (check exact HW id) |
| VGA | `com.mediatek.tvinput/.vga.VGAInputService` (check exact HW id) |
| SCART | `com.mediatek.tvinput/.scart.SCARTInputService` (check exact HW id) |

### ADB input switching command

```bash
# Switch to composite
adb -s 192.168.1.3:5555 shell am start -a android.intent.action.VIEW \
  -d "content://android.media.tv/passthrough/com.mediatek.tvinput%2F.composite.CompositeInputService%2FHW2"

# Switch to HDMI 1
adb -s 192.168.1.3:5555 shell am start -a android.intent.action.VIEW \
  -d "content://android.media.tv/passthrough/com.mediatek.tvinput%2F.hdmi.HDMIInputService%2FHW6"

# Discover all inputs
adb -s 192.168.1.3:5555 shell dumpsys tv_input | grep "inputId\|state:"
```

## Pairing certs location

- `/var/lib/openclaw/.androidtv/certificates/` — used by the MCP server (openclaw user)
- `/root/.androidtv/certificates/` — root's copy (from initial pairing)

Certificates persist across reboots. The tmpfiles rule
`Z /var/lib/openclaw 0750 openclaw openclaw - -` ensures ownership.

## NixOS-specific gotchas

1. **OpenClaw blocks `C_INCLUDE_PATH`** in MCP server env (security filter).
   The `evdev` wheel must be pre-built for the `openclaw` user. If the uvx
   cache is ever cleared, rebuild with:
   ```bash
   sudo -u openclaw env HOME=/var/lib/openclaw \
     PATH="<gcc-path>/bin:<python3-path>/bin:<uv-path>/bin:/run/current-system/sw/bin" \
     UV_PYTHON_PREFERENCE=only-system \
     C_INCLUDE_PATH="<linux-headers-path>/include" \
     uvx --from "androidtvmcp @ https://github.com/tellmeY18/androidtvmcp/archive/refs/heads/main.zip" \
     androidtvmcp --version
   ```

2. **Gateway holds exclusive connection** — the remote protocol allows only one
   active client. Don't test manually while the gateway is running (stop it first).

3. **UDP 5353 (mDNS)** must be open in the firewall for device discovery.

4. **ADB auth** — the TV has authorized chopper's ADB key. If the key changes
   (e.g. new system generation with different `/root/.android/adbkey`), you'll
   need to re-authorize on the TV screen.

## Open issues on tellmeY18/androidtvmcp

- [#1](https://github.com/tellmeY18/androidtvmcp/issues/1) — `atv_send_key` for arbitrary keycodes (merged in fork)
- [#2](https://github.com/tellmeY18/androidtvmcp/issues/2) — Comprehensive ADB transport (input switching, shell, intents, screenshots)

## Next steps

1. **Implement ADB tools** in the fork (issue #2) — priority: `atv_switch_input`, `atv_list_inputs`, `atv_shell`
2. **Add `adb` to chopper's service PATH** once ADB tools are in the MCP (currently only available at root's PATH)
3. **Update to new fork version** after ADB features are merged — redeploy and rebuild uvx cache
4. **Consider persisting ADB keys** for the `openclaw` user (currently using root's `~/.android/adbkey`)

## Quick verification commands (from your Mac)

```bash
# Check gateway is running
ssh root@100.107.213.17 'systemctl is-active openclaw-gateway'

# Probe MCP tools
ssh root@100.107.213.17 'export PATH="..."; export OPENCLAW_CONFIG_PATH="/var/lib/openclaw/merged-config.json"; openclaw mcp probe androidtv --json'

# Test ADB connection
ssh root@100.107.213.17 'adb connect 192.168.1.3:5555 && adb -s 192.168.1.3:5555 shell echo OK'

# Switch TV input (direct ADB)
ssh root@100.107.213.17 'adb -s 192.168.1.3:5555 shell am start -a android.intent.action.VIEW -d "content://android.media.tv/passthrough/com.mediatek.tvinput%2F.hdmi.HDMIInputService%2FHW6"'
```
