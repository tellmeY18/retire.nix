{
  pkgs,
  lib,
  config,
  ...
}: let
  mod = "Mod4";
  wallpaperDir = "${config.home.homeDirectory}/.wallpaper";
  wallpaperInterval = 30; # seconds

  # Nix-standard wallpaper slideshow service
  wallpaperSlideshow = pkgs.writeShellApplication {
    name = "wallpaper-slideshow";
    runtimeInputs = with pkgs; [swaybg findutils coreutils];
    text = ''
      WALLPAPER_DIR="${wallpaperDir}"

      if [ ! -d "$WALLPAPER_DIR" ]; then
        echo "Wallpaper directory $WALLPAPER_DIR not found"
        exit 1
      fi

      # Find all image files
      mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
           -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.webp" \) \
        | sort)

      if [ ''${#WALLPAPERS[@]} -eq 0 ]; then
        echo "No wallpaper images found in $WALLPAPER_DIR"
        exit 1
      fi

      # Kill any existing swaybg processes
      pkill swaybg || true

      # Cycle through wallpapers
      while true; do
        for wallpaper in "''${WALLPAPERS[@]}"; do
          if [ -f "$wallpaper" ]; then
            echo "Setting wallpaper: $wallpaper"
            swaybg -i "$wallpaper" -m fit &
            SWAYBG_PID=$!
            sleep ${toString wallpaperInterval}
            kill "$SWAYBG_PID" 2>/dev/null || true
          fi
        done
      done
    '';
  };

  screenshot = pkgs.writeShellApplication {
    name = "sway-screenshot";
    runtimeInputs = with pkgs; [grim slurp wl-clipboard];
    text = ''
      grim -g "$(slurp)" - | wl-copy
    '';
  };
in {
  fonts.fontconfig.enable = true;

  programs.wofi = {
    enable = true;
    settings = {
      allow_markup = true;
      width = 250;
    };
  };

  wayland.windowManager.sway = {
    enable = true;
    package = pkgs.swayfx;
    checkConfig = false;

    config = {
      modifier = mod;

      bars = [];

      gaps = {
        inner = 3;
        outer = 0;
      };

      colors = {
        focused = {
          background = "#285577";
          border = "#4c7899";
          childBorder = "#285577";
          indicator = "#2e9ef4";
          text = "#ffffff";
        };
        focusedInactive = {
          background = "#5f676a";
          border = "#333333";
          childBorder = "#5f676a";
          indicator = "#484e50";
          text = "#ffffff";
        };
        unfocused = {
          background = "#222222";
          border = "#333333";
          childBorder = "#222222";
          indicator = "#292d2e";
          text = "#888888";
        };
        urgent = {
          background = "#900000";
          border = "#2f343a";
          childBorder = "#900000";
          indicator = "#900000";
          text = "#ffffff";
        };
        placeholder = {
          background = "#0c0c0c";
          border = "#000000";
          childBorder = "#0c0c0c";
          indicator = "#000000";
          text = "#ffffff";
        };
      };

      floating = {
        border = 2;
        criteria = [
          {app_id = "pavucontrol";}
          {app_id = "blueman-manager";}
          {title = "Picture-in-Picture";}
        ];
      };

      window = {
        border = 2;
        titlebar = false;
        commands = [
          {
            command = "opacity 0.95";
            criteria = {app_id = "kitty";};
          }
          {
            command = "opacity 0.9";
            criteria = {class = "firefox";};
          }
        ];
      };

      input = {
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "disabled";
          dwt = "enabled";
          middle_emulation = "enabled";
        };
      };

      keybindings = let
        # Workspace bindings
        workspaceBindings = lib.listToAttrs (map (num: let
          ws = toString num;
        in {
          name = "${mod}+${ws}";
          value = "workspace ${ws}";
        }) (lib.range 1 9) ++ [{
          name = "${mod}+0";
          value = "workspace 10";
        }]);

        workspaceMoveBindings = lib.listToAttrs (map (num: let
          ws = toString num;
        in {
          name = "${mod}+Ctrl+${ws}";
          value = "move container to workspace ${ws}";
        }) (lib.range 1 9) ++ [{
          name = "${mod}+Ctrl+0";
          value = "move container to workspace 10";
        }]);

        # Directional bindings (using Shift instead of Ctrl for moves to avoid conflicts)
        directionBindings = lib.concatMapAttrs (key: direction: {
          "${mod}+${key}" = "focus ${direction}";
          "${mod}+Shift+${key}" = "move ${direction}";
        }) {
          h = "left";
          j = "down";
          k = "up";
          l = "right";
        };

        # General bindings
        generalBindings = {
          "${mod}+Return" = "exec ${pkgs.kitty}/bin/kitty";
          "${mod}+space" = "exec ${pkgs.wofi}/bin/wofi --show drun,run";
          "${mod}+x" = "kill";

          # Layout
          "${mod}+a" = "focus parent";
          "${mod}+e" = "layout toggle split";
          "${mod}+f" = "fullscreen toggle";
          "${mod}+g" = "split h";
          "${mod}+s" = "layout stacking";
          "${mod}+v" = "split v";
          "${mod}+w" = "layout tabbed";

          # System
          "${mod}+Shift+r" = "reload";
          "${mod}+Ctrl+q" = "exit";
          "${mod}+Ctrl+l" = "exec ${pkgs.swaylock-fancy}/bin/swaylock-fancy";

          # Screenshot
          "--release Print" = "exec ${screenshot}/bin/sway-screenshot";

          # Wallpaper
          "${mod}+Shift+w" = "exec ${wallpaperSlideshow}/bin/wallpaper-slideshow";
        };
      in
        lib.mkMerge [
          workspaceBindings
          workspaceMoveBindings
          directionBindings
          generalBindings
        ];

      focus.followMouse = false;
      workspaceAutoBackAndForth = true;

      startup = [
        {command = "${wallpaperSlideshow}/bin/wallpaper-slideshow";}
      ];
    };

    systemd.enable = true;
    wrapperFeatures.gtk = true;
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
  };

  services.cliphist.enable = true;

  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
    mako
    swaybg
    # Font Awesome fonts for waybar icons
    font-awesome
    # Additional icon theme packages
    papirus-icon-theme
    adwaita-icon-theme
  ];
}
