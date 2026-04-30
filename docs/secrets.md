# Secrets Management

This repository uses [sops-nix](https://github.com/Mic92/sops-nix) for secrets.

## How it works

1. Each host has an **age key** derived from its SSH host ed25519 key
2. Secrets are encrypted in `secrets/<host>/secrets.yaml` using [sops](https://github.com/getsops/sops)
3. At build time, sops-nix decrypts secrets to `/run/secrets/<name>`

## Bootstrap a new host

1. Install the host (NixOS or darwin)
2. Get the host's age public key:
   ```sh
   ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
   ```
3. Add the key to `.sops.yaml` under the appropriate creation rule
4. Create `secrets/<hostname>/secrets.yaml`:
   ```sh
   sops secrets/<hostname>/secrets.yaml
   ```
5. Add a `sops.nix` module to the host importing the secrets file
6. Reference secrets via `/run/secrets/<name>` or `config.sops.secrets.<name>.path`

## Edit existing secrets

```sh
sops secrets/chopper/secrets.yaml
```

## Rotate keys

If a host's SSH key changes:
1. Get the new age key: `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`
2. Update `.sops.yaml`
3. Re-encrypt: `sops updatekeys secrets/chopper/secrets.yaml`

## Current secrets

| Host | Secret | Used by |
|------|--------|---------|
| chopper | `tailscale-auth-key` | `services.tailscale.authKeyFile` |
| chopper | `nextcloud-admin-pass` | `services.nextcloud.config.adminpassFile` |
| chopper | `cloudflared-tunnel-credentials` | `services.cloudflared.tunnels.*.credentialsFile` |
