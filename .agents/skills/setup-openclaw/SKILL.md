---
name: setup-openclaw
description: End-to-end OpenClaw gateway bootstrap on a NixOS host — flake config, sops secrets, Tailscale Serve, device pairing, Signal channel, and troubleshooting.
---

# OpenClaw Setup — End-to-End

Sets up the OpenClaw gateway on a NixOS host (`services.openclaw-gateway`) with:
- Token-based auth via sops-nix
- HTTPS via Tailscale Serve
- Declarative permission self-healing via tmpfiles
- Telegram + Signal messenger channels

---

## 1. Flake integration

Add `nix-openclaw` to `flake.nix` inputs (done on this repo already):

```nix
nix-openclaw = {
  url = "github:openclaw/nix-openclaw";
  # Intentionally NOT following nixpkgs — lets the upstream flake use its
  # own pinned revision so Garnix binary cache hits.
};
```

Also add `openclaw-signal-custom` package (Signal channel plugin):

```nix
# In overlays/default.nix — custom-packages overlay:
openclaw-signal-custom = final.callPackage ../packages/openclaw-signal-custom/default.nix { };
```

Import the NixOS module and pin the package in the host's `extraModules`:

```nix
inputs.nix-openclaw.nixosModules.openclaw-gateway
({ lib, ... }: {
  services.openclaw-gateway.package = lib.mkForce
    inputs.nix-openclaw.packages.x86_64-linux.openclaw-gateway;
})
```

Add `cache.garnix.io` to `nix.settings.substituters` and `trusted-public-keys`
— see `../modules/binary-cache.nix`.

---

## 2. Sops secrets — `hosts/<name>/sops.nix`

All secrets consumed by the gateway must be readable by the `openclaw` system
user (not root):

```nix
"openclaw-gateway-token" = {
  owner = "openclaw";
  group = "openclaw";
  mode = "0400";
};
"openclaw-anthropic-key" = {
  owner = "openclaw";
  group = "openclaw";
  mode = "0400";
};
"openclaw-telegram-token" = {
  owner = "openclaw";
  group = "openclaw";
  mode = "0400";
};
"openclaw-signal-number" = { };  # just documented here; see step 5.2
```

Encrypt the values:

```bash
just secrets <host>
# Add keys:
#   openclaw-gateway-token:   <openssl rand -hex 32>
#   openclaw-anthropic-key:   <your Anthropic API key>
#   openclaw-telegram-token:  <your Telegram bot token>
#   openclaw-signal-number:   <"+15551234567">
```

---

## 3. NixOS config — `hosts/<name>/parts/services.nix`

### 3.1 Declarative permission self-heal

Add a tmpfiles `Z` rule so runtime files created by root-run tooling
(e.g. `openclaw devices approve`) don't wedge the gateway:

```nix
systemd.tmpfiles.rules = [
  "Z /var/lib/openclaw 0750 openclaw openclaw - -"
];
```

### 3.2 Gateway service

```nix
services.openclaw-gateway = {
  enable = true;
  port = 18789;

  config = {
    gateway.mode = "local";

    # Signal messenger channel config.
    channels.signal-custom = {
      configPath = "/var/lib/signal-cli";
      autoStart = true;
    };
  };

  environment = {
    ANTHROPIC_API_KEY  = config.sops.secrets.openclaw-anthropic-key.path;
    TELEGRAM_BOT_TOKEN = config.sops.secrets.openclaw-telegram-token.path;
  };

  # signal-cli and the Signal plugin source on PATH.
  servicePath = [
    pkgs.signal-cli
    pkgs.openclaw-signal-custom
  ];

  # OPENCLAW_GATEWAY_TOKEN must be the *value* of the token, not a file path.
  execStart = let
    pkg       = config.services.openclaw-gateway.package;
    port      = toString config.services.openclaw-gateway.port;
    tokenPath = config.sops.secrets.openclaw-gateway-token.path;

    wrapper = pkgs.writeScript "openclaw-gateway-wrapper" ''
      #!${pkgs.bash}/bin/bash
      export OPENCLAW_GATEWAY_TOKEN="$(cat ${tokenPath})"
      exec ${pkg}/bin/openclaw gateway --auth token --port ${port}
    '';
  in "${wrapper}";

  # Install the Signal plugin on first boot.
  execStartPre = let
    gwPkg = config.services.openclaw-gateway.package;
    pluginSrc = "${pkgs.openclaw-signal-custom}";
  in [
    (let
      installPlugin = pkgs.writeScript "install-signal-plugin" ''
        #!${pkgs.bash}/bin/bash
        set -e
        if ! ${gwPkg}/bin/openclaw plugins inspect signal-custom &>/dev/null; then
          cd "${pluginSrc}"
          ${gwPkg}/bin/openclaw plugins install -l . --link
        fi
      '';
    in installPlugin)
  ];
};

# signal-cli on PATH for interactive use.
environment.systemPackages = [ pkgs.signal-cli ];
```

