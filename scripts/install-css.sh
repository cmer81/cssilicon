#!/bin/bash
# Ask the running Steam (inside Wine) to install Counter-Strike: Source (appid 240). Opens Steam's install dialog.
. "$(dirname "$0")/_env.sh"
pgrep -f 'steam.exe' >/dev/null || { echo "Steam is not running — start it first (scripts/steam.sh --login)"; exit 1; }
cd "$STEAM_DIR" && "$WINE" steam.exe "steam://install/$CSS_APPID" >/dev/null 2>&1 &
disown; echo "requested CS:S install in Steam"
