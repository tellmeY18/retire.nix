# Apache Answer with plugins — multi-stage build (CI-optimized).
#
# Plugins are compiled into the binary at build time (Go static linking).
# To add/remove plugins, edit `plugins.txt` and re-run the workflow.
#
# Layer cache strategy:
#   Stage 1 (answer-builder): upstream binary + entrypoint — rarely changes
#   Stage 2 (deps):           system packages — changes only on base image bump
#   Stage 3 (golang-builder): Go module download (cached layer if go.sum unchanged)
#                             + actual compilation
#   Stage 4 (final):          minimal runtime — only copies the binary
#
# The key insight: `answer build` does download+compile in one shot, so we
# can't split Go modules into a separate layer. BUT with GHA layer cache
# (mode=max), the ENTIRE RUN layer is cached when plugins.txt hasn't changed.
# Native arm64 runners make the uncached build ~3min instead of ~15min (QEMU).

# ─── Stage 1: Extract upstream answer CLI + entrypoint ───────────────────────
FROM apache/answer AS answer-builder

# ─── Stage 2: System dependencies (cached unless golang base bumps) ──────────
FROM golang:1.23-alpine AS deps

RUN apk --no-cache add \
    build-base \
    git \
    bash \
    nodejs \
    npm \
    && npm install -g pnpm@10.7.0

# ─── Stage 3: Build answer binary with plugins ──────────────────────────────
FROM deps AS golang-builder

# Bring in the upstream answer CLI (used as the build tool)
COPY --from=answer-builder /usr/bin/answer /usr/bin/answer

# plugins.txt is the cache-invalidation key.
# If this file hasn't changed, the GHA layer cache reuses the build layer.
COPY plugins.txt /tmp/plugins.txt

# Build with all plugins. Go module + pnpm caches are buildx cache mounts
# that persist within a CI workflow run (helps if the job retries or if
# buildx reuses them from the GHA cache backend).
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/root/.local/share/pnpm/store \
    set -e; \
    ARGS=""; \
    while IFS= read -r plugin || [ -n "$plugin" ]; do \
      plugin=$(echo "$plugin" | sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$//'); \
      [ -z "$plugin" ] && continue; \
      ARGS="$ARGS --with $plugin"; \
    done < /tmp/plugins.txt; \
    echo "Building with plugins: $ARGS"; \
    answer build $ARGS --output /usr/bin/new_answer

# ─── Stage 4: Minimal runtime image ─────────────────────────────────────────
FROM alpine

LABEL maintainer="tellmeY18"
LABEL org.opencontainers.image.source="https://github.com/tellmeY18/retire.nix"
LABEL org.opencontainers.image.description="Apache Answer with S3 storage + plugins"

ARG TIMEZONE
ENV TIMEZONE=${TIMEZONE:-"Asia/Kolkata"}

RUN apk update && apk --no-cache add \
    bash \
    ca-certificates \
    curl \
    dumb-init \
    gettext \
    openssh \
    sqlite \
    gnupg \
    tzdata \
    && ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    && rm -rf /var/cache/apk/*

COPY --from=golang-builder /usr/bin/new_answer /usr/bin/answer
COPY --from=answer-builder /data /data
COPY --from=answer-builder /entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

VOLUME /data
EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
