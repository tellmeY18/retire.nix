{ ... }: {
  homebrew = {
    enable = true;

    taps = [
      "d12frosted/emacs-plus"
      "minio/stable"
      "rockymadden/rockymadden"
      "koekeishiya/formulae"

    ];
    brews = [
      "mactop"
      "gtk+3"
      "dbus"
      "bash"
      "adwaita-icon-theme"
      "hapi-fhir-cli"
    ];

    masApps = {
      # "Wireguard" = 1451685025;
      # "Perplexity" = 6714467650;
      # "Tailscale" = 1475387142;
      # "Outline" = 1356178125;
      # "elytra" = 1433266971;
    };

    casks = [
      "cyberduck"
      "gimp"
      "obs"
      "unetbootin"
      "balenaetcher"
      "lens"
      "macfuse"
      "brave-browser@beta"
      "maccy"
      "inkscape"
      "pika"
      "warp"
      "beekeeper-studio"
      "aldente"
      "ghostty"
      "qbittorrent"
      "firefox@developer-edition"
      "zen"
      "zed@preview"
      "notion"
      "1password"
      "whatsapp@beta"
      "slack"
      "arc"
      "kitty"
      "github"
      "kdenlive"
      "signal@beta"
      "hoppscotch"
      "drawio"
      "monofocus"
      "mindmac"
      "localsend"
      "onlyoffice"
      "vlc"
      "libreoffice"
      "pika"
      "thunderbird"
      "blender"
    ];

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
  };
}
