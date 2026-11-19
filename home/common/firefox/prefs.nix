{
  # Security & Privacy
  "dom.security.https_only_mode" = true;
  "privacy.donottrackheader.enabled" = true;
  "privacy.firstparty.isolate" = true;
  "privacy.globalprivacycontrol.enabled" = true;
  "network.IDN_show_punycode" = true;
  "network.trr.mode" = 5;

  # Performance
  "gfx.webrender.all" = true;
  "gfx.webrender.compositor" = true;
  "gfx.canvas.accelerated.cache-items" = 4096;
  "gfx.canvas.accelerated.cache-size" = 512;
  "gfx.content.skia-font-cache-size" = 20;
  "content.notify.interval" = 100000;
  "network.http.max-connections" = 1800;
  "network.http.max-persistent-connections-per-server" = 10;
  "network.http.max-urgent-start-excessive-connections-per-host" = 5;
  "network.http.pacing.requests.enabled" = false;
  "network.dns.disablePrefetch" = false;
  "network.dns.disablePrefetchFromHTTPS" = false;
  "network.predictor.enabled" = false;
  "network.prefetch-next" = false;

  # UI / Behavior
  "accessibility.force_disabled" = 1;
  "browser.aboutConfig.showWarning" = false;
  "browser.aboutHomeSnippets.updateUrl" = "";
  "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
  "browser.selfsupport.url" = "";
  "browser.startup.homepage" = "https://noai.duckduckgo.com";
  "browser.startup.homepage_override.buildID" = "";
  "browser.startup.homepage_override.mstone" = "ignore";
  "browser.tabs.firefox-view" = false;
  "browser.tabs.firefox-view-next" = false;
  "browser.urlbar.suggest.history" = false;
  "browser.urlbar.suggest.topsites" = false;
  "dom.events.asyncClipboard.clipboardItem" = true;
  "extensions.htmlaboutaddons.recommendations.enabled" = false;
  "extensions.recommendations.themeRecommendationUrl" = "";
  "sidebar.main.tools" = "history,bookmarks";
  "sidebar.verticalTabs" = true;
  "sidebar.verticalTabs.dragToPinPromo.dismissed" = true;
  "signon.management.page.breach-alerts.enabled" = false;
  "startup.homepage_override_url" = "";
  "startup.homepage_welcome_url" = "";
  "startup.homepage_welcome_url.additional" = "";
  "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

  # Indic languages: Latin first so English sites stay English, then the
  # scripts we read. Per-script default fonts (Noto ships all of them; see
  # profiles/indic.nix for the system side).
  "intl.accept_languages" = "en-IN, en-US, en, hi, ml, ta, te, kn, bn, gu, mr, pa";
  "font.name.sans-serif.x-mlym" = "Noto Sans Malayalam";
  "font.name.serif.x-mlym" = "Noto Serif Malayalam";
  "font.name.sans-serif.x-deva" = "Noto Sans Devanagari";
  "font.name.serif.x-deva" = "Noto Serif Devanagari";
  "font.name.sans-serif.x-taml" = "Noto Sans Tamil";
  "font.name.serif.x-taml" = "Noto Serif Tamil";
  "font.name.sans-serif.x-telu" = "Noto Sans Telugu";
  "font.name.serif.x-telu" = "Noto Serif Telugu";
  "font.name.sans-serif.x-knda" = "Noto Sans Kannada";
  "font.name.serif.x-knda" = "Noto Serif Kannada";
  "font.name.sans-serif.x-beng" = "Noto Sans Bengali";
  "font.name.serif.x-beng" = "Noto Serif Bengali";
  "font.name.sans-serif.x-gujr" = "Noto Sans Gujarati";
  "font.name.serif.x-gujr" = "Noto Serif Gujarati";
  "font.name.sans-serif.x-guru" = "Noto Sans Gurmukhi";
  "font.name.serif.x-guru" = "Noto Serif Gurmukhi";
  "font.name.sans-serif.x-orya" = "Noto Sans Oriya";
  "font.name.serif.x-orya" = "Noto Serif Oriya";

  # macOS-specific
  "widget.disable-swipe-tracker" = true;
}