# Disko configuration for kenobi (OCI aarch64 VM).
# Single disk: sda (100 GB).
# Layout: EFI + Swap + ZFS root pool.
#
# Layout is identical across the single-disk VMs, so it lives in one
# place. This file stays as the entry point because `disko --flake`
# and docs/bootstrap-nixos.md reference this path directly.
import ../../profiles/vm-zfs-disk.nix
