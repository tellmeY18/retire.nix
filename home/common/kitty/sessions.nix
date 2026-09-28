# home/common/kitty/sessions.nix
#
# Declarative kitty session files.
#
# Each file below is written to
# ~/.config/kitty/sessions/<name>.kitty-session and picked up by the session
# browser bound to kitty_mod+s (see ./default.nix).
#
# Session file grammar reference: `docs/sessions.rst` in the kitty source.
# The directives used here are `new_tab`, `cd`, `layout`, `launch` and `focus`.
#
# `focus` takes NO argument — it focuses the most recently launched window, so
# it has to follow the `launch` line it applies to. Omit the command on a
# `launch` line for a plain shell.
{ config, ... }:

let
  home = config.home.homeDirectory;

  # Every cluster command in this repo must run against the glug-infra
  # cluster (see CLAUDE.md), so bake it into the session rather than
  # relying on the shell having exported it.
  kubeconfig = "KUBECONFIG=${home}/.kube/glug-infra.yaml";
in
{
  xdg.configFile = {
    "kitty/sessions/development.kitty-session".text = ''
      new_tab Development
      cd ${home}/Projects
      layout splits
      launch --title Editor nvim
      focus
      launch --title Shell
    '';

    "kitty/sessions/nix.kitty-session".text = ''
      new_tab Nix
      cd ${home}/.config/nix
      layout splits
      launch --title Editor nvim
      focus
      launch --title Build
    '';

    "kitty/sessions/cluster-admin.kitty-session".text = ''
      new_tab Cluster
      cd ${home}/.config/nix
      layout tall
      launch --title K9s --env ${kubeconfig} k9s
      focus
      launch --title Shell --env ${kubeconfig}
    '';
  };
}
