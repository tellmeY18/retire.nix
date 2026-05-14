{ ... }:
{
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
      "baresip"
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
      "openmtp"
      "caffeine"
      "kodi"
      "macdroid"
      "gimp"
      "obs"
      "lens"
      "macfuse"
      "brave-browser@beta"
      "maccy"
      "warp"
      "beekeeper-studio"
      "aldente"
      "qbittorrent"
      "firefox@developer-edition"
      "zen"
      "notion"
      "1password"
      "whatsapp@beta"
      "slack"
      "arc"
      "github"
      "signal@beta"
      "hoppscotch"
      "drawio"
      "monofocus"
      "localsend"
      "onlyoffice"
      "vlc"
      "libreoffice"
      "pika"
      "thunderbird"
    ];

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
  };
}
