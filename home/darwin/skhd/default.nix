{ pkgs, ... }:

let
  kitten = "${pkgs.kitty}/bin/kitten";
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
      alt - return : ${kitten} quick-access-terminal --detach

      # Browser
      alt - b : ${open} -a "Firefox"
    '';
  };
}