Key points:
- `--auth token` tells the gateway to use token-based auth.
- The wrapper script reads the sops file into `OPENCLAW_GATEWAY_TOKEN`.
- `execStartPre` installs the Signal plugin only once.

### 3.3 Tailscale Serve oneshot

Proxies `https://<host>.ts.net` → `http://127.0.0.1:18789` so the control UI
gets a secure context (required for WebRTC device identity):

```nix
systemd.services.tailscale-serve-openclaw = {
  description = "Tailscale Serve proxy for OpenClaw gateway";
  after = [ "tailscaled.service" ];
  wants = [ "tailscaled.service" ];
  wantedBy = [ "multi-user.target" ];
  path = [ pkgs.tailscale ];
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --https 443 http://127.0.0.1:18789";
  };
};
```

### 3.4 Firewall

Port 18789 does NOT need to be open in the firewall. Tailscale Serve binds on
port 443 on the tailscale interface. Remove it from `networking.firewall.allowedTCPPorts`.

---

## 4. Deploy

```bash
just deploy <host>
```

After deploy, the gateway starts but requires **device pairing** (step 5) before
a browser can connect.

---

## 5. Device pairing (imperative)

The control UI uses device identity (WebRTC) for auth. The first browser visit
triggers a pairing request that must be approved on the gateway host.

### 5.1 Open the control UI

Navigate to `https://<host>.tail<N>.ts.net/chat?session=main` in a browser.

The page will show: *"Device pairing required"* with a request ID.

### 5.2 Approve the device

SSH into the host and approve the pending request:

```bash
ssh root@<host>
OPENCLAW_GATEWAY_TOKEN="$(cat /run/secrets/openclaw-gateway-token)" \
  /nix/store/*openclaw*/bin/openclaw devices approve <request-id>
```

The `request-id` is shown in the browser error message (e.g.
`0b6592f8-fc8b-433e-8260-b239c4836861`).

### 5.3 Reconnect

Refresh the browser page. The connection should complete.

---
|------

## 6. Signal messenger setup (imperative — Nix mode caveat)

The gateway runs in Nix mode (`OPENCLAW_NIX_MODE=1`), which protects the
config and plugins from runtime modification. This means `openclaw plugins
install` is blocked at runtime (the gateway's config is immutable from the
CLI).

The Signal plugin must therefore be installed **outside Nix mode** — either
by temporarily disabling it, or by pre-building the plugin into a Nix package
and symlinking it into the plugin-skills directory (not yet implemented in
this repo).

### 6.1 Prerequisites

```bash
# signal-cli is already installed declaratively
which signal-cli
```

### 6.2 Manual plugin install (outside Nix mode)

On a non-Nix-mode gateway (e.g. a dev instance), install the plugin:

```bash
cd /tmp
git clone https://github.com/kaikozlov/openclaw-signal-custom
cd openclaw-signal-custom
pnpm install --frozen-lockfile
openclaw plugins install -l . --link
```

### 6.3 Register the Signal number

```bash
# Register the phone number with Signal
signal-cli -u "+15551234567" register

# Check the SMS code and verify
signal-cli -u "+15551234567" verify <code-from-sms>
```

