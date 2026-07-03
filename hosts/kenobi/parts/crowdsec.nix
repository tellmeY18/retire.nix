# hosts/kenobi/parts/crowdsec.nix — CrowdSec security engine + firewall bouncer.
#
# fail2ban-style behavioral IP banning + the CrowdSec community blocklist
# (CAPI), enforced at the HOST firewall — banned IPs are dropped at INPUT
# before they cost Traefik, Anubis, or PHP-FPM a single cycle.
#
# Log source: Traefik access logs written as JSON to /var/log/traefik/
# (hostPath mount from the traefik pod — see k8s/apps/traefik/values.yaml).
# Context: the 2026-07 MediaWiki scraper waves (docs/mediawiki-bot-attack-2026-07.md).
#
# No sops secrets required:
#   - machine registration against the local LAPI is automatic (`machine add --auto`)
#   - CAPI (community blocklist) registration is automatic (`capi register`)
#   - the firewall bouncer self-registers via cscli on this host
#
# LAPI listens on 127.0.0.1:8082 — NOT 8080, which Traefik (hostNetwork)
# already occupies on this node.
#
# Day-2:
#   cscli decisions list            # current bans
#   cscli alerts list               # what fired
#   cscli metrics                   # parser/scenario hit counts
#   cscli decisions add -i 1.2.3.4  # manual ban
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Same generate call as the nixpkgs crowdsec module — produces the identical
  # store path the crowdsec service itself runs with.
  crowdsecConfigFile =
    (pkgs.formats.yaml { }).generate "crowdsec.yaml"
      config.services.crowdsec.settings.general;
  # Constants from the nixpkgs crowdsec-firewall-bouncer module (not exported).
  apiKeyFile = "/var/lib/crowdsec-firewall-bouncer-register/api-key.cred";
  bouncerName = config.services.crowdsec-firewall-bouncer.registerBouncer.bouncerName;
