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

    # ── OmniWM ─────────────────────────────────────────────────────────
    # Niri + Dwindle tiling window manager.
    # Installed via homebrew cask: packages/darwin/homebrew.nix
    #
    # Config lifecycle (managed by the nix-darwin-aerohud module):
    #   - darwin-rebuild switch writes Nix-generated settings.toml
    #     to ~/.config/omniwm/settings.toml (activation script).
    #   - Launchd agent re-applies Nix config 4s after every login
    #     (after OmniWM finishes its startup defaults write).
    #   - IPC must be enabled once per session via the menu bar.
    omniwm = {
      enable = false;

      settings = {
        # ── Empty placeholder lists ────────────────────────────────
        monitorBarOverrides = [ ];
        monitorDwindleOverrides = [ ];
        monitorNiriOverrides = [ ];
        monitorOrientationOverrides = [ ];

        # ── General ────────────────────────────────────────────────
        general = {
          ipcEnabled = true;
          updateChecksEnabled = false;
          defaultLayoutType = "niri";
          hotkeysEnabled = true;
          animationsEnabled = true;
          preventSleepEnabled = false;
        };

        # ── Focus ──────────────────────────────────────────────────
        focus = {
          followsMouse = false;
          followsWindowToMonitor = false;
          moveMouseToFocusedWindow = false;
          crossesMonitorAtEdge = true;
        };

        # ── Mouse warp ─────────────────────────────────────────────
        mouseWarp = {
          axis = "horizontal";
          margin = 1;
          monitorOrder = [ ];
        };

        # ── Appearance ─────────────────────────────────────────────
        appearance = {
          mode = "dark";
        };

        # ── Gaps ───────────────────────────────────────────────────
        gaps = {
          size = 8.0;
          outer = {
            left = 10.0;
            right = 10.0;
            top = 52.0;
            bottom = 10.0;
          };
        };

        # ── Borders ────────────────────────────────────────────────
        borders = {
          enabled = true;
          width = 4.0;
          color = {
            red = 0.5;
            green = 0.7;
            blue = 1.0;
            alpha = 1.0;
          };
        };

        # ── Niri layout ────────────────────────────────────────────
        niri = {
          maxVisibleColumns = 3;
          centerFocusedColumn = "never";
          alwaysCenterSingleColumn = true;
          singleWindowAspectRatio = "disabled";
          infiniteLoop = false;
          columnWidthPresets = [
            0.3333333333333333
            0.5
            0.66
          ];
          maxWindowsPerColumn = 0;
        };

        # ── Dwindle layout ─────────────────────────────────────────
        dwindle = {
          smartSplit = true;
          defaultSplitRatio = 0.5;
          useGlobalGaps = true;
          singleWindowAspectRatio = "fill";
          splitWidthMultiplier = 1.0;
          moveToRootStable = false;
        };

        # ── Workspace bar is managed by hosts/darwin/bar.nix ────────

        # ── Gestures ──────────────────────────────────────────────
        # Trackpad gestures disabled — they conflict with browser navigation
        # (3-finger back/forward). Re-enable only if OmniWM workspace swiping
        # is preferred over browser gesture pass-through.
        gestures = {
          scrollEnabled = false;
          fingerCount = 3;
          invertDirection = false;
          scrollSensitivity = 1.0;
          scrollModifierKey = "optionShift";
          mouseResizeModifierKey = "option";
          trackpadScrollStyle = "snap";
        };

        # ── Status bar ─────────────────────────────────────────────
        statusBar = {
          showWorkspaceName = true;
          showAppNames = false;
          useWorkspaceId = false;
        };

        # ── Clipboard ──────────────────────────────────────────────
        clipboard = {
          historyEnabled = true;
          maxItems = 50;
          maxItemBytes = 8388608;
          maxTotalBytes = 67108864;
        };

        # ── Quake terminal ─────────────────────────────────────────
        quakeTerminal = {
          enabled = true;
          position = "center";
          widthPercent = 0.7;
          heightPercent = 0.5;
          autoHide = true;
          animationDuration = 0.2;
          opacity = 1.0;
          monitorMode = "focusedWindow";
          command = "/Users/mathew/.nix-profile/bin/kitty";
        };

        # ── Hotkeys (migrated from AeroSpace) ──────────────────────
        hotkeys = [
          # Focus (vim)
          {
            id = "focus.left";
            binding = "Option+H";
          }
          {
            id = "focus.down";
            binding = "Option+J";
          }
          {
            id = "focus.up";
            binding = "Option+K";
          }
          {
            id = "focus.right";
            binding = "Option+L";
          }

          # Move windows (vim)
          {
            id = "move.left";
            binding = "Option+Shift+H";
          }
          {
            id = "move.down";
            binding = "Option+Shift+J";
          }
          {
            id = "move.up";
            binding = "Option+Shift+K";
          }
          {
            id = "move.right";
            binding = "Option+Shift+L";
          }

          # Cycle column width (was Opt+-/= in AeroSpace)
          {
            id = "cycleColumnWidthBackward";
            binding = "Option+-";
          }
          {
            id = "cycleColumnWidthForward";
            binding = "Option+=";
          }

          # Workspaces 1–9
          {
            id = "switchWorkspace.0";
            binding = "Option+1";
          }
          {
            id = "switchWorkspace.1";
            binding = "Option+2";
          }
          {
            id = "switchWorkspace.2";
            binding = "Option+3";
          }
          {
            id = "switchWorkspace.3";
            binding = "Option+4";
          }
          {
            id = "switchWorkspace.4";
            binding = "Option+5";
          }
          {
            id = "switchWorkspace.5";
            binding = "Option+6";
          }
          {
            id = "switchWorkspace.6";
            binding = "Option+7";
          }
          {
            id = "switchWorkspace.7";
            binding = "Option+8";
          }
          {
            id = "switchWorkspace.8";
            binding = "Option+9";
          }

          # Move window to workspace
          {
            id = "moveToWorkspace.0";
            binding = "Option+Shift+1";
          }
          {
            id = "moveToWorkspace.1";
            binding = "Option+Shift+2";
          }
          {
            id = "moveToWorkspace.2";
            binding = "Option+Shift+3";
          }
          {
            id = "moveToWorkspace.3";
            binding = "Option+Shift+4";
          }
          {
            id = "moveToWorkspace.4";
            binding = "Option+Shift+5";
          }
          {
            id = "moveToWorkspace.5";
            binding = "Option+Shift+6";
          }
          {
            id = "moveToWorkspace.6";
            binding = "Option+Shift+7";
          }
          {
            id = "moveToWorkspace.7";
            binding = "Option+Shift+8";
          }
          {
            id = "moveToWorkspace.8";
            binding = "Option+Shift+9";
          }

          # Back-and-forth
          {
            id = "workspaceBackAndForth";
            binding = "Option+Tab";
          }

          # Fullscreen
          {
            id = "toggleFullscreen";
            binding = "Option+Shift+F";
          }

          # Toggle floating
          {
            id = "toggleFocusedWindowFloating";
            binding = "Option+Shift+Space";
          }

          # Toggle layout (Niri ↔ Dwindle)
          {
            id = "toggleWorkspaceLayout";
            binding = "Option+Shift+L";
          }

          # Overview (exposé)
          {
            id = "toggleOverview";
            binding = "Option+Shift+O";
          }

          # Launch Kitty (regular tiled window, not quake dropdown)
          {
            id = "exec.0";
            binding = "Option+Grave";
            command = "/Users/mathew/.nix-profile/bin/kitty";
          }

          # Quake terminal (Kitty dropdown via OmniWM)
          {
            id = "toggleQuakeTerminal";
            binding = "Option+Return";
          }

          # Focus next monitor
          {
            id = "focusMonitorNext";
            binding = "Option+Shift+Tab";
          }

          # ── Unassigned defaults (prevent OmniWM from re-adding) ──
          {
            id = "switchWorkspace.next";
            binding = "Unassigned";
          }
          {
            id = "switchWorkspace.previous";
            binding = "Unassigned";
          }
          {
            id = "moveColumnToWorkspace.0";
            binding = "Unassigned";
          }
          {
            id = "moveColumnToWorkspace.1";
            binding = "Unassigned";
          }
          {
            id = "moveColumnToWorkspace.2";
            binding = "Unassigned";
          }
          {
            id = "moveColumnToWorkspace.3";
            binding = "Unassigned";
          }
          {
            id = "moveColumnToWorkspace.4";
            binding = "Unassigned";
          }
          {
            id = "moveColumnToWorkspace.5";
            binding = "Unassigned";
          }
          {
            id = "moveColumnToWorkspace.6";
            binding = "Unassigned";
          }
          {
            id = "moveColumnToWorkspace.7";
            binding = "Unassigned";
          }
          {
            id = "moveColumnToWorkspace.8";
            binding = "Unassigned";
          }
          {
            id = "focusMonitorPrevious";
            binding = "Unassigned";
          }
          {
            id = "focusMonitorLast";
            binding = "Unassigned";
          }
          {
            id = "toggleNativeFullscreen";
            binding = "Unassigned";
          }
          {
            id = "moveToRoot";
            binding = "Unassigned";
          }
          {
            id = "toggleSplit";
            binding = "Unassigned";
          }
          {
            id = "swapSplit";
            binding = "Unassigned";
          }
          {
            id = "preselect.left";
            binding = "Unassigned";
          }
          {
            id = "preselect.right";
            binding = "Unassigned";
          }
          {
            id = "preselect.up";
            binding = "Unassigned";
          }
          {
            id = "preselect.down";
            binding = "Unassigned";
          }
          {
            id = "preselectClear";
            binding = "Unassigned";
          }
          {
            id = "openCommandPalette";
            binding = "Unassigned";
          }
          {
            id = "rescueOffscreenWindows";
            binding = "Unassigned";
          }
          {
            id = "assignFocusedWindowToScratchpad";
            binding = "Unassigned";
          }
          {
            id = "toggleScratchpadWindow";
            binding = "Unassigned";
          }
          {
            id = "toggleWorkspaceBarVisibility";
            binding = "Unassigned";
          }
          {
            id = "toggleHiddenBar";
            binding = "Unassigned";
          }
        ];

        # Workspaces 1–5 on laptop (main), 6–9 on external monitor (secondary).
        # displayName is optional — it decorates the workspace label in the bar.
        workspaces = [
          {
            name = "1";
            layoutType = "niri";
            monitorAssignment = {
              type = "main";
            };
          }
          {
            name = "2";
            layoutType = "niri";
            monitorAssignment = {
              type = "main";
            };
          }
          {
            name = "3";
            layoutType = "niri";
            monitorAssignment = {
              type = "main";
            };
          }
          {
            name = "4";
            layoutType = "niri";
            monitorAssignment = {
              type = "main";
            };
          }
          {
            name = "5";
            layoutType = "niri";
            monitorAssignment = {
              type = "main";
            };
          }
          {
            name = "6";
            layoutType = "niri";
            monitorAssignment = {
              type = "secondary";
            };
          }
          {
            name = "7";
            layoutType = "niri";
            monitorAssignment = {
              type = "secondary";
            };
          }
          {
            name = "8";
            layoutType = "niri";
            monitorAssignment = {
              type = "secondary";
            };
          }
          {
            name = "9";
            layoutType = "niri";
            monitorAssignment = {
              type = "secondary";
            };
          }
        ];

        appRules = [
          {
            bundleId = "com.apple.finder";
            layout = "float";
          }
          {
            bundleId = "com.apple.systempreferences";
            layout = "float";
          }
          {
            bundleId = "com.spotify.client";
            minWidth = 800.0;
            minHeight = 600.0;
          }
          {
            bundleId = "com.hnc.Discord";
            minWidth = 800.0;
            minHeight = 500.0;
          }
          {
            bundleId = "com.google.Chrome";
            minWidth = 500.0;
            minHeight = 375.0;
          }
          {
            bundleId = "dev.zed.Zed";
            minWidth = 360.0;
            minHeight = 240.0;
          }
          # Ghostty — the quake terminal (Opt+Return). Min size for safe toggling.
          # Non-floating so OmniWM tiles it when not in quake mode.
          {
            bundleId = "com.mitchellh.ghostty";
            minWidth = 90.0;
            minHeight = 48.0;
          }
          {
            bundleId = "com.apple.Safari";
            minWidth = 574.0;
            minHeight = 220.0;
          }

          # Emacs — floating rectangle, borderless via emacs-macport
          # Title bar is hidden inside Emacs (mac-hide-title-bar t in ui.el);
          # OmniWM floats it at a fixed size so it behaves like a focused
          # writing/coding popout rather than a tiled pane.
          {
            bundleId = "org.gnu.Emacs";
            layout = "float";
            minWidth = 1400.0;
            minHeight = 900.0;
          }
        ];
      };
    };

    # AeroHUD — workspace overview / exposé overlay.
    # Launched via Opt+Space (the keybinding below).
    aerohud = {
      enable = false;
      # 5 columns to match the 10 persistent workspaces (2 rows x 5 cols)
      cols = 5;
      layout = [
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
      keybinding = "alt-space";
    };

    # ── AeroSpace ────────────────────────────────────────────────────
    # Tiling window manager. Replaces OmniWM when enabled.
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
