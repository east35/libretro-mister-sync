#!/bin/sh
set -eu

# Env:
#   WATCH_DIR      : directory to watch (mounted volume)
#   POLL_INTERVAL  : seconds between scans
#   PUID, PGID     : run the loop as this user/group
#   INCLUDE_EXTS   : comma-separated list of extensions (case-insensitive), e.g. "sav,srm"
#
# Behavior:
#   - Top-level only (no recursion)
#   - Ignores dotfiles, .syncthing*, *.tmp*
#   - Mirrors sav <-> srm using copy-if-newer and preserves mtime
#   - Creates files with 664 perms, honors PUID/PGID ownership

WATCH_DIR="${WATCH_DIR:-/watch}"
POLL_INTERVAL="${POLL_INTERVAL:-2}"
PUID="${PUID:-0}"
PGID="${PGID:-0}"
INCLUDE_EXTS="${INCLUDE_EXTS:-sav,srm}"

# Ensure group & user exist for chown (when PUID/PGID set)
if [ "$PGID" -ne 0 ] && ! getent group "$PGID" >/dev/null 2>&1; then
  addgroup -g "$PGID" syncgroup
fi
if [ "$PUID" -ne 0 ] && ! getent passwd "$PUID" >/dev/null 2>&1; then
  adduser -D -H -u "$PUID" -G "$(getent group "$PGID" | cut -d: -f1 || echo root)" syncuser
fi

run_as() {
  # Run the given command as PUID:PGID if specified, else as current user
  if [ "$PUID" -ne 0 ] || [ "$PGID" -ne 0 ]; then
    # chown once so subsequent files match ownership
    chown -R "$PUID":"$PGID" "$WATCH_DIR" 2>/dev/null || true
    su -s /bin/sh -c "$*" "$(getent passwd "$PUID" | cut -d: -f1)"
  else
    sh -c "$*"
  fi
}

# Build a case-insensitive match list from INCLUDE_EXTS
# e.g. "sav,srm" -> regex: \.(sav|srm)$
INC_REGEX="\.( $(printf '%s' "$INCLUDE_EXTS" | tr '[:upper:], ' '[:lower:]|' ) )$"
INC_REGEX="$(printf '%s' "$INC_REGEX" | tr -d ' ')"

echo "[sync] WATCH_DIR=${WATCH_DIR} POLL_INTERVAL=${POLL_INTERVAL}s EXTENSIONS=${INCLUDE_EXTS} PUID=${PUID} PGID=${PGID}"

# Main loop runs as requested user/group
run_as '
  umask 0002
  while :; do
    for f in '"$WATCH_DIR"'/*; do
      [ -f "$f" ] || continue
      n="${f##*/}"

      # ignore hidden & temp/syncthing artifacts
      case "$n" in
        .*|*.syncthing*|*.tmp|*.tmp.*) continue;;
      esac

      # filter by extensions
      lname=$(printf "%s" "$n" | tr A-Z a-z)
      case "$lname" in
        *'"$INC_REGEX"') ;;
        *) continue;;
      esac

      base="${f%.*}"
      ext="${lname##*.}"

      cpnew() {
        src="$1"; dst="$2"
        if [ ! -f "$dst" ] || [ "$src" -nt "$dst" ]; then
          cp -f -p "$src" "$dst"
          touch -r "$src" "$dst"
          chmod 664 "$dst" 2>/dev/null || true
          echo "[sync] $(date) wrote $(basename "$dst") from $(basename "$src")"
        fi
      }

      if [ "$ext" = "sav" ]; then
        cpnew "$f" "${base}.srm"
      elif [ "$ext" = "srm" ]; then
        cpnew "$f" "${base}.sav"
      fi
    done
    sleep '"$POLL_INTERVAL"'
  done
'