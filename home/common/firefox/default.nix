{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;

    # Pin the legacy config path explicitly to silence HM's warning about
    # the upcoming default change to `${xdg.configHome}/mozilla/firefox`
    # (active when home.stateVersion >= "26.05"). Migrating the on-disk
    # profile to XDG can be done later as a deliberate change.
    # On macOS the default is "Library/Application Support/Firefox" which
    # is correct, so this is a no-op on darwin but keeps the setting
    # consistent across platforms.
    configPath = ".mozilla/firefox";

    # Enterprise policies injected via the Firefox wrapper (about:policies).
    # These are locked — users cannot override them in about:config.
    policies = import ./policies.nix;

    # firefox-beta and firefox-devedition have a nixpkgs packaging bug
    # on macOS: the app bundle name contains a space ("Developer Edition.app")
    # which breaks the wrapper's `touch` command. Use stable firefox instead.
    package = pkgs.firefox-bin;

    profiles.default = {
      id = 0;
      name = "Default";
      isDefault = true;

      # About:config preferences applied via user.js (user_pref). These
      # are defaults — users can change them in about:config if needed.
      settings = import ./prefs.nix;
    };
  };
}
