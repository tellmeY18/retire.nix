{ pkgs, config, self, ... }: {
  nixpkgs.config.allowUnfree = true;

  # Import system packages
  imports = [ ../../packages/darwin ./programs.nix ./services.nix ];
  system.defaults = {
    loginwindow.LoginwindowText = "Declare Nix ! Not War";
  };

  system.activationScripts.applications.text =
    let
      env = pkgs.buildEnv {
        name = "system-applications";
        paths = config.environment.systemPackages;
        pathsToLink = "/Applications";
      };
    in
    pkgs.lib.mkForce ''
      # Set up applications.
      echo "setting up /Applications..." >&2
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps
      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
      while read -r src; do
        app_name=$(basename "$src")
        echo "copying $src" >&2
        ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        # Add Spotlight indexing for Nix Apps
        mdimport "/Applications/Nix Apps/$app_name"
      done
    '';

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Set primary user for Homebrew and other user-specific options
  system.primaryUser = "mathewalex";

  # Used for backwards compatibility
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Enable Touch ID for sudo authentication.
  security.pam.services.sudo_local.touchIdAuth = true;
}
