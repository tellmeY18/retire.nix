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
  # Daily-driver workstation; left the k3s cluster 2026-11-16.
  roles = [
    "laptop"
    "zfs"
    "workstation"
  ];

  # deploy-rs configuration — see docs/deploy.md
  deploy = {
    host = "100.107.213.17"; # Tailscale IP
    sshUser = "root";
    # Build remotely via ssh-ng://. Requires the deploying user to be in
    # nix.settings.trusted-users on the Mac (see profiles/base.nix).
    remoteBuild = true;
  };
}
