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
  # Permanent ban list — ranges/IPs that are blocked forever at the firewall.
  # Add entries here; the crowdsec-permanent-bans oneshot ensures they are
  # always present after every boot (idempotent).
  permanentBans = [
    {
      range = "57.141.0.0/16";
      reason = "MediaWiki scraper bot farm - spoofed Chrome UAs, 17k+ reqs across .0/24 and .18/24 (2026-07)";
    }
    {
      range = "139.59.231.238/32";
      reason = "LeakIX vulnerability scanner infrastructure (l9scan)";
    }
    {
      range = "34.106.201.42/32";
      reason = "GCP-hosted recon - .git/config and .git/HEAD probing";
    }
  ];
in
{
  services.crowdsec = {
    enable = true;
    autoUpdateService = true; # daily `cscli hub update`

    settings.config = {
      # Pinned: the existing DB, hub and credentials live here. The module
      # default (/var/lib/crowdsec/data) would silently start an empty DB
      # and drop every ban, allowlist and the CAPI registration.
      config_paths.data_dir = "/var/lib/crowdsec/state";
      prometheus.listen_addr = "0.0.0.0";
      api.server = {
        enable = true;
        listen_uri = "127.0.0.1:8082";
        # MUST be set for the community blocklist to be pulled at all —
        # with the default (null) CAPI is disabled.
        online_client.credentials_path = "/var/lib/crowdsec/state/online_api_credentials.yaml";
      };
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

    settings = {
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
          name = "glug/whitelist-member-ua";
          description = "Never ban FOSSCell Wiki Access extension users";
          whitelist = {
            reason = "FOSSCell Wiki member browser extension";
            expression = [ "evt.Parsed.http_user_agent matches '^FOSSCellWiki/token='" ];
          };
        }
        {
          name = "glug/whitelist-nix-cache";
          description = "Binary cache traffic is indistinguishable from crawling by design";
          whitelist = {
            reason = "attic binary cache (unique content-addressed paths ARE its normal traffic)";
            # Deliberately the whole vhost, not just 404s.
            #
            # First attempt scoped this to status 404, reasoning that a cache
            # miss is the normal negative answer. That was too narrow and got
            # a GitHub Actions runner banned mid-build under
            # http-crawl-non_statics — at status *200*. Cache HITS trip it
            # too: every request is a unique /system/<hash>.narinfo, so a
            # single `nix build` walks thousands of distinct non-static paths.
            # That is precisely what crawl detection looks for, and no status
            # filter can separate it from abuse, because the traffic really is
            # identical in shape.
            #
            # Exempting the vhost is safe here in a way it would not be for
            # mediawiki: Attic is a content-addressed store with public reads
            # and token-gated writes. There is no login, no query surface, no
            # sensitive path to probe — the scan scenarios have nothing to
            # protect. Every other vhost keeps full protection.
            expression = [
              "evt.Meta.target_fqdn == 'cache.tellmey.fyi'"
            ];
          };
        }
        {
          name = "glug/whitelist-matrix-client-api";
          description = "Matrix client API 404s and unique-path polling are normal";
          whitelist = {
            reason = "matrix client API (account_data/thumbnail 404s and per-room polling are normal)";
            # A Matrix client (Element) legitimately 404s on account_data and
            # missing media thumbnails, and long-polls a distinct URI per room
            # and per sync. http-probing scored that as scanning and banned the
            # operator's home IP — which also carries skywalker, so the Nix
            # cache went down as collateral.
            #
            # NARROWER than the binary-cache rule on purpose. Attic is a
            # content-addressed store with nothing to attack; Synapse has a
            # real auth surface, so /login and /register are deliberately NOT
            # exempt and still feed the scenarios — password spraying against
            # them must remain bannable. Federation (/_matrix/federation/) and
            # the admin API are likewise untouched.
            #
            # evt.Parsed.request is set by s01 traefik-logs, so this does not
            # depend on parser ordering within s02 (evt.Meta.http_path is only
            # populated later, by http-logs).
            expression = [
              "evt.Meta.target_fqdn == 'chat.tellmey.fyi' && evt.Parsed.request startsWith '/_matrix/client/' && !(evt.Parsed.request matches '/(login|register)')"
            ];
          };
        }
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
              "27.63.223.218/32" # admin home IP (dynamic — update if it changes)
              "103.184.239.103/32" # mathew (2026-11-16, dynamic — update if it changes)
            ];
          };
        }
      ];

      # fail2ban behavior for the bot walls: an IP that keeps slamming into
      # 403/429 (Anubis DENY rules, Traefik rate limits) earns a firewall ban
      # (default profile: 4h).
      #
      # NOTE: deliberately lenient (capacity=30, 5min leak) to avoid false
      # positives. Real users hitting Traefik's 429 rate-limiter while navigating
      # (or getting stuck on the Turnstile challenge page) would need 30+
      # rate-limited requests over 2.5+ hours to overflow. Only sustained
      # scraper abuse — hundreds of requests in minutes — triggers a ban.
      scenarios = [
        {
          type = "leaky";
          name = "glug/http-deny-flood";
          description = "Sustained 403/429 abuse (high threshold for real users)";
          filter = "evt.Meta.log_type == 'http_access-log' && evt.Meta.http_status in ['403', '429']";
          groupby = "evt.Meta.source_ip";
          capacity = 30;
          leakspeed = "5m";
          blackhole = "10m";
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

  # Upstream module bug #0: rules (parsers, scenarios, whitelists) are
  # rendered into /etc/crowdsec/, but nothing makes systemd restart the
  # daemon when those files change. A deploy therefore updates the rules on
  # disk while the RUNNING crowdsec keeps enforcing whatever it loaded at
  # boot — silently, with no error anywhere.
  #
  # This bit hard: the nix-cache whitelist below was deployed, showed as
  # "enabled" in `cscli parsers list`, and `cscli explain` (which spawns a
  # fresh process against the on-disk config) confirmed it whitelisted the
  # event — while the live daemon, last started 15 days earlier, went on
  # banning the exact traffic it was written to permit.
  #
  # Hashing settings means any rule change forces a restart.
  systemd.services.crowdsec.restartTriggers = [
    (builtins.toJSON config.services.crowdsec.settings)
  ];

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

  # Upstream module bug #3: the register unit sets DynamicUser=true together
  # with User=crowdsec. Under DynamicUser systemd once migrated
  # /var/lib/crowdsec into /var/lib/private/ and chowned it away from the
  # static crowdsec user — corrupting the agent's state dir. Run it as the
  # plain static user. (Bugs #1 raw-cscli and #2 missing `after` are fixed
  # upstream since the 2026-11 module rewrite.)
  systemd.services.crowdsec-firewall-bouncer-register.serviceConfig.DynamicUser = lib.mkForce false;

  # Declarative permanent bans — applied on every boot after CrowdSec starts.
  # Uses 87600h (10 years) as "forever" since cscli doesn't support infinite.
  # Idempotent: skips ranges that already have an active decision.
  systemd.services.crowdsec-permanent-bans = {
    description = "Apply declarative permanent CrowdSec bans";
    after = [ "crowdsec.service" ];
    requires = [ "crowdsec.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ config.services.crowdsec.package pkgs.jq ];
    script =
      let
        cscli = lib.getExe' config.services.crowdsec.package "cscli";
        banCmds = lib.concatMapStringsSep "\n" (entry: ''
          if ! ${cscli} decisions list -r ${entry.range} --output json | jq -e 'length > 0' >/dev/null 2>&1; then
            echo "Adding permanent ban: ${entry.range} (${entry.reason})"
            ${cscli} decisions add -r ${entry.range} --duration 87600h --reason '${entry.reason}'
          else
            echo "Already banned: ${entry.range}"
          fi
        '') permanentBans;
      in
      banCmds;
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
