# hosts/chopper/parts/users.nix
# User accounts — identity data sourced from users/*.nix
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

    root = {
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = vysakhMeta.sshKeys;
    };
  };

  security.sudo.extraRules = [
    {
      users = [ "vysakh" ];
      commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ];
    }
  ];
}
