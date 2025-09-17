{ config, lib, pkgs, ... }:


{
  programs.tmux = {
    enable = true;
    package = pkgs.tmux;
    shell = "${pkgs.zsh}/bin/zsh";

    # Core settings
    terminal = "screen-256color";
    historyLimit = 100000;
    baseIndex = 1;

    # Mouse and keyboard
    mouse = true;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    resizeAmount = 10;

    # Behavior
    aggressiveResize = true;
    clock24 = true;
    escapeTime = 0;
    focusEvents = true;
    newSession = false;
    disableConfirmationPrompt = false;
    reverseSplit = false;

    # Security
    secureSocket = true;

    # Prefix key
    prefix = "C-a";


    # Sensible plugin at top
    sensibleOnTop = true;

    # Plugins for enhanced functionality
    plugins = with pkgs.tmuxPlugins; [
      # Essential plugins
      sensible
      pain-control
      prefix-highlight

      # Session management
      resurrect
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
          set -g @continuum-boot 'on'
        '';
      }

      # Navigation and copy
      {
        plugin = yank;
        extraConfig = ''
          set -g @yank_selection_mouse 'clipboard'
          set -g @yank_action 'copy-pipe-and-cancel'
        '';
      }

      # Visual enhancements
      {
        plugin = cpu;
        extraConfig = ''
          set -g @cpu_low_icon "ᚏ"
          set -g @cpu_medium_icon "ᚐ"
          set -g @cpu_high_icon "ᚑ"

          set -g @cpu_low_fg_color "#[fg=green]"
          set -g @cpu_medium_fg_color "#[fg=yellow]"
          set -g @cpu_high_fg_color "#[fg=red]"

          set -g @cpu_percentage_format "%3.1f%%"
        '';
      }

      {
        plugin = battery;
        extraConfig = ''
          set -g @batt_icon_status_charged '🔋'
          set -g @batt_icon_status_charging '⚡'
          set -g @batt_icon_status_discharging '👎'
          set -g @batt_color_status_primary_charged '#3daee9'
          set -g @batt_color_status_primary_charging '#3daee9'
        '';
      }

      # File tree
      {
        plugin = sidebar;
        extraConfig = ''
          set -g @sidebar-tree-command 'tree -C'
          set -g @sidebar-tree-width '25'
        '';
      }

      # Logging
      {
        plugin = logging;
        extraConfig = ''
          set -g @logging-path "$HOME/.tmux/logs"
        '';
      }

      # Open URLs and files
      {
        plugin = open;
        extraConfig = ''
          set -g @open-S 'https://www.google.com/search?q='
        '';
      }
    ];

    # Additional configuration
    extraConfig = ''
      # =====================================
      # ===           Shell               ===
      # =====================================

      # Ensure zsh is used as default shell
      set -g default-shell "${pkgs.zsh}/bin/zsh"
      set -g default-command "${pkgs.zsh}/bin/zsh"

      # =====================================
      # ===           Theme               ===
      # =====================================

      # Status bar design
      set -g status-justify left
      set -g status-interval 2
      set -g status-position bottom
      set -g status-bg colour235
      set -g status-fg colour137
      set -g status-left-length 70
      set -g status-right-length 50

      set -g status-left '#[fg=colour233,bg=colour245,bold] #h #[fg=colour245,bg=colour238,nobold]#[fg=colour245,bg=colour238] #S #[fg=colour238,bg=colour235,nobold]'

      set -g status-right '#[fg=colour238,bg=colour235]#[fg=colour245,bg=colour238] #{cpu_percentage} #[fg=colour245,bg=colour238]#[fg=colour233,bg=colour245,bold] #{battery_percentage} #[fg=colour245,bg=colour245]#[fg=colour232,bg=colour245,bold] %d/%m %H:%M:%S '

      # Window status
      setw -g window-status-current-format '#[fg=colour235,bg=colour208]#[fg=colour232,bg=colour208] #I #[fg=colour208,bg=colour237,nobold]#[fg=colour250,bg=colour237] #W #[fg=colour237,bg=colour235,nobold]'
      setw -g window-status-format '#[fg=colour235,bg=colour238]#[fg=colour245,bg=colour238] #I #[fg=colour238,bg=colour235,nobold]#[fg=colour245,bg=colour235] #W #[fg=colour235,bg=colour235,nobold]'

      # =====================================
      # ===        Key bindings           ===
      # =====================================

      # Reload config file
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"

      # Split panes using | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # New window in current path
      bind c new-window -c "#{pane_current_path}"

      # Switch panes using Alt-arrow without prefix
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Shift arrow to switch windows
      bind -n S-Left  previous-window
      bind -n S-Right next-window

      # Copy mode vi-style
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
      bind-key -T copy-mode-vi r send-keys -X rectangle-toggle

      # Synchronize panes
      bind a set-window-option synchronize-panes\; display-message "synchronize-panes is now #{?synchronize-panes,on,off}"

      # =====================================
      # ===          Appearance           ===
      # =====================================

      # Pane border
      set -g pane-border-style fg=colour238
      set -g pane-active-border-style fg=colour208

      # Message text
      set -g message-style bg=colour235,fg=colour208
      set -g message-command-style bg=colour235,fg=colour208

      # Window mode
      setw -g mode-style bg=colour238,fg=colour208

      # Window status bell
      setw -g window-status-bell-style bg=colour1,fg=colour255,bold

      # =====================================
      # ===      Plugin configurations   ===
      # =====================================

      # Resurrect settings
      set -g @resurrect-strategy-vim 'session'
      set -g @resurrect-strategy-nvim 'session'
      set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-save-shell-history 'on'

      # Prefix highlight
      set -g @prefix_highlight_fg 'colour232'
      set -g @prefix_highlight_bg 'colour208'
      set -g @prefix_highlight_show_copy_mode 'on'
      set -g @prefix_highlight_copy_mode_attr 'fg=colour232,bg=colour208,bold'
      set -g @prefix_highlight_prefix_prompt 'Wait'
      set -g @prefix_highlight_copy_prompt 'Copy'
    '';
  };
}
