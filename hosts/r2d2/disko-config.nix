# Disko configuration for r2d2 (x86_64 Proxmox VM).
# Single disk (will be resized): sda (40 GB → bigger).
# Layout: EFI + Swap + ZFS root pool (mirrors kenobi/disko-config.nix).
#
# Layout is identical across the single-disk VMs, so it lives in one
# place. This file stays as the entry point because `disko --flake`
# and docs/bootstrap-nixos.md reference this path directly.
import ../../profiles/vm-zfs-disk.nix
