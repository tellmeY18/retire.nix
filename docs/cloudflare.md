# Cloudflare Tunnel & Declarative DNS

This repository exposes self-hosted services to the public internet through
[Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
(`cloudflared`). DNS records (CNAMEs) and tunnel ingress routes are
**declared in one place** — the host's NixOS config — and provisioned
automatically on `nh os switch`.

There is no manual clicking in the Cloudflare dashboard, no `cloudflared tunnel
route dns` commands to remember, and no risk of DNS drifting from your tunnel
config. The hostnames in `services.cloudflared.tunnels.<id>.ingress` are the
**single source of truth**.

---

## TL;DR — Add a new public service

To expose `example.tellmey.fyi`:

1. Make the service listen on a local port (any standard NixOS service module):
   ```nix
   # somewhere in your host config
   services.example = {
     enable = true;
     listenAddress = "127.0.0.1";
     port = 9000;
   };
   ```

2. Add **one line** to the cloudflared ingress block in
   `hosts/chopper/parts/services.nix`:
   ```nix
   services.cloudflared.tunnels."b0ca1206-1d09-4892-9d69-d3a196877013" = {
     # ...
     ingress = {
       "next.tellmey.fyi"    = { service = "http://localhost:80"; };
       "chat.tellmey.fyi"    = { service = "http://localhost:6167"; };
       "cal.tellmey.fyi"     = { service = "http://localhost:4000"; };
       "school.tellmey.fyi"  = { service = "http://localhost:7000"; };
       "example.tellmey.fyi" = { service = "http://localhost:9000"; };  # ← NEW
     };
   };
   ```

3. Commit and deploy:
   ```sh
   git add -A && git commit -m "feat(chopper): expose example.tellmey.fyi"
   nh os switch
   ```

When activation runs, the `cloudflared-dns.service` one-shot picks up the
new hostname, creates the CNAME in Cloudflare, and the tunnel starts routing
traffic. Within a few seconds, `https://example.tellmey.fyi` is reachable
from anywhere on the internet — with valid TLS, DDoS protection, and zero
inbound firewall rules.

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

## How declarative DNS works

The flake includes a custom NixOS module: `modules/services/cloudflared-dns.nix`.

At a high level:

1. The module reads `services.cloudflared.tunnels.*.ingress` at evaluation time.
2. For each hostname, it generates a shell line like
   `cloudflared tunnel route dns --overwrite-dns <tunnel-id> <hostname>`.
3. Those lines run as a systemd one-shot (`cloudflared-dns.service`) on
   every activation.
4. The command is **idempotent** — already-correct records are no-ops, missing
   records are created, mismatched records are corrected.

The systemd unit is hardened (`DynamicUser`, `ProtectSystem=strict`, etc.) and
gets the Cloudflare origin cert via `LoadCredential`, so the secret never
touches disk in plaintext.

### Wildcards

Wildcard hostnames (e.g. `*.tellmey.fyi`) are filtered out automatically
because cloudflared cannot provision DNS for them. If you need a wildcard
record, create it manually in the Cloudflare dashboard or via API.

---

## One-time setup: the origin cert

Declarative DNS provisioning needs a Cloudflare **origin cert** (`cert.pem`)
that grants `cloudflared` permission to create DNS records on your behalf.
This is a one-time bootstrap step per zone (domain).

### 1. Generate the cert on a workstation with a browser

On your Mac (or any machine with `cloudflared` installed):

```sh
cloudflared tunnel login
```

This opens a browser. Select the `tellmey.fyi` zone. The command writes
`~/.cloudflared/cert.pem` containing the API token.

### 2. Encrypt it with sops

```sh
cd ~/nix-config

# Add the cert as a multi-line block scalar in the secrets file
sops secrets/chopper/secrets.yaml
```

Add an entry like:

```yaml
cloudflare-cert: |
  -----BEGIN PRIVATE KEY-----
  MIGHAgEA...
  -----END PRIVATE KEY-----
  -----BEGIN CERTIFICATE-----
  MIIDXTCC...
  -----END CERTIFICATE-----
```

Save and quit — sops re-encrypts the file. Commit it.

### 3. Wipe the local copy

```sh
rm ~/.cloudflared/cert.pem
```

The cert is now safely encrypted in the repo and decrypted only at activation
time on chopper to `/run/secrets/cloudflare-cert` (root-only, tmpfs).

### 4. Deploy

```sh
nh os switch
journalctl -u cloudflared-dns
```

You should see lines like:

```
[cloudflared-dns] Ensuring CNAME: next.tellmey.fyi -> b0ca1206-...
[cloudflared-dns] Ensuring CNAME: chat.tellmey.fyi -> b0ca1206-...
[cloudflared-dns] DNS provisioning complete.
```

---

## Adding a brand-new tunnel (different account/zone)

If you ever need a second tunnel (e.g. for a different domain):

1. Create the tunnel:
   ```sh
   cloudflared tunnel create <tunnel-name>
   # Outputs a UUID and writes ~/.cloudflared/<uuid>.json
   ```

2. Encrypt the credentials JSON into sops:
   ```sh
   sops secrets/chopper/secrets.yaml
   # Add: cloudflared-tunnel-credentials-<name>: |  (JSON contents)
   ```

3. Declare the tunnel in your host config alongside the existing one:
   ```nix
   services.cloudflared.tunnels."<new-uuid>" = {
     credentialsFile = "/run/secrets/cloudflared-tunnel-credentials-<name>";
     default = "http_status:404";
     ingress = {
       "service.example.com" = { service = "http://localhost:8080"; };
     };
   };
   ```

4. Add a sops secret declaration in `hosts/chopper/sops.nix` for the
   credentials file.

5. Deploy. Both tunnels run side-by-side; the DNS module handles both.

If the new tunnel is on a different Cloudflare account, you'll also need a
separate `cert.pem` for that account. Either run two instances of the DNS
module (more complex) or just provision the new account's records manually.

---

## Common subdomain patterns

### Plain HTTP service

```nix
"app.tellmey.fyi" = {
  service = "http://localhost:3000";
};
```

### HTTPS backend (rare — usually localhost is HTTP)

```nix
"secure.tellmey.fyi" = {
  service = "https://localhost:8443";
  # ...originRequest options if needed
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

Then on the client side: `cloudflared access ssh --hostname ssh.tellmey.fyi`.

---

## Troubleshooting

### "DNS provisioning failed" in journalctl

- **Wrong cert.pem** — regenerate with `cloudflared tunnel login`, re-encrypt.
- **Cert.pem is for the wrong account** — must match the account that owns
  the tunnel.
- **Zone not active** — newly added domains need ~minutes to propagate
  Cloudflare nameservers. Check the dashboard for "Active" status.

### CNAME exists but points to old tunnel

`--overwrite-dns` should handle this. If not, delete the record manually in
the dashboard and re-run `nh os switch`.

### Service not reachable through tunnel

Check in order:
1. Is the underlying service actually listening?
   `sudo ss -tlnp | grep <port>`
2. Is `cloudflared` connected?
   `journalctl -u cloudflared-tunnel-<id>`
3. Is the CNAME present?
   `dig example.tellmey.fyi`
4. Cloudflare dashboard → Zero Trust → Networks → Tunnels → check status

### Removing a hostname

Remove the entry from the `ingress` block and run `nh os switch`. **Note:**
the DNS module *creates* and *updates* records but does not delete them. To
fully remove a CNAME, delete it manually in the Cloudflare dashboard after
removing it from your config. (Idempotent removal is on the roadmap.)

---

## Changing the apex domain (e.g. `tellmey.tech` → `tellmey.fyi`)

This is a do-once-and-forget operation now:

1. Add the new domain to your Cloudflare account
2. Update every hostname in the ingress block (find/replace)
3. Update `services.nextcloud.hostName` (and any other service that takes a
   hostname argument)
4. Generate a fresh `cert.pem` for the new zone (see "One-time setup" above)
5. Re-encrypt it into sops, deploy

Old DNS records under the previous domain stay until you delete them in the
dashboard or remove the zone entirely.

---

## Related docs

- [`secrets.md`](./secrets.md) — how sops-nix secrets work (the cert.pem and
  tunnel credentials are managed this way)
- [`security.md`](./security.md) — firewall and SSH posture; explains why no
  inbound ports are needed
- [`deploy.md`](./deploy.md) — how to push config changes to chopper
