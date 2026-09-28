# profiles/tailscale-online.nix — gate k3s on tailscale0 actually being UP.
#
# Imported by the hosts whose tailscale0 can take a while to appear (c3po on
# WiFi, yoda on a cloud VM).
#
# The k3s module orders k3s after tailscaled.service, but that only means the
# DAEMON is running — NOT that the WireGuard tunnel is established and
# tailscale0 has its IP. WiFi association + DHCP + Tailscale handshake can
# take 30–60s. If k3s starts before tailscale0 exists, flannel
# (--flannel-iface=tailscale0) can't find its interface and the node stays
# NotReady permanently.
{ pkgs, ... }:
{
  systemd.services.tailscale-online = {
    description = "Wait for tailscale0 interface to be UP";
    after = [
      "tailscaled.service"
      "network-online.target"
    ];
    requires = [ "tailscaled.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    before = [ "k3s.service" ];
    # coreutils (timeout/sleep), bash (sh), iproute2 (ip), gnugrep (grep) must
    # be on PATH — the ExecStart shells out to all of them. Without this the
    # unit exits 127 ("sh: No such file or directory"), which fails activation
    # and triggers a deploy-rs rollback.
    path = [
      pkgs.coreutils
      pkgs.bash
      pkgs.iproute2
      pkgs.gnugrep
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Wait up to 90s for tailscale0 to appear and have RUNNING state.
      ExecStart = ''/bin/sh -c "timeout 90 sh -c 'until ip link show tailscale0 2>/dev/null | grep -q UP; do sleep 2; done'"'';
    };
  };
}
