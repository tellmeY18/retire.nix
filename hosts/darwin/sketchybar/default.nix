# hosts/darwin/sketchybar — Lua-based sketchybar config with AeroSpace integration.
#
# Architecture (following azuwis/nix-config pattern):
#   - services.sketchybar.enable manages the launchd service
#   - launchd agent gets Lua (with sbarlua) in PATH
#   - --config points to our ./config/sketchybarrc entry point
#   - All .lua files live as real files (not inline nix strings)
#   - Hotload is disabled when running from /nix/store (nix-darwin restarts on change)
{ lib, pkgs, ... }:

let
  lua = pkgs.sbarlua.luaModule.withPackages (_ps: [
    pkgs.sbarlua
  ]);
in
{
  # Hide the native macOS menu bar — sketchybar replaces it.
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;

  # Install sketchybar-app-font for app-name-to-icon mapping.
  fonts.packages = with pkgs; [
    sketchybar-app-font
    nerd-fonts.symbols-only
  ];

  services.sketchybar = {
    enable = true;
    extraPackages = with pkgs; [
      lua
    ];
  };

  # Override the launchd agent to use our Lua config directory.
  launchd.user.agents.sketchybar = {
    path = lib.mkBefore [ lua ];
    serviceConfig.ProgramArguments = lib.mkAfter [
      "--config"
      "${./config}/sketchybarrc"
    ];
  };
}
