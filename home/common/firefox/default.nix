{ pkgs, ... }:
let
  # Helper function for forced extension installation
  install = install_url: {
    inherit install_url;
    installation_mode = "force_installed";
  };

  # Policies configuration
  policies = {
    DisableAppUpdate = true;
    DisableFirefoxAccounts = true;
    DisableFirefoxStudies = true;
    DisableFormHistory = true;
    DisablePocket = true;
    DisableTelemetry = true;
    DisplayBookmarksToolbar = "newtab";
    DontCheckDefaultBrowser = true;
    
    EnableTrackingProtection = {
      Value = true;
      Locked = true;
      Cryptomining = true;
      EmailTracking = true;
      Fingerprinting = true;
    };
    
    ExtensionSettings = {
      "*" = {
        installation_mode = "blocked";
        blocked_install_message = "Add it to your nix config to install extensions.";
      };
      # Query AMO Addon ID helper
      "queryamoid@kaply.com" =
        install "https://github.com/mkaply/queryamoid/releases/download/v0.2/query_amo_addon_id-0.2-fx.xpi";
      # uBlock Origin
      "uBlock0@raymondhill.net" =
        install "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
      # Privacy Badger
      "jid1-MnnxcxisBPnSXQ@jetpack" =
        install "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
      # Dracula Dark theme
      "{b743f56d-1cc1-4048-8ba6-f9c2ab7aa54d}" =
        install "https://addons.mozilla.org/firefox/downloads/latest/dracula-dark-colorscheme/latest.xpi";
      # 1Password
      "{d634138d-c276-4fc8-924b-40a0ea21d284}" =
        install "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
    };
    
    FirefoxHome = {
      Search = true;
      TopSites = false;
      SponsoredTopSites = false;
      Highlights = false;
      Pocket = false;
      SponsoredPocket = false;
      Snippets = false;
      Locked = true;
    };
    
    FirefoxSuggest = {
      WebSuggestions = false;
      SponsoredSuggestions = false;
      ImproveSuggest = false;
      Locked = true;
    };
    
    Homepage = {
      StartPage = "previous-session";
      Locked = true;
    };
    
    NetworkPrediction = false;
    NewTabPage = false;
    NoDefaultBookmarks = true;
    OfferToSaveLogins = false;
    OverrideFirstRunPage = "";
    OverridePostUpdatePage = "";
    PasswordManagerEnabled = false;
    PrimaryPassword = false;
    SearchSuggestEnabled = false;
    
    UserMessaging = {
      WhatsNew = false;
      ExtensionRecommendations = false;
      FeatureRecommendations = false;
      UrlbarInterventions = false;
      SkipOnboarding = true;
      MoreFromMozilla = false;
      Locked = true;
    };
  };

  # Advanced preferences
  extraPrefs = ''
    lockPref("accessibility.force_disabled", 1);
    lockPref("app.shield.optoutstudies.enabled", false);
    lockPref("browser.aboutConfig.showWarning", false);
    lockPref("browser.aboutHomeSnippets.updateUrl", "");
    lockPref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);
    lockPref("browser.ml.chat.enabled", false);
    lockPref("browser.ml.chat.shortcuts", false);
    lockPref("browser.ml.chat.sidebar", false);
    lockPref("browser.selfsupport.url", "");
    lockPref("browser.startup.homepage", "https://start.duckduckgo.com");
    lockPref("browser.startup.homepage_override.buildID", "");
    lockPref("browser.startup.homepage_override.mstone", "ignore");
    lockPref("browser.tabs.firefox-view", false);
    lockPref("browser.tabs.firefox-view-next", false);
    lockPref("browser.urlbar.suggest.history", false);
    lockPref("browser.urlbar.suggest.topsites", false);
    lockPref("content.notify.interval", 100000);
    lockPref("dom.events.asyncClipboard.clipboardItem", true);
    lockPref("dom.security.https_only_mode", true);
    lockPref("extensions.htmlaboutaddons.recommendations.enabled", false);
    lockPref("extensions.recommendations.themeRecommendationUrl", "");
    lockPref("gfx.canvas.accelerated.cache-items", 4096);
    lockPref("gfx.canvas.accelerated.cache-size", 512);
    lockPref("gfx.content.skia-font-cache-size", 20);
    lockPref("gfx.webrender.all", true);
    lockPref("gfx.webrender.compositor", true);
    lockPref("network.dns.disablePrefetch", false);
    lockPref("network.dns.disablePrefetchFromHTTPS", false);
    lockPref("network.http.max-connections", 1800);
    lockPref("network.http.max-persistent-connections-per-server", 10);
    lockPref("network.http.max-urgent-start-excessive-connections-per-host", 5);
    lockPref("network.http.pacing.requests.enabled", false);
    lockPref("network.IDN_show_punycode", true);
    lockPref("network.predictor.enabled", false);
    lockPref("network.prefetch-next", false);
    lockPref("network.trr.mode", 5);
    lockPref("privacy.donottrackheader.enabled", true);
    lockPref("privacy.firstparty.isolate", true);
    lockPref("privacy.globalprivacycontrol.enabled", true);
    lockPref("sidebar.main.tools", "history,bookmarks");
    lockPref("sidebar.verticalTabs", true);
    lockPref("signon.management.page.breach-alerts.enabled", false);
    lockPref("startup.homepage_override_url", "");
    lockPref("startup.homepage_welcome_url", "");
    lockPref("startup.homepage_welcome_url.additional", "");
    lockPref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
    lockPref("widget.disable-swipe-tracker", true);
    lockPref("widget.gtk.global-menu.wayland.enabled", true);
    lockPref("widget.wayland.fractional-scale.enabled", true);
  '';

