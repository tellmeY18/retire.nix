{ pkgs, ... }:

{
  environment.systemPackages = import ./system-packages.nix { inherit pkgs; };
}
