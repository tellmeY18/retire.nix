# hosts/darwin/defaults.nix
# macOS system defaults managed by nix-darwin.
#
# Every setting here overrides the equivalent `defaults write` command.
# Values probed from the live system on 2026-06-30.
# Changes take effect on next login / reboot after `nh darwin switch`.
#
# Run `defaults read <domain>` to audit what's currently set on the
# system. Use `CustomUserPreferences` for any macOS pref that doesn't
# have a dedicated nix-darwin option yet.
{ ... }:
{
  system = {
    # ── Keyboard hardware remapping (hidutil) ────────────────────
    # No custom HID key mappings are currently active on this system.
    # To remap Caps Lock → Escape/Control or swap modifiers, add entries here:
    #   system.keyboard = {
    #     enableKeyMapping  = true;
    #     remapCapsLockToControl  = true;
    #     # or userKeyMapping = [
    #     #   { HIDKeyboardModifierMappingSrc = 0x700000039;  # Caps Lock
    #     #     HIDKeyboardModifierMappingDst = 0x700000029;  # Control
    #     #   }
    #     # ];
    #   };

    defaults = {
      # ── Login Window ──────────────────────────────────────────────
      loginwindow = {
        LoginwindowText = "Declare Nix ! Not War";
      };

      # ── NSGlobalDomain (.GlobalPreferences) ───────────────────────
      NSGlobalDomain = {
        # Keep the menu bar always visible — no auto-hide.
        _HIHideMenuBar = false;

        # Dark mode.
        AppleInterfaceStyle = "Dark";

        # Disable two-finger swipe for back/forward in browsers
        # (avoids accidental navigation when scrolling).
        AppleEnableSwipeNavigateWithScrolls = false;

        # Enable full keyboard access (Tab through all controls).
        AppleKeyboardUIMode = 2;

        # Key repeat rate (1=fastest, 120=slowest; default 6).
        # Currently unset on this system (macOS default 6).
        KeyRepeat = 6;

        # Initial key repeat delay (15=shortest, 120=longest; default 35).
        # Currently unset on this system (macOS default 35).
        InitialKeyRepeat = 35;

        # Disable press-and-hold accent menu so key repeat works for vim
        # hjkl navigation. false = repeat on held key, true = accent popup.
        ApplePressAndHoldEnabled = false;

        # Auto-capitalize sentences.
        NSAutomaticCapitalizationEnabled = true;

        # Smart period (double-space → .).
        NSAutomaticPeriodSubstitutionEnabled = true;

        # Auto-correct spelling.
        NSAutomaticSpellingCorrectionEnabled = true;

        # Spring-loaded (hover-to-open) directories.
        "com.apple.springing.enabled" = true;
        "com.apple.springing.delay" = 0.5;

        # Trackpad tracking speed (0–3, default 1).
        "com.apple.trackpad.scaling" = 3.0;

        # Force Click — single-finger pressure click for previews,
        # Look Up, and variable-speed fast-forward.
        "com.apple.trackpad.forceClick" = true;

        # Mouse tracking speed (0–3, default 1).
        # Note: this is also available under system.defaults.".GlobalPreferences".
        # "com.apple.mouse.scaling" = 3.0;

        # Natural scrolling direction.
        "com.apple.swipescrolldirection" = true;

        # Beep/alert volume feedback when changing system volume.
        "com.apple.sound.beep.feedback" = 1;
      };

      # ── Dock ──────────────────────────────────────────────────────
      dock = {
        # Auto-hide the Dock (it pops up on mouse hover).
        autohide = true;

        # Icon size in points.
        tilesize = 64;

        # Don't auto-rearrange Spaces by recent use.
        mru-spaces = false;

        # Show recent apps in the Dock.
        show-recents = true;

        # Bottom-right hot corner → Mission Control.
        wvous-br-corner = 2;

        # Enable trackpad gestures for Mission Control.
        showMissionControlGestureEnabled = true;
      };

      # ── Finder ────────────────────────────────────────────────────
      finder = {
        # Column view as default.
        FXPreferredViewStyle = "clmv";

        # Show external hard drives on Desktop.
        ShowExternalHardDrivesOnDesktop = true;

        # Hide internal hard drives on Desktop.
        ShowHardDrivesOnDesktop = false;

        # Show removable media on Desktop.
        ShowRemovableMediaOnDesktop = true;
      };

      # ── Screenshots ───────────────────────────────────────────────
      screencapture = {
        # Save to a dedicated folder instead of cluttering the Desktop.
        location = "~/Pictures/ScreenGrab";
        # Copy to clipboard instead of saving a file by default.
        target = "clipboard";
      };

      # ── Menu-bar clock ────────────────────────────────────────────
      menuExtraClock = {
        # Flash the colon separators on each tick.
        FlashDateSeparators = true;

        # Always show full date (0=when-space-allows, 1=always, 2=never).
        ShowDate = 1;

        # Show day of week (e.g. "Mon").
        ShowDayOfWeek = true;

        # Show seconds.
        ShowSeconds = true;

        # Digital clock (not analog).
        IsAnalog = false;

        # Show AM/PM label.
        ShowAMPM = true;
      };

      # ── Trackpad ──────────────────────────────────────────────────
      trackpad = {
        # Tap to click.
        Clicking = true;

        # Secondary click (two-finger tap).
        TrackpadRightClick = true;

        # Three-finger drag — disabled; use force-click for selections
        # and drag from trackpad bottom.
        TrackpadThreeFingerDrag = false;

        # Tap to drag.
        Dragging = false;

        # Haptic feedback (strong click).
        ActuateDetents = true;

        # Drag lock (disable after drag).
        DragLock = false;

        # Force click not suppressed.
        ForceSuppressed = false;

        # Click threshold: 0=light, 1=medium, 2=firm.
        FirstClickThreshold = 0;
        SecondClickThreshold = 0;

        # Three-finger tap gesture: 0=disable, 2=Look up.
        TrackpadThreeFingerTapGesture = 0;

        # Corner secondary click: 0=disable, 1=bottom-left, 2=bottom-right.
        TrackpadCornerSecondaryClick = 0;

        # Four-finger horizontal swipe: 0=disable, 2=full-screen apps.
        TrackpadFourFingerHorizSwipeGesture = 2;

        # Four-finger pinch: 0=disable, 2=Desktop/Launchpad.
        TrackpadFourFingerPinchGesture = 2;

        # Four-finger vertical swipe: 0=disable, 2=Mission Control/Exposé.
        TrackpadFourFingerVertSwipeGesture = 2;

        # Momentum/inertia scrolling.
        TrackpadMomentumScroll = true;

        # Two-finger pinch to zoom.
        TrackpadPinch = true;

        # Two-finger rotation gesture.
        TrackpadRotate = true;

        # Three-finger horizontal swipe: 0=disable, 1=pages, 2=full-screen.
        TrackpadThreeFingerHorizSwipeGesture = 1;

        # Three-finger vertical swipe: 0=disable, 2=Mission Control/Exposé.
        TrackpadThreeFingerVertSwipeGesture = 2;

        # Smart zoom — double-tap with two fingers.
        TrackpadTwoFingerDoubleTapGesture = true;

        # Two-finger swipe from right edge: 0=disable, 3=Notification Center.
        TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
      };

      # ── Window Manager (tiling / Stage Manager) ───────────────────
      WindowManager = {
        # Stage Manager — disabled (back to classic Spaces).
        GloballyEnabled = false;

        # Auto-hide Stage Manager strip.
        AutoHide = false;

        # App grouping: false="One at a time", true="All at once".
        AppWindowGroupingBehavior = true;

        # No window margins when tiling.
        EnableTiledWindowMargins = false;

        # Hide desktop icons in Stage Manager.
        HideDesktop = true;

        # Hide widgets on desktop.
        StandardHideWidgets = false;

        # Hide widgets in Stage Manager.
        StageManagerHideWidgets = false;
      };

      # ── Activity Monitor ──────────────────────────────────────────
      ActivityMonitor = {
        # Show category: 100=All Processes.
        ShowCategory = 100;

        # Dock icon: 5=CPU Usage.
        IconType = 5;

        # Don't open main window on launch.
        OpenMainWindow = false;
      };

      # ── Spaces ────────────────────────────────────────────────────
      spaces = {
        # Separate spaces per display (default, not one spanning all).
        spans-displays = false;
      };

      # ── Hitoolbox (keyboard) ──────────────────────────────────────
      hitoolbox = {
        # Fn key action: "Start Dictation".
        AppleFnUsageType = "Start Dictation";
      };

      # ── Apple Symbolic HotKeys & Services shortcuts ──────────────
      # Captured from the live system on 2026-06-30.
      # These are macOS built-in shortcuts that we freeze declaratively so
      # they survive nix-darwin switches and don't drift.
      #
      # To update: `plutil -convert json -o - \
      #   ~/Library/Preferences/com.apple.symbolichotkeys.plist` and copy
      #   the AppleSymbolicHotKeys dict here.
      #
      # Key equivalent syntax for ServicesMenu:
      #   @ = Cmd,  ~ = Opt,  ^ = Ctrl,  $ = Shift
      CustomUserPreferences = {
        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            # Dictation — Fn key (default: Fn-Fn)
            "52" = {
              enabled = true;
              value = {
                type = "standard";
                parameters = [
                  100
                  2
                  1572864
                ];
              };
            };

            # Mission Control: Move left a space (default: Ctrl+←)
            "79" = {
              enabled = true;
              value = {
                type = "standard";
                parameters = [
                  65535
                  123
                  8650752
                ];
              };
            };

            # Mission Control: Move right a space (default: Ctrl+→)
            "80" = {
              enabled = true;
              value = {
                type = "standard";
                parameters = [
                  65535
                  123
                  8781824
                ];
              };
            };

            # Keyboard: Move focus to next window (default: Ctrl+F4)
            "81" = {
              enabled = true;
              value = {
                type = "standard";
                parameters = [
                  65535
                  124
                  8650752
                ];
              };
            };

            # Keyboard: Move focus to previous window (default: Ctrl+Shift+F4)
            "82" = {
              enabled = true;
              value = {
                type = "standard";
                parameters = [
                  65535
                  124
                  8781824
                ];
              };
            };

            # Input: Select previous input source (default: Ctrl+Space)
            "118" = {
              enabled = true;
              value = {
                type = "standard";
                parameters = [
                  65535
                  18
                  262144
                ];
              };
            };

            # Input: Select next input source (default: Ctrl+Opt+Space)
            "119" = {
              enabled = true;
              value = {
                type = "standard";
                parameters = [
                  65535
                  19
                  262144
                ];
              };
            };

            # Accessibility: Zoom In toggle (default: Opt+Cmd+8)
            "120" = {
              enabled = true;
              value = {
                type = "standard";
                parameters = [
                  65535
                  20
                  262144
                ];
              };
            };

            # Screenshots: Show floating thumbnail (default: Shift+Cmd+5)
            "121" = {
              enabled = true;
              value = {
                type = "standard";
                parameters = [
                  65535
                  21
                  262144
                ];
              };
            };

            # Spotlight: Show Finder search (default: Opt+Cmd+Space)
            "122" = {
              enabled = true;
              value = {
                type = "standard";
                parameters = [
                  65535
                  23
                  262144
                ];
              };
            };

            # Spotlight: Show window (default: Cmd+Space)
            "123" = {
              enabled = true;
              value = {
                type = "standard";
                parameters = [
                  65535
                  22
                  262144
                ];
              };
            };

            # Services: Show in Finder (default: Shift+Cmd+C)
            "124" = {
              enabled = true;
              value = {
                type = "standard";
                parameters = [
                  65535
                  26
                  262144
                ];
              };
            };

            # Keyboard: Change input method (default: unbound placeholder)
            "160" = {
              enabled = true;
              value = {
                type = "standard";
                parameters = [
                  65535
                  65535
                  0
                ];
              };
            };

            # Accessibility: App Exposé (disabled)
            "164" = {
              enabled = false;
              value = {
                type = "standard";
                parameters = [
                  65535
                  65535
                  0
                ];
              };
            };
          };
        };

        # Keyboard shortcut for the Launch Kitty Automator service.
        # Deployed by home-manager to ~/Library/Services/Launch Kitty.workflow/
        "com.apple.ServicesMenu" = {
          KeyboardShortcuts = {
            "Launch Kitty" = "~$k"; # Opt+Shift+K
          };
        };
      };

      # ── iCal (Calendar) ───────────────────────────────────────────
      iCal = {
        # Week starts on: "System Setting" (= 0).
        "first day of week" = "System Setting";

        # Show calendar sidebar.
        CalendarSidebarShown = true;
      };

      # ── .GlobalPreferences (extra) ────────────────────────────────
      # These live under the .GlobalPreferences domain and aren't
      # covered by NSGlobalDomain above.
      ".GlobalPreferences" = {
        # Mouse tracking speed (0–3, default 1).
        "com.apple.mouse.scaling" = 3.0;

        # System alert sound.
        "com.apple.sound.beep.sound" = "/System/Library/Sounds/Tink.aiff";
      };
    };
  };
}
