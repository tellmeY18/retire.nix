{
  hostname = "yoda";
  system = "x86_64-linux";
  hostId = "8c95266a"; # required for ZFS (8 hex chars)
  timezone = "Asia/Kolkata";
  locale = "en_US.UTF-8";
  stateVersion = "25.11";
  type = "nixos";
  users = [ "vysakh" ];

  # Intended final roles — NOT yet wired in phase 1 (bootstrap).
  # Phase 2 imports profiles/k3s-compute-node.nix + parts/k3s.nix.
  roles = [
    "k3s"
    "compute"
  ];

  # ── deploy-rs ──────────────────────────────────────────────────────────
  # Phase 1: the node is only reachable over its OCI public IP (no Tailscale
  # yet). yoda has ~1 GB RAM and cannot build a NixOS closure, so builds are
  # offloaded to chopper (buildHost) and only the finished closure is copied
  # to yoda. In phase 2, switch `host` to yoda's Tailscale IP.
  deploy = {
    host = "140.245.252.206"; # OCI public IP — becomes the tailnet IP in phase 2
    sshUser = "root";
    remoteBuild = false; # build on chopper, copy closure to yoda
    buildHost = "chopper.tail477f2f.ts.net"; # x86_64-linux builder
  };
}
