{ pkgs, ... }:

{
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
      };
    };
  };
}
