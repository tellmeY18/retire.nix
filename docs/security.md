# Security

This document describes the security posture of this Nix configuration and
the rationale behind key decisions.

## Threat model

This configuration manages:
- **chopper** — a personal laptop that also runs services (Nextcloud,
  Matrix/conduwuit) exposed via Cloudflare Tunnel. It is NOT directly
  internet-facing.
- **Vysakhs-MacBook-Pro** — a personal development machine.

Neither host is a production server. The primary threats are:
1. Unauthorized SSH access to chopper
2. Secret leakage from the repository
3. Service compromise via exposed ports

## SSH

- **Password authentication** is disabled globally (`PasswordAuthentication = false`).
- **Root login** is restricted to **key-based only** (`PermitRootLogin = "prohibit-password"`).
  If root SSH is unnecessary, change to `"no"`.
- **Authorized keys** are managed declaratively in `users/<name>.nix`.

## Sudo

- Wheel group **requires a password** (`wheelNeedsPassword = true`).
- If specific automation requires passwordless sudo, add a targeted
  `security.sudo.extraRules` entry instead of blanket NOPASSWD.

## Firewall

- Only **port 22 (SSH)** is open on the external interface.
- All web services (Nextcloud, conduwuit, care) bind to `localhost` and
  are exposed exclusively via **Cloudflare Tunnel** (`cloudflared`).
- The Tailscale interface (`tailscale0`) is fully trusted.
- UDP port for Tailscale's WireGuard is open.

## Secrets

- Managed via **sops-nix** (see `docs/secrets.md`).
- Age keys are derived from each host's SSH host key.
- No plaintext secrets in the repository.
- Secrets are decrypted at boot to `/run/secrets/` (tmpfs).

## Insecure packages

| Package | Reason | Tracking |
|---------|--------|----------|
| `conduwuit-0.4.6` | Flagged insecure by nixpkgs but is the latest conduwuit release. Matrix homeserver functionality requires it. | Remove when a non-flagged version is available in nixpkgs. |

## Recommendations

- [ ] Consider `PermitRootLogin = "no"` if root SSH is never used.
- [ ] Regularly rotate sops age keys (see `docs/secrets.md`).
- [ ] Review `networking.firewall.allowedTCPPorts` when adding new services.
- [ ] Consider fail2ban or SSHGuard for brute-force protection.
