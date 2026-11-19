# home/desktop/mpv.nix — mpv, tuned for chopper's Intel iGPU and themed with
# the live ink/paper palette.
#
# Look: uosc replaces the stock OSC. Its colours and mpv's OSD/background
# colours are read from ~/.local/state/theme/{uosc.conf,mpv-theme.conf}, which
# `theme toggle` rewrites; new mpv windows pick the switch up.
# Quality: "saver" is the default (battery friendly); Ctrl+h applies "quality"
# (gpu-hq, interpolation, deband), Ctrl+l goes back to "saver".
{ config, lib, pkgs, ... }:

let
  state = "${config.home.homeDirectory}/.local/state/theme";
  audioExts = [ "mp3" "flac" "ogg" "opus" "m4a" "wav" "aac" "wma" ];
  mimeTypes = [
    "video/mp4"
    "video/x-matroska"
    "video/webm"
    "video/quicktime"
    "video/x-msvideo"
    "video/mpeg"
    "video/ogg"
    "video/x-flv"
    "video/mp2t"
    "audio/mpeg"
    "audio/flac"
    "audio/ogg"
    "audio/x-opus+ogg"
    "audio/mp4"
    "audio/x-wav"
    "audio/aac"
  ];
in
{
  home.packages = [ pkgs.yt-dlp ];

  programs.mpv = {
    enable = true;

    scripts = with pkgs.mpvScripts; [
      uosc # modern, themeable on-screen controller + menus
      thumbfast # timeline thumbnails for uosc
      mpris # MPRIS: playerctl, media keys, the desktop widgets
      autoload # queue the other files in the folder
      quality-menu # pick stream quality for YouTube and friends
      memo # watch history
      sponsorblock # skip sponsor segments on YouTube
      reload # reload stalled streams
    ];

    scriptOpts = {
      thumbfast = {
        max_height = 280;
        max_width = 480;
      };
      autoload = {
        videos = "yes";
        audio = "yes";
        images = "no";
        ignore_hidden = "yes";
      };
    };

    config = {
      # ── video ──────────────────────────────────────────────────────────
      vo = "gpu-next";
      gpu-context = "wayland";
      hwdec = "auto-safe";
      scale = "spline36";
      cscale = "spline36";
      dscale = "mitchell";
      video-sync = "audio";
      deband = false;
      interpolation = false;

      # ── window ─────────────────────────────────────────────────────────
      osc = false; # uosc draws the controls
      osd-bar = false;
      border = false;
      keep-open = true;
      autofit-larger = "90%x90%";
      cursor-autohide = 1000;
      snap-window = true;
      title = "\${?media-title:\${media-title}}\${!media-title:\${filename}}";
      osd-font = "sans-serif";
      osd-font-size = 28;

      # ── resume ─────────────────────────────────────────────────────────
      save-position-on-quit = true;
      write-filename-in-watch-later-config = true;

      # ── audio ──────────────────────────────────────────────────────────
      ao = "pipewire,pulse,alsa";
      volume = 100;
      volume-max = 150;
      audio-pitch-correction = true;
      audio-file-auto = "fuzzy";
      audio-display = "embedded-first";
      alang = [ "en" "eng" "ja" "jpn" ];

      # ── subtitles ──────────────────────────────────────────────────────
      slang = [ "en" "eng" ];
      sub-auto = "fuzzy";
      sub-file-paths = [ "subs" "Subs" "subtitles" ];
      sub-font = "sans-serif";
      sub-font-size = 40;
      sub-border-size = 2.2;
      sub-shadow-offset = 1;
      sub-use-margins = true;

      # ── cache ──────────────────────────────────────────────────────────
      cache = true;
      demuxer-max-bytes = "150MiB";
      demuxer-max-back-bytes = "75MiB";
      demuxer-readahead-secs = 20;

      # ── screenshots (next to the `shot` tool's) ────────────────────────
      screenshot-dir = "${config.xdg.userDirs.pictures}/Screenshots";
      screenshot-format = "png";
      screenshot-png-compression = 7;
      screenshot-template = "%F - %P";

      # ── streaming ──────────────────────────────────────────────────────
      ytdl = true;
      ytdl-format = "bestvideo[height<=?1080]+bestaudio/best";
    };

    profiles = {
      # Default for battery life; Ctrl+l re-applies it.
      saver = {
        profile-desc = "battery friendly";
        scale = "bilinear";
        cscale = "bilinear";
        dscale = "bilinear";
        deband = false;
        interpolation = false;
        video-sync = "audio";
      };
      quality = {
        profile-desc = "high quality (gpu-hq, interpolation, deband)";
        profile = "gpu-hq";
        scale = "ewa_lanczossharp";
        cscale = "ewa_lanczossharp";
        video-sync = "display-resample";
        interpolation = true;
        tscale = "oversample";
        deband = true;
      };
      "extension.gif" = {
        loop-file = "inf";
      };
      "protocol.http" = {
        profile-desc = "network streams";
        demuxer-max-bytes = "300MiB";
        force-window = "immediate";
      };
      "protocol.https" = {
        profile-desc = "network streams";
        demuxer-max-bytes = "300MiB";
        force-window = "immediate";
      };
    } // lib.genAttrs (map (e: "extension.${e}") audioExts) (_: {
      profile-desc = "audio files";
      force-window = "yes";
      autofit = "40%x40%";
      keep-open = false;
    });

    includes = [ "${state}/mpv-theme.conf" ];

    bindings = {
      # uosc
      MENU = "script-binding uosc/menu";
      MBTN_RIGHT = "script-binding uosc/menu";
      s = "script-binding uosc/subtitles";
      a = "script-binding uosc/audio";
      q = "script-binding uosc/stream-quality";
      p = "script-binding uosc/items";
      ">" = "script-binding uosc/next";
      "<" = "script-binding uosc/prev";

      # playback
      SPACE = "cycle pause; script-binding uosc/flash-pause-indicator";
      MBTN_LEFT_DBL = "cycle fullscreen";
      f = "cycle fullscreen";
      h = "seek -5; script-binding uosc/flash-timeline";
      l = "seek 5; script-binding uosc/flash-timeline";
      H = "seek -30; script-binding uosc/flash-timeline";
      L = "seek 30; script-binding uosc/flash-timeline";
      LEFT = "seek -5; script-binding uosc/flash-timeline";
      RIGHT = "seek 5; script-binding uosc/flash-timeline";
      "Shift+LEFT" = "seek -30; script-binding uosc/flash-timeline";
      "Shift+RIGHT" = "seek 30; script-binding uosc/flash-timeline";
      "," = "frame-back-step";
      "." = "frame-step";
      "[" = "multiply speed 0.9091";
      "]" = "multiply speed 1.1";
      BS = "set speed 1.0; show-text \"speed 1.0\"";
      "Ctrl+LEFT" = "add chapter -1";
      "Ctrl+RIGHT" = "add chapter 1";

      # volume
      WHEEL_UP = "add volume 5; script-binding uosc/flash-volume";
      WHEEL_DOWN = "add volume -5; script-binding uosc/flash-volume";
      UP = "add volume 5; script-binding uosc/flash-volume";
      DOWN = "add volume -5; script-binding uosc/flash-volume";
      k = "add volume 5; script-binding uosc/flash-volume";
      j = "add volume -5; script-binding uosc/flash-volume";
      m = "cycle mute; script-binding uosc/flash-volume";

      # picture
      d = "cycle deband; show-text \"deband \${deband}\"";
      D = "cycle deinterlace; show-text \"deinterlace \${deinterlace}\"";
      "Ctrl+h" = "apply-profile quality; show-text \"quality profile\"";
      "Ctrl+l" = "apply-profile saver; show-text \"saver profile\"";
      r = "cycle_values video-rotate 90 180 270 0";
      "Alt+LEFT" = "add video-pan-x 0.05";
      "Alt+RIGHT" = "add video-pan-x -0.05";
      "Alt+UP" = "add video-pan-y 0.05";
      "Alt+DOWN" = "add video-pan-y -0.05";
      "Alt+=" = "add video-zoom 0.1";
      "Alt+-" = "add video-zoom -0.1";
      "Alt+0" = "set video-zoom 0; set video-pan-x 0; set video-pan-y 0";

      # subtitles
      v = "cycle sub-visibility";
      z = "add sub-delay -0.1; show-text \"sub delay \${sub-delay}\"";
      Z = "add sub-delay 0.1; show-text \"sub delay \${sub-delay}\"";
      "Ctrl+z" = "set sub-delay 0";

      # tools
      S = "screenshot";
      "Ctrl+s" = "screenshot window";
      i = "script-binding stats/display-stats-toggle";
      I = "script-binding stats/display-stats";
      y = "script-binding memo-history";
      "Ctrl+r" = "script-binding reload/reload_resume";
      "Ctrl+c" = "run wl-copy \"\${path}\"; show-text \"path copied\"";
      ESC = "set fullscreen no";
    };
  };

  # uosc's colours: the live theme (rewritten by `theme toggle`).
  xdg.configFile."mpv/script-opts/uosc.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${state}/uosc.conf";

  xdg.mimeApps = {
    enable = true;
    defaultApplications = lib.genAttrs mimeTypes (_: "mpv.desktop");
  };
}
