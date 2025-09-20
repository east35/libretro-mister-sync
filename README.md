# libretro-mister-sync (battery save mirroring)

Tiny Docker container that keeps **`.sav`** and **`.srm`** files in sync within a folder:
- If `<game>.sav` changes → write/update `<game>.srm`
- If `<game>.srm` changes → write/update `<game>.sav`

It preserves timestamps to avoid ping-pong loops and ignores Syncthing temps/hidden files.

Supported consoles that use the same SAV↔SRM battery-save schema: 
- Game Boy / Game Boy Color / Game Boy Advance
- SNES (Super Nintendo)
- Genesis / Mega Drive
- Neo Geo Pocket / WonderSwan
- PC Engine / TurboGrafx-16

---

## Quick start (docker run)

```bash
docker run -d \
  --name gba-sync-poller \
  --restart unless-stopped \
  -e PUID=1026 -e PGID=100 \        # <- your NAS user/group (optional but recommended)
  -e WATCH_DIR=/watch \
  -e POLL_INTERVAL=2 \
  -e INCLUDE_EXTS="sav,srm" \
  -v /path/to/your/saves:/watch \
  ghcr.io/<youruser>/gba-srm-sync:latest

