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
  # helm-diff's plugin.yaml includes `platformHooks` (install/update hooks
  # for `helm plugin install`).  Helm fails to parse this field, and the
  # failure prevents ALL plugins from loading.  Strip the hooks section
  # since wrapHelm provides the binary directly.
  helm-diff-patched =
    pkgs.runCommand "helm-diff-patched-3.15.8"
      {
        src = pkgs.kubernetes-helmPlugins.helm-diff;
      }
      ''
        mkdir -p $out/helm-diff
        cp -r $src/helm-diff/* $out/helm-diff/
        ${pkgs.gnused}/bin/sed -i '/^platformHooks:/,/^[^ ]/d' $out/helm-diff/plugin.yaml
      '';

  # Wrap helm with plugins so `helm secrets`, `helm diff`, and git-sourced
  # charts Just Work. helm-git is needed for charts not published to a registry
  # (e.g. rustfs-operator which lives at github.com/rustfs/operator).
  #
  # Use the CURRENT helm (4.x), not a Helm 3 pin.  This used to pin Helm
  # 3.17.3 on the theory that `helm secrets` was Helm-3-only, but
  # helm-secrets 4.x ships a Helm-4-style plugin.yaml (`apiVersion: v1`,
  # `type: cli/v1`).  Helm 3 strict-decodes that manifest, fails on the
  # unknown `apiVersion` field, and then loads NO plugins at all — which
  # broke `helm secrets` and therefore every `helmfile` command that
  # touches an encrypted values file:
  #
  #   failed to load plugins: ... unknown field "apiVersion"
  #   Error: unknown command "secrets" for "helm"
  #
  # Helm 4 reads both the legacy and v1 plugin formats, so all three
  # plugins load (diff + helm-git as `legacy`, secrets as `v1`).
  helm-with-plugins = pkgs.wrapHelm pkgs.kubernetes-helm {
    plugins = [
      pkgs.kubernetes-helmPlugins.helm-secrets
      helm-diff-patched
      pkgs.kubernetes-helmPlugins.helm-git
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
