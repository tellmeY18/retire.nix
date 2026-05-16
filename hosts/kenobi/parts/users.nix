# hosts/kenobi/parts/users.nix
# User accounts — sourced from users/vysakh.nix (same as chopper).
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

    # Root needs SSH keys for:
    #   - nixos-anywhere installation
    #   - deploy-rs pushes
    root.openssh.authorizedKeys.keys = vysakhMeta.sshKeys;
  };

  # Enable SSH — critical for remote management of a cloud VM.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # zsh must be enabled system-wide for it to work as a login shell.
  programs.zsh.enable = true;
}
