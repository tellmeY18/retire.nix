# Cloudflare Tunnel & Declarative DNS

This repository exposes self-hosted services to the public internet through
[Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
(`cloudflared`). Tunnels, DNS records (CNAMEs), and ingress routes are
all **declared in one place** — the host's NixOS config — and provisioned
automatically on `nh os switch`.

There is no manual clicking in the Cloudflare dashboard, no
`cloudflared tunnel create` commands, no UUIDs in the repo, and no risk of
drift between your config and Cloudflare's state.

## Three modules, one source of truth

The flake provides three composing modules:

| Module | What it does | When it runs |
|---|---|---|
| `services.cloudflared-bootstrap` | Creates tunnels by **name** in Cloudflare if missing; writes credentials to `/var/lib/cloudflared/<name>.json` | Once per boot, before tunnels start |
| `services.cloudflared` (upstream) | Runs the tunnel daemon, routes ingress to localhost services | After bootstrap |
| `services.cloudflared-dns` | Creates Cloudflare CNAMEs for every ingress hostname | After tunnels are up |

All three read from the same `services.cloudflared.tunnels.<name>` config,
so adding a service or changing the tunnel name updates everything atomically.

---

## TL;DR — Add a new public service

To expose `example.tellmey.fyi`:

1. Make the service listen on a local port:
   ```nix
   services.example = {
     enable = true;
     listenAddress = "127.0.0.1";
     port = 9000;
   };
   ```

2. Add **one line** to the cloudflared ingress block in
   `hosts/chopper/parts/services.nix`:
   ```nix
   services.cloudflared.tunnels.chopper-main.ingress = {
     "next.tellmey.fyi"    = { service = "http://localhost:80"; };
     "chat.tellmey.fyi"    = { service = "http://localhost:6167"; };
     "example.tellmey.fyi" = { service = "http://localhost:9000"; };  # ← NEW
   };
   ```

3. Commit and deploy:
   ```sh
   git add -A && git commit -m "feat(chopper): expose example.tellmey.fyi"
   nh os switch
   ```

The DNS module picks up the new hostname, creates the CNAME, and the tunnel
starts routing traffic. Within seconds, `https://example.tellmey.fyi` is
reachable with valid TLS, DDoS protection, and zero inbound firewall rules.

---

## TL;DR — Add a new tunnel

Want a separate tunnel (e.g. for a different domain or isolation)?

1. Add the name to the bootstrap list:
   ```nix
   services.cloudflared-bootstrap.tunnels = [ "chopper-main" "chopper-staging" ];
   ```

2. Declare the tunnel's ingress, referencing the auto-generated credentials path:
   ```nix
   services.cloudflared.tunnels.chopper-staging = {
     credentialsFile = "/var/lib/cloudflared/chopper-staging.json";
     default = "http_status:404";
     ingress = {
       "staging.tellmey.fyi" = { service = "http://localhost:9100"; };
     };
   };
   ```

3. Deploy. The tunnel is created in Cloudflare, credentials are written, the
   daemon connects, and the CNAME is provisioned — all in one activation.

---

## Architecture

```
                 Public Internet
                       │
                       ▼
         ┌──────────────────────────┐
         │  Cloudflare Edge         │
         │  - TLS termination       │
         │  - DDoS protection       │
         │  - DNS (auto-managed)    │
         └────────────┬─────────────┘
                      │  encrypted tunnel (outbound from chopper)
                      ▼
              chopper (NixOS)
              ┌──────────────────┐
              │  cloudflared     │
              │  systemd service │
              └────────┬─────────┘
                       │ localhost
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
   nextcloud:80   conduit:6167   any-service:N
```

**No inbound ports are open.** chopper's firewall only allows port 22 (SSH);
all web traffic comes through the tunnel as outbound connections from
chopper to Cloudflare. See [`security.md`](./security.md).

---

## How it works

### `services.cloudflared-bootstrap`

On every activation, a systemd oneshot runs:

1. Reads the `cert.pem` (account-level Cloudflare credential) from
   `/run/secrets/cloudflare-cert` via systemd `LoadCredential`.
2. For each name in the `tunnels` list:
   - Calls `cloudflared tunnel list --output json` and filters for the name.
   - **If found AND credentials file exists locally** — no-op.
   - **If found BUT credentials file missing locally** — deletes and recreates
     (Cloudflare doesn't allow re-downloading credentials for an existing
     tunnel, so rotation is the only option). The DNS module will repoint
     CNAMEs on the next run via `--overwrite-dns`.
   - **If not found** — calls `cloudflared tunnel create <name>`, which
     allocates a new UUID and writes `/var/lib/cloudflared/<name>.json`.

### `services.cloudflared` (upstream NixOS module)

Declares the actual tunnel daemon. Reads the credentials JSON written by
the bootstrap module, parses ingress rules, and connects outbound to
Cloudflare's edge.

### `services.cloudflared-dns`

After tunnels start, this oneshot reads `services.cloudflared.tunnels.*.ingress`
at eval time and runs:
```
cloudflared tunnel route dns --overwrite-dns <tunnel> <hostname>
```
for each (tunnel, hostname) pair. Idempotent — already-correct records
are no-ops.

Wildcards (e.g. `*.tellmey.fyi`) are filtered out; cloudflared cannot
provision DNS for them.

---

## One-time setup: the origin cert

All three modules need a Cloudflare **origin cert** (`cert.pem`) to
authenticate. This is a one-time bootstrap step per Cloudflare zone (domain).

### 1. Generate the cert on a workstation with a browser

On your Mac (or any machine with `cloudflared` installed):

```sh
cloudflared tunnel login
```

This opens a browser. Pick the `tellmey.fyi` zone. The command writes
`~/.cloudflared/cert.pem`.

### 2. Encrypt it with sops

**⚠️ Important:** the `cert.pem` produced by `cloudflared tunnel login`
contains **three PEM-style blocks** concatenated. You need to copy the
**entire file contents** — missing the third block (`ARGO TUNNEL TOKEN`)
causes `Error decoding origin cert: missing token in the certificate` at
run time.

Verify before you start:

```sh
grep -c "BEGIN" ~/.cloudflared/cert.pem
# Should output: 3
```

Then edit the secrets file:

```sh
cd ~/nix-config
sops secrets/chopper/secrets.yaml
```

Add an entry like this — **all three blocks are required**:

```yaml
cloudflare-cert: |
  -----BEGIN PRIVATE KEY-----
  MIGHAgEA...
  -----END PRIVATE KEY-----
  -----BEGIN CERTIFICATE-----
  MIIDXTCC...
  -----END CERTIFICATE-----
  -----BEGIN ARGO TUNNEL TOKEN-----
  eyJhUI...
  -----END ARGO TUNNEL TOKEN-----
```

The quickest way to copy the file verbatim:

```sh
cat ~/.cloudflared/cert.pem | pbcopy            # macOS
cat ~/.cloudflared/cert.pem | xclip -sel clip   # Linux
```

Save and quit — sops re-encrypts the file. Commit it.

### 3. Wipe the local copy

```sh
rm ~/.cloudflared/cert.pem
```

### 4. Deploy

```sh
nh os switch
journalctl -u cloudflared-bootstrap
journalctl -u cloudflared-dns
```

First run will create the tunnel and print its new UUID:

```
[cloudflared-bootstrap] Ensuring tunnel: chopper-main
[cloudflared-bootstrap] Creating tunnel 'chopper-main'...
Tunnel credentials written to /var/lib/cloudflared/chopper-main.json. ...
Created tunnel chopper-main with id 7f3e2d1c-...
```

Subsequent runs just confirm everything is in place.

---

## Rotating a tunnel

If you need to forcibly rotate a tunnel's credentials (e.g. after a
compromise or recovering from a lost credentials file):

