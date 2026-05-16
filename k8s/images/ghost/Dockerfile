# Ghost CMS with Object Store Storage Adapter + custom themes.
#
# Based on ghost:6.25-alpine (matches source server version).
# - Installs CodeForAfrica ghost-object-store-storage-adapter for S3/RustFS
# - Downloads custom themes from themes.txt URLs into content.orig
#
# Build:
#   docker build -t ghcr.io/tellmey18/ghost:latest .

FROM ghost:6.25-alpine

# Install git (for npm GitHub installs) + curl (for theme downloads).
# Install the S3 storage adapter into the Ghost version's adapters directory
# (not /content/ which gets overwritten by the Docker entrypoint on every start).
RUN apk add --no-cache git curl && \
    cd /tmp && \
    npm install https://github.com/CodeForAfrica/ghost-object-store-storage-adapter.git --omit=dev && \
    mkdir -p /var/lib/ghost/versions/6.25.1/core/server/adapters/storage/object-store && \
    cp -r ./node_modules/ghost-object-store-storage-adapter/* /var/lib/ghost/versions/6.25.1/core/server/adapters/storage/object-store/ && \
    rm -rf /tmp/node_modules /tmp/package-lock.json /tmp/package.json

# Download and install custom themes from themes.txt.
# Format: <url> <theme-name> (one per line, # comments ignored)
# Themes go into content.orig/themes/ so the entrypoint copies them
# into /var/lib/ghost/content/themes/ on every container start.
COPY themes.txt /tmp/themes.txt
RUN set -e; \
    while IFS=' ' read -r url name || [ -n "$url" ]; do \
      url=$(echo "$url" | sed 's/#.*//;s/^[[:space:]]*//;s/[[:space:]]*$//'); \
      [ -z "$url" ] && continue; \
      name=$(echo "$name" | sed 's/[[:space:]]*$//'); \
      echo "Downloading theme: $name from $url"; \
      mkdir -p "/var/lib/ghost/content.orig/themes/$name"; \
      curl -sSL "$url" | tar xz --strip-components=1 -C "/var/lib/ghost/content.orig/themes/$name"; \
    done < /tmp/themes.txt; \
    rm /tmp/themes.txt; \
    echo "Themes installed:"; ls /var/lib/ghost/content.orig/themes/
