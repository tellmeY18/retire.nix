# profiles/k3s-node.nix — NixOS profile for k3s cluster nodes
#
# Installs cluster-admin tooling at the system level and imports the
# k3s-cluster NixOS module.  This profile intentionally does NOT call
# services.k3s-cluster.enable; that decision (and the role — server-init,
# server, agent, quorum) belongs to each host's own configuration so that
# different nodes can carry different responsibilities.
#
# Regular users: after the system is up, copy /etc/rancher/k3s/k3s.yaml to
# ~/.kube/config (adjusting the server URL to the node's Tailscale address if
# needed).  Root gets kubectl access automatically via KUBECONFIG below.
#
# TODO: helm-secrets plugin is NOT a nixpkgs package.  Install it manually
# once after bootstrapping:
#   helm plugin install https://github.com/jkroepke/helm-secrets --version v4.6.0
# helmfile picks it up automatically via the HELM_SECRETS_BACKEND env var.
{ pkgs, ... }:
{
  imports = [ ../modules/services/k3s.nix ];

  environment = {
    systemPackages = with pkgs; [
      kubectl
      kubernetes-helm
      helmfile
      k9s
      sops
    ];

    # Gives the root user (and sudo sessions) immediate kubectl access.
    # Regular users should copy /etc/rancher/k3s/k3s.yaml to ~/.kube/config.
    variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };
}
