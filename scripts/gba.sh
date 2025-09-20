# scripts/gba.sh  (MiSTer .sav <-> RetroArch .srm)
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXT_A=sav EXT_B=srm SAVE_DIR="${SAVE_DIR:-/path/to/GBA/saves}" \
  "$SCRIPT_DIR/sram-sync.sh"