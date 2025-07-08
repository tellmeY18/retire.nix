# Unified Nix Flake: macOS (nix-darwin) + NixOS

This repository provides a unified [Nix flake](https://nixos.wiki/wiki/Flakes) for managing both macOS (via [nix-darwin](https://github.com/LnL7/nix-darwin)) and NixOS configurations. It enables reproducible, declarative system setups for both platforms from a single source of truth.

## Features

- [x] **Single Flake for Multiple Systems:** Manage both macOS and NixOS hosts from one repository
- [x] **macOS Support:** Uses `nix-darwin` for system configuration with Homebrew integration
- [x] **NixOS with ZFS:** Configured with ZFS root and dataset provisioning using `disko`
- [x] **Modular Design:** Clean separation between host-specific and shared modules
- [ ] **Secrets Management:** Integration with [sops-nix](https://github.com/Mic92/sops-nix) for secure secrets handling
- [ ] **Sane Deployment:** Integration with [deploy-rs](https://github.com/serokell/deploy-rs) for secure secrets handling
- [x] **Nix Utilities:** Includes formatting tools and nix-index for better developer experience

## Repository Structure

```
.
├── flake.nix                # Flake entrypoint: inputs, outputs, host configs
├── hosts/                   # Host-specific configurations
│   ├── darwin/              # macOS configurations
│   └── chopper/             # NixOS configuration for "chopper" host
├── modules/                 # Shared NixOS modules
│   ├── arr.nix              # Arr stack configuration
│   ├── conduit.nix          # Conduit Matrix homeserver
│   ├── esp.nix              # ESP-related tools
│   ├── nextcloud.nix        # Nextcloud server configuration
│   └── zfs.nix              # ZFS configuration and utilities
├── overlays/                # Nixpkgs overlays
├── packages/                # Custom packages
│   ├── chopper/             # Packages specific to chopper
│   ├── darwin/              # Packages specific to macOS
│   └── default.nix          # Package definitions
└── scripts/                 # Helper scripts
```

## Usage

### macOS (nix-darwin)

```sh
nh darwin switch <PATH>
```

### NixOS

```sh
nh os switch <PATH>
```

## Customization

- Add new host configurations under `hosts/<hostname>/`
- Reference new hosts in `flake.nix` under the appropriate section
- Create reusable modules in the `modules/` directory
- Add custom packages in the `packages/` directory

## Common Commands

```sh
# Update flake inputs
nix flake update

# Check system generation history
nix profile history --profile /nix/var/nix/profiles/system

# Format nix files
nix fmt

# Search packages
nix search nixpkgs <package-name>

# Start a dev shell
nix develop
```

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [disko](https://github.com/nix-community/disko)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)

## License

See [LICENSE](LICENSE) for details.
