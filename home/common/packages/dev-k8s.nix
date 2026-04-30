# home/common/packages/dev-k8s.nix — Kubernetes/cluster admin tooling for home-manager
#
# Installs the k8s client-side toolset for any user whose home profile includes
# this module. Shell aliases are defined via home.shellAliases so they work
# across both zsh and bash without duplicating configuration.
#
# NOTE: helm-secrets is NOT a nixpkgs package — it is a helm plugin.
# Install it once after bootstrapping:
#   helm plugin install https://github.com/jkroepke/helm-secrets --version v4.6.0
# helmfile picks it up automatically from the helm plugins directory.
# TODO: automate this with a home.activation script once the install is idempotent.
#
# NOTE: cmctl is packaged as pkgs.cmctl in nixpkgs (>= 24.05).  If the build
# fails, check nixpkgs for the correct attribute name (it was briefly
# pkgs.cert-manager in some branches).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    helmfile
    k9s
    sops
    cmctl # cert-manager CLI — see note above if attribute not found
  ];

  home.shellAliases = {
    k = "kubectl";
    kns = "kubectl config set-context --current --namespace";
    kctx = "kubectl config use-context";
  };
}
