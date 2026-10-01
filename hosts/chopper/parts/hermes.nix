# hosts/chopper/parts/hermes.nix — Hermes Agent (replaces the OpenClaw gateway).
#
# Upstream ships a first-class NixOS module (github:NousResearch/hermes-agent,
# nixosModules.default), so unlike the OpenClaw setup there is no wrapper
# script, no `mkForce` on the package, and no permittedInsecurePackages.
#
# Three units come out of this file:
#
#   hermes-agent      — the messaging gateway (Signal). Started by the
#                       upstream module from `services.hermes-agent`.
#   hermes-backend    — `hermes dashboard`: the web admin panel plus the
#                       /api/ws + /api/pty sockets Hermes Desktop uses.
#                       Loopback-only, reached over an SSH tunnel from the
#                       Mac (see `backend` below).
#   signal-cli-daemon — Hermes talks to Signal over signal-cli's HTTP/JSON-RPC
#                       daemon rather than embedding a plugin, so the daemon
#                       is ours to run. It reuses the already-linked device
#                       state in /var/lib/signal-cli.
#
# Native mode (not `container.enable`) because chopper runs k3s/containerd,
# not docker or podman, and pulling in a second container runtime for one
# service is not worth it on a 8 GB laptop. Revisit if the agent needs a
# writable Ubuntu layer to install its own apt/pip packages.
#
# Secrets: all provider keys live in ONE sops secret rendered as a dotenv
# file (`hermes-env`), consumed via `environmentFiles`. The option takes a
# `str`, not a `path`, specifically so runtime sops paths stay out of the
# world-readable Nix store.
{ config, pkgs, ... }:
let
  signalHttpPort = 8080;
  backendPort = 9119;
  magicDns = "chopper.tail477f2f.ts.net";
