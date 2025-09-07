{ pkgs, config, self, ... }: {
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    hostPlatform = "aarch64-darwin";
  };
  # Import system packages
  imports = [  ../../packages/darwin ./programs.nix ./services.nix ];
  system = {
    defaults = {
      loginwindow = {
        LoginwindowText = "Declare Nix ! Not War";
      };
    };
    activationScripts = {
      applications = {
        text =
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
      };
    };
    # Set Git commit hash for darwin-version.
    configurationRevision = self.rev or self.dirtyRev or null;
    # Set primary user for Homebrew and other user-specific options
    primaryUser = "mathewalex";
    # Used for backwards compatibility
    stateVersion = 5;
  };
  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "100.107.213.17";
        sshUser = "vysakh";  # Changed from 'user' to 'sshUser'
        systems = [ "x86_64-linux" ];
        # Optional additional settings you might want to add:
        # maxJobs = 4;
        # speedFactor = 2;
        # supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        # mandatoryFeatures = [ ];
        # sshKey = "/path/to/ssh/key"; # if needed
        # protocol = "ssh-ng"; # for better performance
      }
    ];
    linux-builder = {
      enable = true;
    };
    # These are the global Nix settings
    settings = {
      experimental-features = "nix-command flakes ca-derivations";
    };
  };
  # Enable Touch ID for sudo authentication.
  security = {
    pam = {
      services = {
        sudo_local = {
          touchIdAuth = true;
        };
      };
    };
  };
}
