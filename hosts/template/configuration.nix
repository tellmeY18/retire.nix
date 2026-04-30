# Template host configuration
# Copy this directory and customize for your new host.
{ ... }:
{
  imports = [
    # ./hardware-configuration.nix  # Generate with: nixos-generate-config
    # ./disko-config.nix            # Optional: declarative disk partitioning
  ];

  # Host-specific networking is typically set via metadata.nix.
  # Add additional host-specific config below.
}
