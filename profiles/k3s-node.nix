# profiles/k3s-node.nix — NixOS profile for k3s cluster nodes
#
# Installs cluster-admin tooling at the system level and imports the
# k3s-cluster NixOS module.  This profile intentionally does NOT call
# services.k3s-cluster.enable; that decision (and the role — server-init,
# server, agent, quorum) belongs to each host's own configuration so that
# different nodes can carry different responsibilities.
#
# Out-of-the-box kubectl access:
#   - The k3s module writes /etc/rancher/k3s/k3s.yaml as 0640 root:wheel,
#     so any user in the `wheel` group can read it directly.
#   - This profile sets KUBECONFIG=/etc/rancher/k3s/k3s.yaml as a system-wide
#     environment variable, so `kubectl`, `helm`, `k9s` etc. work in any
#     freshly-opened login shell on the node with no further setup.
#   - Note: environment.variables only reaches NEW login sessions. After a
#     `nh os switch` you must re-login (or `exec zsh`, or `source /etc/zshenv`)
#     for the variable to be visible. Until then, fall back to one of:
#         sudo k3s kubectl get nodes
#         KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get nodes
#
# helm-secrets plugin is NOT a nixpkgs package. Install it manually once after
# bootstrapping (helmfile picks it up via the helm plugins directory):
#   helm plugin install https://github.com/jkroepke/helm-secrets --version v4.6.0
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

    # Default KUBECONFIG for every user on this host. Combined with the
    # 0640 root:wheel mode set by modules/services/k3s.nix, this gives any
    # admin (wheel-group) user immediate kubectl access without sudo.
    variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };
}
