# hosts/chopper/parts/users.nix
# User accounts — identity data sourced from users/*.nix
{ pkgs, ... }:

let
  vysakhMeta = import ../../../users/vysakh.nix;
  satanMeta = import ../../../users/satan.nix;
in
{
  users.users = {
    vysakh = {
      shell = pkgs.zsh;
      isNormalUser = vysakhMeta.isNormalUser;
      extraGroups = vysakhMeta.extraGroups;
      openssh.authorizedKeys.keys = vysakhMeta.sshKeys;
    };

    # Primary personal + admin account. No password in the repo: set it with
    # `sudo passwd satan` (mutable users).
    satan = {
      shell = pkgs.zsh;
      isNormalUser = satanMeta.isNormalUser;
      description = satanMeta.fullName;
      extraGroups = satanMeta.extraGroups;
      openssh.authorizedKeys.keys = satanMeta.sshKeys;
    };

    root = {
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = vysakhMeta.sshKeys;
    };
  };

  security.sudo.extraRules = [
    {
      users = [ "vysakh" ];
      commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
    }
  ];
}
