{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  programs.kitty = {
    settings = {
      # Linux-specific window decorations
      linux_display_server = "auto";

      # Use system notifications on Linux
      enable_audio_bell = false;

      # Linux-specific clipboard handling
      clipboard_control = "write-clipboard write-primary read-clipboard-ask read-primary-ask";

      # Better performance on Linux
      wayland_titlebar_color = "system";

      # Linux font rendering
      disable_ligatures = "never";

      # X11/Wayland specific settings
      x11_hide_window_decorations = false;
      wayland_enable_ime = true;
    };

    # Linux-specific keybindings
    keybindings = {
      # Use Ctrl+Shift+Insert for paste (common on Linux)
      "ctrl+shift+insert" = "paste_from_clipboard";

      # Middle mouse paste
      "shift+insert" = "paste_from_selection";
    };
  };
}