```sh
sudo rm /var/lib/cloudflared/chopper-main.json
nh os switch
```

The bootstrap module will detect the existing tunnel in Cloudflare without
matching local credentials, delete it, recreate it with a fresh UUID, and
the DNS module will repoint all CNAMEs automatically.

---

## Common subdomain patterns

### Plain HTTP service

```nix
"app.tellmey.fyi" = {
  service = "http://localhost:3000";
};
```

### Static fallback / coming-soon page

```nix
"new.tellmey.fyi" = {
  service = "http_status:503";  # returns "Service Unavailable"
};
```

### TCP service (SSH, databases, etc.)

```nix
"ssh.tellmey.fyi" = {
  service = "ssh://localhost:22";
};
```

Client: `cloudflared access ssh --hostname ssh.tellmey.fyi`.

---

## Troubleshooting

### `Error decoding origin cert: missing token in the certificate`

The `cert.pem` you encrypted into sops is incomplete — it's missing the
`-----BEGIN ARGO TUNNEL TOKEN-----` block at the end. cloudflared expects
all three blocks (PRIVATE KEY, CERTIFICATE, ARGO TUNNEL TOKEN) concatenated.

Fix:

```sh
# Re-login if you already deleted the local cert.pem
cloudflared tunnel login

# Verify all 3 blocks are present
grep -c "BEGIN" ~/.cloudflared/cert.pem  # must be 3

# Re-encrypt with the full file contents
sops secrets/chopper/secrets.yaml
# Replace the cloudflare-cert value with the entire cert.pem
```

