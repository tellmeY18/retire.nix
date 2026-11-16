# home/desktop/full.nix — the rest of the Hyprland desktop on top of
# hyprland.nix (theme + core binds): navigation, scratchpad, groups,
# resize submap, gestures, window rules, and the session services
# (idle/lock, polkit, clipboard, notifications history, media, removable
# media, network/bluetooth applets, night light, screenshots, recording).
#
# Look stays paper/ink: no blur, shadows or animations. Menus reuse tofi
# with the live theme's colours (~/.local/state/theme/tofi.args).
{ config, lib, pkgs, ... }:

let
  state = "${config.home.homeDirectory}/.local/state/theme";
  shots = "${config.xdg.userDirs.pictures}/Screenshots";
  videos = "${config.xdg.userDirs.videos}/Recordings";

  # tofi in dmenu mode, themed: menu "prompt" < choices
  menu = pkgs.writeShellScriptBin "menu" ''
    exec ${pkgs.tofi}/bin/tofi $(cat ${state}/tofi.args) --prompt-text "''${1:-select} " --require-match true
  '';

  power = pkgs.writeShellScriptBin "power-menu" ''
    choice=$(printf 'lock\nsuspend\nlogout\nreboot\nshutdown\n' | ${menu}/bin/menu power)
    case "$choice" in
      lock) loginctl lock-session ;;
      suspend) systemctl suspend ;;
      logout) hyprctl dispatch 'hl.dsp.exit()' ;;
      reboot) systemctl reboot ;;
      shutdown) systemctl poweroff ;;
    esac
  '';

  clipboard = pkgs.writeShellScriptBin "clipboard-menu" ''
    ${pkgs.cliphist}/bin/cliphist list | ${menu}/bin/menu clip | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
  '';

  # shot region|full|window — saves to ~/Pictures/Screenshots and copies.
  shot = pkgs.writeShellScriptBin "shot" ''
    mkdir -p "${shots}"
    f="${shots}/$(date +%Y-%m-%d_%H-%M-%S).png"
    case "''${1:-region}" in
      full) ${pkgs.grim}/bin/grim "$f" ;;
      window) g=$(hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
              ${pkgs.grim}/bin/grim -g "$g" "$f" ;;
      *) g=$(${pkgs.slurp}/bin/slurp) || exit 0; ${pkgs.grim}/bin/grim -g "$g" "$f" ;;
    esac
    ${pkgs.wl-clipboard}/bin/wl-copy < "$f"
    ${pkgs.libnotify}/bin/notify-send -i "$f" "screenshot" "$(basename "$f")"
  '';

  # record — toggle a region recording to ~/Videos/Recordings.
  record = pkgs.writeShellScriptBin "record" ''
    if pkill -INT -x wf-recorder; then
      ${pkgs.libnotify}/bin/notify-send "recording" "saved to ${videos}"; exit 0
    fi
    mkdir -p "${videos}"
    g=$(${pkgs.slurp}/bin/slurp) || exit 0
    ${pkgs.libnotify}/bin/notify-send "recording" "started — run again to stop"
    exec ${pkgs.wf-recorder}/bin/wf-recorder -g "$g" -f "${videos}/$(date +%Y-%m-%d_%H-%M-%S).mp4"
  '';

  nightlight = pkgs.writeShellScriptBin "nightlight" ''
    if pkill -x hyprsunset; then ${pkgs.libnotify}/bin/notify-send "night light" "off"
    else ${pkgs.libnotify}/bin/notify-send "night light" "on (4500K)"; exec ${pkgs.hyprsunset}/bin/hyprsunset -t 4500
    fi
  '';

  picker = pkgs.writeShellScriptBin "pick-colour" ''
    c=$(${pkgs.hyprpicker}/bin/hyprpicker -a -f hex) && ${pkgs.libnotify}/bin/notify-send "colour" "$c (copied)"
  '';
