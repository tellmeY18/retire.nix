# profiles/dev.nix — development tools and environment
#
# Enables common developer tooling: lazygit, direnv, git, and
# Docker with buildx. Hosts can layer on language-specific tools
# (Rust via Fenix, Node, Python, etc.) in their own parts/ files.
{ pkgs, ... }:
{
  programs = {
    lazygit.enable = true;
    direnv.enable = true;
    git.enable = true;
  };

  virtualisation.docker = {
    enable = true;
    extraPackages = with pkgs; [
      docker-buildx
    ];
  };
}
