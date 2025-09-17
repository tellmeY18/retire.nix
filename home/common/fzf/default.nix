{  pkgs, lib, ... }:
{

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    package = pkgs.fzf;

    defaultCommand = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git";
    fileWidgetCommand = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git";
    changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d --hidden --follow --exclude .git";

    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--info=inline"
      "--multi"
      "--preview='${pkgs.bat}/bin/bat --color=always {}'"
    ];

    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];

    tmux.enableShellIntegration = true;
  };

  home.sessionVariables = {
    FZF_DEFAULT_COMMAND = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git";
    FZF_CTRL_T_COMMAND = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git";
    FZF_ALT_C_COMMAND = "${pkgs.fd}/bin/fd --type d --hidden --follow --exclude .git";
  };
}
