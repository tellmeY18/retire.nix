# home/common/kitty/sessions.nix
#
# Declarative kitty session files.
#
# Each entry in `sessions` below is rendered to
# ~/.config/kitty/sessions/<name>.kitty-session and picked up by the session
# browser bound to kitty_mod+s (see ./default.nix).
#
# Session file grammar reference: `docs/sessions.rst` in the kitty source.
# The directives used here are `new_tab`, `cd`, `layout`, `launch` and `focus`.
{ config, lib, ... }:

let
  home = config.home.homeDirectory;

  # Every cluster command in this repo must run against the glug-infra
  # cluster (see CLAUDE.md), so bake it into the session rather than
  # relying on the shell having exported it.
  kubeEnv = {
    KUBECONFIG = "${home}/.kube/glug-infra.yaml";
  };

  # Render one window as a `launch` line.
  #
  # kitty's `focus` directive takes NO argument — it focuses the most
  # recently launched window. It therefore has to be emitted directly after
  # the launch line it applies to, not as a trailing `focus <index>`.
  mkWindow =
    w:
    let
      envArgs = lib.concatStrings (lib.mapAttrsToList (n: v: " --env ${n}=${v}") (w.env or { }));
      command = lib.optionalString (w ? command) " ${w.command}";
      focus = lib.optionalString (w.focus or false) "\nfocus";
    in
    "launch --title ${lib.escapeShellArg w.title}${envArgs}${command}${focus}";

  mkSession = s: ''
    new_tab ${s.tab}
    cd ${s.cwd}
    layout ${s.layout}
    ${lib.concatMapStringsSep "\n" mkWindow s.windows}
  '';

  # `command` omitted -> plain shell. `focus = true` -> active on open.
  sessions = {
    development = {
      tab = "Development";
      cwd = "${home}/Projects";
      layout = "splits";
      windows = [
        {
          title = "Editor";
          command = "nvim";
          focus = true;
        }
        { title = "Shell"; }
      ];
    };

    nix = {
      tab = "Nix";
      cwd = "${home}/.config/nix";
      layout = "splits";
      windows = [
        {
          title = "Editor";
          command = "nvim";
          focus = true;
        }
        { title = "Build"; }
      ];
    };

    cluster-admin = {
      tab = "Cluster";
      cwd = "${home}/.config/nix";
      layout = "tall";
      windows = [
        {
          title = "K9s";
          command = "k9s";
          env = kubeEnv;
          focus = true;
        }
        {
          title = "Shell";
          env = kubeEnv;
        }
      ];
    };
  };
in
{
  xdg.configFile = lib.mapAttrs'
    (
      name: session:
        lib.nameValuePair "kitty/sessions/${name}.kitty-session" { text = mkSession session; }
    )
    sessions;
}