See "One-time setup: the origin cert" above for the full format.

### Bootstrap fails on first run

- **Wrong cert.pem** — regenerate with `cloudflared tunnel login`, re-encrypt
  in sops.
- **Cert.pem is for the wrong account** — must match the account that should
  own the tunnel.
- **Zone not active** — newly added domains need ~minutes to propagate
  Cloudflare nameservers. Check the dashboard.

### Tunnel exists but service won't start

```sh
journalctl -u cloudflared-tunnel-chopper-main
ls -la /var/lib/cloudflared/
```

If credentials file is missing, delete the tunnel in Cloudflare dashboard
and let bootstrap recreate it. Or run the rotation flow above.

### DNS records pointing to wrong tunnel

`--overwrite-dns` should fix this on the next run. Force it:
```sh
systemctl restart cloudflared-dns
```

### Removing a hostname

Remove the entry from `ingress` and run `nh os switch`. **Note:** the DNS
module *creates* and *updates* records but does not delete them. To fully
remove a CNAME, delete it manually in the Cloudflare dashboard after
removing it from your config.

### Removing a tunnel entirely

1. Remove the name from `services.cloudflared-bootstrap.tunnels`.
2. Remove the `services.cloudflared.tunnels.<name>` block.
3. Deploy.
4. Manually delete the tunnel + DNS records in the Cloudflare dashboard.

(Auto-cleanup is on the roadmap but kept off by default for safety.)

---

## Migration notes (for the curious)

This repo previously hardcoded a tunnel UUID in `services.nix` and stored
its credentials JSON in sops as `cloudflared-tunnel-credentials`. That
worked but had two pain points:

1. The UUID was opaque — grepping for `b0ca1206-...` revealed nothing about
   what tunnel it was.
2. Setting up a fresh host (or recovering after losing credentials) required
   manual `cloudflared tunnel create` + sops dance.

The `cloudflared-bootstrap` module replaces both: tunnels are addressed by
friendly name, and creation is automatic.

The `cloudflared-tunnel-credentials` sops secret is no longer used and was
removed from `hosts/chopper/sops.nix`.

---

## Related docs

- [`secrets.md`](./secrets.md) — how sops-nix secrets work; the cert.pem is
  managed this way
- [`security.md`](./security.md) — firewall/SSH posture; explains why no
  inbound ports are needed
- [`deploy.md`](./deploy.md) — how to push config changes to chopper
