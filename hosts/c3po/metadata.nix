{
  hostname = "c3po";
  system = "x86_64-linux";
  hostId = "663cc5c7"; # required for ZFS (8 hex chars)
  timezone = "Asia/Kolkata";
  locale = "en_US.UTF-8";
  stateVersion = "25.11";
  type = "nixos";
  users = [ "vysakh" ];
  roles = [
    "server"
    "storage"
    "zfs"
  ];

  deploy = {
    host = "100.109.132.76"; # Tailscale IP
    sshUser = "root";
    remoteBuild = true;
  };
}
