{
  config,
  lib,
  pkgs,
  ...
}:

let
  kittyBin = "${config.home.homeDirectory}/.nix-profile/bin/kitty";
in
{
  # ── Deploy the Automator Quick Action service ──────────────────
  # This creates a "Launch Kitty" entry in the Services menu that
  # can be assigned a global keyboard shortcut via macOS System
  # Settings → Keyboard → Shortcuts → Services.
  home.file = {
    "Library/Services/Launch Kitty.workflow/Contents/Info.plist" = {
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>NSServices</key>
          <array>
            <dict>
              <key>NSServicePrincipalBundleIdentifier</key>
              <string>com.apple.automator</string>
            </dict>
          </array>
        </dict>
        </plist>
      '';
    };

    "Library/Services/Launch Kitty.workflow/Contents/document.wflow" = {
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>AMApplicationBuild</key>
          <string></string>
          <key>AMApplicationVersion</key>
          <string></string>
          <key>AMDocumentVersion</key>
          <string>2</string>
          <key>AMShowWhenRun</key>
          <false/>
          <key>AMWorkflowActions</key>
          <array>
            <dict>
              <key>Action</key>
              <dict>
                <key>AMAccepts</key>
                <dict>
                  <key>Container</key>
                  <string>List</string>
                  <key>Optional</key>
                  <true/>
                  <key>Types</key>
                  <array>
                    <string>public.data</string>
                  </array>
                </dict>
                <key>AMActionVersion</key>
                <string></string>
                <key>AMApplication</key>
                <array>
                  <string>Automator</string>
                </array>
                <key>AMParameterProperties</key>
                <dict>
                  <key>COMMAND_STRING</key>
                  <string>open -a ${kittyBin}</string>
                </dict>
                <key>ActionBundlePath</key>
                <string>/System/Library/Automator/Run Shell Script.action</string>
                <key>ActionName</key>
                <string>Run Shell Script</string>
                <key>ActionParameters</key>
                <dict>
                  <key>COMMAND_STRING</key>
                  <string>open -a ${kittyBin}</string>
                </dict>
                <key>BundleIdentifier</key>
                <string>com.apple.automator.RunShellScript</string>
                <key>CFBundleIdentifier</key>
                <string>com.apple.automator.RunShellScript</string>
                <key>CanUseAsShellCommand</key>
                <true/>
                <key>LocalizedApplicationName</key>
                <string>Automator</string>
                <key>WorkflowActionName</key>
                <string>Run Shell Script</string>
              </dict>
            </dict>
          </array>
          <key>AMWorkflowContentPath</key>
          <string></string>
          <key>AMWorkflowType</key>
          <string>Service</string>
        </dict>
        </plist>
      '';
    };
  };
}
