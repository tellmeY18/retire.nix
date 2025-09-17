{ lib, pkgs, ... }:

{
  # Darwin-specific packages - only install on macOS
  home.packages = lib.optionals pkgs.stdenv.isDarwin (with pkgs; [
    # macOS-specific tools
    mas  # Mac App Store CLI
    zoxide
  ]);
}
