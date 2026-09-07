{
  hostname = "skywalker";
  system = "x86_64-linux";
  hostId = "c3cb4ad2"; # required for ZFS
  timezone = "Asia/Kolkata";
  locale = "en_US.UTF-8";
  # Fresh install off the current flake pin (nixpkgs 26.11-unstable). The
  # older hosts read 25.11 because that is when THEY were installed —
  # stateVersion is an install-time marker, not a thing to keep current.
  stateVersion = "26.11";
  type = "nixos";
  users = [ "vysakh" ];

  # GPU workstation/compute node — deliberately NOT a k3s member (yet).
  roles = [ "gpu" ];

  # Reached over the tailnet, like every other host. The LAN address was only
  # ever a bootstrap crutch: this box sits behind DHCP that reassigns leases
  # aggressively (192.168.165.205 got handed to a different machine mid-setup),
  # and the LAN it is on is not always the LAN you are on. MagicDNS is stable
  # regardless of either. Ryzen 3300X, 8 threads — builds its own closure.
  deploy = {
    host = "skywalker.tail477f2f.ts.net";
    sshUser = "root";
    remoteBuild = true;
  };
}
