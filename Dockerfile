FROM alpine:3

# Optional: set default TZ to avoid log warnings. Override with -e TZ=...
ENV TZ=UTC

# Minimal tools only (no bash needed)
RUN apk add --no-cache coreutils tzdata

# Configurable defaults (can be overridden at runtime)
ENV WATCH_DIR=/watch
ENV POLL_INTERVAL=2
ENV PUID=0
ENV PGID=0
ENV INCLUDE_EXTS="sav,srm"    # comma-separated list; default libretro battery saves

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Volume mount where saves live
VOLUME ["/watch"]

# Run as root but we’ll drop to PUID:PGID inside the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]