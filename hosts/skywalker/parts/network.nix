# hosts/skywalker/parts/network.nix — LAN + tailnet networking.
#
# Wired Realtek RTL8111 (enp6s0) on DHCP. There is also a USB wifi adapter
# (wlp10s0f3u1) — not configured; wire it up only if the box ever leaves the
# ethernet drop.
#
# Tailscale is enabled WITHOUT an authKeyFile, deliberately. The other hosts
# pull a pre-auth key out of sops because they are cloud VMs that must join
# the tailnet unattended on first boot. skywalker is a physical box on a desk:
# it was authenticated once by hand (`tailscale up`), and tailscaled's state
# lives in /var/lib/tailscale on the ZFS root, so it re-joins across reboots
# and redeploys by itself. That avoids a host age key, a .sops.yaml rule, a
# secrets/skywalker/ file, and sops-nix in the module list — none of which buy
# anything here. Add them only if this box starts being reinstalled from
# scratch regularly and needs to come back on the tailnet with no human.
{ ... }:
{
  networking = {
    useDHCP = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      # Anything reachable over the tailnet is already authenticated by
      # WireGuard; don't make tailnet peers fight the host firewall too.
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = [ "8.8.8.8" "1.1.1.1" ];
  };

  services.tailscale = {
    enable = true;
    # Opens the WireGuard UDP port so peers connect directly instead of
    # falling back to a DERP relay.
    openFirewall = true;
    extraUpFlags = [
      "--accept-dns" # MagicDNS via systemd-resolved split-DNS
      "--accept-routes" # reach the k3s pod/service CIDRs advertised by the cluster nodes
    ];
  };
}
