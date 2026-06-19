{ config, lib, ... }:

{
  # Symlink settings.toml directly from the repo (not Nix store)
  # so OmniWM can write to it.  The file lives at:
  #   ~/.config/omniwm/settings.toml → hosts/darwin/omniwm/settings.toml
  # `force = true` ensures home-manager switch re-creates the symlink.
  xdg.configFile."omniwm/settings.toml" = {
    source = config.lib.file.mkOutOfStoreSymlink ./settings.toml;
    force = true;
  };
}
