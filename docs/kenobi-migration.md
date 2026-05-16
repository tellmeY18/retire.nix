# docs/kenobi-migration.md — OCI Compute Node (NixOS Anywhere + k3s + Traefik)

This document covers the full migration plan for converting `ez.kenobi.win` (an Oracle Cloud Infrastructure ARM64 VM) from Ubuntu to NixOS, joining it to the glug-infra k3s cluster, and deploying Traefik as a public ingress controller.

---

## 1. Machine Reconnaissance

| Property | Value |
|---|---|
| **Current Hostname** | `ubundu-mariadb` → becomes `kenobi` |
| **Provider** | Oracle Cloud Infrastructure (OCI), KVM/QEMU |
| **Architecture** | `aarch64` (ARM Neoverse-N1, 4 cores) |
| **RAM** | 17.5 GiB |
| **Boot** | UEFI |
| **Public IP** | `68.233.115.209` |
| **Internal IP** | `10.0.0.244/24` (enp0s6, MTU 9000 jumbo frames) |
| **Kernel** | `6.17.0-1007-oracle` (OCI-optimized) |
| **Disk** | `sda` — 100 GB (only disk available) |
| **Current OS** | Ubuntu 24.04.4 LTS |

### Disk Layout (pre-migration)

| Device | Size | State |
|---|---|---|
| `sda` (100 GB) | Boot disk | ext4 root (26 GB used), EFI partition |
| `sda15` (99 MB) | EFI | vfat `/boot/efi` |

> **Note:** `sdb` (50 GB block volume) was detached and is no longer available. All ZFS datasets live on `sda`.

### Current Services (will be destroyed)

- Docker + Caddy reverse proxy (ports 80/443)
- iSCSI daemon (OCI block volume attachment)
- UFW firewall (ports 22, 80, 443, 25, 3306, 5432 open)
- No Tailscale installed

---

## 2. Architecture After Migration

```
                        Internet
                           │
                    ┌──────┴──────┐
                    │  DNS A rec  │
                    │ *.kenobi.win│
                    │ tellmey.fyi │
                    └──────┬──────┘
                           │
                    68.233.115.209
                    ┌──────┴──────┐
                    │   kenobi    │  (aarch64, OCI, 4c/18GB)
                    │  Traefik    │  :80 → :443 (ACME TLS)
                    │  ┌────────┐ │
                    │  │ Ghost  │ │  Stateless pods
                    │  │ Wiki   │ │  (prefer compute node)
                    │  │ Answer │ │
                    │  └────────┘ │
                    │  k3s agent  │
                    └──────┬──────┘
                      tailscale0 (WireGuard)
                           │
                    ┌──────┴──────┐
                    │  chopper    │  (x86_64, laptop, ZFS)
                    │  k3s server │
                    │  ┌────────┐ │
                    │  │ CNPG   │ │  PostgreSQL (PVCs on ZFS)
                    │  │ PXC    │ │  MySQL (PVCs on ZFS)
                    │  │ RustFS │ │  S3 storage (PVCs on ZFS)
                    │  └────────┘ │
                    └─────────────┘
```

### Role separation

| Node | Role | Workloads |
|---|---|---|
| **chopper** | `server-init` (etcd + apiserver) | Databases (CNPG, PXC), object storage (RustFS), operators |
| **kenobi** | `agent` (worker only) | Stateless web apps (Ghost, MediaWiki, Answer), Traefik ingress |

### Why agent, not server?

With 2 nodes, etcd cannot form a proper quorum. Adding kenobi as a second server would make the cluster **worse** — losing either node makes etcd read-only. An agent is lighter weight and failing cleanly just means pods reschedule back to chopper.

---

## 3. Phase 1 — NixOS Configuration & Installation

### 3.1 Repository changes

