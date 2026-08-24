{ lib, pkgs, ... }:

{
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
      marked = "#7a4a8a";

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
      background_opacity = "0.85";
      hide_window_decorations = false;
      confirm_os_window_close = 0;
      background_blur = 24;

      # Tab bar
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_title_template = "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";

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

      # Shell integration
      shell_integration = "enabled";

      # Terminal type
      term = "xterm-256color";

      # Advanced
      allow_remote_control = false;
      listen_on = "unix:/tmp/kitty";
    }
    # macOS-specific settings
    // (lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      macos_hide_titlebar = true;
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

    # Key bindings
    keybindings = {
      # Tab management
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+w" = "close_tab";
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+left" = "previous_tab";
      "ctrl+shift+q" = "quit";

      # Window management
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+n" = "new_os_window";

      # Font size
      "ctrl+shift+plus" = "change_font_size all +2.0";
      "ctrl+shift+minus" = "change_font_size all -2.0";
      "ctrl+shift+backspace" = "change_font_size all 0";

      # Clipboard
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";

      # Scrolling
      "ctrl+shift+up" = "scroll_line_up";
      "ctrl+shift+down" = "scroll_line_down";
      "ctrl+shift+page_up" = "scroll_page_up";
      "ctrl+shift+page_down" = "scroll_page_down";
      "ctrl+shift+home" = "scroll_home";
      "ctrl+shift+end" = "scroll_end";
    }
    # Linux-specific keybindings (merged from home/chopper/kitty/)
    // (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      "ctrl+shift+insert" = "paste_from_clipboard";
      "shift+insert" = "paste_from_selection";
    });
  };
}
