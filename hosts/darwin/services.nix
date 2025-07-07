{ pkgs, ... }: {
  services = {
    aerospace = {
      enable = true;
      settings = {
        after-startup-command = [ "exec-and-forget sketchybar" ];

        # Notify Sketchybar about workspace change
        exec-on-workspace-change = [
          "/bin/bash"
          "-c"
          "sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
          "exec-and-forget borders active_color=0xffe1e3e4 inactive_color=0xff494d64 width=5.0"
        ];

        # Start AeroSpace at login
        start-at-login = false;

        # Normalizations. See: https://nikitabobko.github.io/AeroSpace/guide#normalization
        enable-normalization-flatten-containers = true;
        enable-normalization-opposite-orientation-for-nested-containers = true;

        # See: https://nikitabobko.github.io/AeroSpace/guide#layouts
        # The 'accordion-padding' specifies the size of accordion padding
        # You can set 0 to disable the padding feature
        accordion-padding = 300;

        # Possible values: tiles|accordion
        default-root-container-layout = "tiles";

        # Possible values: horizontal|vertical|auto
        # 'auto' means: wide monitor (anything wider than high) gets horizontal orientation,
        #               tall monitor (anything higher than wide) gets vertical orientation
        default-root-container-orientation = "auto";

        # Mouse follows focus when focused monitor changes
        # Drop it from your config, if you don't like this behavior
        # See https://nikitabobko.github.io/AeroSpace/guide#on-focus-changed-callbacks
        # See https://nikitabobko.github.io/AeroSpace/commands#move-mouse
        # Fallback value (if you omit the key): on-focused-monitor-changed = []
        on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

        # You can effectively turn off macOS "Hide application" (cmd-h) feature by toggling this flag
        # Useful if you don't use this macOS feature, but accidentally hit cmd-h or cmd-alt-h key
        # Also see: https://nikitabobko.github.io/AeroSpace/goodness#disable-hide-app
        automatically-unhide-macos-hidden-apps = false;

        # Key mapping
        key-mapping = {
          preset = "qwerty";
        };

        # Gaps between windows (inner-*) and between monitor edges (outer-*).
        gaps = {
          inner = {
            horizontal = 20;
            vertical = 20;
          };
          outer = {
            left = 20;
            bottom = 20;
            top = 10;
            right = 20;
          };
        };

        # 'main' binding mode declaration
        mode = {
          main = {
            binding = {
              alt-enter = "exec-and-forget kitty --directory ~";
              alt-shift-f = "fullscreen";
              alt-shift-space = "layout floating tiling";
              alt-shift-left = "join-with left";
              alt-shift-down = "join-with down";
              alt-shift-up = "join-with up";
              alt-shift-right = "join-with right";
              alt-slash = "layout tiles horizontal vertical";
              alt-comma = "layout accordion horizontal vertical";
              alt-h = "focus left";
              alt-j = "focus down";
              alt-k = "focus up";
              alt-l = "focus right";
              alt-shift-h = "move left";
              alt-shift-j = "move down";
              alt-shift-k = "move up";
              alt-shift-l = "move right";
              alt-shift-minus = "resize smart -50";
              alt-shift-equal = "resize smart +50";
              alt-1 = "workspace 1";
              alt-2 = "workspace 2";
              alt-3 = "workspace 3";
              alt-4 = "workspace 4";
              alt-5 = "workspace 5";
              alt-6 = "workspace 6";
              alt-7 = "workspace 7";
              alt-8 = "workspace 8";
              alt-9 = "workspace 9";
              alt-0 = "workspace 10";
              alt-shift-1 = "move-node-to-workspace 1 --focus-follows-window";
              alt-shift-2 = "move-node-to-workspace 2 --focus-follows-window";
              alt-shift-3 = "move-node-to-workspace 3 --focus-follows-window";
              alt-shift-4 = "move-node-to-workspace 4 --focus-follows-window";
              alt-shift-5 = "move-node-to-workspace 5 --focus-follows-window";
              alt-shift-6 = "move-node-to-workspace 6 --focus-follows-window";
              alt-shift-7 = "move-node-to-workspace 7 --focus-follows-window";
              alt-shift-8 = "move-node-to-workspace 8 --focus-follows-window";
              alt-shift-9 = "move-node-to-workspace 9 --focus-follows-window";
              alt-shift-0 = "move-node-to-workspace 10 --focus-follows-window";
              alt-tab = "workspace-back-and-forth";
              alt-shift-tab = "move-workspace-to-monitor --wrap-around next";
              alt-shift-semicolon = "mode service";
              alt-shift-enter = "mode apps";
              alt-t = "exec-and-forget open -a /Applications/Telegram.app";
              alt-a = "exec-and-forget open -a /Applications/Arc.app";
              alt-o = "exec-and-forget open -a /Applications/Obsidian.app";
              alt-g = "exec-and-forget open -a /Applications/Kitty.app";
              alt-s = "exec-and-forget open -a /Applications/Safari.app";
              alt-q = "exec-and-forget open -a /System/Applications/QuickTime Player.app";
              alt-w = "exec-and-forget open -a /Applications/WezTerm.app";
            };
          };
          service = {
            binding = {
              esc = [ "reload-config" "mode main" ];
              r = [ "flatten-workspace-tree" "mode main" ]; # reset layout
              f = [ "layout floating tiling" "mode main" ]; # Toggle between floating and tiling layout
              backspace = [ "close-all-windows-but-current" "mode main" ];
            };
          };
          apps = {
            binding = {
              alt-w = [ "exec-and-forget open -a /Applications/WezTerm.app" "mode main" ];
              esc = "mode main";
            };
          };
        };

        # workspace-to-monitor-force-assignment (commented out)
        # workspace-to-monitor-force-assignment = {
        #   "1" = "^dell$";
        #   "2" = "^dell$";
        #   "3" = "^dell$";
        #   "4" = "^dell$";
        #   "5" = "main";
        #   "6" = "^elgato$";
        # };
      };
    };
  };
}
