{
  username = "vysakh";
  fullName = "Vysakh Premkumar";
  email = "vysakhpr218@gmail.com";
  shell = "zsh"; # will be mapped to pkgs.zsh by the consumer
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOoUJulOP9ZLy8Ny2LgS6HT7WSg93a4eHwbA412LbOR5"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEAAcrvQNZlE5PT9OhS6s7SH+gHCJB2sqIRo2mITwnER"
  ];
  extraGroups = [
    "wheel"
    "docker"
    "networkmanager"
  ];
  isNormalUser = true;
}
