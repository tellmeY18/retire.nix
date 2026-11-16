# home/satan/default.nix — satan, the primary personal + admin profile.
#
# Deliberately minimal for now; grows piece by piece.
{ ... }:
{
  imports = [
    ../desktop/hyprland.nix
    ../admin.nix
  ];

  home.stateVersion = "26.11";

  # Standard ~/Desktop, ~/Documents, ~/Downloads, ~/Music, ~/Pictures,
  # ~/Public, ~/Templates, ~/Videos — created on activation.
  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "satanvysakh";
      email = "satanvysakh@riseup.net";
    };
  };

  programs.jujutsu = {
    enable = true;
    settings.user = {
      name = "satanvysakh";
      email = "satanvysakh@riseup.net";
    };
  };
}
