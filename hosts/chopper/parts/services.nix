{
  config,
  pkgs,
  openclaw-signal-plugin,
  ...
}:
{
  ####################
  # OpenSSH          #
  ####################
  services.openssh = {
    enable = true;
    settings = {
      # Root login via SSH key only — password auth globally disabled.
      # If you don't need root SSH at all, set to "no".
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      X11Forwarding = true;
      X11UseLocalhost = false; # Allows remote X connections
      PubkeyAuthentication = true;
    };
  };

  ####################
  # Tailscale VPN    #
  ####################
  services.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale-auth-key";
    extraUpFlags = [
      "--accept-routes"
      "--advertise-exit-node"
      "--accept-dns"
      # Advertise this node's pod CIDR so other nodes can route to our pods
      "--advertise-routes=10.42.0.0/24"
    ];
    openFirewall = true;
  };

  ####################
  # Nextcloud        #
  ####################
  services.nextcloud = {
    enable = false;
    hostName = "next.tellmey.fyi";

    # Manually increment with every major upgrade.
    package = pkgs.nextcloud33;

    database.createLocally = true;
    configureRedis = true;

    # Increase the maximum file upload size to avoid problems uploading videos.
    maxUploadSize = "16G";
    https = true;

    autoUpdateApps.enable = true;
    extraAppsEnable = true;
    extraApps = with config.services.nextcloud.package.packages.apps; {
      tasks = tasks;
      contacts = contacts;
      memories = memories;
    };

    settings = {
      overwriteprotocol = "https";
      default_phone_region = "IN";
      port = "8789";
    };

    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      adminpassFile = "/run/secrets/nextcloud-admin-pass";
    };
  };

  ####################
  # Cloudflare Tunnel#
  ####################
  # Disabled: cloudflared fails to build on nixpkgs-unstable
  # (test flake in management/events_test.go). Re-enable once upstream
  # fixes the panic-in-goroutine issue.
  services.cloudflared = {
    enable = false;
  };

  # OpenClaw uses LLMs to process untrusted content — upstream marks it
  # insecure due to prompt-injection risk. We accept this intentionally.
  # The version MUST match the releaseVersion from the nix-openclaw flake's
  # openclaw-source.nix (currently 2026.6.11). This applies to nixpkgs-unstable
  # host packages only; the upstream flake's openclaw-gateway package uses the
  # upstream flake's own nixpkgs pin and may have a different version string.
  nixpkgs.config.permittedInsecurePackages = [ "openclaw-2026.6.11" ];

  # Self-heal OpenClaw state directory ownership on every boot. Runtime files
  # under /var/lib/openclaw/ (paired.json, pending.json, device-auth.json,
  # etc.) can be created by root-run tooling (e.g. `openclaw devices approve`)
  # and become unreadable by the openclaw user. The Z directive recursively
  # resets user:group on every boot.
  systemd.tmpfiles.rules = [
    "Z /var/lib/openclaw 0750 openclaw openclaw - -"
  ];

  ####################
  # OpenClaw Gateway #
  ####################
  services.openclaw-gateway = {
    enable = true;
    port = 18789;

    config = {
      gateway.mode = "local";

      # Instance identity — display name shown in the control UI and chat.
      ui.assistant.name = "tinaku";

      # Increase signal debounce to prevent session init race in multi-member groups.
      messages.queue = {
        mode = "collect";
        debounceMsByChannel.signal = 3000;
      };

      # Default agent with group chat behavior.
      agents.list = [
        {
          id = "main";
          default = true;
          name = "tinaku";
          model = "copilot/claude-opus-4.6";
          groupChat = {
            mentionPatterns = [ "tinaku" "\\bt\\b" ];
            historyLimit = 50;
            unmentionedInbound = "room_event";
            visibleReplies = "automatic";
          };
        }
      ];

      # GitHub Copilot Enterprise — direct bearer auth against the Copilot API.
      models.providers.copilot = {
        api = "openai-completions";
        baseUrl = "https://api.githubcopilot.com";
        apiKey = "\${GITHUB_TOKEN}";
        models = [
          {
            id = "claude-opus-4.6";
            name = "Claude Opus 4.6 (Copilot)";
            input = [ "text" ];
            contextWindow = 200000;
            maxTokens = 32768;
          }
        ];
      };

      # Android TV remote control MCP server — lets the assistant
      # discover, pair, navigate, and control Android TV devices on the
      # local network. Spawned via uvx (uv must be on servicePath).
      mcp.servers.androidtv = {
        command = "uvx";
        args = [ "androidtvmcp" "serve" ];
      };

      # Load the official @openclaw/signal runtime plugin from the Nix store.
      # This is the upstream built-in Signal channel (not the custom fork).
      plugins.load.paths = [
        "${openclaw-signal-plugin}"
      ];
      # Explicitly enable the Signal plugin (loaded from plugins.load.paths).
      # Non-bundled plugins are NOT auto-enabled by channels.<id>.enabled — that
      # bypass only works for bundled extensions. Without this entry the Signal
      # channel config is read but no signal-cli process is spawned.
      plugins.entries.signal.enabled = true;

      # Signal messenger channel.
      # The phone number is injected at runtime by the wrapper script
      # (reads the sops secret and patches the config with jq) because
      # the Signal plugin's schema requires account to be a string, not
      # a SecretRef ({ source, provider, id }) object.
      channels.signal = {
        enabled = true;
        configPath = "/var/lib/signal-cli";
        autoStart = true;
        account = "__INJECTED_BY_WRAPPER__";
        dmPolicy = "allowlist";
        allowFrom = [ "__INJECTED_BY_WRAPPER__" ];
        groupPolicy = "open";
      };
    };

    # Secrets are read from sops-decrypted files in the wrapper script (rather
    # than systemd Environment=) because the upstream module passes env vars as
    # literal strings that would leak into the world-readable Nix store.
    execStart =
      let
        pkg = config.services.openclaw-gateway.package;
        port = toString config.services.openclaw-gateway.port;
        tokenPath = config.sops.secrets.openclaw-gateway-token.path;
        anthropicPath = config.sops.secrets.openclaw-anthropic-key.path;
        openaiPath = config.sops.secrets.openclaw-openai-key.path;
        githubTokenPath = config.sops.secrets.openclaw-github-token.path;
        signalNumberPath = config.sops.secrets.openclaw-signal-number.path;
        allowlistPath = config.sops.secrets.openclaw-signal-allowlist.path;


        wrapper = pkgs.writeScript "openclaw-gateway-wrapper" ''
          #!${pkgs.bash}/bin/bash
          set -e
          error_exit() { echo "openclaw-wrapper: $1" >&2; exit 1; }
          [ -r "${tokenPath}"       ] || error_exit "missing token: ${tokenPath}"
          [ -r "${anthropicPath}"   ] || error_exit "missing anthropic key: ${anthropicPath}"
          [ -r "${openaiPath}"      ] || error_exit "missing openai key: ${openaiPath}"
          [ -r "${githubTokenPath}" ] || error_exit "missing github token: ${githubTokenPath}"
          [ -r "${signalNumberPath}" ] || error_exit "missing signal number: ${signalNumberPath}"
          [ -r "${allowlistPath}"     ] || error_exit "missing signal allowlist: ${allowlistPath}"
          export OPENCLAW_GATEWAY_TOKEN="$(cat ${tokenPath})"
          export ANTHROPIC_API_KEY="$(cat ${anthropicPath})"
          export OPENAI_API_KEY="$(cat ${openaiPath})"
          export GITHUB_TOKEN="$(cat ${githubTokenPath})"
          SIGNAL_NUMBER="$(cat ${signalNumberPath})"
          export OPENCLAW_SIGNAL_NUMBER="$SIGNAL_NUMBER"
          # Inject signal number and DM allowlist into the Nix-generated config.
          # Signal plugin requires account as a plain string, not a SecretRef.
          # allowFrom is a JSON array of phone numbers from sops.
          ALLOWLIST="$(cat ${allowlistPath})"
          MERGED_CONFIG="/var/lib/openclaw/merged-config.json"
          ${pkgs.jq}/bin/jq --arg num "$SIGNAL_NUMBER" --argjson allow "$ALLOWLIST" \
            '.channels.signal.account = $num | .channels.signal.allowFrom = $allow' \
            "${config.services.openclaw-gateway.configPath}" \
            > "$MERGED_CONFIG" \
            || error_exit "jq merge failed"
          chmod 0644 "$MERGED_CONFIG"
          export OPENCLAW_CONFIG_PATH="$MERGED_CONFIG"
          # Set Signal profile name to match the bot identity.
          ${pkgs.signal-cli}/bin/signal-cli --config /var/lib/signal-cli \
            -u "$SIGNAL_NUMBER" updateProfile --given-name "tinaku" \
            2>/dev/null || true
          exec ${pkg}/bin/openclaw gateway --auth token --port ${port}
        '';
      in
      "${wrapper}";

    # signal-cli on PATH for the gateway process (needed by the Signal channel).
    servicePath = [
      pkgs.signal-cli
      pkgs.uv # uvx for MCP servers (androidtvmcp)
    ];
  };

  # signal-cli on root's interactive PATH for registration and debugging.
  # openclaw CLI for admin tasks (pairing, device management, etc.).
  environment.systemPackages = [
    pkgs.signal-cli
    config.services.openclaw-gateway.package
  ];

  ##############################
  # Tailscale Serve — OpenClaw #
  ##############################
  # Proxies https://chopper.tail477f2f.ts.net to the OpenClaw gateway so
  # browsers can use WebRTC device identity (requires a secure context).
  # This is preferred over gateway.controlUi.allowInsecureAuth because the
  # browser-enforced secure-context requirement can't be bypassed server-side.
  systemd.services.tailscale-serve-openclaw = {
    description = "Tailscale Serve proxy for OpenClaw gateway";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.tailscale
      pkgs.iproute2
    ];
    serviceConfig = {
      Type = "oneshot";
      # Wait for tailscale0 to be up before configuring serve
      ExecStartPre = ''
        /bin/sh -c "until ip link show tailscale0 2>/dev/null | grep -q UP; do sleep 1; done"
      '';
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --https 443 http://127.0.0.1:18789";
    };
  };

  ####################
  # ZFS Maintenance  #
  ####################
  services.zfs = {
    trim.enable = true;
    autoScrub.enable = true;
  };
}
