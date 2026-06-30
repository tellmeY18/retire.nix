{ config, lib, pkgs, ... }:

let
  inherit (lib) types mkOption mkIf mkMerge;

  cfg = config.omniwm-bar;

  # ── Satanic palette: matches kitty + Ghostty ──────────────────────
  satanic = rec {
    void = { red = 0.039; green = 0.039; blue = 0.059; alpha = 1.0; };
    voidAlt = { red = 0.078; green = 0.063; blue = 0.102; alpha = 1.0; };
    crimson = { red = 0.757; green = 0.129; blue = 0.153; alpha = 1.0; };
    gold = { red = 0.831; green = 0.659; blue = 0.294; alpha = 1.0; };
    emerald = { red = 0.290; green = 0.612; blue = 0.435; alpha = 1.0; };
    frost = { red = 0.290; green = 0.416; blue = 0.612; alpha = 1.0; };
    plum = { red = 0.478; green = 0.290; blue = 0.541; alpha = 1.0; };
    teal = { red = 0.290; green = 0.612; blue = 0.612; alpha = 1.0; };
    mist = { red = 0.831; green = 0.773; blue = 0.831; alpha = 1.0; };
    brightRed = { red = 0.902; green = 0.224; blue = 0.275; alpha = 1.0; };
    brightGold = { red = 0.910; green = 0.753; blue = 0.357; alpha = 1.0; };
  };

  # ── Resolve accent / text colour from theme selector ──────────────
  accentColor =
    if cfg.theme == "satanic" then satanic.crimson
    else if cfg.theme == "crimson" then satanic.crimson
    else if cfg.theme == "gold" then satanic.gold
    else if cfg.theme == "frost" then satanic.frost
    else if cfg.theme == "teal" then satanic.teal
    else if cfg.theme == "emerald" then satanic.emerald
    else if cfg.theme == "custom" then cfg.customAccentColor
    else satanic.crimson;

  textColor =
    if cfg.theme == "satanic" then satanic.mist
    else if cfg.theme == "crimson" then satanic.mist
    else if cfg.theme == "gold" then satanic.void
    else if cfg.theme == "frost" then satanic.mist
    else if cfg.theme == "teal" then satanic.mist
    else if cfg.theme == "emerald" then satanic.mist
    else if cfg.theme == "custom" then cfg.customTextColor
    else satanic.mist;

  # ── Build per-monitor override list (keyed by display name) ───────
  monitorBarSettings = lib.mapAttrsToList
    (name: mon:
      { inherit name; }
      // lib.filterAttrs (_: v: v != null) {
        enabled = mon.enabled;
        showLabels = mon.showLabels;
        showFloatingWindows = mon.showFloatingWindows;
        deduplicateAppIcons = mon.deduplicateAppIcons;
        hideEmptyWorkspaces = mon.hideEmptyWorkspaces;
        reserveLayoutSpace = mon.reserveLayoutSpace;
        notchAware = mon.notchAware;
        position = mon.position;
        windowLevel = mon.windowLevel;
        height = mon.height;
        backgroundOpacity = mon.backgroundOpacity;
        xOffset = mon.xOffset;
        yOffset = mon.yOffset;
      }
    )
    cfg.monitors;

  # ── Submodule for RGBA colour components ──────────────────────────
  colorOptions = {
    options = {
      red = mkOption {
        type = types.number;
        default = 1.0;
        description = "Red component (0.0 - 1.0).";
      };
      green = mkOption {
        type = types.number;
        default = 1.0;
        description = "Green component (0.0 - 1.0).";
      };
      blue = mkOption {
        type = types.number;
        default = 1.0;
        description = "Blue component (0.0 - 1.0).";
      };
      alpha = mkOption {
        type = types.number;
        default = 1.0;
        description = "Alpha / opacity (0.0 - 1.0).";
      };
    };
  };

  # ── Submodule for per-monitor overrides ───────────────────────────
  monitorOptions = {
    options = {
      enabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable the bar on this monitor.";
      };
      showLabels = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
      showFloatingWindows = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
      deduplicateAppIcons = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
      hideEmptyWorkspaces = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
      reserveLayoutSpace = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
      notchAware = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
      position = mkOption {
        type = types.nullOr (types.enum [
          "overlappingMenuBar"
          "underMenuBar"
          "floating"
        ]);
        default = null;
      };
      windowLevel = mkOption {
        type = types.nullOr (types.enum [ "popup" "statusBar" "floating" ]);
        default = null;
      };
      height = mkOption {
        type = types.nullOr types.number;
        default = null;
      };
      backgroundOpacity = mkOption {
        type = types.nullOr types.number;
        default = null;
      };
      xOffset = mkOption {
        type = types.nullOr types.number;
        default = null;
      };
      yOffset = mkOption {
        type = types.nullOr types.number;
        default = null;
      };
    };
  };
