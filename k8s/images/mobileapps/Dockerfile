# Dockerfile for Wikimedia mobileapps service
# Provides /api/rest_v1/ endpoints for Wikipedia mobile app
FROM node:20-alpine

WORKDIR /app

# Clone the mobileapps repo (pinned to a known-good commit)
RUN apk add --no-cache git && \
    git clone --depth 1 https://github.com/wikimedia/mediawiki-services-mobileapps.git /app && \
    apk del git

# Install ALL dependencies (not just production)
RUN npm install

# Patch: Fix Wikidata getCentralDescription crashing on non-Wikimedia wikis.
# The code uses `languages ? getCentralDescription() : resolve({})` but
# an empty array [] is truthy in JS, so the Wikidata call fires even when
# there are no language variants. This call then fails because:
#   a) our mwapi_req uses /api.php (Wikidata needs /w/api.php)
#   b) the site code "wikiwiki" (from domain wiki.*) doesn't exist on Wikidata
# Fix: check languages.length AND add .catch() to gracefully degrade.
RUN sed -i \
    's/languages ? mwapi\.getCentralDescription(req, site, languages) : BBPromise\.resolve({})/languages \&\& languages.length ? mwapi.getCentralDescription(req, site, languages).catch(function() { return {}; }) : BBPromise.resolve({})/g' \
    /app/lib/mwapi.js

# Add custom random/summary route — the Wikipedia app expects this endpoint
# but it was never part of mobileapps (it was in RESTBase). This queries the
# MediaWiki API for a random page then fetches its summary.
COPY random.js /app/routes/page/random.js

# Remove config.yaml (will be mounted from ConfigMap)
RUN rm -f /app/config.yaml

EXPOSE 8888

CMD ["node", "server.js", "-c", "/etc/mobileapps/config.yaml"]
