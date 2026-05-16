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

# Install only extensions NOT bundled in the base mediawiki image.
# The base image already includes: AbuseFilter, Cite, CiteThisPage, ConfirmEdit,
# Nuke, ParserFunctions, Scribunto, SpamBlacklist, TemplateStyles, TextExtracts,
# PageImages, CategoryTree, Elastica, CirrusSearch, MobileFrontend, etc.
# We only add the ones that are missing.
RUN cd /var/www/html/extensions && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/DarkMode && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/RSS && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/ContributionScores && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/Comments && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/VoteNY && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/BlogPage && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/HitCounters && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/Popups && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/Description2 && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/RelatedArticles && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/UserMerge && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/SocialProfile && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/UserExport && \
    git clone --depth 1 -b REL1_42 https://gerrit.wikimedia.org/r/mediawiki/extensions/SmiteSpam && \
    git clone --depth 1 https://github.com/edwardspec/mediawiki-aws-s3.git AWS

# Install Composer dependencies for the AWS S3 extension
RUN cd /var/www/html/extensions/AWS && composer install --no-dev --no-interaction

# Scribunto needs lua binary
RUN ln -sf /usr/bin/lua5.1 /usr/bin/lua
