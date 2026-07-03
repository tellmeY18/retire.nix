# hosts/yoda/default.nix — parts composition (phase 2).
#
# yoda is the 4th k3s node: an x86_64 OCI compute/agent node on the tailnet.
#
#   - sops     : Tailscale auth key + shared k3s join token
#   - boot     : UEFI + systemd-boot + ZFS + OCI virtio/serial console
#   - network  : DHCP on ens3, Tailscale, host-gw pod routes, firewall
#   - users    : vysakh + root SSH keys, zsh, openssh
#   - zram     : compressed RAM swap — essential on this ~1 GB box
#
# NOT included yet (phase 2): ./sops.nix, ./parts/k3s.nix, Tailscale.
# The k3s agent itself (parts/k3s.nix) and the compute-node profile are wired
# in once the node has joined the tailnet and its static Tailscale IP is known
# (k3s needs that IP for --node-ip). See parts/k3s.nix.
{ lib, ... }:
{
  system.stateVersion = "25.11";

  imports = [
    ./sops.nix
    ./parts/boot.nix
    ./parts/network.nix
    ./parts/users.nix
    ./parts/k3s.nix
    ../../profiles/zram.nix
  ];

  # ZRAM swap — this box has only ~1 GB RAM, so compressed RAM swap is the
  # difference between surviving and OOM-killing kubelet/containerd. zstd for
  # the best compression ratio (RAM, not CPU, is the bottleneck here).
  profiles.zram = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # ── Closure slimming (kept from bootstrap) ────────────────────────────
  # Still valuable in phase 2: a smaller closure means faster, RAM-safer
  # deploy-rs copies onto this tiny box.

  # Drop all documentation. The NixOS manual in particular drags the
  # ~196 MB nixpkgs `source` into the closure.
  documentation.enable = lib.mkForce false;
  documentation.man.enable = lib.mkForce false;
  documentation.info.enable = lib.mkForce false;
  documentation.doc.enable = lib.mkForce false;
  documentation.nixos.enable = lib.mkForce false;

  # Build only the locale we use instead of the full glibc-locales set.
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];

  # Don't pin the nixpkgs flake source (~196 MB) into the system via the
  # flake registry / NIX_PATH — useless on a deploy-rs-managed node and the
  # single biggest NAR in the closure.
  nixpkgs.flake.setFlakeRegistry = false;
  nixpkgs.flake.setNixPath = false;

  # Minor extras not needed to boot / SSH / run ZFS / k3s.
  programs.command-not-found.enable = false;

  # OCI KVM guest: firmware/microcode is the hypervisor's job.
  hardware.enableRedistributableFirmware = lib.mkForce false;
}
