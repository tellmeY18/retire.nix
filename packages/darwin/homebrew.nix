{ ... }:
{
  homebrew = {
    enable = true;

    taps = [
      "d12frosted/emacs-plus"
      "minio/stable"
      "rockymadden/rockymadden"
      "koekeishiya/formulae"
      "BarutSRB/tap"
    ];
    brews = [
      "mactop"
      "gtk+3"
      "baresip"
      "dbus"
      "mole"
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
      "caffeine"
      "gimp"
      "obs"
      "lens"
      "macfuse"
      "brave-browser@beta"
      "maccy"
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
      "localsend"
      "onlyoffice"
      "vlc"
      "libreoffice"
      "pika"
      "thunderbird"
    ];

    onActivation = {
      # autoUpdate triggers `brew update` which git-pulls into the nix-store-backed
      # brew installation, causing corruption and "Failed to fetch" on brew bundle.
      # Keep brew fresh via `nix flake update` instead — it's pinned to 6.0.1 already.
      autoUpdate = false;
      upgrade = true;
      # --cleanup is deprecated in modern Homebrew; leave it to default behavior.
      cleanup = "none";
    };
  };
}
