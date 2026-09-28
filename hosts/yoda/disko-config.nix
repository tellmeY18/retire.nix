# Disko configuration for yoda (OCI KVM x86_64 VM).
# Single disk: sda (46.6 GB). nixos-anywhere wipes it and applies this layout.
# Layout: EFI + Swap + ZFS root pool (mirrors kenobi/r2d2).
#
# Layout is identical across the single-disk VMs, so it lives in one
# place. This file stays as the entry point because `disko --flake`
# and docs/bootstrap-nixos.md reference this path directly.
import ../../profiles/vm-zfs-disk.nix
