# profiles/admin-user.nix — the standard admin account + SSH setup.
#
# Shared verbatim by kenobi, r2d2, yoda and skywalker, whose users.nix files
# were byte-identical (modulo comments).
#
# NOT used by chopper: chopper additionally sets root's shell and declares a
# sudo rule, so it keeps its own hosts/chopper/parts/users.nix. Don't fold
# those differences in here — add a host-specific part instead.
#
# Also distinct from profiles/server.nix, which pulls in journald settings
# this does not want.
{ pkgs, ... }:

let
  vysakhMeta = import ../users/vysakh.nix;
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
