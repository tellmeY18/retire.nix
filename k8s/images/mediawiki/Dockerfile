# MediaWiki with Caddy + PHP-FPM + extensions in a single container.
#
# Caddy serves static files and proxies PHP to FPM (localhost:9000).
# No Apache, no nginx sidecar, no shared volumes.
#
# Extensions are grouped by category. All from REL1_45 branch unless noted.
#
# BUNDLED with base image (DO NOT clone — already present):
#   AbuseFilter, CategoryTree, CheckUser, Cite, CiteThisPage,
#   CodeEditor, ConfirmEdit, DiscussionTools, Echo, Gadgets, ImageMap,
#   InputBox, Interwiki, Linter, LoginNotify, Math, MultimediaViewer,
#   Nuke, OATHAuth, PageImages, ParserFunctions, PdfHandler, Poem,
#   Renameuser, ReplaceText, Scribunto, SecureLinkFixer, SpamBlacklist,
#   SyntaxHighlight, TemplateData, TemplateStyles, TextExtracts, Thanks,
#   TitleBlacklist, VisualEditor, WikiEditor
#
# NOT bundled (must clone): CodeMirror, AdvancedSearch, and all custom ones
#
# Build:
#   docker build -t ghcr.io/tellmey18/mediawiki:latest .

FROM mediawiki:stable-fpm-alpine

# Install dependencies + nginx + PHP Redis extension
RUN apk add --no-cache git lua5.1 unzip curl nginx supervisor \
    autoconf gcc g++ make php83-dev \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del autoconf gcc g++ make php83-dev

# ─── Extensions: Content & Navigation ────────────────────────────────────────
RUN cd /var/www/html/extensions && \
    # Cargo — structured data storage & querying (master — no REL1_45 branch)
    git clone --depth 1 https://gerrit.wikimedia.org/r/mediawiki/extensions/Cargo && \
    # Disambiguator — mark and track disambiguation pages
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/Disambiguator && \
    # DisplayTitle — custom display titles for pages
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/DisplayTitle && \
    # BreadCrumbs2 — breadcrumb navigation from category hierarchy
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/BreadCrumbs2 && \
    # Description2 — meta descriptions for pages
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/Description2 && \
    # RelatedArticles — show related pages at the bottom
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/RelatedArticles && \
    # CollapsibleSections — make page sections collapsible
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/CollapsibleSections

# ─── Extensions: User Engagement & Social ────────────────────────────────────
RUN cd /var/www/html/extensions && \
    # AJAXPoll — inline polls on wiki pages
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/AJAXPoll && \
    # CommentStreams — threaded discussion comments on any page
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/CommentStreams && \
    # Comments — simple page comments
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/Comments && \
    # VoteNY — vote/rate pages
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/VoteNY && \
    # SocialProfile — user profile pages
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/SocialProfile && \
    # ContributionScores — leaderboard of top contributors
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/ContributionScores && \
    # BlogPage — blog-style pages
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/BlogPage && \
    # WhosOnline — show who's currently online
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/WhosOnline

# ─── Extensions: Content Quality & Moderation ────────────────────────────────
RUN cd /var/www/html/extensions && \
    # SmiteSpam — spam fighting tools
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/SmiteSpam && \
    # UserMerge — merge duplicate user accounts
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/UserMerge

# ─── Extensions: Visual & UX ─────────────────────────────────────────────
RUN cd /var/www/html/extensions && \
    # CodeMirror — syntax-highlighted source editor (NOT bundled in base image)
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/CodeMirror && \
    # AdvancedSearch — enhanced search UI with filters (NOT bundled in base image)
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/AdvancedSearch && \
    # DarkMode — dark theme toggle
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/DarkMode && \
    # Popups — page previews on hover
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/Popups && \
    # MobileFrontend — mobile-optimized interface
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileFrontend

# ─── Extensions: Media & Embeds ──────────────────────────────────────────────
RUN cd /var/www/html/extensions && \
    # EmbedVideo v3.x — embed YouTube, Vimeo, Twitch, etc.
    # Modern fork with MW 1.39+ support (replaces old hydrawiki v2.8)
    git clone --depth 1 https://github.com/StarCitizenTools/mediawiki-extensions-EmbedVideo.git EmbedVideo && \
    # RSS — embed RSS feeds
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/RSS && \
    # HitCounters — page view counts
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/HitCounters

# ─── Extensions: Analytics ───────────────────────────────────────────────────
RUN cd /var/www/html/extensions && \
    # PageViewInfo — show page view statistics
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/PageViewInfo

# ─── Extensions: S3 Storage ──────────────────────────────────────────
RUN cd /var/www/html/extensions && \
    # AWS — S3-compatible storage backend for file uploads
    git clone --depth 1 https://github.com/edwardspec/mediawiki-aws-s3.git AWS

# ─── Skins: Citizen ──────────────────────────────────────────────────
RUN cd /var/www/html/skins && \
    # Citizen — modern responsive skin with dark mode, command palette, etc.
    git clone --depth 1 https://github.com/StarCitizenTools/mediawiki-skins-Citizen.git Citizen

