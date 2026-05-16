# Ghost CMS with S3 Storage Adapter + custom themes.
#
# Based on ghost:6.25-alpine (matches source server version).
# - Installs colinmeinke/ghost-storage-adapter-s3 for direct S3 serving
# - Downloads custom themes from themes.txt URLs into content.orig
#
# Build:
#   docker build -t ghcr.io/tellmey18/ghost:latest .

FROM ghost:6.25-alpine

# Install the S3 storage adapter (colinmeinke/ghost-storage-adapter-s3).
# This adapter stores the full public S3 URL in the database so browsers
# fetch images directly from S3 — Ghost pod is never a proxy.
RUN mkdir -p /var/lib/ghost/versions/6.25.1/core/server/adapters/storage/s3 && \
    cd /var/lib/ghost/versions/6.25.1/core/server/adapters/storage/s3 && \
    npm init -y > /dev/null 2>&1 && \
    npm install ghost-storage-adapter-s3 --omit=dev && \
    cp -r node_modules/ghost-storage-adapter-s3/* . && \
    rm -rf node_modules/ghost-storage-adapter-s3

# Download and install custom themes from themes.txt.
# Themes go into content.orig/themes/ so the entrypoint copies them
# into /var/lib/ghost/content/themes/ on every container start.
COPY themes.txt /tmp/themes.txt
RUN apk add --no-cache curl && \
    set -e; \
    while IFS=' ' read -r url name || [ -n "$url" ]; do \
      url=$(echo "$url" | sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$//'); \
      [ -z "$url" ] && continue; \
      name=$(echo "$name" | sed 's/[[:space:]]*$//'); \
      echo "Downloading theme: $name from $url"; \
      mkdir -p "/var/lib/ghost/content.orig/themes/$name"; \
      curl -sSL "$url" | tar xz --strip-components=1 -C "/var/lib/ghost/content.orig/themes/$name"; \
    done < /tmp/themes.txt; \
    rm /tmp/themes.txt; \
    apk del curl; \
    echo "Themes installed:"; ls /var/lib/ghost/content.orig/themes/
