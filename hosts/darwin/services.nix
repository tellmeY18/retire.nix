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
    # Config is managed by the services.omniwm module from the nix-darwin fork.
    omniwm = {
      enable = true;

      settings = {
        general = {
          ipcEnabled = true;
          updateChecksEnabled = false;
          defaultLayoutType = "niri";
          hotkeysEnabled = true;
          animationsEnabled = true;
          spacesTrackingEnabled = true;
          # Use the key name OmniWM expects — otherwise the entire
          # [general] section falls into recovery mode and defaults
          # override everything including ipcEnabled.
          hyperTrigger = "none";
        };

        appearance = {
          mode = "dark";
        };

        gaps = {
          size = 8.0;
          outer = {
            left = 10.0;
            right = 10.0;
            top = 52.0;
            bottom = 10.0;
          };
        };

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

        niri = {
          maxVisibleColumns = 3;
          centerFocusedColumn = "never";
          alwaysCenterSingleColumn = true;
          singleWindowAspectRatio = "disabled";
          infiniteLoop = false;
        };

        dwindle = {
          smartSplit = true;
          defaultSplitRatio = 0.5;
          useGlobalGaps = true;
          singleWindowAspectRatio = "fill";
        };

        # Built-in OmniWM workspace bar replaces sketchybar.
        # Positions: overlappingMenuBar, underMenuBar, floating
        workspaceBar = {
          enabled = true;
          position = "overlappingMenuBar";
          height = 32.0;
          showLabels = true;
          deduplicateAppIcons = true;
          hideEmptyWorkspaces = true;
          notchAware = true;
        };

        gestures = {
          scrollEnabled = true;
          fingerCount = 3;
          invertDirection = false;
        };

        statusBar = {
          showWorkspaceName = true;
          useWorkspaceId = false;
        };

        clipboard = {
          historyEnabled = true;
          maxItems = 50;
        };

        quakeTerminal = {
          enabled = true;
          position = "center";
          widthPercent = 0.7;
          heightPercent = 0.5;
          autoHide = true;
        };

        # ── Hotkeys ────────────────────────────────────────────────
        # Migrated from AeroSpace muscle memory:
        #   Opt+HJKL → focus,  Opt+Shift+HJKL → move
        #   Opt+1-9 → workspace,  Opt+Shift+1-9 → move to workspace
        #   Opt+Tab → back-and-forth,  Opt+Shift+F → fullscreen
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

          # Cycle column width (AeroSpace resize)
          {
            id = "cycleColumnWidthBackward";
            binding = "Option+-";
          }
          {
            id = "cycleColumnWidthForward";
            binding = "Option+=";
          }

          # Workspaces 1–9 (AeroSpace: alt-1 through alt-9)
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

          # Move window to workspace (AeroSpace: alt-shift-1-9)
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

          # Quick switch (back-and-forth)
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

          # Toggle workspace layout (Niri ↔ Dwindle)
          {
            id = "toggleWorkspaceLayout";
            binding = "Option+Shift+L";
          }

          # Overview (workspace exposé)
          {
            id = "toggleOverview";
            binding = "Option+Shift+O";
          }

          # Quake terminal — keep default (Opt+`) but also add Opt+Return as alternative
          {
            id = "toggleQuakeTerminal";
            binding = "Option+Return";
          }

          # Focus next/prev monitor (AeroSpace: alt-shift-tab → move-workspace-to-monitor)
          {
            id = "focusMonitorNext";
            binding = "Option+Shift+Tab";
          }
        ];

        # Workspaces 1–5 on laptop, 6–9 on external monitor.
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
        ];
      };
    };

    # AeroHUD is not used with OmniWM (OmniWM has its own overview).
    aerohud = {
      enable = false;
    };
  };
}
