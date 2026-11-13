# syntax=docker/dockerfile:1
# The workflow resolves this mutable distro tag to its current digest daily.
ARG SELKIES_BASE=ghcr.io/linuxserver/baseimage-selkies:debiantrixie
FROM ${SELKIES_BASE}

ARG BRAVE_VERSION
ARG SELKIES_BASE_DIGEST=manual

LABEL org.opencontainers.image.title="brave-org" \
      org.opencontainers.image.description="Brave Origin on LinuxServer Selkies with persistent browser data" \
      org.opencontainers.image.source="https://github.com/MSPDaniel/brave-org" \
      org.opencontainers.image.base.digest="${SELKIES_BASE_DIGEST}" \
      io.github.mspdaniel.brave-org.brave-version="${BRAVE_VERSION}"

ENV TITLE="XOM" \
    PIXELFLUX_WAYLAND="false" \
    NO_DECOR="true" \
    LC_ALL="C.UTF-8" \
    LANG="C.UTF-8"

# Stable Brave Origin from the officially signed Brave APT repository.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl fonts-noto-core tint2; \
    curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
      https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg; \
    curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
      https://brave-browser-apt-release.s3.brave.com/brave-browser.sources; \
    apt-get update; \
    if [ -n "${BRAVE_VERSION}" ]; then \
      apt-get install -y --no-install-recommends "brave-origin=${BRAVE_VERSION}"; \
    else \
      apt-get install -y --no-install-recommends brave-origin; \
    fi; \
    apt-get install -y --no-install-recommends librsvg2-bin; \
    mkdir -p /usr/share/selkies/www; \
    curl -fsSL --retry 3 \
      https://cdn.jsdelivr.net/npm/simple-icons@v15/icons/brave.svg \
      -o /tmp/brave-monochrome.svg; \
    rsvg-convert --background-color=white -w 256 -h 256 \
      /tmp/brave-monochrome.svg -o /usr/share/selkies/www/icon.png; \
    test -s /usr/share/selkies/www/icon.png; \
    apt-get purge -y --auto-remove librsvg2-bin; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY root/ /
RUN chmod 755 /defaults/autostart /defaults/autostart_wayland /usr/local/bin/start-brave-org
EXPOSE 3000 3001
VOLUME /config
