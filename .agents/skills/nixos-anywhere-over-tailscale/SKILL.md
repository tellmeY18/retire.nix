---
name: nixos-anywhere-over-tailscale
description: End-to-end bootstrap of a NixOS host via nixos-anywhere over Tailscale, covering Proxmox VM preparation (UEFI/OVMF), host config creation (disko, boot, network, users, sops, k3s), building a Tailscale-aware kexec image with static binaries for nixpkgs-unstable, sops secrets management, age key injection, remote building on a fast builder, and post-boot verification. Works when the target is only reachable over the tailnet.
---

# NixOS bootstrapping over Tailscale — end-to-end

Bootstrap a NixOS host remotely via `nixos-anywhere` while keeping it
reachable over Tailscale (same IP) through the entire kexec → disko →
nixos-install → reboot cycle. Based on the real-world bootstrap of
`r2d2` (x86_64 Proxmox VM → NixOS 25.11 + ZFS + k3s compute node).

**Architecture references:**
- Global tailscale-preservation skill → `nixos-anywhere-tailscale` (concept)
- Low-RAM bootstrap pitfall skill → `low-ram-nixos-anywhere` (memory-constrained hosts)

---

## 1. Problem: Tailscale disappears after kexec

`nixos-anywhere` normally:
1. SSH in → upload kexec tarball → kexec (kernel replaces itself)
2. SSH back → disko → nixos-install → reboot

Step 2 fails if the target is only reachable over **Tailscale** — the kexec
environment doesn't have tailscale, so the machine vanishes from the tailnet.

