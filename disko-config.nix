{
  disko.devices = {
    disk.nvme0n1 = {
      device = "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "500M"; # must use K/M/G/T units :contentReference[oaicite:2]{index=2}
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/efi";
            };
          };
          swap = {
            size = "16G";
            content = { type = "swap"; resumeDevice = true; };
          };
          pool = {
            size = "100%";
            content = { type = "zfs"; pool = "rpool"; };
          };
        };
      };
    };

    zpool.rpool = {
      type = "zpool";
      rootFsOptions = {
        compression = "lz4";
        xattr = "sa";
        acltype = "posixacl";
        "com.sun:auto-snapshot" = "true";
      };
      datasets = {
        "nixos/root" = { type = "zfs_fs"; mountpoint = "/"; };
        "nixos/home" = { type = "zfs_fs"; mountpoint = "/home"; };
        "nixos/nix" = { type = "zfs_fs"; mountpoint = "/nix"; };
        "nixos/var" = { type = "zfs_fs"; mountpoint = "/var"; };
      };
    };
  };
}

