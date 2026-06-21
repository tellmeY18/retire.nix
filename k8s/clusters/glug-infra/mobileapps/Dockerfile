# Dockerfile for Wikimedia mobileapps service
# Provides /api/rest_v1/ endpoints for Wikipedia mobile app
FROM node:20-alpine

WORKDIR /app

# Clone the mobileapps repo
RUN apk add --no-cache git && \
    git clone --depth 1 https://github.com/wikimedia/mediawiki-services-mobileapps.git /app && \
    apk del git

# Install dependencies
RUN npm install --production

# Remove config.yaml (will be mounted from ConfigMap)
RUN rm -f /app/config.yaml

EXPOSE 8888

CMD ["node", "server.js", "-c", "/etc/mobileapps/config.yaml"]