| File | Action |
|---|---|
| `lib/default.nix` | Add `"aarch64-linux"` to `supportedSystems` |
| `hosts/kenobi/metadata.nix` | New — host metadata |
| `hosts/kenobi/configuration.nix` | New — imports chain |
| `hosts/kenobi/default.nix` | New — parts-based structure |
| `hosts/kenobi/disko-config.nix` | New — ZFS on sda (single disk) |
| `hosts/kenobi/sops.nix` | New — k3s-token + tailscale-auth-key |
| `hosts/kenobi/parts/boot.nix` | New — systemd-boot + UEFI + ZFS |
| `hosts/kenobi/parts/network.nix` | New — OCI networking, firewall |
| `hosts/kenobi/parts/k3s.nix` | New — agent role joining chopper |
| `hosts/kenobi/parts/users.nix` | New — vysakh user |
| `.sops.yaml` | Add `&kenobi` anchor + creation rule |
| `secrets/kenobi/secrets.yaml` | New — sops-encrypted secrets |
| `flake.nix` | Add kenobi to `extraModules` |
| `Justfile` | Add `build-kenobi` recipe |

### 3.2 Disko layout (single disk: sda 100 GB)

```
sda (100 GB GPT)
├── sda1: EFI System Partition (512M, vfat, /boot/efi)
├── sda2: Swap (4G)
└── sda3: ZFS pool "rpool" (~95.5 GB)
    ├── rpool/nixos/root  → /
    ├── rpool/nixos/home  → /home
    ├── rpool/nixos/nix   → /nix   (compression=zstd)
    └── rpool/nixos/var   → /var   (includes /var/lib/rancher/k3s)
```

**Key choices:**
- `ashift=12` — correct for OCI block volumes (4K sectors behind iSCSI)
- `compression=zstd` — saves space on container images under /var
- No separate data pool — single disk means everything on rpool
- k3s state (container images, emptyDirs) lives under `/var/lib/rancher/k3s` which is part of `rpool/nixos/var`

### 3.3 OCI-specific considerations

| Issue | Solution |
|---|---|
| **No serial console by default** | Add `console=ttyAMA0` to kernel params for OCI Cloud Shell |
| **DHCP networking** | `networking.useDHCP = true` on enp0s6 (simpler than NetworkManager for cloud) |
| **MTU 9000 (jumbo frames)** | Preserve — OCI VCN uses jumbo frames |
| **No second disk** | Everything on rpool (sda) — fine for a compute node |
| **Public IP** | Directly routable — Traefik binds to 80/443 |
| **OCI metadata service** | 169.254.169.254 — routes already set by DHCP |

### 3.4 NixOS Anywhere installation

#### Prerequisites

1. **Generate age keypair locally (on your Mac):**
   ```sh
   age-keygen -o kenobi.key
   # Note the public key printed to stdout: age1abc123...
   ```

2. **Add the PUBLIC key to `.sops.yaml`:**
   Replace the placeholder:
   ```yaml
   - &kenobi age1abc123...  # replace with your actual public key
   ```

3. **Encrypt secrets for kenobi:**
   ```sh
   mkdir -p secrets/kenobi
   sops secrets/kenobi/secrets.yaml
   ```
   Add these keys:
   - `k3s-token`: same value as chopper's (decrypt chopper's to read it:
     `sops -d secrets/chopper/secrets.yaml | grep k3s-token`)
   - `tailscale-auth-key`: new pre-auth key from
     https://login.tailscale.com/admin/settings/keys (reusable, tagged)

4. **Prepare the private key for install via `--extra-files`:**
   ```sh
   mkdir -p /tmp/kenobi-extra/var/lib/sops-nix
   cp kenobi.key /tmp/kenobi-extra/var/lib/sops-nix/key.txt
   chmod 600 /tmp/kenobi-extra/var/lib/sops-nix/key.txt
   ```

5. **Verify config evaluates** (this does NOT cross-compile — it just
   checks the Nix expression evaluates without error):
   ```sh
   nix eval .#nixosConfigurations.kenobi.config.system.build.toplevel.drvPath
   ```

#### Installation command

> **Important:** The default kexec bundled with nixos-anywhere is x86_64.
> For aarch64, you MUST provide the `--kexec` flag with an ARM64 image.
> Additionally, `--build-on-remote` ensures the NixOS closure is built on
> the target machine (kenobi itself) — no cross-compilation from your Mac.

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake .#kenobi \
  --kexec https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-kexec-installer-noninteractive-aarch64-linux.tar.gz \
  --build-on-remote \
  --extra-files /tmp/kenobi-extra \
  root@ez.kenobi.win
