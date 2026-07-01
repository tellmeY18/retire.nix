{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./packages/default.nix
    ./zsh/default.nix
    ./emacs/default.nix
    ./pulse/default.nix
    ./gomuks/default.nix
    ./kitty-launcher/default.nix
    ./skhd/default.nix
    ../common/packages/dev-k8s.nix
  ];

  # Darwin-specific environment variables
  home.sessionVariables = lib.mkIf pkgs.stdenv.isDarwin {
    BROWSER = "firefox";
    HOMEBREW_PREFIX = "/opt/homebrew";
    HOMEBREW_CELLAR = "/opt/homebrew/Cellar";
    HOMEBREW_REPOSITORY = "/opt/homebrew";
    LIBRARY_PATH = "${config.home.homeDirectory}/.nix-profile/lib";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.cargo/bin"
  ];
}
