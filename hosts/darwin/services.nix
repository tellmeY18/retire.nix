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

        # Workspaces 1–5 on laptop, 6–9 on external monitor.
        # Hotkeys follow OmniWM defaults: Cmd+1-9 for workspace switch,
        # Shift+Cmd+1-9 for move-to-workspace, Cmd+HJKL for vim focus.
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