**Solution:** Build a custom kexec image that:
- Mounts the old root partition (still intact — kexec doesn't touch the disk)
- Copies `/var/lib/tailscale/tailscaled.state` into tmpfs
- Starts `tailscaled` → reconnects as the **same node** (same IP)
- Starts SSHD → `nixos-anywhere` reconnects on the same tailnet address

---

## 2. Repository layout

```
hosts/<hostname>/
├── metadata.nix            # hostname, system, hostId, roles, deploy
├── configuration.nix       # imports profile + default.nix
├── default.nix             # imports sops + parts/*
├── disko-config.nix        # EFI + Swap + ZFS layout
├── hardware-configuration.nix  # nixos-generate-config output
├── sops.nix                # secret declarations
└── parts/
    ├── boot.nix             # bootloader (systemd-boot / GRUB), ZFS, kernel modules
    ├── k3s.nix              # k3s role (agent/server)
    ├── network.nix          # interface, firewall, tailscale, pod routes
    └── users.nix            # SSH keys, shell, sudo

secrets/<hostname>/
└── secrets.yaml             # sops-encrypted (tailscale-auth-key, k3s-token, etc.)

packages/
├── kexec-image.nix          # Tailscale-aware kexec tarball builder
└── kexec-run.sh             # kexec boot script (preserves SSH keys + network)
```

---

## 3. Pre-flight: assess the target

SSH into the target and gather:

```sh
ssh root@<tailscale-ip>

uname -a                             # arch
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE  # disk layout
[ -d /sys/firmware/efi ] && echo UEFI || echo BIOS  # boot mode
tailscale ip -4                      # tailscale IP
cat /var/lib/tailscale/tailscaled.state > /dev/null \
  && echo "tailscale state exists"   # confirm state
cat /etc/fstab                       # root device + fstype
nixos-version                        # current NixOS version
```

**Record these (you'll need them):**
| Item | Example | Used for |
|---|---|---|
| Root partition | `/dev/sda2` | `rootDevice` in `kexec-image.nix` |
| Root filesystem | `ext4` | `rootFsType` in `kexec-image.nix` |
| Full disk device | `/dev/sda` | `disk.sda.device` in `disko-config.nix` |
| Architecture | `x86_64-linux` | `system` in `metadata.nix` |
| Boot mode | UEFI or BIOS | Bootloader choice in `boot.nix` |
| Tailscale IP | `100.x.y.z` | `deploy.host` in `metadata.nix` |

---

## 4. Create the host configuration

### 4.1 `hosts/<hostname>/metadata.nix`

```nix
{
  hostname = "<hostname>";
  system = "x86_64-linux";  # or aarch64-linux
  hostId = "<8-char-hex>";  # head -c 4 /dev/urandom | od -A none -t x4 | tr -d ' '
  timezone = "Asia/Kolkata";
  locale = "en_US.UTF-8";
  stateVersion = "25.11";
  type = "nixos";
  users = [ "vysakh" ];
  roles = [ "k3s" "compute" ];

  deploy = {
    host = "<tailscale-ip>";
    sshUser = "root";
    remoteBuild = true;
  };
}
```

### 4.2 `hosts/<hostname>/disko-config.nix`

Single-disk ZFS layout (EFI + Swap + ZFS):

```nix
{
  disko.devices = {
    disk.sda = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/efi";
              mountOptions = [ "umask=0077" ];
            };
          };
          swap = {
            size = "4G";
            content = { type = "swap"; resumeDevice = true; };
          };
          pool = {
            size = "100%";
            content = { type = "zfs"; pool = "rpool"; };
          };
        };
      };
    };

    zpool.rpool = {
      type = "zpool";
      options = { ashift = "12"; };
      rootFsOptions = {
        compression = "zstd";
        xattr = "sa";
        acltype = "posixacl";
        atime = "off";
        "com.sun:auto-snapshot" = "true";
      };
      datasets = {
        "nixos/root" = { type = "zfs_fs"; mountpoint = "/"; };
        "nixos/home" = { type = "zfs_fs"; mountpoint = "/home"; };
        "nixos/nix" = { type = "zfs_fs"; mountpoint = "/nix"; options.compression = "zstd"; };
        "nixos/var" = { type = "zfs_fs"; mountpoint = "/var"; options.compression = "zstd"; };
      };
    };
  };
}
```

### 4.3 `hosts/<hostname>/configuration.nix`

```nix
{ ... }: {
  imports = [
    ../../profiles/k3s-compute-node.nix  # or k3s-node.nix, or none
    ./default.nix
  ];

  networking = { hostName = "<hostname>"; hostId = "<8-char-hex>"; };
  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    trusted-users = [ "root" "vysakh" ];
    substituters = [ "https://cache.nixos.org" ];
    experimental-features = "nix-command flakes";
  };
  security.sudo = { enable = true; wheelNeedsPassword = true; };
}
```

### 4.4 `hosts/<hostname>/default.nix`

```nix
{ ... }: {
  system.stateVersion = "25.11";
  imports = [
    ./sops.nix
    ./parts/boot.nix
    ./parts/network.nix
    ./parts/users.nix
    ./parts/k3s.nix  # if k3s node
  ];
}
```

### 4.5 Parts files

| Part | Key concerns |
|---|---|
| `parts/boot.nix` | systemd-boot (UEFI) vs GRUB (BIOS), ZFS modules, virtio modules |
| `parts/network.nix` | DHCP, firewall rules, tailscale (`authKeyFile`, routes), pod CIDR routes |
| `parts/users.nix` | SSH keys from `users/<user>.nix`, root SSH keys for deploy-rs |
| `parts/k3s.nix` | Agent vs server role, `serverAddr`, `tokenFile`, `nodeIP` (tailscale), `tls-san` |

---

## 5. Wire into the flake

### 5.1 `flake.nix` — extraModules

Add the host to `nixosConfigurations` extraModules:

```nix
nixosConfigurations = myLib.mkNixosConfigurations {
  hostsDir = ./hosts;
  extraModules = {
    <hostname> = [
      ./hosts/<hostname>/disko-config.nix
      sops-nix.nixosModules.sops
      disko.nixosModules.disko
    ];
  };
};
```

The lib factory auto-discovers hosts with `metadata.nix` + `configuration.nix`.

### 5.2 `flake.nix` — kexec-image package

```nix
packages = myLib.forAllSystems ({ pkgs, system, ... }: {
  kexec-image = pkgs.callPackage ./packages/kexec-image.nix { };
});
```

### 5.3 Update the Justfile

Add entries for `ssh`, `gc`, `build-<host>`, `eval-all`, `closure-sizes`,
and `deploy` (deploy-rs auto-discovers from metadata).

---

## 6. Proxmox-specific: UEFI/OVMF preparation

If the target VM uses SeaBIOS but the disko config creates an ESP for
systemd-boot, the VM firmware must be switched to OVMF **before**
nixos-anywhere.

### 6.1 Why firmware matters

SeaBIOS cannot read the ESP (EFI System Partition). After nixos-anywhere
installs systemd-boot to the ESP and reboots, SeaBIOS has no way to find
it → `"No bootable device"`. OVMF reads the ESP and executes
`\EFI\BOOT\BOOTX64.EFI` (systemd-boot).

### 6.2 Why you do it before nixos-anywhere

Firmware change takes effect on the **next cold boot**. kexec bypasses
firmware entirely — it's a kernel-in-place replacement, not a power-on
reset. So the sequence works as:

```
1. Change VM to OVMF in Proxmox (while VM is running)
2. SSH in via Tailscale (old BIOS system still running)
3. nixos-anywhere → kexec → disko → install
4. Reboot → OVMF runs for the first time → finds systemd-boot ✅
```

### 6.3 Terraform changes (`vms.tf`)

```hcl
resource "proxmox_virtual_environment_vm" "vm_name" {
  name      = "vm-name"
  machine   = "q35"       # ADD: q35 chipset for OVMF

  # ... clone, cpu, memory, agent ...

  efi_disk {               # ADD: EFI disk for UEFI boot
    datastore_id = "local-lvm"
    file_format  = "raw"
    type         = "4m"
  }

  # ... initialization, network_device ...
}
```

After `tofu apply`, cold-reboot the VM once so the firmware change
registers. The VM will lose Tailscale connectivity temporarily (fresh
boot), but the next nixos-anywhere run reconnects via the kexec image.

---

## 7. Build the kexec image

### 7.1 The kexec-image.nix

`packages/kexec-image.nix` — produces a tarball:

```
kexec/
├── bzImage     # kernel (from netboot-minimal)
├── initrd      # initramfs (with tailscale, SSH, tools)
├── kexec       # STATIC kexec-tools (dynamic fails in tmpfs!)
├── ip          # STATIC iproute2
└── run         # kexec boot script
```

Key architecture changes from the original `nixos-anywhere-tailscale`
skill (which uses the removed `installer/kexec/kexec.nix`):

| Change | Reason |
|---|---|
| Uses `installer/netboot/netboot-minimal.nix` | The `kexec.nix` module was removed from nixpkgs-unstable |
| `lib.mkForce` on `system.build.kexecTarball` | `netboot.nix` defines its own `kexecTarball` (different format) |
| Static kexec-tools (`pkgs.pkgsStatic.kexec-tools`) | Dynamic binary fails in tmpfs (no dynamic linker) |
| Static iproute2 (`pkgs.pkgsStatic.iproute2`) | Same reason, plus no `iptables` dependency |
| Uncompressed tar output | `nixos-anywhere` extracts with `tar -xf`, not `tar -xzf` |

### 7.2 Build the tarball

```sh
# With remote builder:
nix build '.#packages.x86_64-linux.kexec-image' \
  --builders "ssh://user@builder x86_64-linux - 4 1 - - -"

# Verify:
file result
tar -tf result
# → kexec/  bzImage  initrd  kexec  ip  run
file kexec/kexec  # → ... statically linked ...
```

---

## 8. Secrets management

### 8.1 Generate age key on target

```sh
ssh root@<tailscale-ip> "mkdir -p /var/lib/sops-nix && \
  nix-shell -p age --run 'age-keygen -o /var/lib/sops-nix/key.txt'"
ssh root@<tailscale-ip> "grep -o 'age1[^ ]*' /var/lib/sops-nix/key.txt"
# → age1xxxxx...  ← add to .sops.yaml
```

### 8.2 Update `.sops.yaml`

```yaml
keys:
  - &<hostname> age1xxxxx...

creation_rules:
  - path_regex: secrets/<hostname>/.*
    key_groups:
      - age:
          - *master
          - *<hostname>
```

### 8.3 Create encrypted secrets

```sh
# Create plaintext
cat > /tmp/secrets-plain.yaml << EOF
tailscale-auth-key: tskey-auth-<value>
k3s-token: <value>
EOF

# Encrypt in place
cp /tmp/secrets-plain.yaml secrets/<hostname>/secrets.yaml
sops --encrypt --in-place secrets/<hostname>/secrets.yaml
```

### 8.4 Stage age key for injection

Disko wipes the disk. Inject the key into the new system:

```sh
rm -rf /tmp/extra-files && mkdir -p /tmp/extra-files/var/lib/sops-nix
scp root@<tailscale-ip>:/var/lib/sops-nix/key.txt /tmp/extra-files/var/lib/sops-nix/
chmod 600 /tmp/extra-files/var/lib/sops-nix/key.txt
```

---

## 9. Build the target config (optional but recommended)

Validate the config and warm caches:

```sh
# With remote builder:
nix build '.#nixosConfigurations.<hostname>.config.system.build.toplevel' \
  --builders "ssh://user@builder x86_64-linux - 4 1 - - -"
```

Note: nix-daemon (root) runs the remote builder. Trust the builder's host key:

```sh
sudo ssh -o StrictHostKeyChecking=accept-new user@builder.true
```

---

## 10. Run nixos-anywhere

```sh
nix run github:tellmeY18/nixos-anywhere -- \
  --kexec ./result \
  --extra-files /tmp/extra-files \
  --flake .#<hostname> \
  root@<tailscale-ip>
```

**What happens:**
1. SSH key uploaded → facts gathered
2. **Kexec**: tarball uploaded → `kexec-run.sh` runs on target →
   saves SSH keys + network config → appends to initrd →
   `kexec --load` → `kexec -e` → reboot
3. **Kexec env boot**: tailscale-prepare copies state → tailscale
   reconnects → SSHD starts
4. **Reconnect**: nixos-anywhere polls SSH on same IP
5. **Disko**: partitions disk (ZFS)
6. **Install**: nixos-install writes system (+ `--extra-files`)
7. **Reboot**: into new NixOS

---

## 11. Post-boot

### 11.1 Verify

```sh
ssh root@<tailscale-ip>
zpool status rpool
tailscale ip -4
nixos-version
systemctl --failed
```

### 11.2 Generate permanent age key

The injected key was a temporary copy. Generate a fresh one:

```sh
ssh root@<tailscale-ip> "rm -f /var/lib/sops-nix/key.txt && \
  nix-shell -p age --run 'age-keygen -o /var/lib/sops-nix/key.txt'"
ssh root@<tailscale-ip> "grep -o 'age1[^ ]*' /var/lib/sops-nix/key.txt"
# → new key. Update .sops.yaml and run:
sops updatekeys --yes secrets/<hostname>/secrets.yaml
```

### 11.3 Deploy with deploy-rs

```sh
nix run .#deploy-rs -- .#<hostname> --skip-checks --magic-rollback false
```

---

## 12. Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `sh: kexec: cannot execute: required file not found` | Dynamic kexec binary in tmpfs | Use `pkgs.pkgsStatic.kexec-tools` |
| VM offline >2 min after kexec | tailscale-prepare mount failed | Wrong `rootDevice` or `rootFsType` |
| `tar: Archive is compressed` | gzip tar + `tar -xf` | Build uncompressed (`tar -cvf`) |
| SeaBIOS → `No bootable device` | OVMF not set before bootstrap | Switch VM to OVMF + q35 + EFI disk beforehand |
| `Failed to find a machine for remote build` | nix-daemon SSH to builder broken | `sudo ssh` once to accept host key |
| `no matching creation rules found` (sops) | Plaintext file at wrong path | Use `sops --encrypt --in-place` on the actual path |
| secrets decryption fails | Age key changed after disk wipe | Update `.sops.yaml` + `sops updatekeys` |

---

## 13. End-to-end checklist

- [ ] Target reachable over Tailscale
- [ ] Pre-flight recon done (root device, fstype, arch, boot mode)
- [ ] Host configs created (metadata, config, disko, parts, sops)
- [ ] Proxmox: OVMF + q35 + EFI disk applied, VM cold-rebooted
- [ ] Age key generated on target, `.sops.yaml` updated
- [ ] Secrets encrypted with sops
- [ ] Age key staged in `/tmp/extra-files`
- [ ] Kexec image built (static binaries, correct rootDevice)
- [ ] Host wired into `flake.nix` extraModules
- [ ] Justfile updated (ssh, gc, build, eval, deploy)
- [ ] kexec image builds ✅
- [ ] `nixos-anywhere` completes ✅
- [ ] New system boots and reconnects to tailnet
- [ ] Permanent age key generated, `.sops.yaml` updated
- [ ] deploy-rs works for ongoing management
