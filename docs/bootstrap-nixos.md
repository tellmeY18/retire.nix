# Bootstrap: NixOS

How to go from a fresh NixOS installer to a fully configured host.

## Prerequisites

- NixOS installer booted (USB or netboot)
- Internet connection
- An age key for sops (see `docs/secrets.md`)

## Steps

### 1. Partition and mount disks

If using disko (like the `chopper` host):

```sh
# From the installer environment
sudo nix --experimental-features "nix-command flakes" run \
  github:nix-community/disko -- --mode disko /tmp/nix-config/hosts/<hostname>/disko-config.nix
```

Or partition manually and mount to `/mnt`.

### 2. Generate hardware config

```sh
nixos-generate-config --root /mnt --show-hardware-config > /tmp/hardware-configuration.nix
```

### 3. Clone this repository

```sh
sudo git clone <repo-url> /mnt/etc/nixos
cd /mnt/etc/nixos
```

### 4. Create your host

```sh
cp -r hosts/template hosts/<hostname>
cp /tmp/hardware-configuration.nix hosts/<hostname>/
$EDITOR hosts/<hostname>/metadata.nix
$EDITOR hosts/<hostname>/configuration.nix
```

### 5. Set up secrets

```sh
# Get the host's age key (after first boot you'll use the SSH host key)
# For initial install, generate a temporary key:
age-keygen -o /mnt/var/lib/sops-nix/key.txt

# Add the public key to .sops.yaml and encrypt secrets
sops secrets/<hostname>/secrets.yaml
```

### 6. Install

```sh
sudo nixos-install --flake /mnt/etc/nixos#<hostname>
```

### 7. Reboot and switch

```sh
reboot
# After login:
cd /etc/nixos
nh os switch .
```

## Post-install

- Set user passwords: `sudo passwd <username>`
- Verify Tailscale: `sudo tailscale up`
- Verify services: `systemctl status`
