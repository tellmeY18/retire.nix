{ pkgs, ... }:

{
  home.packages = [
    pkgs.lazyjj
  ];
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Vysakh Premkumar";
        email = "vysakhpr218@gmail.com";
      };
      ui = {
        default-command = "log";
        diff-editor = "vimdiff";
        pager = "less -FRX";
      };
      core = {
        autosquash = true;
        allow-new-working-copy = true;
      };
      signing = {
        sign-all = false;
        backend = "gpg";
      };
      revset-aliases = {
        "log" = "ancestors(HEAD)";
      };
    };
  };
}
