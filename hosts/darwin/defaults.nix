# hosts/darwin/defaults.nix
# macOS system defaults managed by nix-darwin.
#
# Every setting here overrides the equivalent `defaults write` command.
# Changes take effect on next login / reboot after `nh darwin switch`.
#
# Run `defaults read <domain>` to audit what's currently set on the
# system. Use `CustomUserPreferences` for any macOS pref that doesn't
# have a dedicated nix-darwin option yet.
{ ... }:
{
  system = {
    defaults = {
      # ── Login Window ──────────────────────────────────────────────
      loginwindow = {
        LoginwindowText = "Declare Nix ! Not War";
      };

      # ── Global Preferences (NSGlobalDomain / .GlobalPreferences) ──
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

        # Spring-loaded (hover-to-open) directories
        "com.apple.springing.enabled" = true;
        "com.apple.springing.delay" = 0.5;

        # Trackpad tracking speed (0–3, default 1).
        "com.apple.trackpad.scaling" = 3;

        # Force Click — single-finger pressure click for previews,
        # Look Up, and variable-speed fast-forward.
        "com.apple.trackpad.forceClick" = true;

        # Mouse tracking speed (0–3, default 1).
        "com.apple.mouse.scaling" = 3;
      };

      # ── Dock ──────────────────────────────────────────────────────
      dock = {
        # Auto-hide the Dock (it pops up on mouse hover).
        autohide = true;

        # Icon size in points.
        tilesize = 64;

        # Don't auto-rearrange Spaces by recent use.
        mru-spaces = false;

        # Bottom-right hot corner → Mission Control.
        wvous-br-corner = 2;

        # Enable 3-finger vertical swipe for Mission Control / Exposé.
        showMissionControlGestureEnabled = true;
      };

      # ── Finder ────────────────────────────────────────────────────
      finder = {
        # Column view as default.
        FXPreferredViewStyle = "clmv";
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
        FlashDateSeparators = true;
        ShowDate = 1; # 0=when-space-allows, 1=always, 2=never
        ShowDayOfWeek = true;
        ShowSeconds = true;
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
      };

      # ── Window Manager (tiling / Stage Manager) ───────────────────
      WindowManager = {
        # Stage Manager — disabled (back to classic Spaces).
        GloballyEnabled = false;

        # No window margins when tiling (cleaner full-screen feel).
        EnableTiledWindowMargins = false;

        # Hide desktop icons (keeps the desktop empty/clutter-free).
        HideDesktop = true;
      };
    };
  };
}
