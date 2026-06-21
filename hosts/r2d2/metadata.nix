{
  hostname = "r2d2";
  system = "x86_64-linux";
  hostId = "f5074045";
  timezone = "Asia/Kolkata";
  locale = "en_US.UTF-8";
  stateVersion = "25.11";
  type = "nixos";
  users = [ "vysakh" ];
  roles = [
    "k3s"
    "compute"
  ];

  deploy = {
    host = "100.82.170.61"; # Tailscale IP
    sshUser = "root";
    remoteBuild = true;
  };
}
