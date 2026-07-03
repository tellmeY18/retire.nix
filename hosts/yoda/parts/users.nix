# hosts/yoda/parts/users.nix — user accounts.
#
# The OCI Ubuntu image blocks root SSH (forced "login as ubuntu" command), so
# nixos-anywhere connects as the `ubuntu` sudo user. Once NixOS is installed,
# root SSH with the keys below works directly (deploy-rs + admin access).
{ pkgs, ... }:

let
  vysakhMeta = import ../../../users/vysakh.nix;
in
{
  users.users = {
    vysakh = {
      shell = pkgs.zsh; # phase 2: zsh restored (bootstrap used bashInteractive)
      isNormalUser = vysakhMeta.isNormalUser;
      extraGroups = vysakhMeta.extraGroups;
      openssh.authorizedKeys.keys = vysakhMeta.sshKeys;
    };

    # Root needs SSH keys for:
    #   - nixos-anywhere installation (copies the closure in)
    #   - deploy-rs pushes (phase 2 updates)
    root.openssh.authorizedKeys.keys = vysakhMeta.sshKeys;
  };

  # SSH — essential for deploy-rs.
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
