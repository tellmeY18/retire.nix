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
RUN apk add --no-cache git && \
    mkdir -p /var/lib/ghost/content/adapters/storage/object-store && \
    cd /tmp && \
    npm install https://github.com/CodeForAfrica/ghost-object-store-storage-adapter.git --omit=dev && \
    cp -r ./node_modules/ghost-object-store-storage-adapter/* /var/lib/ghost/content/adapters/storage/object-store/ && \
    rm -rf /tmp/node_modules /tmp/package-lock.json /tmp/package.json

# The adapter is now available as "object-store" in Ghost config.
