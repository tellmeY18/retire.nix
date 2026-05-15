# Apache Answer with plugins — multi-stage build.
#
# Plugins are compiled into the binary at build time (Go static linking).
# To add/remove plugins, edit `plugins.txt` and re-run the workflow.
#
# Build:
#   docker build -t ghcr.io/tellmey18/answer:latest .
#
# Based on the official plugin build pattern from:
#   https://answer.apache.org/docs/plugins

FROM apache/answer AS answer-builder

FROM golang:1.23-alpine AS golang-builder

COPY --from=answer-builder /usr/bin/answer /usr/bin/answer

RUN apk --no-cache add \
  build-base git bash nodejs npm go && \
  npm install -g pnpm@10.7.0

# Copy the plugin list and build with all listed plugins.
COPY plugins.txt /tmp/plugins.txt

# Build the answer binary with all plugins from the list.
# Each line in plugins.txt is a --with argument.
# Cache Go modules + pnpm store for faster rebuilds.
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

# Final minimal image.
FROM alpine

LABEL maintainer="tellmeY18"
LABEL org.opencontainers.image.source="https://github.com/tellmeY18/retire.nix"
LABEL org.opencontainers.image.description="Apache Answer with S3 storage + plugins"

ARG TIMEZONE
ENV TIMEZONE=${TIMEZONE:-"Asia/Kolkata"}

RUN apk update \
  && apk --no-cache add \
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
  && echo "${TIMEZONE}" > /etc/timezone

COPY --from=golang-builder /usr/bin/new_answer /usr/bin/answer
COPY --from=answer-builder /data /data
COPY --from=answer-builder /entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

VOLUME /data
EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
