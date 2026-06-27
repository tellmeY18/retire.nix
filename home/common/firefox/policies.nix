let
  install = install_url: {
    inherit install_url;
    installation_mode = "force_installed";
    private_browsing = false;
  };
  mkSearchEngine = Name: Alias: Method: URLTemplate: IconURL: {
    inherit
      Name
      Alias
      Method
      URLTemplate
      IconURL
      ;
  };
in
{
  AIControls = {
    Default = {
      Value = "blocked";
      Locked = true;
    };
    Translations = {
      Value = "blocked";
      Locked = true;
    };
    PDFAltText = {
      Value = "blocked";
      Locked = true;
    };
    SmartTabGroups = {
      Value = "blocked";
      Locked = true;
    };
    LinkPreviewKeyPoints = {
      Value = "blocked";
      Locked = true;
    };
    SidebarChatbot = {
      Value = "blocked";
      Locked = true;
    };
    SmartWindow = {
      Value = "blocked";
      Locked = true;
    };
  };
  DefaultSerialGuardSetting = 3;
  DisableAppUpdate = true;
  DisableFirefoxAccounts = true;
  DisableFirefoxScreenshots = true;
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
      blocked_install_message = "Add it to firefox/policies.nix to install it.";
    };
    # Query AMO Addon ID helper
    "queryamoid@kaply.com" =
      install "https://github.com/mkaply/queryamoid/releases/download/v0.2/query_amo_addon_id-0.2-fx.xpi";
    # uBlock Origin
    "uBlock0@raymondhill.net" = (install "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi") // {
      private_browsing = true;
    };
    # Privacy Badger
    "jid1-MnnxcxisBPnSXQ@jetpack" = (install "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi") // {
      private_browsing = true;
    };
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

  GenerativeAI = {
    Enabled = false;
    Chatbot = false;
    LinkPreviews = false;
    TabGroups = false;
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

  SearchEngines = {
    PreventInstalls = true;
    Add = [
      (mkSearchEngine "Merriam-Webster" "@define" "GET"
        "https://www.merriam-webster.com/dictionary/{searchTerms}"
        "https://www.merriam-webster.com/favicon.ico"
      )
      (mkSearchEngine "ProtonDB" "@game" "GET" "https://www.protondb.com/search?q={searchTerms}"
        "https://www.protondb.com/favicon.ico"
      )
      (mkSearchEngine "Nix Packages" "@np" "GET"
        "https://search.nixos.org/packages?channel=unstable&sort=alpha_asc&query={searchTerms}"
        "https://nixos.org/favicon.ico"
      )
      (mkSearchEngine "Nix Options" "@no" "GET"
        "https://search.nixos.org/options?channel=unstable&sort=alpha_asc&query={searchTerms}"
        "https://nixos.org/favicon.ico"
      )
      (mkSearchEngine "GitHub" "@gh" "GET" "https://github.com/search?type=repositories&q={searchTerms}"
        "https://github.com/favicon.ico"
      )
      (mkSearchEngine "Docker Hub" "@docker" "GET" "https://hub.docker.com/search?&q={searchTerms}"
        "https://hub.docker.com/favicon.ico"
      )
      (mkSearchEngine "YouTube" "@yt" "GET" "https://www.youtube.com/results?&search_query={searchTerms}"
        "https://www.youtube.com/favicon.ico"
      )
    ];
    Remove = [
      "Google"
      "Bing"
      "Perplexity"
    ];
  };

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
}
