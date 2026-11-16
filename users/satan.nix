{
  username = "satan";
  fullName = "satanvysakh";
  email = "satanvysakh@riseup.net";
  shell = "zsh"; # will be mapped to pkgs.zsh by the consumer
  # satan@chopper is the fleet's operator/deploy key (root on every host via
  # profiles/admin-user.nix); vysakh's keys are kept for login.
  deployKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFB/wNfOElzx7a5KdpBLS9Ls5AjKWsQXKJyp/BAhh9zD satan@chopper";
  sshKeys = (import ./vysakh.nix).sshKeys ++ [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFB/wNfOElzx7a5KdpBLS9Ls5AjKWsQXKJyp/BAhh9zD satan@chopper"
  ];
  extraGroups = [
    "wheel"
    "networkmanager"
    "video"
  ];
  isNormalUser = true;
}