in
{
  services.hermes-agent = {
    enable = true;

    # Puts `hermes` on PATH and exports HERMES_HOME system-wide so root and
    # vysakh get the TUI against the same state the gateway uses.
    addToSystemPackages = true;

    settings = {
      model = {
        default = "anthropic/claude-opus-4.6";
        provider = "openrouter";
        base_url = "https://openrouter.ai/api/v1";
      };

      # The CLI/TUI keeps the full toolset; Signal gets the standard curated
      # messaging preset rather than everything.
      platform_toolsets = {
        cli = [ "hermes-cli" ];
        signal = [ "hermes-signal" ];
      };

      # Tailnet dashboard exposure (see the tailscale-serve unit below).
      #
      # Two separate gates have to be satisfied, and both are deliberate
      # upstream defences — neither can be skipped:
      #
      #   1. Host header. The server rejects any request whose Host differs
      #      from the bound address OR `public_url` (DNS-rebinding defence).
      #      Without public_url, a request proxied in as
      #      chopper.tail477f2f.ts.net gets:
      #        400 {"detail":"Invalid Host header…"}
      #   2. Auth gate. Setting a public_url requires an auth provider even
      #      though the backend itself still binds loopback. There is no
      #      unauthenticated public-dashboard option in Hermes.
      #
      # password_hash is scrypt, generated with:
      #   python -c "from plugins.dashboard_auth.basic import hash_password; \
      #              print(hash_password('…'))"
      # The plaintext lives in sops as `hermes-dashboard-password`.
      #
      # NOTE: this hash lands in the world-readable Nix store. That is
      # acceptable here because it is scrypt over a 24-char random password
      # and the endpoint is already tailnet-only (Tailscale ACLs are the
      # real perimeter; this is defence in depth). Do NOT reuse the password.
      dashboard = {
        public_url = "https://${magicDns}";
        basic_auth = {
          username = "vysakh";
          password_hash = "scrypt$16384$8$1$sqXW0VjIIE2NFrr/jRsN7Q==$mQQbwavb/YaKLuO58lafG5T3Xwt4NhiB4lkHvsb0dUg=";
        };
      };
    };

    # Android TV remote control — ported from the OpenClaw `mcp.servers`
    # block. Spawned via uvx. UV_PYTHON_PREFERENCE=only-system forces uv onto
    # Nix's Python instead of downloading a dynamically linked interpreter
    # that NixOS cannot execute. C_INCLUDE_PATH supplies the kernel headers
    # the evdev C extension needs (pulled in by pynput).
    #
    # NOTE: the device pairing certificates live in the old gateway's state
    # dir (/var/lib/openclaw/.androidtv/certificates/) and must be copied to
    # $HERMES_HOME/.androidtv/ or the TV has to be re-paired.
    #
    # `command` is the absolute Nix store path, NOT bare "uvx". With a bare
    # name Hermes' own package manager tries to stage a managed `uv` into
    # $HERMES_HOME/tools/, and that binary is a dynamically linked FHS build
    # which NixOS cannot execute ("exited 127: Could not start dynamically
    # linked executable"). An absolute path bypasses the tool store entirely.
    mcpServers.androidtv = {
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "--from"
        "androidtvmcp @ https://github.com/tellmeY18/androidtvmcp/archive/refs/heads/main.zip"
        "androidtvmcp"
        "serve"
      ];
      env = {
        UV_PYTHON_PREFERENCE = "only-system";
        C_INCLUDE_PATH = "${pkgs.linuxHeaders}/include";
      };
    };

    # On the gateway's PATH: uvx + a system Python and C compiler for the
    # MCP server above, signal-cli for ad-hoc debugging, and the runtime
    # tools Hermes expects to find (it warns "install out of sync" without
    # ffmpeg/node/npm/ripgrep — ffmpeg is used for voice-memo transcription,
    # ripgrep for its own session search).
    extraPackages = [
      pkgs.uv
      pkgs.python3
      pkgs.gcc
      pkgs.signal-cli
      pkgs.ffmpeg-headless
      pkgs.nodejs
      pkgs.ripgrep
    ];

    # Dotenv with OPENROUTER_API_KEY, ANTHROPIC_API_KEY, OPENAI_API_KEY,
    # GITHUB_TOKEN, SIGNAL_ACCOUNT, SIGNAL_ALLOWED_USERS, SIGNAL_HOME_CHANNEL.
    environmentFiles = [ config.sops.secrets.hermes-env.path ];

    environment = {
      SIGNAL_HTTP_URL = "http://127.0.0.1:${toString signalHttpPort}";
    };

    # `dashboard` = the /api/ws + /api/pty sockets that Hermes Desktop needs,
    # PLUS the browser admin panel on the same port. ("serve" is the same
    # process without the web UI — it only returns a headless stub page.)
    #
    # Stays bound to LOOPBACK even though it is reachable on the tailnet:
    # `tailscale serve` (unit below) terminates TLS on chopper and proxies
    # to 127.0.0.1, so nothing listens on a routable address. Binding the
    # MagicDNS name directly would also work, but loopback keeps the blast
    # radius smaller and Tailscale handles the transport.
    #
    # Two ways in:
    #   tailnet  https://chopper.tail477f2f.ts.net   (basic auth, see settings)
    #   tunnel   ssh -N -L 9119:127.0.0.1:9119 root@chopper.tail477f2f.ts.net
    #            then http://127.0.0.1:9119 (no auth — loopback Host)
    backend = {
      mode = "dashboard";
      host = "127.0.0.1";
      port = backendPort;
      # Stable token so Hermes Desktop re-attaches to this backend across
      # restarts instead of each start minting a token nobody knows.
      sessionTokenFile = config.sops.secrets.hermes-dashboard-token.path;
    };
  };

  ##############################
  # signal-cli HTTP daemon     #
  ##############################
  # Hermes streams inbound messages from this daemon over SSE and sends
  # replies via JSON-RPC. Loopback-only: Hermes runs on the same host.
  #
  # /var/lib/signal-cli already holds the linked-device state from the
  # OpenClaw deployment, so no re-link is needed — only a change of owner.
  systemd.tmpfiles.rules = [
    "Z /var/lib/signal-cli 0750 hermes hermes - -"
  ];

  systemd.services.signal-cli-daemon = {
    description = "signal-cli HTTP daemon (Signal transport for Hermes Agent)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    # SIGNAL_ACCOUNT comes from the same dotenv Hermes uses, so the phone
    # number is defined in exactly one place.
    serviceConfig = {
      Type = "simple";
      User = "hermes";
      Group = "hermes";
      EnvironmentFile = config.sops.secrets.hermes-env.path;
      ExecStart = pkgs.writeShellScript "signal-cli-daemon" ''
        exec ${pkgs.signal-cli}/bin/signal-cli \
          --config /var/lib/signal-cli \
          --account "$SIGNAL_ACCOUNT" \
          daemon --http 127.0.0.1:${toString signalHttpPort}
      '';
      Restart = "on-failure";
      RestartSec = 5;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/lib/signal-cli" ];
    };
  };

  # signal-cli on root's interactive PATH for re-linking and debugging.
  environment.systemPackages = [ pkgs.signal-cli ];

  ##############################
  # Tailscale Serve — Hermes   #
  ##############################
  # Publishes the loopback dashboard on the tailnet as
  # https://chopper.tail477f2f.ts.net (TLS terminated by Tailscale, valid
  # cert from the tailnet CA). Same pattern the OpenClaw gateway used, and
  # the host-service equivalent of the Tailscale LoadBalancer Service that
  # fronts Grafana in k8s — that one needs the Tailscale k8s operator, which
  # only applies to in-cluster workloads.
  #
  # `path` is declared explicitly: a unit that shells out without it fails
  # to find its binaries, and an ExecStartPre that loops forever on a
  # missing tool wedges switch-to-configuration and holds the activation
  # lock, breaking every later deploy. See .agents/skills/deploy-k3s-nodes.
  systemd.services.tailscale-serve-hermes = {
    description = "Tailscale Serve proxy for the Hermes Agent dashboard";
    after = [ "tailscaled.service" "hermes-backend.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.tailscale
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.bash
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Wait for tailscaled to reach Running, not merely for the interface
      # to exist. After a tailscaled restart the interface appears before
      # the daemon finishes authenticating, and `tailscale serve` then fails
      # with "unexpected state: NoState". Bounded so it cannot wedge
      # activation if tailscaled never comes up.
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 60); do tailscale status --json 2>/dev/null | grep -q \"BackendState.*Running\" && exit 0; sleep 2; done; echo \"tailscaled not Running after 120s\" >&2; exit 1'";
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --https 443 http://127.0.0.1:${toString backendPort}";
      ExecStop = "${pkgs.tailscale}/bin/tailscale serve --https 443 off";
    };
  };
}
