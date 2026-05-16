# MediaWiki with Caddy + PHP-FPM in a single container.
#
# Caddy serves static files and proxies PHP to FPM (localhost:9000).
# No Apache, no nginx sidecar, no shared volumes.
#
# Build:
#   docker build -t ghcr.io/tellmey18/mediawiki:latest .

FROM mediawiki:stable-fpm-alpine

# Install dependencies + Caddy
RUN apk add --no-cache git lua5.1 unzip curl caddy supervisor

# Install only extensions NOT bundled in the base image.
RUN cd /var/www/html/extensions && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/DarkMode && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/RSS && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/ContributionScores && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/Comments && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/VoteNY && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/BlogPage && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/HitCounters && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/Popups && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileFrontend && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/Description2 && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/RelatedArticles && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/UserMerge && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/SocialProfile && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/UserExport && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/SmiteSpam && \
    git clone --depth 1 https://github.com/edwardspec/mediawiki-aws-s3.git AWS

# Install Composer for AWS extension
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    cd /var/www/html/extensions/AWS && composer install --no-dev --no-interaction

# Lua for Scribunto
RUN ln -sf /usr/bin/lua5.1 /usr/bin/lua || true

# Caddyfile — serves MediaWiki with php_fastcgi
RUN cat > /etc/caddy/Caddyfile <<'EOF'
:80 {
    root * /var/www/html
    file_server

    @php path *.php
    php_fastcgi @php 127.0.0.1:9000

    # Short URLs: /wiki/Article → index.php
    try_files {path} {path}/ /index.php?{query}

    # Block access to sensitive paths
    @blocked path /images/deleted/* /cache/* /includes/* /maintenance/*
    respond @blocked 403

    header /images/* X-Content-Type-Options nosniff
}
EOF

# Supervisord config — runs both Caddy and PHP-FPM
RUN cat > /etc/supervisord.conf <<'EOF'
[supervisord]
nodaemon=true
logfile=/dev/stdout
logfile_maxbytes=0

[program:php-fpm]
command=/usr/local/sbin/php-fpm -F
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:caddy]
command=caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

EXPOSE 80
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
