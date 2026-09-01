{ config, lib, pkgs, ... }:

let
  # Global command modifier for every kitty binding below.
  # Fed to kitty's own `kitty_mod` alias, so the bindings themselves stay
  # written as `kitty_mod+<key>` and only this value changes per platform.
  kittyMod =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "cmd"
    else if pkgs.stdenv.hostPlatform.isLinux then
      "ctrl"
    else
      "ctrl+shift";
in

{
  imports = [ ./sessions.nix ];

  programs.kitty = {
    enable = true;

    # Font configuration
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12.0;
    };

    # Theme and colors — SATANIC PALETTE
    # FreeBSD devil-inspired: void blacks, crimson reds, gold accents
    # themeFile deliberately unset; colors defined inline below

    # Settings
    settings = {
      # Global command modifier — see `kittyMod` above
      kitty_mod = kittyMod;

      # Font configuration
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";

      # ── Satanic color palette ──────────────────────────
      foreground = "#d4c5d4";
      background = "#0a0a0f";
      selection_foreground = "#d4c5d4";
      selection_background = "#3a1a2a";
      cursor = "#c12127";
      cursor_text_color = "#0a0a0f";
      url_color = "#d4a84b";

      # Black
      color0 = "#0a0a0f";
      color8 = "#14101a";

      # Red
      color1 = "#c12127";
      color9 = "#e63946";

      # Green
      color2 = "#4a9c6f";
      color10 = "#5abc7f";

      # Yellow
      color3 = "#d4a84b";
      color11 = "#e8c05b";

      # Blue
      color4 = "#4a6a9c";
      color12 = "#5a8abe";

      # Magenta
      color5 = "#7a4a8a";
      color13 = "#9a5aaa";

      # Cyan
      color6 = "#4a9c9c";
      color14 = "#5abeae";

      # White
      color7 = "#d4c5d4";
      color15 = "#f0e0f0";

      # Performance
      repaint_delay = 10;
      input_delay = 3;
      sync_to_monitor = true;

      # Window layout
      remember_window_size = false;
      initial_window_width = 1200;
      initial_window_height = 800;
      window_padding_width = 30;
      window_margin_width = 0;
      background_opacity = "0.45";
      dynamic_background_opacity = true;
      hide_window_decorations = false;
      confirm_os_window_close = -1;
      background_blur = 24;

      # Layouts
      enabled_layouts = "splits:equalize_on_window_close=yes,tall,stack,grid";

      # Tab bar
      tab_bar_edge = "left";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_title_template = "{session_name + ': ' if session_name else ''}{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";

      # Cursor
      cursor_shape = "beam";
      cursor_beam_thickness = "1.5";
      cursor_blink_interval = 0;
      cursor_trail = 1;

      # Mouse
      copy_on_select = true;
      strip_trailing_spaces = "smart";

      # Terminal bell
      enable_audio_bell = false;
      visual_bell_duration = "0.0";

      # URL handling
      url_style = "curly";
      open_url_with = "default";

      # Scrollback
      scrollback_lines = 10000;
      scrollback_pager_history_size = 100;

      # Shell integration
      shell_integration = "enabled";
      notify_on_cmd_finish = "invisible 10";

      # Advanced
      allow_remote_control = false;
    }
    # macOS-specific settings
    // (lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      # Fully borderless: no titlebar, no traffic lights, no rounded corners.
      # In kitty's cocoa backend this is decorations_desc = "none" — the window
      # is undecorated (square edges). Still resizable via macos_window_resizable
      # (default yes), but there is no titlebar left to drag, so use macOS's
      # ctrl+cmd+drag to move the window.
      hide_window_decorations = true;
    })
    # Linux-specific settings (merged from home/chopper/kitty/)
    // (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      linux_display_server = "auto";
      clipboard_control = "write-clipboard write-primary read-clipboard-ask read-primary-ask";
      wayland_titlebar_color = "system";
      disable_ligatures = "never";
      x11_hide_window_decorations = false;
      wayland_enable_ime = true;
    });

    # Key bindings — all prefixed with kitty_mod (cmd on macOS, ctrl on Linux)
    keybindings = {
      # Tab management
      "kitty_mod+t" = "new_tab_with_cwd";
      "kitty_mod+w" = "close_tab";
      "kitty_mod+right" = "next_tab";
      "kitty_mod+left" = "previous_tab";
      "kitty_mod+q" = "quit";

      # Window management
      "kitty_mod+enter" = "new_window_with_cwd";
      "kitty_mod+n" = "new_os_window_with_cwd";

      # Layouts
      "kitty_mod+l" = "next_layout";
      "kitty_mod+alt+z" = "toggle_layout stack";
      "kitty_mod+r" = "start_resizing_window";
      "kitty_mod+alt+e" = "layout_action equalize";

      # Sessions
      "kitty_mod+s" = "goto_session ${config.xdg.configHome}/kitty/sessions";
      "kitty_mod+alt+s" = "save_as_session --relocatable --base-dir ${config.xdg.configHome}/kitty/sessions";
      "kitty_mod+alt+left" = "goto_session -1";

      # Font size
      "kitty_mod+plus" = "change_font_size all +2.0";
      "kitty_mod+minus" = "change_font_size all -2.0";
      "kitty_mod+backspace" = "change_font_size all 0";

      # Clipboard
      "kitty_mod+c" = "copy_to_clipboard";
      "kitty_mod+v" = "paste_from_clipboard";

      # Scrolling
      "kitty_mod+up" = "scroll_line_up";
      "kitty_mod+down" = "scroll_line_down";
      "kitty_mod+page_up" = "scroll_page_up";
      "kitty_mod+page_down" = "scroll_page_down";
      "kitty_mod+home" = "scroll_home";
      "kitty_mod+end" = "scroll_end";
      "kitty_mod+g" = "show_last_command_output";
      "kitty_mod+alt+c" = "copy_last_command_output";
      "kitty_mod+z" = "scroll_to_prompt -1";
      "kitty_mod+x" = "scroll_to_prompt 1";
      "kitty_mod+slash" = "search_scrollback";

      # Discovery and visible text
      "kitty_mod+f3" = "command_palette";
      "kitty_mod+e" = "open_url_with_hints";

      # Opacity
      "kitty_mod+a>minus" = "set_background_opacity -0.05";
      "kitty_mod+a>plus" = "set_background_opacity +0.05";
      "kitty_mod+a>0" = "set_background_opacity default";
    }
    # Linux-specific keybindings (merged from home/chopper/kitty/)
    # Deliberately literal, not kitty_mod — these are X11/Wayland conventions.
    // (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      "ctrl+shift+insert" = "paste_from_clipboard";
      "shift+insert" = "paste_from_selection";
    });
  };

  xdg.configFile = {
    "kitty/quick-access-terminal.conf".text = ''
      lines 25
      edge top
      layer overlay
      background_opacity 0.85
      hide_on_focus_loss yes
      kitty_override background_blur=24
      kitty_override window_padding_width=20
    '';
  };
}
