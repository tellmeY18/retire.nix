#!/usr/bin/env python3
"""Generate Cloudprober ConfigMap from endpoints.yaml.

Usage:
    python3 gen-cloudprober-config.py endpoints.yaml > /tmp/cloudprober-cm.yaml
    kubectl apply -f /tmp/cloudprober-cm.yaml

Or via Justfile:
    just k8s::endpoints-sync
"""

import sys
import yaml

HEADER = """\
# =============================================================================
# AUTO-GENERATED — do not edit manually.
# Source: endpoints.yaml → gen-cloudprober-config.py
# Regenerate: just k8s::endpoints-sync
# =============================================================================
"""

CM_TEMPLATE = """\
apiVersion: v1
kind: ConfigMap
metadata:
  name: cloudprober-config
  namespace: monitoring
  labels:
    app.kubernetes.io/name: cloudprober
    app.kubernetes.io/component: prober
    app.kubernetes.io/part-of: victoria-metrics-k8s-stack
    app.kubernetes.io/managed-by: kustomize
data:
  cloudprober.cfg: |
{cfg}
"""


def make_probe(ep):
    """Generate a Cloudprober probe block from an endpoint dict."""
    from urllib.parse import urlparse

    parsed = urlparse(ep["url"])
    host = parsed.hostname
    path = parsed.path or "/"
    protocol = "HTTPS" if parsed.scheme == "https" else "HTTP"
    name = ep["name"]
    team = ep.get("team", "unknown")
    tier = ep.get("tier", "unknown")

    return f"""\
    probe {{
      name: "{name}"
      type: HTTP
      targets {{
        host_names: "{host}"
      }}
      http_probe {{
        protocol: {protocol}
        relative_url: "{path}"
        resolve_first: true
      }}
      interval_msec: 30000
      timeout_msec: 10000
      validator {{
        name: "status_2xx"
        http_validator {{
          success_status_codes: "200-399"
        }}
      }}
      additional_label {{
        key: "service"
        value: "{name}"
      }}
      additional_label {{
        key: "tier"
        value: "{tier}"
      }}
      additional_label {{
        key: "team"
        value: "{team}"
      }}
    }}"""


def make_tls_probe(endpoints):
    """Generate a single TLS cert-check probe for all endpoints."""
    hosts = ",".join(
        set(
            __import__("urllib.parse", fromlist=["urlparse"])
            .urlparse(ep["url"])
            .hostname
            for ep in endpoints
        )
    )
    return f"""\
    probe {{
      name: "tls-expiry"
      type: HTTP
      targets {{
        host_names: "{hosts}"
      }}
      http_probe {{
        protocol: HTTPS
        relative_url: "/"
        resolve_first: true
      }}
      interval_msec: 3600000
      timeout_msec: 10000
      additional_label {{
        key: "check"
        value: "tls"
      }}
    }}"""


SURFACER = """\
    surfacer {
      type: PROMETHEUS
      prometheus_surfacer {
        metrics_prefix: "cloudprober_"
      }
    }"""


def main():
    if len(sys.argv) < 2:
        print("Usage: gen-cloudprober-config.py endpoints.yaml", file=sys.stderr)
        sys.exit(1)

    with open(sys.argv[1]) as f:
        data = yaml.safe_load(f)

    endpoints = data.get("endpoints", [])
    if not endpoints:
        print("ERROR: No endpoints found in", sys.argv[1], file=sys.stderr)
        sys.exit(1)

    parts = [HEADER.rstrip()]
    for ep in endpoints:
        parts.append(make_probe(ep))
    parts.append("")
    parts.append("    # TLS certificate expiry check (hourly, all endpoints)")
    parts.append(make_tls_probe(endpoints))
    parts.append("")
    parts.append(SURFACER)

    cfg = "\n\n".join(parts)
    print(CM_TEMPLATE.format(cfg=cfg))


if __name__ == "__main__":
    main()
