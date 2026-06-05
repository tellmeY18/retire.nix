# k8s/images/derper/Dockerfile — Tailscale DERP relay (derper).
#
# Self-hosted DERP so kenobi↔c3po (c3po is behind symmetric NAT, currently
# relayed through Tailscale's shared, bandwidth-throttled Bengaluru DERP)
# bounces through OUR own node instead. That relay is the bottleneck behind
# slow attic→RustFS uploads and the fragile etcd/CNPG/MGR behaviour across
# that node pair.
#
# Built from the tailscale Go module, pinned to the tailnet's tailscale
# version (keep in lockstep with services.tailscale's package version). The
# runtime mode — DERP-over-HTTP behind Traefik's TLS termination, with
# --verify-clients against the host tailscaled socket — is set by the
# Deployment args in k8s/clusters/glug-infra/derper/, NOT here.
#
# Built multi-arch (amd64 + arm64) so it runs on kenobi (arm64) via
# derper-build.yml. Tags: build-{N} + sha-{7}. No :latest.
ARG TS_VERSION=1.98.3

# ─── Stage 1: build derper from the tailscale module ─────────────────────────
# tailscale v1.98.3's go.mod requires Go 1.26.3; use a matching toolchain
# (GOTOOLCHAIN=auto fetches the exact patch if the base lags).
FROM golang:1.26-alpine AS builder
ARG TS_VERSION
ENV CGO_ENABLED=0 GOTOOLCHAIN=auto
RUN apk add --no-cache git
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go install tailscale.com/cmd/derper@v${TS_VERSION}

# ─── Stage 2: minimal runtime ────────────────────────────────────────────────
FROM alpine

LABEL org.opencontainers.image.source="https://github.com/tellmeY18/retire.nix"
LABEL org.opencontainers.image.description="Tailscale DERP relay (derper) for the glug-infra tailnet"

RUN apk add --no-cache ca-certificates tzdata \
    && adduser -D -u 1000 derper

COPY --from=builder /go/bin/derper /usr/local/bin/derper

USER 1000

# 8080 = DERP served over HTTP (Traefik terminates TLS in front).
# 3478/udp = STUN (only used if exposed directly via hostNetwork; optional).
EXPOSE 8080 3478/udp

ENTRYPOINT ["/usr/local/bin/derper"]
