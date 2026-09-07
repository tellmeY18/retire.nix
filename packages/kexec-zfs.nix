# packages/kexec-zfs.nix — plain ZFS-capable kexec tarball for nixos-anywhere
#
# Build:   nix build .#packages.x86_64-linux.kexec-zfs
# Use:     nixos-anywhere --kexec ./result --flake .#<host> root@<ip>
#
# WHY THIS EXISTS
# ---------------
# OpenZFS only supports kernels up to the current LTS-ish line. The NixOS
# 26.05 minimal ISO now boots kernel 7.2.x, which OpenZFS does not build
# against, so the installer environment has no `zfs` module and `disko`
# cannot create a zpool:
#
#   modprobe: FATAL: Module zfs not found in directory .../7.2.3
#
# This flake is pinned to kernel 6.18.45, which OpenZFS does support. So we
# build a kexec image from OUR nixpkgs, jump into it, and run disko there.
#
# Differs from kexec-image.nix, which is the Tailscale-aware variant used to
# reinstall a host that is only reachable over the tailnet (it mounts the old
# root to recover tailscaled.state). This one is for LAN-reachable targets:
# no Tailscale, no old-root mount, just ZFS + SSH + DHCP.
{ pkgs }:

let
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOoUJulOP9ZLy8Ny2LgS6HT7WSg93a4eHwbA412LbOR5" # vysakh
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEAAcrvQNZlE5PT9OhS6s7SH+gHCJB2sqIRo2mITwnER" # vysakh (2)
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMgedb3cJt6ID0W2c8Fzgb+58tz/qWvuoAR3xmp1WHQZ" # mathewalex
    # c3po's own installer key. REQUIRED: the install runs detached on c3po,
    # so there is no forwarded agent once your SSH session ends. After the
    # kexec jump nixos-anywhere reconnects as c3po — if this key is missing
    # the install stalls forever on "Permission denied (publickey)".
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHdFJv5+TjlcSd1yhAD/hkjlD6mGAzJqmet4MTtRaef" # c3po-installer
  ];

  # Static binaries for the kexec environment (tmpfs, no shared libs).
  iprouteStatic = pkgs.pkgsStatic.iproute2.override { iptables = null; };
  kexecStatic = pkgs.pkgsStatic.kexec-tools;

  modulesPath = "${pkgs.path}/nixos/modules";

  kexecConfig = pkgs.nixos (
    { config
    , pkgs
    , lib
    , ...
    }:
    {
      imports = [
        (modulesPath + "/installer/netboot/netboot-minimal.nix")
      ];

      # ── The entire point: a ZFS-capable installer environment ──
      boot.supportedFilesystems = [ "zfs" ];
      # This env only ever creates a fresh pool; never force-import a
      # foreign one (26.11 default, and the safe choice on a box whose disk
      # we are about to wipe).
      boot.zfs.forceImportRoot = false;
      # Any stable value; the kexec env is ephemeral and never imports a pool
      # it did not just create. disko writes the real host's hostId itself.
      networking.hostId = "deadbeef";

      # ── SSH — nixos-anywhere reconnects here after the kexec jump ──
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "prohibit-password";
        };
      };
      users.users.root.openssh.authorizedKeys.keys = sshKeys;

      environment.systemPackages = with pkgs; [
        coreutils
        util-linux
        bash
        zfs
      ];

      # Bare-metal desktop: NVMe + SATA + USB, no virtio.
      boot.initrd.availableKernelModules = [
        "nvme"
        "ahci"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];

      boot.initrd.compressor = "xz";

      networking.useDHCP = true;
      networking.networkmanager.enable = lib.mkForce false;

      system.stateVersion = "24.11";

      # nixos-anywhere expects the simple tarball format (initrd, bzImage,
      # kexec, ip, run) — not the netboot module's make-system-tarball.
      system.build.kexecTarball = lib.mkForce (
        pkgs.runCommand "nixos-kexec-zfs-x86_64-linux.tar"
          {
            init = config.system.build.toplevel + "/init";
            kernelParams = builtins.toString config.boot.kernelParams;
            nativeBuildInputs = [
              pkgs.buildPackages.shellcheck
              pkgs.buildPackages.gnutar
              pkgs.buildPackages.gzip
              pkgs.buildPackages.cpio
            ];
          }
          ''
            mkdir kexec

            cp "${config.system.build.netbootRamdisk}/initrd" kexec/initrd
            cp "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}" kexec/bzImage
            cp "${kexecStatic}/bin/kexec" kexec/kexec
            cp "${iprouteStatic}/bin/ip" kexec/ip

            kexec/ip -V
            kexec/kexec --version

            substituteAll \
              ${./kexec-run.sh} \
              kexec/run
            chmod +x kexec/run
            shellcheck -e SC3040 kexec/run

            tar -cvf "$out" kexec
          ''
      );
    }
  );
in
kexecConfig.config.system.build.kexecTarball
