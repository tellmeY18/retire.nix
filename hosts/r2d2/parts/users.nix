# hosts/r2d2/parts/users.nix
# User accounts — note: vladmin keys for cloud-init, vysakh for nix management.
# Once nixos-anywhere provisions the new system, cloud-init user is replaced
# by NixOS-declared users.
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
    #   - nixos-anywhere installation (initial SSH)
    #   - deploy-rs pushes
    root.openssh.authorizedKeys.keys = vysakhMeta.sshKeys;
  };

  # SSH — essential for deploy-rs
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
