{ lib, pkgs, ... }:
{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-esr;  
    
    profiles.default = {
      # Unique identifier for the profile
      id = 0;
      
      # Profile name
      name = "default";
      
      # Set as default profile
      isDefault = true;
      
      # Firefox preferences (about:config settings)
      settings = {
        # Disable telemetry
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.ping-centre.telemetry" = false;
        "browser.tabs.crashReporting.sendReport" = false;
        "devtools.onboarding.telemetry.logged" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.server" = "";
        "toolkit.telemetry.unified" = false;
        
        # Privacy settings
        "privacy.donottrackheader.enabled" = true;
        "privacy.trackingprotection.enabled" = true;
        
        # Disable pocket
        "extensions.pocket.enabled" = false;
        
        # Set homepage (optional)
        # "browser.startup.homepage" = "https://example.com";
      };
      
      # Search engine configuration
      search = {
        force = true;  # Force search settings
        default = "DuckDuckGo";
        order = [ "DuckDuckGo" "Google" ];
      };
      
      # Bookmarks (optional)
      bookmarks = [
        {
          name = "Nix Sites";
          toolbar = true;
          bookmarks = [
            {
              name = "NixOS Wiki";
              url = "https://nixos.wiki";
            }
            {
              name = "Home Manager Options";
              url = "https://nix-community.github.io/home-manager/options.xhtml";
            }
          ];
        }
      ];
    };
  };
}