in
{
  programs.firefox = {
    enable = true;
    
    package = pkgs.firefox.override {
      extraPolicies = policies;
      inherit extraPrefs;
    };
    
    profiles.default = {
      id = 0;
      name = "Default";
      isDefault = true;
      
      # Custom CSS for Hyprland minimum window width fix
      userChrome = ''
        /* Reduce minimum window width for firefox */
        :root:not([chromehidden~="toolbar"]){
          min-width: 20px !important;
        }
      '';
      
      search = {
        default = "DuckDuckGo";
        force = true;
        
        engines = {
          # Hide default search engines
          "Bing".metaData.hidden = true;
          "Google".metaData.hidden = true;
          
          # ProtonDB - Game compatibility
          "ProtonDB" = {
            urls = [{
              template = "https://www.protondb.com/search";
              params = [{
                name = "q";
                value = "{searchTerms}";
              }];
            }];
            icon = "https://www.protondb.com/favicon.ico";
            definedAliases = [ "@game" ];
          };
          
          # Nix Packages search
          "Nix Packages" = {
            urls = [{
              template = "https://search.nixos.org/packages";
              params = [
                {
                  name = "channel";
                  value = "unstable";
                }
                {
                  name = "sort";
                  value = "alpha_asc";
                }
                {
                  name = "query";
                  value = "{searchTerms}";
                }
              ];
            }];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };
          
          # NixOS Options search
          "NixOS Options" = {
            urls = [{
              template = "https://search.nixos.org/options";
              params = [
                {
                  name = "channel";
                  value = "unstable";
                }
                {
                  name = "sort";
                  value = "alpha_asc";
                }
                {
                  name = "query";
                  value = "{searchTerms}";
                }
              ];
            }];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@no" ];
          };
          
          # GitHub repository search
          "GitHub" = {
            urls = [{
              template = "https://github.com/search";
              params = [
                {
                  name = "q";
                  value = "{searchTerms}";
                }
                {
                  name = "type";
                  value = "repositories";
                }
              ];
            }];
            icon = "https://github.com/favicon.ico";
            definedAliases = [ "@gh" ];
          };
          
          # Docker Hub search
          "Docker Hub" = {
            urls = [{
              template = "https://hub.docker.com/search";
              params = [{
                name = "q";
                value = "{searchTerms}";
              }];
            }];
            icon = "https://hub.docker.com/favicon.ico";
            definedAliases = [ "@docker" ];
          };
          
          # YouTube search
          "YouTube" = {
            urls = [{
              template = "https://www.youtube.com/results";
              params = [{
                name = "search_query";
                value = "{searchTerms}";
              }];
            }];
            icon = "https://www.youtube.com/favicon.ico";
            definedAliases = [ "@yt" ];
          };
        };
      };
    };
  };
}
