# Adding a New Host

This guide walks through adding a new host to the Nix configuration.
Thanks to auto-discovery, no `flake.nix` edits are required for basic hosts.

## Quick start

```sh
# 1. Copy the template
cp -r hosts/template hosts/<your-hostname>

# 2. Edit metadata
$EDITOR hosts/<your-hostname>/metadata.nix

# 3. Write your configuration
$EDITOR hosts/<your-hostname>/configuration.nix

# 4. Verify it's discovered
nix flake show
# You should see your host under nixosConfigurations or darwinConfigurations
```

## Step by step

### 1. Create the host directory

```sh
mkdir hosts/<hostname>
```

### 2. Create `metadata.nix`

This file tells the discovery system about your host:

```nix
{
  hostname = "<hostname>";          # Must be unique
  system = "x86_64-linux";          # or "aarch64-darwin" for macOS
  hostId = "<8-hex-chars>";         # Generate: head -c 4 /dev/urandom | od -A none -t x4 | tr -d ' '
  timezone = "America/New_York";
  locale = "en_US.UTF-8";
  stateVersion = "25.11";           # Current NixOS release
  type = "nixos";                   # "nixos" or "darwin"
  users = [ "youruser" ];
  roles = [ "laptop" "dev" ];       # See profiles/ for available roles
}
```

### 3. Create `configuration.nix`

This is your host's NixOS (or nix-darwin) entry point:

```nix
{ ... }:
{
  imports = [
    ./hardware-configuration.nix    # From nixos-generate-config
    # ./disko-config.nix            # Optional: declarative partitioning
  ];

  # Your host-specific config here
}
```

For NixOS, generate hardware config on the target machine:
```sh
nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix
```

### 4. (Optional) Add extra modules in `flake.nix`

If your host needs third-party modules (disko, sops-nix, etc.), add them
to `extraModules` in `flake.nix`:

```nix
nixosConfigurations = myLib.mkNixosConfigurations {
  hostsDir = ./hosts;
  extraModules = {
    <hostname> = [
      sops-nix.nixosModules.sops
      disko.nixosModules.disko
    ];
  };
};
```

### 5. (Optional) Add secrets

See `docs/secrets.md` for setting up sops-nix secrets for the new host.

### 6. (Optional) Enable remote deployment

Add a `deploy` block to your host's `metadata.nix`:

```nix
deploy = {
  host = "<tailscale-ip-or-hostname>";
  sshUser = "root";
  remoteBuild = true;
};
```

Then deploy from your workstation:

```sh
deploy .#<hostname>
```

See `docs/deploy.md` for full details.

### 7. (Optional) Add Home Manager

Create a Home Manager entry in `home/<hostname>/` or reuse existing
user configs. Add the homeConfiguration to `flake.nix`:

```nix
homeConfigurations."<user>@<hostname>" = myLib.mkHome {
  system = "<system>";
  modules = [ ./home/linux-home.nix ];  # or a custom entry point
};
```

## Validation

```sh
# Check it evaluates
nix flake check

# Build (dry-run)
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --dry-run

# Full build (will download/compile)
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel
```

## Example: vm-test

The `hosts/vm-test/` host is a minimal example that exists purely to
validate the auto-discovery system. It has no hardware config and can be
evaluated but not deployed to real hardware.
