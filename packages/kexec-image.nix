# packages/kexec-image.nix — Tailscale-aware kexec tarball for nixos-anywhere
#
# Build:   nix build .#packages.<system>.kexec-image
# Use:     nixos-anywhere --kexec ./result \
#            --flake .#<hostname> root@<tailscale-ip>
#
# Based on the nixos-images kexec-installer module.
# The kexec environment mounts the OLD root partition, copies the existing
# tailscaled.state into tmpfs, and starts tailscaled. This makes the kexec
# environment appear as the same tailscale node (same IP), so nixos-anywhere
# can reconnect over the tailnet after the kexec jump.
#
# Adjust rootDevice/rootFsType for your target.
{ pkgs, lib }:

let
  # ════════════════════════════════════════════════
  # CONFIGURE THESE for your target
  # ════════════════════════════════════════════════
  rootDevice = "/dev/sda2"; # OLD root partition (before disko wipes it)
  rootFsType = "ext4"; # filesystem of the old root
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOoUJulOP9ZLy8Ny2LgS6HT7WSg93a4eHwbA412LbOR5" # vysakh
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMgedb3cJt6ID0W2c8Fzgb+58tz/qWvuoAR3xmp1WHQZ" # mathewalex
  ];

  # Static iproute2 (no iptables linkage) for the kexec env
  # Static binaries for the kexec environment (tmpfs, no shared libs)
  iprouteStatic = pkgs.pkgsStatic.iproute2.override { iptables = null; };
  kexecStatic = pkgs.pkgsStatic.kexec-tools;

  # Path to nixpkgs NixOS modules
  modulesPath = "${pkgs.path}/nixos/modules";

  # Build a kexec-image NixOS config, then extract the kexecTarball derivation.
  kexecConfig = pkgs.nixos (
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        # netboot-minimal gives us a minimal initrd + kernel + tmpfs root.
        # This is the current standard way to build a kexec-capable image
        # in nixpkgs (the old installer/kexec/kexec.nix was removed).
        (modulesPath + "/installer/netboot/netboot-minimal.nix")
      ];

      # ── Tailscale — reconnects using old state ──
      services.tailscale.enable = true;

      # ── Pre-start: mount old root, copy tailscale state ──
      systemd.services.tailscale-prepare = {
        description = "Mount old root partition and copy Tailscale state";
        before = [ "tailscaled.service" ];
        requiredBy = [ "tailscaled.service" ];
        unitConfig.DefaultDependencies = false;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart =
            let
              c = "${pkgs.coreutils}";
              u = "${pkgs.util-linux}";
            in
            builtins.concatStringsSep " && " [
              "${c}/bin/mkdir -p /mnt/oldroot /var/lib/tailscale"
              "${u}/bin/mount -t ${rootFsType} -o ro ${rootDevice} /mnt/oldroot 2>/dev/null || true"
              "( ${c}/bin/test -f /mnt/oldroot/var/lib/tailscale/tailscaled.state"
              "  && ${c}/bin/cp /mnt/oldroot/var/lib/tailscale/tailscaled.state /var/lib/tailscale/"
              "  && ${c}/bin/chmod 600 /var/lib/tailscale/tailscaled.state )"
              "  || ${c}/bin/true"
              "${u}/bin/umount /mnt/oldroot 2>/dev/null || ${c}/bin/true"
            ];
        };
      };

      # ── SSH — nixos-anywhere reconnects here ──
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "prohibit-password";
        };
      };
      users.users.root.openssh.authorizedKeys.keys = sshKeys;

      # ── Required tools in the kexec env ──
      environment.systemPackages = with pkgs; [
        coreutils
        util-linux
        bash
      ];

      # ── Kernel modules for Proxmox/QEMU VirtIO ──
      boot.initrd.availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
      ];

      # ── Compress initrd with xz (smaller upload) ──
      boot.initrd.compressor = "xz";

      # ── Disable NetworkManager (netboot-minimal uses networkd) ──
      networking.networkmanager.enable = lib.mkForce false;

      system.stateVersion = "24.11";

      # ── Build a nixos-anywhere-compatible kexec tarball ──
      # mkForce: the netboot module defines a different kexecTarball format
      # (make-system-tarball), but nixos-anywhere expects the simpler format
      # with just initrd, bzImage, kexec, ip, and run script.
      system.build.kexecTarball = lib.mkForce (
        pkgs.runCommand "nixos-kexec-installer-x86_64-linux.tar.gz"
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

            # Copy boot assets
            cp "${config.system.build.netbootRamdisk}/initrd" kexec/initrd
            cp "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}" kexec/bzImage
            cp "${kexecStatic}/bin/kexec" kexec/kexec
            cp "${iprouteStatic}/bin/ip" kexec/ip

            # Verify binaries
            kexec/ip -V
            kexec/kexec --version

            # Generate the kexec-run script (substitutes @init@ and @kernelParams@)
            substituteAll \
              ${./kexec-run.sh} \
              kexec/run
            chmod +x kexec/run
            shellcheck -e SC3040 kexec/run

            # Create uncompressed tar (nixos-anywhere extracts with tar -xf)
            tar -cvf "$out" kexec
          ''
      );
    }
  );
in
kexecConfig.config.system.build.kexecTarball
