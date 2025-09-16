{ pkgs, ... }:

{
  imports = [
    ./common.nix
  ];

  # Darwin-specific user info
  home.username = "mathewalex";
  home.homeDirectory = "/Users/mathew";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.05";

  # Darwin-specific packages
  home.packages = with pkgs; [
    zoxide
  ];

  # Darwin-specific environment variables
  home.sessionVariables = {
    # Inherit common variables and add Darwin-specific ones
    BROWSER = "firefox";
  };

  # macOS-specific shell configuration
}
