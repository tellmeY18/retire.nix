{ pkgs, ... }:

let
  kitty = "${pkgs.kitty}/bin/kitty";
  open = "/usr/bin/open";
in
{
  # ── skhd — hotkey daemon ───────────────────────────────
  services.skhd = {
    enable = true;
    package = pkgs.skhd;

    config = ''
      # ════════════════════════════════════════════════════════════════
      #  skhd config — managed by Nix / home-manager
      # ════════════════════════════════════════════════════════════════
      #
      #  Modifier: Option (⌥)
      #

      # ── Application launchers ─────────────────────────────────

      # Kitty terminal
      alt - return : ${kitty} --directory ~

      # Browser
      alt - b : ${open} -a "Firefox"
    '';
  };
}
