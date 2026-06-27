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

  # macOS-specific
  "widget.disable-swipe-tracker" = true;
}
