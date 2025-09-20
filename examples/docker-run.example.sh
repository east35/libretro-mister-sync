#!/usr/bin/env sh
docker run -d \
  --name gba-sync-poller \
  --restart unless-stopped \
  -e PUID=1026 -e PGID=100 \
  -e WATCH_DIR=/watch \
  -e POLL_INTERVAL=2 \
  -e INCLUDE_EXTS="sav,srm" \
  -v /volume1/MiSTer/saves/GBA:/watch \
  ghcr.io/<youruser>/gba-srm-sync:latest