```

`--extra-files` directory structure (mirrors the target root filesystem):
```
/tmp/kenobi-extra/
└── var/
    └── lib/
        └── sops-nix/
            └── key.txt    ← PRIVATE age key (chmod 600)
```

#### What happens during install

1. SSH into Ubuntu as root
2. Download aarch64 kexec image from nixos-images
3. kexec into NixOS installer ramdisk (Ubuntu is gone)
4. Run disko — wipes sda, creates GPT + EFI + swap + ZFS pool
5. Build the NixOS closure **on kenobi itself** (no cross-compile)
6. Install NixOS to the ZFS pool
7. Copy `--extra-files` contents (age key) into the installed system
8. Reboot into NixOS

#### Post-install: delete the local key copy

```sh
rm kenobi.key
# The only copy now lives on kenobi at /var/lib/sops-nix/key.txt
# Keep the PUBLIC key in .sops.yaml (that's safe to commit)
```

### 3.5 Post-install verification

```sh
# SSH in (should work with same key)
ssh root@ez.kenobi.win

# Verify ZFS
zpool status rpool

# Verify Tailscale
tailscale status

# Note the Tailscale IP for k3s config
tailscale ip -4

# Verify k3s joined the cluster
kubectl get nodes
```

After noting the Tailscale IP, update `hosts/kenobi/parts/k3s.nix` with the `nodeIP` value and run `deploy-rs` to push the update.

---

## 4. Phase 2 — Traefik Ingress

### 4.1 Why Traefik (replacing Tailscale Funnel)

| | Tailscale Funnel (current) | Traefik (target) |
|---|---|---|
| **Latency** | High — traffic proxied through Tailscale's edge | Low — direct HTTPS to OCI VM |
| **Custom domains** | Limited (CNAME to .ts.net) | Full control |
| **TLS** | Managed by Tailscale | Let's Encrypt (Traefik ACME) |
| **Rate limits** | Tailscale's Funnel limits | None (you own the IP) |
| **Dependency** | Tailscale infra must be up | Self-hosted, only depends on Let's Encrypt |

### 4.2 Traefik deployment

Deployed via Helmfile (release #7), running on compute nodes only:

- **Chart:** `traefik/traefik` (latest stable)
- **Namespace:** `traefik-system`
- **hostNetwork:** `true` (binds directly to node's public IP on 80/443)
- **nodeSelector:** `node-role.glug.infra/compute: "true"`
- **TLS:** Traefik's built-in ACME resolver (Let's Encrypt)
  - Why not cert-manager? Only 3 domains. cert-manager is a whole operator + CRDs for 3 certs.
- **Dashboard:** Disabled publicly, accessible only via tailnet

### 4.3 DNS records

| Domain | Type | Value | Service |
|---|---|---|---|
| `tellmey.fyi` | A | `68.233.115.209` | Ghost |
| `www.tellmey.fyi` | CNAME | `tellmey.fyi` | Ghost |
| `wiki.kenobi.win` | A | `68.233.115.209` | MediaWiki |
| `ask.kenobi.win` | A | `68.233.115.209` | Answer |

### 4.4 Kubernetes resources

| File | Purpose |
|---|---|
| `k8s/apps/traefik/values.yaml` | Helm values (hostNetwork, ACME, nodeSelector) |
| `k8s/clusters/glug-infra/traefik/namespace.yaml` | Namespace + PSA |
| `k8s/clusters/glug-infra/traefik/kustomization.yaml` | Kustomize entry point |
| `k8s/clusters/glug-infra/ghost/ingress-traefik.yaml` | Traefik IngressRoute for Ghost |
| `k8s/clusters/glug-infra/mediawiki/ingress-traefik.yaml` | Traefik IngressRoute for MediaWiki |
| `k8s/clusters/glug-infra/answer/ingress-traefik.yaml` | Traefik IngressRoute for Answer |

### 4.5 Migration plan (zero-downtime)

1. ✅ Deploy Traefik via helmfile
2. ✅ Apply new IngressRoute resources (Traefik Ingress + Tailscale Funnel coexist)
3. ✅ Update DNS A records to point to `68.233.115.209`
4. ✅ Verify all three services respond on new domains with valid TLS
5. ✅ Update Ghost's `url` env var from `https://ghost.tail477f2f.ts.net` to `https://tellmey.fyi`
6. ✅ Delete old Tailscale Funnel Ingress objects (tailscale-service.yaml for ghost/mediawiki/answer)
7. ✅ Remove Tailscale Funnel annotations from services

