{
  username = "satan";
  fullName = "satanvysakh";
  email = "satanvysakh@riseup.net";
  shell = "zsh"; # will be mapped to pkgs.zsh by the consumer
  # Same authorized keys as vysakh for now.
  sshKeys = (import ./vysakh.nix).sshKeys;
  extraGroups = [
    "wheel"
    "networkmanager"
    "video"
  ];
  isNormalUser = true;
}