# ─── Extensions: Search (CirrusSearch + Elastica) ───────────────────────
RUN cd /var/www/html/extensions && \
    # Elastica — PHP client for Elasticsearch/OpenSearch (required by CirrusSearch)
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/Elastica && \
    # CirrusSearch — full-text search powered by OpenSearch
    git clone --depth 1 -b REL1_45 https://gerrit.wikimedia.org/r/mediawiki/extensions/CirrusSearch

# Install Composer for extensions that need it
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    cd /var/www/html/extensions/AWS && composer install --no-dev --no-interaction && \
    cd /var/www/html/extensions/Cargo && composer install --no-dev --no-interaction && \
    cd /var/www/html/extensions/Elastica && composer install --no-dev --no-interaction && \
    cd /var/www/html/extensions/CirrusSearch && composer install --no-dev --no-interaction

# ─── Semantic MediaWiki (7.0-dev, supports MW 1.45) ──────────────────
RUN cd /var/www/html && \
    chmod a+w . composer.json && \
    COMPOSER_ALLOW_SUPERUSER=1 composer require --no-interaction --update-no-dev mediawiki/semantic-media-wiki "~7.0"

# Lua for Scribunto
RUN ln -sf /usr/bin/lua5.1 /usr/bin/lua || true

# Fix PHP 8.3 compatibility: MediaWiki Rest\StringStream must match PSR-7
# StreamInterface return types (PHP 8.3 enforces these strictly).
# See: https://phabricator.wikimedia.org/T359753
RUN cd /var/www/html/includes/Rest && \
    sed -i 's/public function close() {/public function close(): void {/' StringStream.php && \
    sed -i 's/public function getSize() {/public function getSize(): ?int {/' StringStream.php && \
    sed -i 's/public function tell() {/public function tell(): int {/' StringStream.php && \
    sed -i 's/public function eof() {/public function eof(): bool {/' StringStream.php && \
    sed -i 's/public function isSeekable() {/public function isSeekable(): bool {/' StringStream.php && \
    sed -i 's/public function seek( \$offset, \$whence = SEEK_SET ) {/public function seek( int \$offset, int \$whence = SEEK_SET ): void {/' StringStream.php && \
    sed -i 's/public function rewind() {/public function rewind(): void {/' StringStream.php && \
    sed -i 's/public function isWritable() {/public function isWritable(): bool {/' StringStream.php && \
    sed -i 's/public function write( \$string ) {/public function write( string \$string ): int {/' StringStream.php && \
    sed -i 's/public function isReadable() {/public function isReadable(): bool {/' StringStream.php && \
    sed -i 's/public function read( \$length ) {/public function read( int \$length ): string {/' StringStream.php && \
    sed -i 's/public function getContents() {/public function getContents(): string {/' StringStream.php && \
    sed -i 's/public function __toString() {/public function __toString(): string {/' StringStream.php && \
    sed -i 's/public function detach() {/public function detach(): mixed {/' StringStream.php && \
    sed -i 's/public function getMetadata( \$key = null ) {/public function getMetadata( ?string \$key = null ): mixed {/' StringStream.php

# Fix PHP 8.3 compatibility: MWCallbackStream::write() must match PSR-7
# StreamInterface::write(string $string): int enforced by the Guzzle
# StreamDecoratorTrait. Without this, any outgoing HTTP request (e.g.
# InstantCommons fetches) triggers a fatal error.
RUN sed -i 's/public function write( \$string ) {/public function write( string \$string ): int {/' \
    /var/www/html/includes/http/MWCallbackStream.php

# Create a static health check file (served by Caddy, no PHP needed)
RUN echo 'OK' > /var/www/html/health.txt

# Kubernetes healthcheck — verifies PHP + MySQL + Redis in <100ms
COPY healthcheck.php /var/www/html/healthcheck.php

# Tune PHP-FPM for higher concurrency (default max_children=5 is too low)
RUN echo '[www]' > /usr/local/etc/php-fpm.d/zz-tuning.conf && \
    echo 'pm.max_children = 20' >> /usr/local/etc/php-fpm.d/zz-tuning.conf && \
    echo 'pm.start_servers = 5' >> /usr/local/etc/php-fpm.d/zz-tuning.conf && \
    echo 'pm.min_spare_servers = 3' >> /usr/local/etc/php-fpm.d/zz-tuning.conf && \
    echo 'pm.max_spare_servers = 10' >> /usr/local/etc/php-fpm.d/zz-tuning.conf && \
    echo 'request_terminate_timeout = 300' >> /usr/local/etc/php-fpm.d/zz-tuning.conf

# FOSSCELL NITC favicon/logo
COPY favicon.svg /var/www/html/favicon.svg

# nginx.conf — serves MediaWiki with php_fastcgi, proper PATH_INFO support
COPY nginx.conf /etc/nginx/nginx.conf

# Supervisord config — runs both nginx and PHP-FPM
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

[program:nginx]
command=nginx -g "daemon off;"
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

EXPOSE 80
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
