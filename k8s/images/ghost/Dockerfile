# Ghost CMS with Object Store Storage Adapter.
#
# Based on ghost:5-alpine (same version as the source server).
# Installs the CodeForAfrica ghost-object-store-storage-adapter
# for S3-compatible storage (RustFS).
#
# Build:
#   docker build -t ghcr.io/tellmey18/ghost:latest .

FROM ghost:6.25-alpine

# Install git (needed for npm to clone from GitHub) + the S3 storage adapter.
# Install into the Ghost version's adapters directory (not /content/ which
# gets overwritten by the Docker entrypoint on every start).
RUN apk add --no-cache git && \
    cd /tmp && \
    npm install https://github.com/CodeForAfrica/ghost-object-store-storage-adapter.git --omit=dev && \
    mkdir -p /var/lib/ghost/versions/6.25.1/core/server/adapters/storage/object-store && \
    cp -r ./node_modules/ghost-object-store-storage-adapter/* /var/lib/ghost/versions/6.25.1/core/server/adapters/storage/object-store/ && \
    rm -rf /tmp/node_modules /tmp/package-lock.json /tmp/package.json

# Bake custom themes into the content.orig directory so the entrypoint
# copies them into /var/lib/ghost/content/themes/ on every start.
COPY themes/ /var/lib/ghost/content.orig/themes/

# The adapter is now available as "object-store" in Ghost config.