### 6.4 Configure the gateway channel

```bash
# Point the plugin at the registered account
openclaw config set channels.signal-custom.account '"+15551234567"'
openclaw config set channels.signal-custom.configPath '"/var/lib/signal-cli"'
systemctl restart openclaw-gateway
```

### 6.5 Verify

```bash
cat /var/lib/openclaw/logs/gateway.log | grep -i signal
```

---You should see the Signal channel starting successfully.

---

## 7. Troubleshooting

### 7.1 "auth token was missing" in gateway logs

Check `/var/lib/openclaw/logs/gateway.log`:

```
auth token was missing. Generated a runtime token for this startup
```

**Cause:** The `OPENCLAW_GATEWAY_TOKEN` env var wasn't set or was unreadable.

**Fix:**
1. Verify the sops secret exists and is readable by `openclaw`:
   ```bash
   sudo -u openclaw cat /run/secrets/openclaw-gateway-token
   ```
2. Check the wrapper script has the correct token path:
   ```bash
   systemctl cat openclaw-gateway | grep ExecStart
   ```

### 7.2 "Permission denied" reading device JSON files

```
JsonFileReadError: EACCES: permission denied, open '.../paired.json'
```

**Cause:** A root-run command (e.g. `openclaw devices approve` over SSH) created
files owned by `root` that the `openclaw` user can't read.

**Fix:** Fix ownership and restart:
```bash
chown -R openclaw:openclaw /var/lib/openclaw
systemctl restart openclaw-gateway
```

The tmpfiles `Z` rule prevents recurrence on subsequent boots.

### 7.3 "Secure browser context required"

```
control ui requires device identity (use HTTPS or localhost secure context)
```

**Cause:** The control UI's WebRTC device-identity API requires a secure context
(HTTPS or localhost). Plain HTTP from a remote host won't work.

**Fix:** Use Tailscale Serve (see section 3.3). Access via
`https://<host>.ts.net` instead of `http://<host>:18789`.

### 7.4 "Auth did not match" / "token_mismatch"

```
ws unauthorized ... reason=token_mismatch
```

**Cause:** The gateway token in the browser doesn't match the gateway's
configured token.

**Fix:** Ensure `--auth token` is on the gateway command and the
`OPENCLAW_GATEWAY_TOKEN` env var contains the correct value.

After setting `OPENCLAW_GATEWAY_TOKEN`, restart the service so it picks up the
configured token instead of the runtime-generated one.

### 7.5 "Could not connect" after device approval

**Cause:** Device pairing files (`paired.json`, `pending.json`) owned by `root`
instead of `openclaw` — the gateway reads them at startup to verify device
approval status but hits EACCES.

**Fix:** Same as 7.2 — chown + restart. The tmpfiles `Z` rule handles this on
boot.

### 7.6 signal-cli "Failed to connect to Signal" / "websocket not connected"

**Cause:** Signal registration hasn't completed, or the signal-cli daemon
hasn't fully synced the message queue.

**Fix:**
```bash
# Check signal-cli status
signal-cli -u "+15551234567" getUserStatus

# If not registered, follow step 6.1
# If registered but not connected, wait for initial sync (can take a minute)
journalctl -u openclaw-gateway --no-pager -n 50 | grep -i signal
```

---

## 8. File reference

| File | Purpose |
|---|---|
| `hosts/<name>/sops.nix` | Sops secret declarations (owner: openclaw) |
| `hosts/<name>/parts/services.nix` | Gateway service + Signal plugin + Tailscale Serve |
| `hosts/<name>/parts/network.nix` | Firewall (remove port 18789) |
| `secrets/<host>/secrets.yaml` | Encrypted secret values |
| `.sops.yaml` | Encryption key groups (master + host keys) |
| `modules/binary-cache.nix` | Garnix cache for nix-openclaw |
| `packages/openclaw-signal-custom/default.nix` | Fetches Signal plugin source |
| `overlays/default.nix` | Registers openclaw-signal-custom package |
