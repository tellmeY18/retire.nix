 {
   programs.kitty = {
     enable = true;

     # Font configuration
     font = {
       name = "JetBrains Mono";
       size = 12;
     };

     # Theme and colors
     theme = "Tokyo Night";

     # Settings
     settings = {
       # Performance
       repaint_delay = 10;
       input_delay = 3;
       sync_to_monitor = true;

       # Window layout
       remember_window_size = false;
       initial_window_width = 1200;
       initial_window_height = 800;
       window_padding_width = 8;
       window_margin_width = 0;

       # Tab bar
       tab_bar_edge = "bottom";
       tab_bar_style = "powerline";
       tab_powerline_style = "slanted";
       tab_title_template = "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";

       # Cursor
       cursor_shape = "beam";
       cursor_beam_thickness = "1.5";
       cursor_blink_interval = 0;

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
     };

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
     };
   };
 }
