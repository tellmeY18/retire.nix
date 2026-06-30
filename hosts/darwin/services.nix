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
          command = "/Applications/Ghostty.app/Contents/MacOS/ghostty";
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

          # Quake terminal (Ghostty dropdown via OmniWM)
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

    # AeroHUD is not used with OmniWM (OmniWM has its own overview).
    aerohud = {
      enable = false;
    };
  };
}
