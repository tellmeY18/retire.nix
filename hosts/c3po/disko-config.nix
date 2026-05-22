# hosts/c3po/disko-config.nix — ZFS root on single 238GB SSD
# nixos-anywhere will wipe the disk and apply this layout.
{ ... }:
{
  disko.devices = {
    disk.main = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          zfs = {
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
        autotrim = "on";
      };
      rootFsOptions = {
        compression = "zstd";
        atime = "off";
        xattr = "sa";
        acltype = "posixacl";
        "com.sun:auto-snapshot" = "false";
      };

      datasets = {
        "root" = {
          type = "zfs_fs";
          mountpoint = "/";
          options.mountpoint = "legacy";
        };
        "nix" = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options.mountpoint = "legacy";
          options.compression = "zstd";
          options.atime = "off";
        };
        "home" = {
          type = "zfs_fs";
          mountpoint = "/home";
          options.mountpoint = "legacy";
        };
        "storage" = {
          type = "zfs_fs";
          mountpoint = "/storage";
          options.mountpoint = "legacy";
          options.compression = "zstd";
          options.recordsize = "1M"; # large recordsize for bulk storage
        };
      };
    };
  };
}
