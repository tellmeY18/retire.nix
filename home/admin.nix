# home/admin.nix — infra/cluster administration tooling for an operator account.
#
# The sops master age key lives at ~/.config/sops/age/keys.txt and the
# kubeconfig at ~/.kube/glug-infra.yaml; both are installed out-of-band and
# never enter the Nix store.
{ config, pkgs, ... }:
{
  # kubectl, wrapped helm/helmfile (secrets/diff/git plugins), k9s, sops, ...
  imports = [ ./common/packages/dev-k8s.nix ];

  home.sessionVariables.KUBECONFIG = "${config.home.homeDirectory}/.kube/glug-infra.yaml";

  home.packages = with pkgs; [
    age
    deploy-rs
    git
    jujutsu
    just
  ];
}