### 4.6 Ghost URL migration

Ghost requires its `url` config to match the public-facing URL. Changing it:
- Update `deployment.yaml`: `url: "https://tellmey.fyi"`
- Update `storage__s3__assetHost` if S3 images are served via a new domain
- Restart Ghost pod — it picks up the new URL on boot

---

## 5. Phase 3 — Firewall Hardening

### NixOS firewall on kenobi

```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 22 80 443 ];  # SSH + Traefik HTTP/HTTPS
  allowedUDPPorts = [ config.services.tailscale.port ];
  trustedInterfaces = [ "tailscale0" ];
  # cni0 and flannel.1 auto-trusted by k3s module
};
```

### OCI Security List (cloud-side)

After migration, clean up the OCI Security List:
- **Keep:** 22/tcp (SSH), 80/tcp (HTTP), 443/tcp (HTTPS)
- **Remove:** 25 (SMTP), 3306 (MySQL), 5432 (PostgreSQL) — databases are internal, accessed only via tailnet
- Tailscale uses UDP 41641 and punches through NAT — no explicit rule needed

---

## 6. Secrets

| Secret | Where | Encrypted to |
|---|---|---|
| Age private key | `/var/lib/sops-nix/key.txt` on kenobi | n/a (IS the key) |
| k3s-token | `secrets/kenobi/secrets.yaml` | master + kenobi |
| tailscale-auth-key | `secrets/kenobi/secrets.yaml` | master + kenobi |

The k3s-token must be the **same value** as chopper's — it's the shared cluster join token.

---

## 7. Implementation Checklist

- [ ] Add `aarch64-linux` to `supportedSystems` in `lib/default.nix`
- [ ] Create `hosts/kenobi/` with all configuration files
- [ ] Add kenobi age key to `.sops.yaml`
- [ ] Create `secrets/kenobi/secrets.yaml` (sops-encrypted)
- [ ] Update `flake.nix` extraModules for kenobi
- [ ] Verify build: `nix build .#nixosConfigurations.kenobi.config.system.build.toplevel`
- [ ] Generate age key on kenobi (post-install) or pre-generate and embed
- [ ] Run NixOS Anywhere: `nix run github:nix-community/nixos-anywhere -- --flake .#kenobi root@ez.kenobi.win`
- [ ] Verify ZFS, Tailscale, k3s agent
- [ ] Set nodeIP in k3s config, deploy-rs push
- [ ] Deploy Traefik via helmfile
- [ ] Create IngressRoute resources
- [ ] Update DNS records
- [ ] Test all three services
- [ ] Update Ghost URL config
- [ ] Remove Tailscale Funnel Ingresses
- [ ] Clean OCI Security List

---

## 8. Rollback plan

If NixOS Anywhere fails mid-install:
- OCI Console → **Terminate instance** → **Create from boot volume backup**
- Or: OCI Console → Boot into recovery mode → repair manually

If k3s agent fails to join:
- Check `journalctl -u k3s` on kenobi
- Verify k3s-token matches chopper's
- Verify tailscale0 is up and can reach chopper:6443

If Traefik fails:
- Old Tailscale Funnel Ingresses still work (DNS hasn't changed yet)
- Fix Traefik independently
- Only cut DNS over once Traefik is verified working

---

## 9. Future considerations

- **3rd node (quorum):** Once kenobi is stable, add a tiny always-on VPS as an etcd-only quorum node. This gives true HA (survives any 1 node failure).
- **Horizontal scaling:** More OCI free-tier VMs can join as additional agents.
- **Cert-manager:** If more domains are added, switch from Traefik ACME to cert-manager for centralized certificate management.
- **Pod topology spread:** With 2 nodes, `topologySpreadConstraints` become meaningful — spread replicas across chopper + kenobi for resilience.
