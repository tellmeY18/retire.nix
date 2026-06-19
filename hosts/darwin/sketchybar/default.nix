# hosts/darwin/sketchybar — Disabled in favour of OmniWM's built-in workspace bar.
#
# Kept in-tree for reference; the import was removed from configuration.nix
# and services.sketchybar.enable is set to false.
# If you re-enable it, restore the `./sketchybar` import in configuration.nix.
{ lib, pkgs, ... }:

let
  lua = pkgs.sbarlua.luaModule.withPackages (_ps: [
    pkgs.sbarlua
  ]);
in
{
  # Don't hide the menu bar — OmniWM's bar overlaps it when enabled.
  system.defaults.NSGlobalDomain._HIHideMenuBar = false;

  services.sketchybar = {
    enable = false;
  };
}