in
{
  options = {
    omniwm-bar = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Nix-managed OmniWM workspace bar customisation.";
      };

      theme = mkOption {
        type = types.enum [
          "satanic"
          "crimson"
          "gold"
          "frost"
          "teal"
          "emerald"
          "custom"
        ];
        default = "satanic";
        description = ''
          Theme preset for the workspace bar accent and text colours.

          - satanic:  Crimson accent, mist text (matches kitty/Ghostty palette)
          - crimson:  Same accent palette, focused on red tones
          - gold:     Gold accent, dark text (high-contrast)
          - frost:    Blue accent, mist text
          - teal:     Teal accent, mist text
          - emerald:  Green accent, mist text
          - custom:   Use customAccentColor + customTextColor below
        '';
      };

      customAccentColor = mkOption {
        type = types.nullOr (types.submodule colorOptions);
        default = null;
        description = "Custom RGBA accent colour (used when theme = custom).";
      };

      customTextColor = mkOption {
        type = types.nullOr (types.submodule colorOptions);
        default = null;
        description = "Custom RGBA text colour (used when theme = custom).";
      };

      # ── Basic behaviour toggles ─────────────────────────────────
      showLabels = mkOption {
        type = types.bool;
        default = true;
        description = "Show workspace labels in the bar.";
      };

      showFloatingWindows = mkOption {
        type = types.bool;
        default = false;
        description = "Show floating window indicators.";
      };

      deduplicateAppIcons = mkOption {
        type = types.bool;
        default = true;
        description = "Collapse multiple windows of the same app under one icon.";
      };

      hideEmptyWorkspaces = mkOption {
        type = types.bool;
        default = true;
        description = "Hide workspaces with no open windows.";
      };

      reserveLayoutSpace = mkOption {
        type = types.bool;
        default = false;
        description = "Let the layout engine reserve space so windows do not overlap the bar.";
      };

      # ── Position & level ────────────────────────────────────────
      position = mkOption {
        type = types.enum [ "overlappingMenuBar" "underMenuBar" "floating" ];
        default = "overlappingMenuBar";
        description = "Bar position relative to the macOS menu bar.";
      };

      windowLevel = mkOption {
        type = types.enum [ "popup" "statusBar" "floating" ];
        default = "popup";
        description = "Window level of the bar surface.";
      };

      notchAware = mkOption {
        type = types.bool;
        default = true;
        description = "Shift bar right to avoid the MacBook notch.";
      };

      # ── Offsets ─────────────────────────────────────────────────
      xOffset = mkOption {
        type = types.number;
        default = 0.0;
        description = "Horizontal offset in points (negative = left).";
      };

      yOffset = mkOption {
        type = types.number;
        default = 0.0;
        description = "Vertical offset in points (negative = down).";
      };

      # ── Dimensions & appearance ─────────────────────────────────
      height = mkOption {
        type = types.number;
        default = 32.0;
        description = "Bar height in points.";
        example = 28;
      };

      backgroundOpacity = mkOption {
        type = types.number;
        default = 0.85;
        description = "Background opacity (0.0 - 1.0).";
        example = 0.9;
      };

      labelFontSize = mkOption {
        type = types.number;
        default = 12.0;
        description = "Font size for workspace labels.";
      };

      # ── Per-monitor overrides ───────────────────────────────────
      monitors = mkOption {
        type = types.attrsOf (types.submodule monitorOptions);
        default = { };
        description = ''
          Per-monitor bar customisation overrides.
          Keyed by display name as reported by macOS (e.g. "Built-in Retina Display").
        '';
        example = {
          "DELL U2723QE" = {
            position = "underMenuBar";
            height = 28.0;
            backgroundOpacity = 0.75;
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Merge bar settings into the OmniWM config.
    # Uses mkMerge so that monitors{} can coexist with the global config
    # without the OmniWM module fighting over the same attr path.
    services.omniwm.settings = mkMerge [
      {
        workspaceBar = {
          enabled = true;
          position = cfg.position;
          height = cfg.height;
          showLabels = cfg.showLabels;
          deduplicateAppIcons = cfg.deduplicateAppIcons;
          hideEmptyWorkspaces = cfg.hideEmptyWorkspaces;
          notchAware = cfg.notchAware;
          backgroundOpacity = cfg.backgroundOpacity;
          labelFontSize = cfg.labelFontSize;
          windowLevel = cfg.windowLevel;
          showFloatingWindows = cfg.showFloatingWindows;
          reserveLayoutSpace = cfg.reserveLayoutSpace;
          xOffset = cfg.xOffset;
          yOffset = cfg.yOffset;
          accentColor = accentColor;
          textColor = textColor;
        };
      }
      # Only emit the monitorBarSettings key if at least one override is defined.
      (lib.mkIf (cfg.monitors != { }) {
        monitorBarSettings = monitorBarSettings;
      })
    ];
  };
}
