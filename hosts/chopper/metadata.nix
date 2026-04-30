{
  # Host metadata — consumed by lib/default.nix host discovery
  hostname = "chopper";
  system = "x86_64-linux";
  hostId = "91d4eb37";
  timezone = "Asia/Kolkata";
  locale = "en_US.UTF-8";
  stateVersion = "24.11";
  type = "nixos"; # "nixos" or "darwin"
  users = [ "vysakh" ];
  roles = [
    "laptop"
    "server"
    "zfs"
    "wayland"
    "dev"
  ];
}
