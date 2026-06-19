{ ... }:
{
  services = {
    # Tailscale daemon is intentionally NOT managed by nix-darwin.
    #
    # The macOS Tailscale app (system extension) owns /var/run/tailscale/
    # tailscaled.sock. Running a second tailscaled via launchd races for
    # that socket, loses, and can corrupt scutil DNS state on its way out.
    #
    # Instead: install only the CLI in environment.systemPackages
    # (hosts/darwin/configuration.nix) so `tailscale` works in the terminal
    # while the app handles the tunnel, tray icon, and DNS injection.
    #
    # tailscale = { enable = true; package = pkgs.tailscale; };

    # OmniWM is used instead of AeroSpace + AeroHUD.
    # See https://github.com/BarutSRB/OmniWM
    # Installed via homebrew cask: packages/darwin/homebrew.nix

    aerohud = {
      enable = false;
    };

    aerospace = {
      enable = false;
      settings = {
        # Config version 2 — required for persistent-workspaces and latest features.
        config-version = 2;

        # Sketchybar integration — notify on workspace change.
        # Sketchybar itself is started by nix-darwin's launchd, not AeroSpace.
        exec-on-workspace-change = [
          "/bin/bash"
          "-c"
          "sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
        ];

        # start-at-login is managed by nix-darwin's launchd integration,
        # not by AeroSpace itself. See services.aerospace.enable.

        # Normalizations (recommended defaults).
        enable-normalization-flatten-containers = true;
        enable-normalization-opposite-orientation-for-nested-containers = true;

        # Layout defaults.
        accordion-padding = 30;
        default-root-container-layout = "tiles";
        default-root-container-orientation = "auto";

        # Mouse follows monitor changes (i3 behavior).
        on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

        automatically-unhide-macos-hidden-apps = false;

        key-mapping.preset = "qwerty";

        # Keep all 10 workspaces alive so sketchybar always sees them.
        persistent-workspaces = [
          "1"
          "2"
          "3"
          "4"
          "5"
          "6"
          "7"
          "8"
          "9"
          "10"
        ];

        # ── Monitor assignment ──────────────────────────────────────────
        # 1–5  → laptop (built-in)    alt-1 … alt-5
        # 6–10 → external monitor     alt-6 … alt-0
        workspace-to-monitor-force-assignment = {
          "1" = "main";
          "2" = "main";
          "3" = "main";
          "4" = "main";
          "5" = "main";
          "6" = "secondary";
          "7" = "secondary";
          "8" = "secondary";
          "9" = "secondary";
          "10" = "secondary";
        };

        # ── Gaps ────────────────────────────────────────────────────────
        gaps = {
          inner.horizontal = 10;
          inner.vertical = 10;
          outer.left = 10;
          outer.bottom = 10;
          outer.top = 52;
          outer.right = 10;
        };

        # ── Keybindings ─────────────────────────────────────────────────
        mode = {
          main.binding = {
            # Terminal
            alt-enter = "exec-and-forget /Users/mathew/.nix-profile/bin/kitty --directory ~";

            # Layout
            alt-slash = "layout tiles horizontal vertical";
            alt-comma = "layout accordion horizontal vertical";
            alt-shift-f = "fullscreen";
            alt-shift-space = "layout floating tiling";

            # Focus (vim)
            alt-h = "focus left";
            alt-j = "focus down";
            alt-k = "focus up";
            alt-l = "focus right";

            # Move windows (vim)
            alt-shift-h = "move left";
            alt-shift-j = "move down";
            alt-shift-k = "move up";
            alt-shift-l = "move right";

            # Resize
            alt-minus = "resize smart -50";
            alt-equal = "resize smart +50";

            # Workspaces — laptop (1–5)
            alt-1 = "workspace 1";
            alt-2 = "workspace 2";
            alt-3 = "workspace 3";
            alt-4 = "workspace 4";
            alt-5 = "workspace 5";

            # Workspaces — external monitor (6–10)
            alt-6 = "workspace 6";
            alt-7 = "workspace 7";
            alt-8 = "workspace 8";
            alt-9 = "workspace 9";
            alt-0 = "workspace 10";

            # Move window to workspace (follows focus)
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

            # Quick switch
            alt-tab = "workspace-back-and-forth";
            alt-shift-tab = "move-workspace-to-monitor --wrap-around next";

            # Enter service mode
            alt-shift-semicolon = "mode service";
          };

          service.binding = {
            esc = [
              "reload-config"
              "mode main"
            ];
            r = [
              "flatten-workspace-tree"
              "mode main"
            ];
            f = [
              "layout floating tiling"
              "mode main"
            ];
            backspace = [
              "close-all-windows-but-current"
              "mode main"
            ];

            # Join (merge containers)
            alt-shift-h = [
              "join-with left"
              "mode main"
            ];
            alt-shift-j = [
              "join-with down"
              "mode main"
            ];
            alt-shift-k = [
              "join-with up"
              "mode main"
            ];
            alt-shift-l = [
              "join-with right"
              "mode main"
            ];
          };
        };
      };
    };
  };
}
