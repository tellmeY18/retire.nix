# themes/satanic.nix
# Satanic Vim — custom base16 colorscheme inspired by FreeBSD's devil.
# Palette: void blacks, devil reds, trident gold, dark magic purples.
#
# NOTE: imported via `programs.nixvim.imports`, so these are nixvim submodule
# options and should NOT be wrapped in `programs.nixvim = { ... }`.
{ ... }:
{
  colorschemes.base16 = {
    enable = true;
    colorscheme = {
      # ── Background / foreground ──────────────────────────
      base00 = "#0a0a0f"; # Void black (default bg)
      base01 = "#14101a"; # Slightly lighter void (status bars, line numbers)
      base02 = "#1a1420"; # Selection background, current line
      base03 = "#4a3a4a"; # Comments, invisibles — muted purple-gray
      base04 = "#5a4a5a"; # Dark foreground for status bars
      base05 = "#d4c5d4"; # Ghost white — default text
      base06 = "#e0d0e0"; # Light foreground
      base07 = "#f0e0f0"; # Light background (rarely used)

      # ── Semantic colors ─────────────────────────────────
      base08 = "#c12127"; # Devil red — variables, tags, diff deleted
      base09 = "#e8743c"; # Ember orange — numbers, booleans, constants
      base0A = "#d4a84b"; # Trident gold — classes, search text bg
      base0B = "#4a9c6f"; # Toxic green — strings, diff inserted
      base0C = "#4a9c9c"; # Sulfur cyan — support, regex, escape chars
      base0D = "#e63946"; # Bright blood red — functions, methods, headings
      base0E = "#7a4a8a"; # Dark magic purple — keywords, storage
      base0F = "#b45a8a"; # Blood bloom pink — deprecated, embedded tags
    };
  };
}
