# Disko configuration for r2d2 (x86_64 Proxmox VM).
# Single disk (will be resized): sda (40 GB → bigger).
# Layout: EFI + Swap + ZFS root pool (mirrors kenobi/disko-config.nix).
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
