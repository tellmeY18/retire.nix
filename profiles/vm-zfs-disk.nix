# profiles/vm-zfs-disk.nix — disko layout shared by the single-disk VMs
# (kenobi, r2d2, yoda).
#
# Single disk: sda. Layout: EFI + Swap + ZFS root pool.
#
# These three hosts had byte-identical layouts; this is that layout, unchanged.
# A host that needs a DIFFERENT layout should keep its own disko-config.nix
# rather than growing options here — chopper, c3po and skywalker already do.
#
# Note: each host still has its own hosts/<name>/disko-config.nix which simply
# imports this file, because `disko --flake ...#<host>` and the bootstrap docs
# reference that per-host path directly.
{
  disko.devices = {
    disk.sda = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/efi";
              mountOptions = [ "umask=0077" ];
            };
          };
          swap = {
            size = "4G";
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };
          pool = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };

    zpool.rpool = {
      type = "zpool";
      options = {
        ashift = "12";
      };
      rootFsOptions = {
        compression = "zstd";
        xattr = "sa";
        acltype = "posixacl";
        atime = "off";
        "com.sun:auto-snapshot" = "true";
      };
      datasets = {
        "nixos/root" = {
          type = "zfs_fs";
          mountpoint = "/";
        };
        "nixos/home" = {
          type = "zfs_fs";
          mountpoint = "/home";
        };
        "nixos/nix" = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options.compression = "zstd";
        };
        "nixos/var" = {
          type = "zfs_fs";
          mountpoint = "/var";
          options.compression = "zstd";
        };
      };
    };
  };
}
