{ pkgs, ... }:

{
  home.packages = [
    pkgs.lazyjj
  ];
  programs.jujutsu = {
    enable = false;
    settings = {
      user = {
        name = "Vysakh Premkumar";
        email = "vysakhpr218@gmail.com";
      };
      ui = {
        default-command = "log";
        diff-editor = "vimdiff";
      };
    };
  };
}
