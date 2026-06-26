# Dockerfile for Wikimedia wikifeeds service
# Provides /api/rest_v1/feed/ endpoints for Wikipedia mobile app
FROM node:20-alpine

WORKDIR /app

# Clone the fosscell branch of our fork — contains patches to support
# wiki.fosscell.org as a non-Wikimedia wiki domain.
# Pin to a specific commit so the layer cache is naturally invalidated
# when updating to a newer commit. To update: change WIKIFEEDS_COMMIT.
ARG WIKIFEEDS_COMMIT=9f60cd8
RUN apk add --no-cache git && \
    git clone https://github.com/tellmeY18/mediawiki-services-wikifeeds.git /app && \
    git -C /app checkout "${WIKIFEEDS_COMMIT}" && \
    apk del git

# Install ALL dependencies (not just production)
RUN npm install

# Remove config.yaml (will be mounted from ConfigMap)
RUN rm -f /app/config.yaml

EXPOSE 8889

CMD ["node", "server.js", "-c", "/etc/wikifeeds/config.yaml"]
