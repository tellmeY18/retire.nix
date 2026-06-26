# Dockerfile for Wikimedia wikifeeds service
# Provides /api/rest_v1/feed/ endpoints for Wikipedia mobile app
FROM node:20-alpine

WORKDIR /app

# Clone the fosscell branch of our fork — contains patches to support
# wiki.fosscell.org as a non-Wikimedia wiki domain.
# To sync with upstream: rebase fosscell on upstream/master and push.
# The patches are documented in scripts/fosscell-patches.js.
RUN apk add --no-cache git && \
    git clone --depth 1 -b fosscell https://github.com/tellmeY18/mediawiki-services-wikifeeds.git /app && \
    apk del git

# Install ALL dependencies (not just production)
RUN npm install

# Remove config.yaml (will be mounted from ConfigMap)
RUN rm -f /app/config.yaml

EXPOSE 8889

CMD ["node", "server.js", "-c", "/etc/wikifeeds/config.yaml"]
