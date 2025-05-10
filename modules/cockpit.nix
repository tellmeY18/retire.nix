{ config, lib, pkgs, ... }:
{
  services.cockpit = {
    enable = true;
    openFirewall = true;
    settings = {
      WebService = {
        AllowUnencrypted = true;
      };
    };
  };
}
