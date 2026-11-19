# hosts/yoda/configuration.nix — entry point (phase 2).
#
# yoda is an Oracle Cloud (OCI) KVM x86_64 VM — the 4th k3s node, a compute
# (agent) worker on the tailnet. The compute-node profile declares the
# services.k3s-cluster options and applies the compute node labels; the agent
# itself is enabled in parts/k3s.nix once the node's Tailscale IP is known.
{ ... }:
{
  imports = [
    ../../profiles/base.nix
    ../../profiles/k3s-compute-node.nix
    ./default.nix
  ];

  networking = {
    hostName = "yoda";
    hostId = "8c95266a";
  };

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;
}
