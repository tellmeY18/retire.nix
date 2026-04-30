# Bootstrap: macOS (nix-darwin)

How to set up a fresh Mac with this configuration.

## Prerequisites

- macOS installed
- Admin access
- Internet connection

## Steps

### 1. Install Nix

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 2. Clone this repository

```sh
git clone <repo-url> ~/.config/nix
cd ~/.config/nix
```

### 3. Bootstrap nix-darwin

On first run, nix-darwin needs to be bootstrapped:

```sh
nix run nix-darwin -- switch --flake .#Vysakhs-MacBook-Pro
```

### 4. Subsequent rebuilds

```sh
nh darwin switch .
```

Or with Home Manager standalone:

```sh
home-manager switch --flake .#mathewalex@Vysakhs-MacBook-Pro
```

## Notes

- Homebrew casks are managed by `nix-homebrew`. Nix will install Homebrew
  automatically on first `darwin-rebuild switch`.
- The Nix Apps symlink folder is at `/Applications/Nix Apps/`.
- Touch ID for sudo is enabled via `security.pam.services.sudo_local.touchIdAuth`.

## Troubleshooting

- **"cannot link ... /nix/var/nix/profiles/system"**: Run with `sudo` on first bootstrap.
- **Homebrew errors**: Ensure Rosetta is installed: `softwareupdate --install-rosetta`
- **Rebuild fails after macOS update**: Re-run the bootstrap command above.
