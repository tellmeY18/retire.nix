# Disko configuration for skywalker (bare-metal x86_64 desktop).
#
# TARGET: the internal NVMe ONLY — /dev/nvme0n1, Samsung MZVLB256HBHQ,
# 238.5 GB, currently holding Windows (ESP + MSR + NTFS + WinRE). All of it
# is destroyed.
#
# The disk is pinned by /dev/disk/by-id serial, NOT /dev/nvme0n1, so that a
# kernel enumeration change can never point disko at the wrong device.
# The 465 GB `sda` (Crucial MX500 in a USB enclosure) is NOT declared here
# and is therefore never touched.
#
# Layout: ESP + swap + ZFS root pool (mirrors kenobi/yoda/r2d2).
{
  disko.devices = {
    disk.nvme0n1 = {
      device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLB256HBHQ-000L2_S4DXNX0N750643";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/efi";
              mountOptions = [ "umask=0077" ];
            };
          };
          # 16 GiB — covers swap pressure on 8 GB RAM today and stays sane
          # after the planned RAM upgrade.
          swap = {
            size = "16G";
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
