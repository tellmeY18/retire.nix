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
{ pkgs, lib, ... }:

let
  # Pin to Helm 3.x — helm-secrets and helmfile rely on `helm secrets` which
  # was removed in Helm 4 (no `secrets` subcommand).  The latest Helm 3
  # release is 3.17.3 (2025-06-04).  Once helm-secrets supports Helm 4,
  # this pin can be dropped.
  helm3 = pkgs.stdenv.mkDerivation rec {
    pname = "kubernetes-helm";
    version = "3.17.3";
    src = pkgs.fetchurl {
      url = "https://get.helm.sh/helm-v${version}-${
        {
          "x86_64-linux" = "linux-amd64";
          "aarch64-linux" = "linux-arm64";
          "aarch64-darwin" = "darwin-arm64";
          "x86_64-darwin" = "darwin-amd64";
        }
        .${pkgs.stdenv.hostPlatform.system}
          or (throw "unsupported system: ${pkgs.stdenv.hostPlatform.system}")
      }.tar.gz";
      sha256 =
        {
          "x86_64-linux" = "0sl9638pkky2dwap6pbf0mxri5bsrzrgsp6xg0fhwsvj07pj9cv4";
          "aarch64-darwin" = "15v9l5ccxlslwal6al5whzj8md3b4c3najms3fgj61kvw0yc9bl9";
        }
        .${pkgs.stdenv.hostPlatform.system}
          or (throw "hash unknown for ${pkgs.stdenv.hostPlatform.system}; run nix-prefetch-url --unpack <url> to add it");
    };
    sourceRoot = ".";
    installPhase = ''
      mkdir -p $out/bin
      # The prebuilt tarball extracts into a platform-specific subdirectory
      # (e.g. darwin-arm64/, linux-amd64/). Find helm wherever it landed.
      cp */helm $out/bin/helm
    '';
  };

  # helm-diff's plugin.yaml includes `platformHooks` (install/update hooks
  # for `helm plugin install`).  Helm 3 fails to parse this field, and the
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
  # NOTE: helm-secrets' nix package installs to helm-secrets/ and its
  # plugin.yaml declares name: "secrets". Helm 4's subcommand resolution
  # requires the plugin directory name to start with "helm-" for backwards
  # compatibility with the Helm 3 plugin model (it strips the "helm-"
  # prefix to derive the subcommand).  Directory name: helm-secrets →
  # subcommand: secrets.  Without this convention, `helm secrets` and
  # `helmfile sync` fail with "unknown command 'secrets'".
  # The nix package already installs to the correct directory name
  # (helm-secrets/), so no override is needed.
  helm-with-plugins = pkgs.wrapHelm helm3 {
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
