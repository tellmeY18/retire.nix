# MediaWiki with extensions baked in.
#
# Based on mediawiki:stable-fpm-alpine (matches production).
# Extensions are installed via Composer + git clone at build time.
#
# Build:
#   docker build -t ghcr.io/tellmey18/mediawiki:latest .

FROM mediawiki:stable-fpm-alpine

# Install dependencies for extensions
RUN apk add --no-cache git lua5.1 lua5.1-dev unzip

# Install extensions that are actively used
# (list derived from LocalSettings.php wfLoadExtension calls)
RUN cd /var/www/html/extensions && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/AbuseFilter && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/ConfirmEdit && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/SpamBlacklist && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/DarkMode && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/RSS && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/ContributionScores && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/Comments && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/VoteNY && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/BlogPage && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/HitCounters && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/Popups && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/TextExtracts && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileFrontend && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/Cite && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/CiteThisPage && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/Scribunto && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/TemplateStyles && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/ParserFunctions && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/Description2 && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/PageImages && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/RelatedArticles && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/Elastica && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/CirrusSearch && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/Nuke && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/UserMerge && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/SocialProfile && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/UserExport && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/AWS

# Install Composer dependencies for extensions that need them
RUN cd /var/www/html/extensions/Elastica && composer install --no-dev --no-interaction && \
    cd /var/www/html/extensions/AWS && composer install --no-dev --no-interaction

# Scribunto needs lua binary
RUN ln -sf /usr/bin/lua5.1 /usr/bin/lua
