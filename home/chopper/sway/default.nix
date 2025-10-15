{
  pkgs,
  lib,
  ...
}: let
  mod = "Mod4";

  # Script to slideshow wallpapers from ~/.wallpaper directory
  wallpaper-slideshow = pkgs.writeShellScript "wallpaper-slideshow" ''
    WALLPAPER_DIR="$HOME/.wallpaper"

    if [ ! -d "$WALLPAPER_DIR" ]; then
      echo "Wallpaper directory $WALLPAPER_DIR not found"
      exit 1
    fi

    # Find all image files in the wallpaper directory
    WALLPAPERS=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.webp" \) | sort)

    if [ -z "$WALLPAPERS" ]; then
      echo "No wallpaper images found in $WALLPAPER_DIR"
      exit 1
    fi

    # Kill any existing swaybg processes
    pkill swaybg || true

    # Cycle through wallpapers
    while true; do
      echo "$WALLPAPERS" | while IFS= read -r wallpaper; do
        if [ -f "$wallpaper" ]; then
          echo "Setting wallpaper: $wallpaper"
          ${pkgs.swaybg}/bin/swaybg -i "$wallpaper" -m fit &
          SWAYBG_PID=$!
          sleep 30  # Display each wallpaper for 30 seconds
          kill $SWAYBG_PID || true
        fi
      done
    done
  '';

  # Screenshot command
  screenshot = pkgs.writeShellScript "screenshot" ''
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.wl-clipboard}/bin/wl-copy
  '';
in {
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
      bars = [
        {
          command = "${pkgs.waybar}/bin/waybar";
        }
      ];
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
          { app_id = "pavucontrol"; }
          { app_id = "blueman-manager"; }
          { title = "Picture-in-Picture"; }
        ];
      };
      window = {
        border = 2;
        titlebar = false;
        commands = [
          {
            command = "opacity 0.95";
            criteria = { app_id = "kitty"; };
          }
          {
            command = "opacity 0.9";
            criteria = { class = "firefox"; };
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
      keybindings = lib.attrsets.mergeAttrsList [
        (lib.attrsets.mergeAttrsList (map (num: let
          ws = toString num;
        in {
          "${mod}+${ws}" = "workspace ${ws}";
          "${mod}+Ctrl+${ws}" = "move container to workspace ${ws}";
        }) [1 2 3 4 5 6 7 8 9 0]))

        (lib.attrsets.concatMapAttrs (key: direction: {
            "${mod}+${key}" = "focus ${direction}";
            "${mod}+Ctrl+${key}" = "move ${direction}";
          }) {
            h = "left";
            j = "down";
            k = "up";
            l = "right";
          })

        {
          "${mod}+Return" = "exec --no-startup-id ${pkgs.kitty}/bin/kitty";
          "${mod}+space" = "exec --no-startup-id wofi --show drun,run";

          "${mod}+x" = "kill";

          "${mod}+a" = "focus parent";
          "${mod}+e" = "layout toggle split";
          "${mod}+f" = "fullscreen toggle";
          "${mod}+g" = "split h";
          "${mod}+s" = "layout stacking";
          "${mod}+v" = "split v";
          "${mod}+w" = "layout tabbed";

          "${mod}+Shift+r" = "exec swaymsg reload";
          "--release Print" = "exec --no-startup-id ${screenshot}";
          "${mod}+Ctrl+l" = "exec ${pkgs.swaylock-fancy}/bin/swaylock-fancy";
          "${mod}+Ctrl+q" = "exit";

          # Keybinding to restart wallpaper slideshow
          "${mod}+Shift+w" = "exec ${wallpaper-slideshow}";
        }
      ];
      focus.followMouse = false;
      startup = [
        {command = "firefox";}
        {command = "${wallpaper-slideshow}";}
      ];
      workspaceAutoBackAndForth = true;
    };
    systemd.enable = true;
    wrapperFeatures = {gtk = true;};
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  home.file.".hm-graphical-session".text = pkgs.lib.concatStringsSep "\n" [
    "export MOZ_ENABLE_WAYLAND=1"
    "export NIXOS_OZONE_WL=1" # Electron
  ];

  services.cliphist.enable = true;

#  services.kanshi = {
#    enable = true;
#
#    profiles = {
#      home_office = {
#        outputs = [
#          {
#            criteria = "DP-2";
#            scale = 2.0;
#            status = "enable";
#            position = "0,0";
#          }
#          {
#            criteria = "DP-1";
#            scale = 2.0;
#            status = "enable";
#            position = "3840,0";
#          }
#          {
#            criteria = "DP-3";
#            scale = 2.0;
#            status = "enable";
#            position = "3840,0";
#          }
#        ];
#      };
#    };
#  };

  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
    mako # notifications
    swaybg
  ];
}
