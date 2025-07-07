# Unified Nix Flake: macOS (nix-darwin) + NixOS-on-ZFS

This repository provides a unified [Nix flake](https://nixos.wiki/wiki/Flakes) for managing both macOS (via [nix-darwin](https://github.com/LnL7/nix-darwin)) and NixOS (with ZFS and [disko](https://github.com/nix-community/disko)) configurations. It enables reproducible, declarative system setups for both platforms, leveraging a single source of truth.

---

## Features

- **Single Flake for Multiple Systems:** Manage both macOS and NixOS hosts from one repository.
- **macOS Support:** Uses `nix-darwin` for system configuration and integrates with Homebrew for additional packages and casks.
- **NixOS on ZFS:** Automated ZFS root and dataset provisioning using `disko`.
- **Secrets Management:** [sops-nix](https://github.com/Mic92/sops-nix) integration for secure secrets handling (NixOS).
- **Nix Index Database:** Fast file search with `nix-index` and prebuilt databases.
- **Formatter:** Consistent formatting with `nixpkgs-fmt` for both Darwin and Linux.
- **Modular Host Configurations:** Clean separation of host-specific and shared modules.

---

## Repository Structure

```
nix/
├── flake.nix                # Flake entrypoint: inputs, outputs, host configs
├── hosts/
│   ├── darwin/
│   │   ├── configuration.nix    # Main macOS config (nix-darwin)
│   │   ├── homebrew.nix         # Homebrew taps, brews, casks
│   │   ├── packages.nix         # System packages (Darwin)
│   │   ├── programs.nix         # Shell and CLI programs
│   │   └── services.nix         # macOS-specific services (e.g., AeroSpace)
│   └── chopper/
│       ├── configuration.nix    # Main NixOS config for "chopper" host
│       ├── hardware-configuration.nix # Auto-generated hardware config
│       ├── disko-config.nix     # Disk layout and ZFS pools (disko)
│       └── modules/             # Host-specific NixOS modules
```

---

## Usage

### Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled (`experimental-features = nix-command flakes`)
- For macOS: [nix-darwin](https://github.com/LnL7/nix-darwin) installed
- For NixOS: Installer with ZFS and [disko](https://github.com/nix-community/disko) support

### 1. Clone the Repository

```sh
git clone https://github.com/yourusername/your-nix-flake.git
cd your-nix-flake/nix
```

### 2. macOS (nix-darwin) Setup

#### Switch to the flake configuration:

```sh
darwin-rebuild switch --flake .#Vysakhs-MacBook-Pro
```

- This will apply the configuration defined in `hosts/darwin/configuration.nix` and related files.
- Homebrew packages and casks are managed declaratively via `homebrew.nix`.

#### Notes

- The primary user is set to `mathewalex` (edit as needed).
- Touch ID for sudo is enabled.
- System packages, fonts, and services are managed via Nix.

### 3. NixOS (ZFS, Disko) Setup

#### Install or rebuild the "chopper" host:

```sh
sudo nixos-rebuild switch --flake .#chopper
```

- Disk layout and ZFS pools are defined in `hosts/chopper/disko-config.nix`.
- Hardware configuration is in `hardware-configuration.nix`.
- Additional modules (e.g., ZFS, Nextcloud, Cockpit) are included via the `modules/` directory.

#### Disk Provisioning

- The `disko` module will partition and format disks as specified.
- ZFS datasets are created for `/`, `/home`, `/nix`, and `/var`.

#### Secrets

- [sops-nix](https://github.com/Mic92/sops-nix) is included for secrets management (see `sops-nix` documentation for setup).

---

## Adding or Modifying Hosts

- Add new host configurations under `nix/hosts/<hostname>/`.
- Reference new hosts in `flake.nix` under `darwinConfigurations` or `nixosConfigurations`.
- Use modular imports for reusable or host-specific logic.

---

## Formatting

Format all Nix files using:

```sh
nix fmt
```

---

## References

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [disko](https://github.com/nix-community/disko)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)

---

## License
See [LICENSE](LICENSE) for details.
---

**Happy hacking with Nix!**