in
{
  services.crowdsec = {
    enable = true;
    autoUpdateService = true; # daily `cscli hub update`

    settings = {
      general = {
        prometheus.listen_addr = "0.0.0.0";
        api.server = {
          enable = true;
          listen_uri = "127.0.0.1:8082";
        };
      };
      # Runtime-writable credential paths, populated automatically on first
      # start. capi credentials MUST be set for the community blocklist to
      # be pulled at all — with the default (null) CAPI is disabled.
      lapi.credentialsFile = "/var/lib/crowdsec/state/local_api_credentials.yaml";
      capi.credentialsFile = "/var/lib/crowdsec/state/online_api_credentials.yaml";
    };

    hub = {
      # traefik collection = JSON access-log parser + generic HTTP scenarios;
      # the http collections cover crawl/probing/sensitive-path/CVE patterns.
      collections = [
        "crowdsecurity/traefik"
        "crowdsecurity/base-http-scenarios"
        "crowdsecurity/http-cve"
      ];
    };

    localConfig = {
      acquisitions = [
        {
          source = "file";
          filenames = [ "/var/log/traefik/access.log" ];
          labels.type = "traefik";
        }
      ];

      # Never ban ourselves: tailnet, cluster CIDRs, loopback. Pod-sourced
      # requests (kube-probes, in-cluster clients) must never trip scenarios.
      parsers.s00Raw = [
        # The traefik-logs parser (s01-parse) filters on `evt.Parsed.program
        # startsWith 'traefik'`, but a raw file datasource never sets
        # `program` — that field is only populated by the syslog-logs parser
        # (s00-raw) for syslog/journal sources. Pre-tag our JSON log lines
        # so the traefik parser matches them.
        {
          filter = ''evt.Line.Raw startsWith "{"'';
          name = "glug/traefik-file-source";
          description = "Tag Traefik JSON log lines from file acquisition as program=traefik";
          statics = [
            {
              parsed = "program";
              value = "traefik";
            }
            {
              parsed = "message";
              expression = "evt.Line.Raw";
            }
          ];
          onsuccess = "next_stage";
        }
      ];

      parsers.s02Enrich = [
        {
          name = "glug/whitelist-internal";
          description = "Whitelist tailnet + k3s cluster CIDRs";
          whitelist = {
            reason = "internal networks";
            cidr = [
              "100.64.0.0/10" # tailnet (CGNAT range)
              "10.42.0.0/16" # k3s pod CIDR
              "10.43.0.0/16" # k3s service CIDR
              "127.0.0.0/8"
            ];
          };
        }
      ];

      # fail2ban behavior for the bot walls: an IP that keeps slamming into
      # 403/429 (Anubis DENY rules, Traefik rate limits) earns a firewall ban
      # (default profile: 4h). Bucket = 10 denials, leaking 1/min — sustained
      # abuse overflows in minutes; a human hitting a wall a few times never
      # does. The 2026-07 Drilldown botnet IPs each re-offended well past this.
      scenarios = [
        {
          type = "leaky";
          name = "glug/http-deny-flood";
          description = "IPs repeatedly hitting 403/429 (bot-wall recidivists)";
          filter = "evt.Meta.log_type == 'http_access-log' && evt.Meta.http_status in ['403', '429']";
          groupby = "evt.Meta.source_ip";
          capacity = 10;
          leakspeed = "1m";
          blackhole = "5m";
          labels = {
            service = "http";
            confidence = 2;
            spoofable = 0;
            remediation = true;
            behavior = "http:scan";
            label = "HTTP deny flood";
          };
        }
      ];
    };
  };

  # Enforcement: drop banned IPs at the host firewall. Kenobi uses the
  # default NixOS iptables firewall, so the bouncer runs in iptables/ipset
  # mode (module default) and is partOf firewall.service — firewall reloads
  # restart it so the ban set is always re-applied.
  services.crowdsec-firewall-bouncer.enable = true;

  # Chicken-and-egg wart in the nixpkgs module: `cscli machines add` (run in
  # ExecStartPre) refuses to load the config when the CAPI credentials file
  # referenced by online_client.credentials_path does not exist, so first
  # boot fails before `cscli capi register` ever runs. Pre-create it empty;
  # register fills it in.
  systemd.tmpfiles.settings."11-crowdsec-credentials" = {
    "/var/lib/crowdsec/state/online_api_credentials.yaml".f = {
      user = "crowdsec";
      group = "crowdsec";
      mode = "0600";
    };
  };

  # Upstream module bug #1: the register unit invokes the RAW cscli binary,
  # which expects /etc/crowdsec/config.yaml — a file the NixOS crowdsec module
  # never creates (its config lives in the Nix store). Override the script to
  # pass the generated config explicitly. Same logic as upstream otherwise.
  systemd.services.crowdsec-firewall-bouncer-register.script = lib.mkForce ''
    cscli() {
      ${lib.getExe' config.services.crowdsec.package "cscli"} -c=${crowdsecConfigFile} "$@"
    }
    if cscli bouncers list --output json | ${lib.getExe pkgs.jq} -e -- 'any(.[]; .name == "${bouncerName}")' >/dev/null; then
      # Bouncer already registered. Verify the API key is still present
      if [ ! -f ${apiKeyFile} ]; then
        echo "Bouncer registered but API key is not present"
        exit 1
      fi
    else
      rm -f '${apiKeyFile}'
      if ! cscli bouncers add --output raw -- '${bouncerName}' >${apiKeyFile}; then
        rm ${apiKeyFile}
        exit 1
      fi
    fi
  '';

  # Upstream module bug #2: the bouncer `requires` the register service but
  # has no `after` ordering on it, so both start concurrently and the
  # bouncer's LoadCredential races the API key file into existence.
  systemd.services.crowdsec-firewall-bouncer.after = [ "crowdsec-firewall-bouncer-register.service" ];

  # Upstream module bug #3: the register unit sets DynamicUser=true together
  # with User=crowdsec and StateDirectory="... crowdsec", which makes systemd
  # MIGRATE /var/lib/crowdsec into /var/lib/private/ and chown it away from
  # the static crowdsec user — corrupting the agent's state dir. Run it as
  # the plain static user and keep only its own state directory.
  systemd.services.crowdsec-firewall-bouncer-register.serviceConfig = {
    DynamicUser = lib.mkForce false;
    StateDirectory = lib.mkForce "crowdsec-firewall-bouncer-register";
  };

  # Traefik never rotates its access log file. copytruncate avoids having
  # to signal USR1 into the pod.
  services.logrotate.settings."/var/log/traefik/access.log" = {
    frequency = "daily";
    rotate = 3;
    size = "200M";
    copytruncate = true;
    missingok = true;
    notifempty = true;
    compress = true;
  };
}
