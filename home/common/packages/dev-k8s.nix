# home/common/packages/dev-k8s.nix — Kubernetes/cluster admin tooling for home-manager
#
# Installs the k8s client-side toolset for any user whose home profile includes
# this module. Shell aliases are defined via home.shellAliases so they work
# across both zsh and bash without duplicating configuration.
#
# Helm plugins (helm-secrets, helm-diff, helm-git) are baked into the helm
# binary via wrapHelm, and helmfile is configured to use the same plugin
# directory. No manual `helm plugin install` step is needed.
#
# NOTE: cmctl is packaged as pkgs.cmctl in nixpkgs (>= 24.05).  If the build
# fails, check nixpkgs for the correct attribute name (it was briefly
# pkgs.cert-manager in some branches).
{ pkgs, ... }:
let
  # Wrap helm with plugins so `helm secrets`, `helm diff`, and git-sourced
  # charts Just Work. helm-git is needed for charts not published to a registry
  # (e.g. rustfs-operator which lives at github.com/rustfs/operator).
  helm-with-plugins = pkgs.wrapHelm pkgs.kubernetes-helm {
    plugins = with pkgs.kubernetes-helmPlugins; [
      helm-secrets
      helm-diff
      helm-git
    ];
  };

  # Point helmfile at the same plugin directory so `helmfile sync` can call
  # `helm secrets decrypt` / `helm diff` transparently.
  helmfile-with-plugins = pkgs.helmfile-wrapped.override {
    inherit (helm-with-plugins) pluginsDir;
  };
in
{
  home.packages = with pkgs; [
    kubectl
    helm-with-plugins
    helmfile-with-plugins
    k9s
    sops
    kubectl-cnpg # `kubectl cnpg status`, `kubectl cnpg backup`, etc.
    cmctl # cert-manager CLI — see note above if attribute not found
  ];

  home.shellAliases = {
    k = "kubectl";
    kns = "kubectl config set-context --current --namespace";
    kctx = "kubectl config use-context";
  };
}