in
{
  home.packages = [ menu power clipboard shot record nightlight picker ] ++ (with pkgs; [
    hyprpicker
    hyprsunset
    libnotify
    pavucontrol
    playerctl
    wf-recorder
    wev
  ]);

  # ~/Pictures/Screenshots, ~/Videos/Recordings use the standard XDG dirs.
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  # ── Session services ──────────────────────────────────────────────────
  services.hyprpolkitagent.enable = true;
  services.cliphist.enable = true;
  services.playerctld.enable = true;
  services.udiskie = {
    enable = true;
    tray = "auto";
  };
  services.network-manager-applet.enable = true;
  services.blueman-applet.enable = true;

  # Lock after 5 min, screen off after 6, suspend after 15; always lock
  # before sleep (lid close / power menu) so resume lands on hyprlock.
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
      };
      listener = [
        { timeout = 300; on-timeout = "loginctl lock-session"; }
        {
          timeout = 360;
          on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'";
          on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
        }
        { timeout = 900; on-timeout = "systemctl suspend"; }
      ];
    };
  };

  # Neutral cursor + GTK/Qt base that the light/dark color-scheme drives.
  home.pointerCursor = {
    enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
    gtk.enable = true;
    hyprcursor.enable = true;
  };
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus";
    };
  };

  # ── Hyprland ──────────────────────────────────────────────────────────
  wayland.windowManager.hyprland.settings.config = {
    input = {
      repeat_delay = 300;
      repeat_rate = 40;
      touchpad = {
        tap_to_click = true;
        disable_while_typing = true;
        clickfinger_behavior = true;
        drag_lock = 1;
      };
    };
    gestures.workspace_swipe_distance = 300;
    dwindle.preserve_split = true;
    groupbar = {
      font_family = "sans-serif";
      font_size = 10;
      height = 16;
      gradients = true;
      rounding = 3;
      gradient_rounding = 3;
    };
    binds = {
      workspace_back_and_forth = true;
      allow_workspace_cycles = true;
      movefocus_cycles_groupfirst = true;
    };
    misc = {
      focus_on_activate = true;
      mouse_move_enables_dpms = true;
      key_press_enables_dpms = true;
      enable_swallow = true;
      swallow_regex = "^(kitty)$";
      allow_session_lock_restore = true;
      vrr = 2;
    };
  };

  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    -- ── navigation: focus / move / swap (hjkl + arrows) ──────────────────
    local dirs = { left = { "H", "Left" }, right = { "L", "Right" }, up = { "K", "Up" }, down = { "J", "Down" } }
    for dir, keys in pairs(dirs) do
      for _, k in ipairs(keys) do
        hl.bind("SUPER + " .. k, hl.dsp.focus({ direction = dir }))
        hl.bind("SUPER + SHIFT + " .. k, hl.dsp.window.move({ direction = dir, group_aware = true }))
        hl.bind("SUPER + CTRL + " .. k, hl.dsp.window.swap({ direction = dir }))
      end
    end
    hl.bind("ALT + Tab", function()
      hl.dispatch(hl.dsp.window.cycle_next())
      hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
    end)

    -- ── workspaces 6-10 (1-5 come from settings), cycling, scroll ────────
    for i = 6, 10 do
      local key = tostring(i % 10)
      hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
      hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    end
    hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "previous" }))
    hl.bind("SUPER + ALT + Right", hl.dsp.focus({ workspace = "r+1" }))
    hl.bind("SUPER + ALT + Left", hl.dsp.focus({ workspace = "r-1" }))
    hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

    -- ── scratchpad (special workspace) ───────────────────────────────────
    hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("scratch"))
    hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratch" }))

    -- ── window state ─────────────────────────────────────────────────────
    hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
    hl.bind("SUPER + W", hl.dsp.window.pseudo())
    hl.bind("SUPER + E", hl.dsp.layout("togglesplit"))
    hl.bind("SUPER + SHIFT + E", hl.dsp.layout("swapsplit"))
    hl.bind("SUPER + Y", hl.dsp.window.pin())
    hl.bind("SUPER + C", hl.dsp.window.center())
    hl.bind("SUPER + SHIFT + Q", hl.dsp.window.kill())

    -- ── groups (tabbed windows) ──────────────────────────────────────────
    hl.bind("SUPER + G", hl.dsp.group.toggle())
    hl.bind("SUPER + bracketright", hl.dsp.group.next())
    hl.bind("SUPER + bracketleft", hl.dsp.group.prev())
    hl.bind("SUPER + SHIFT + G", hl.dsp.window.move({ out_of_group = true }))

    -- ── monitors ─────────────────────────────────────────────────────────
    hl.bind("SUPER + period", hl.dsp.focus({ monitor = "+1" }))
    hl.bind("SUPER + comma", hl.dsp.focus({ monitor = "-1" }))
    hl.bind("SUPER + SHIFT + period", hl.dsp.window.move({ monitor = "+1" }))
    hl.bind("SUPER + SHIFT + comma", hl.dsp.window.move({ monitor = "-1" }))

    -- ── resize submap: SUPER+R, then hjkl/arrows, Enter/Esc to leave ─────
    hl.bind("SUPER + R", hl.dsp.submap("resize"))
    hl.define_submap("resize", function()
      local steps = { H = { -40, 0 }, L = { 40, 0 }, K = { 0, -40 }, J = { 0, 40 },
                      Left = { -40, 0 }, Right = { 40, 0 }, Up = { 0, -40 }, Down = { 0, 40 } }
      for k, d in pairs(steps) do
        hl.bind(k, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), { repeating = true })
      end
      hl.bind("Return", hl.dsp.submap("reset"))
      hl.bind("escape", hl.dsp.submap("reset"))
    end)

    -- ── apps & tools ─────────────────────────────────────────────────────
    hl.bind("SUPER + B", hl.dsp.exec_cmd("firefox"))
    hl.bind("SUPER + V", hl.dsp.exec_cmd("clipboard-menu"))
    hl.bind("SUPER + Escape", hl.dsp.exec_cmd("power-menu"))
    hl.bind("SUPER + N", hl.dsp.exec_cmd("dunstctl history-pop"))
    hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("dunstctl close-all"))
    hl.bind("SUPER + ALT + N", hl.dsp.exec_cmd("nightlight"))
    hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("pkill -USR1 waybar"))
    hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("pick-colour"))
    hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("record"))
    hl.bind("Print", hl.dsp.exec_cmd("shot region"))
    hl.bind("SHIFT + Print", hl.dsp.exec_cmd("shot full"))
    hl.bind("ALT + Print", hl.dsp.exec_cmd("shot window"))
    hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("shot region"))

    -- ── media ────────────────────────────────────────────────────────────
    hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
    hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
    hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

    -- ── touchpad gestures ────────────────────────────────────────────────
    hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
    hl.gesture({ fingers = 3, direction = "up", action = function()
      hl.dispatch(hl.dsp.workspace.toggle_special("scratch"))
    end })
    hl.gesture({ fingers = 3, direction = "down", action = "fullscreen" })
    hl.gesture({ fingers = 4, direction = "pinch", action = "cursor_zoom", zoom_level = 2 })

    -- ── window rules ─────────────────────────────────────────────────────
    hl.window_rule({
      match = { class = "^(org.pulseaudio.pavucontrol|nm-connection-editor|.blueman-manager-wrapped|xdg-desktop-portal-gtk|udiskie)$" },
      float = true, center = true, size = { 900, 600 },
    })
    hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true })
    hl.window_rule({ match = { fullscreen = true }, idle_inhibit = "fullscreen" })
    hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })
  '';

  # ── Waybar: richer modules, same flat style ───────────────────────────
  programs.waybar.settings.mainBar = {
    modules-right = lib.mkForce [
      "privacy"
      "idle_inhibitor"
      "cpu"
      "memory"
      "backlight"
      "pulseaudio"
      "bluetooth"
      "network"
      "battery"
      "custom/theme"
      "tray"
      "custom/power"
    ];
    idle_inhibitor = {
      format = "{icon}";
      format-icons = { activated = "awake"; deactivated = "idle"; };
    };
    cpu.format = "cpu {usage}%";
    memory.format = "mem {percentage}%";
    backlight.format = "lux {percent}%";
    bluetooth = {
      format = "bt";
      format-disabled = "";
      format-connected = "bt {num_connections}";
      on-click = "blueman-manager";
    };
    pulseaudio.on-click = "pavucontrol";
    network.on-click = "nm-connection-editor";
    battery.states = { warning = 25; critical = 10; };
    "custom/power" = {
      format = "⏻";
      tooltip = false;
      on-click = "power-menu";
    };
  };
  programs.waybar.style = lib.mkAfter ''
    #privacy, #idle_inhibitor, #cpu, #memory, #backlight, #bluetooth { padding: 0 10px; color: @mute; }
    #battery.warning { color: @ink; }
    #battery.critical { background: @ink; color: @paper; }
    #custom-power { padding: 0 12px; color: @ink; }
  '';
}
