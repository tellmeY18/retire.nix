{
  hostname = "kenobi";
  system = "aarch64-linux";
  hostId = "a1b2c3d4"; # placeholder — generate with: head -c 4 /dev/urandom | od -A none -t x4 | tr -d ' '
  timezone = "Asia/Kolkata";
  locale = "en_US.UTF-8";
  stateVersion = "25.11";
  type = "nixos";
  users = [ "vysakh" ];
  roles = [
    "server"
    "k3s"
    "compute"
  ];

  deploy = {
    host = "100.73.101.89"; # Tailscale IP
    sshUser = "root";
    remoteBuild = true; # aarch64 builds on the target itself
  };
}
