# home/vysakh/default.nix — Hyprland desktop for vysakh (chopper; theme from skywalker).
#
# Aesthetic: werepair.fyi — paper white / ink #161616, 1px rules, 3px radius,
# system sans, flat. No blur, shadows, transparency, animation or wallpaper.
#
# Light/dark toggle: both palettes are built by Nix; `theme toggle` (bar
# button or $mod+T) copies the active one to ~/.local/state/theme/ and
# reloads the apps. Every app `include`s/`source`s from that directory, so
# switching never needs a rebuild.
{ config, lib, pkgs, ... }:

let
  font = "sans-serif";
  state = "${config.home.homeDirectory}/.local/state/theme";

  palettes = {
    light = { bg = "ffffff"; fg = "161616"; rule = "cccccc"; frame = "888888"; mute = "555555"; tint = "f5f5f5"; };
    dark = { bg = "111111"; fg = "f5f5f5"; rule = "444444"; frame = "777777"; mute = "a3a3a3"; tint = "1f1f1f"; };
  };

  # One directory per palette, one file per app.
  mkTheme = name: c:
    let f = pkgs.writeText; in
    pkgs.linkFarm "theme-${name}" [
      {
        name = "waybar.css";
        path = f "waybar.css" ''
          @define-color paper #${c.bg};
          @define-color ink #${c.fg};
          @define-color rule #${c.rule};
          @define-color mute #${c.mute};
          @define-color tint #${c.tint};
        '';
      }
      {
        name = "kitty.conf";
        path = f "kitty.conf" ''
          background #${c.bg}
          foreground #${c.fg}
          cursor #${c.fg}
          selection_background #${c.fg}
          selection_foreground #${c.bg}
        '';
      }
      {
        name = "hypr-theme.lua";
        path = f "hypr-theme.lua" ''
          hl.config({
            general = { col = { active_border = "rgb(${c.fg})", inactive_border = "rgb(${c.rule})" } },
            misc = { background_color = "rgb(${c.bg})" },
          })
        '';
      }
      {
        name = "hyprlock.conf";
        path = f "hyprlock.conf" ''
          $bg = rgb(${c.bg})
          $fg = rgb(${c.fg})
          $mute = rgb(${c.mute})
        '';
      }
      {
        name = "dunst.conf";
        path = f "dunst.conf" ''
          [global]
              frame_color = "#${c.frame}"
          [urgency_low]
              background = "#${c.bg}"
              foreground = "#${c.mute}"
          [urgency_normal]
              background = "#${c.bg}"
              foreground = "#${c.fg}"
          [urgency_critical]
              background = "#${c.fg}"
              foreground = "#${c.bg}"
              frame_color = "#${c.fg}"
        '';
      }
      {
        # tofi has no include; the launcher splices these in as CLI flags.
        name = "tofi.args";
        path = f "tofi.args" ''
          --background-color=#${c.bg} --text-color=#${c.fg} --border-color=#${c.fg} --selection-color=#${c.bg} --selection-background=#${c.fg}
        '';
      }
    ];

  themes = lib.mapAttrs mkTheme palettes;

  # theme [light|dark|toggle|init]  — init applies the saved theme (or light).
  theme = pkgs.writeShellScriptBin "theme" ''
    d=${state}
    mkdir -p "$d"
    cur=$(cat "$d/name" 2>/dev/null || echo light)
    case "''${1:-toggle}" in
      light) new=light ;;
      dark) new=dark ;;
      init) new=$cur ;;
      *) [ "$cur" = light ] && new=dark || new=light ;;
    esac
    case "$new" in
      light) src=${themes.light} ;;
      *) src=${themes.dark} ;;
    esac
    cp -fL --no-preserve=mode,ownership "$src"/* "$d"/
    echo "$new" > "$d/name"
    # Reload; harmless if an app isn't running (e.g. during activation).
    hyprctl reload >/dev/null 2>&1 || true
    pkill -USR2 waybar 2>/dev/null || true
    pkill -USR1 kitty 2>/dev/null || true
    dunstctl reload >/dev/null 2>&1 || true
  '';

  launcher = pkgs.writeShellScript "launcher" ''
    tofi-drun $(cat ${state}/tofi.args) | xargs hyprctl dispatch exec --
  '';
in
{
  home.stateVersion = "26.11";

  home.packages = [ theme ] ++ (with pkgs; [
    brightnessctl
    grim
    slurp
    wl-clipboard
  ]);

  # Seed ~/.local/state/theme on first activation so includes resolve.
  home.activation.themeInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${theme}/bin/theme init
  '';

  # Plain, colourless-by-default zsh so it follows kitty's light/dark theme.
  # Deliberately NOT home/common/zsh: that module aliases ls/cat/find/ps/top
  # to eza/bat/fd/procs/htop, which aren't installed on this box.
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion = {
      enable = true;
      strategy = [ "history" ];
      highlight = "fg=8";
    };
    syntaxHighlighting = {
      enable = true;
      styles = {
        command = "bold";
        builtin = "bold";
        function = "bold";
        alias = "bold";
      };
    };
    history = {
      size = 50000;
      save = 50000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
    };
    shellAliases = {
      ls = "ls --color=auto";
      ll = "ls -lah";
      ".." = "cd ..";
    };
    initContent = ''
      setopt AUTO_CD INTERACTIVE_COMMENTS HIST_REDUCE_BLANKS
      # ~/path ›   (exit status shown only on failure)
      PROMPT='%B%~%b %(?..[%?] )› '
    '';
  };

  # dunst reads dunstrc.d/*.conf as overrides; point it at the live theme.
  xdg.configFile."dunst/dunstrc.d/theme.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${state}/dunst.conf";

  # Hyprland itself comes from the NixOS module (programs.hyprland).
  # Hyprland 0.56+ reads a Lua config: each `settings` attr becomes an
  # hl.<name>(...) call. (The old hyprlang keys like "$mod = ..." generate
  # invalid Lua and silently kill every bind.)
  wayland.windowManager.hyprland =
    let
      lua = lib.generators.mkLuaInline;
      bind = keys: action: opts:
        { _args = [ keys (lua action) ] ++ lib.optional (opts != null) opts; };
      media = { locked = true; repeating = true; };
      workspaces = builtins.concatMap
        (n:
          let k = toString n; in [
            (bind "SUPER + ${k}" "hl.dsp.focus({ workspace = ${k} })" null)
            (bind "SUPER + SHIFT + ${k}" "hl.dsp.window.move({ workspace = ${k} })" null)
          ])
        (builtins.genList (i: i + 1) 5);
    in
    {
      enable = true;
      package = null;
      portalPackage = null;
      # Live light/dark colours; pcall so a missing file can't break the rest.
      extraConfig = ''pcall(dofile, "${state}/hypr-theme.lua")'';
      settings = {
        monitor = { output = ""; mode = "preferred"; position = "auto"; scale = "1"; };

        config = {
          general = {
            gaps_in = 4;
            gaps_out = 8;
            border_size = 1;
            resize_on_border = true;
          };
          decoration = {
            rounding = 3;
            blur.enabled = false;
            shadow.enabled = false;
          };
          animations.enabled = false;
          misc = {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
          };
          input = {
            kb_layout = "us";
            follow_mouse = 1;
            touchpad.natural_scroll = true;
          };
        };

        bind = [
          (bind "SUPER + Return" ''hl.dsp.exec_cmd("kitty")'' null)
          (bind "SUPER + D" ''hl.dsp.exec_cmd("${launcher}")'' null)
          (bind "SUPER + T" ''hl.dsp.exec_cmd("theme toggle")'' null)
          (bind "SUPER + P" ''hl.dsp.exec_cmd("hyprlock")'' null)
          (bind "SUPER + Q" "hl.dsp.window.close()" null)
          (bind "SUPER + Space" ''hl.dsp.window.float({ action = "toggle" })'' null)
          (bind "SUPER + F" "hl.dsp.window.fullscreen()" null)
          (bind "SUPER + SHIFT + M" "hl.dsp.exit()" null)
          (bind "SUPER + mouse:272" "hl.dsp.window.drag()" { mouse = true; })
          (bind "SUPER + mouse:273" "hl.dsp.window.resize()" { mouse = true; })
          (bind "XF86AudioRaiseVolume" ''hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+")'' media)
          (bind "XF86AudioLowerVolume" ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")'' media)
          (bind "XF86AudioMute" ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")'' media)
          (bind "XF86MonBrightnessUp" ''hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+")'' media)
          (bind "XF86MonBrightnessDown" ''hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-")'' media)
        ] ++ workspaces;
      };
    };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 32;
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "battery" "custom/theme" "tray" ];
      "hyprland/workspaces".format = "{name}";
      clock.format = "{:%H:%M · %a %d %b}";
      pulseaudio = { format = "vol {volume}%"; format-muted = "muted"; };
      network = {
        format-wifi = "wifi";
        format-ethernet = "lan";
        format-disconnected = "offline";
      };
      battery.format = "bat {capacity}%";
      "custom/theme" = {
        exec = "cat ${state}/name";
        interval = "once";
        format = "◐ {}";
        tooltip = false;
        on-click = "theme toggle";
      };
      tray.spacing = 8;
    };
    style = ''
      @import url("file://${state}/waybar.css");
      * { font-family: ${font}; font-size: 13px; border: none; border-radius: 0; min-height: 0; }
      window#waybar { background: @paper; color: @ink; border-bottom: 1px solid @rule; }
      #workspaces button { padding: 0 10px; margin: 4px 2px; color: @ink; background: @paper; border: 1px solid @rule; border-radius: 3px; }
      #workspaces button.active { background: @ink; color: @paper; border-color: @ink; }
      #workspaces button:hover { background: @tint; color: @ink; }
      #clock { font-weight: 800; }
      #pulseaudio, #network, #battery, #tray { padding: 0 12px; color: @mute; }
      #custom-theme { padding: 0 10px; margin: 4px 4px; color: @ink; border: 1px solid @rule; border-radius: 3px; }
      #custom-theme:hover { background: @tint; }
    '';
  };

  programs.kitty = {
    enable = true;
    font.name = "monospace";
    font.size = 11;
    settings = {
      window_padding_width = 10;
      enable_audio_bell = false;
      confirm_os_window_close = 0;
    };
    extraConfig = "include ${state}/kitty.conf";
  };

  # Colours come from dunstrc.d/theme.conf (the live theme).
  services.dunst = {
    enable = true;
    settings.global = {
      origin = "top-right";
      offset = "(12, 44)";
      width = 320;
      frame_width = 1;
      corner_radius = 3;
      font = "${font} 11";
      padding = 12;
      horizontal_padding = 12;
      separator_height = 1;
      separator_color = "frame";
    };
  };

  # Colours are passed as flags by the launcher script.
  programs.tofi = {
    enable = true;
    settings = {
      width = 520;
      height = 360;
      border-width = 1;
      outline-width = 0;
      corner-radius = 3;
      padding-left = 16;
      padding-right = 16;
      padding-top = 12;
      padding-bottom = 12;
      result-spacing = 6;
      selection-background-padding = 4;
      selection-background-corner-radius = 3;
      inherit font;
      font-size = 12;
      hide-cursor = true;
      prompt-text = "run ";
    };
  };

  programs.hyprlock = {
    enable = true;
    # $bg/$fg/$mute are defined by the live theme.
    extraConfig = "source = ${state}/hyprlock.conf";
    sourceFirst = true;
    settings = {
      background = [{ color = "$bg"; }];
      input-field = [{
        size = "300, 44";
        outline_thickness = 1;
        outer_color = "$fg";
        inner_color = "$bg";
        font_color = "$fg";
        check_color = "$mute";
        fail_color = "$fg";
        fade_on_empty = false;
        placeholder_text = "password";
        dots_center = true;
        rounding = 3;
        position = "0, -20";
        halign = "center";
        valign = "center";
      }];
      label = [{
        text = "$TIME";
        color = "$fg";
        font_size = 48;
        font_family = font;
        position = "0, 80";
        halign = "center";
        valign = "center";
      }];
    };
  };
}
