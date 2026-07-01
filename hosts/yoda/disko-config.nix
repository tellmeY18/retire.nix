# Disko configuration for yoda (OCI KVM x86_64 VM).
# Single disk: sda (46.6 GB). nixos-anywhere wipes it and applies this layout.
# Layout: EFI + Swap + ZFS root pool (mirrors kenobi/r2d2).
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
          # 4 GiB swap — important on a 1 GB-RAM VM (no zram in phase 1).
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
        ashift = "12"; # 4K sectors behind OCI block volume
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
