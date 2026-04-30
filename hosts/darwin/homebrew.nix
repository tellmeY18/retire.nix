# hosts/darwin/homebrew.nix — nix-homebrew settings for the MacBook Pro.
{
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "mathewalex";
    autoMigrate = true;
  };
}
