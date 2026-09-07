# hosts/skywalker/parts/users.nix — user accounts.
#
# Keys come from users/vysakh.nix, same as every other host. Root keeps SSH
# keys for nixos-anywhere (install) and deploy-rs (updates).
{ pkgs, ... }:

let
  vysakhMeta = import ../../../users/vysakh.nix;
in
{
  users.users = {
    vysakh = {
      shell = pkgs.zsh;
      isNormalUser = vysakhMeta.isNormalUser;
      extraGroups = vysakhMeta.extraGroups;
      openssh.authorizedKeys.keys = vysakhMeta.sshKeys;
    };

    root.openssh.authorizedKeys.keys = vysakhMeta.sshKeys;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  programs.zsh.enable = true;
}
