{ pkgs, ... }:

{
  programs.zsh = {
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
