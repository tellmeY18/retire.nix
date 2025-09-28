{ lib, pkgs, ... }:

{
  programs.zsh = lib.mkIf pkgs.stdenv.isDarwin {
    oh-my-zsh = {
      theme = lib.mkForce "robbyrussell";
    };
    # Inherit common zsh config
    profileExtra = ''
      # Add Homebrew to PATH
      eval "$(/opt/homebrew/bin/brew shellenv)"

      # macOS-specific aliases
      alias showfiles="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
      alias hidefiles="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"
    '';
  };
}
