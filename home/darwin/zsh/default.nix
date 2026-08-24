{ lib, pkgs, ... }:

{
  programs.zsh = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    oh-my-zsh = {
      theme = lib.mkForce "robbyrussell";
    };
    # Inherit common zsh config
    profileExtra = ''
      # GitHub API token for Homebrew (avoids rate limiting on brew bundle, nix flake update)
      export HOMEBREW_GITHUB_API_TOKEN="$(gh auth token 2>/dev/null || true)"

      # GreenPT API key for opencode custom provider (sops-encrypted in secrets/laptop/greenpt.yaml)
      export GREEN_KEY="$(sops --decrypt --extract '["green_key"]' ~/.config/nix/secrets/laptop/greenpt.yaml 2>/dev/null || true)"

      # Add Homebrew to PATH
      eval "$(/opt/homebrew/bin/brew shellenv)"

      # macOS-specific aliases
      alias showfiles="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
      alias hidefiles="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"
    '';
  };
}
