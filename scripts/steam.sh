#!/bin/bash
# start the Steam client inside the cssmt Wine prefix (required before launching CS:S)
#   scripts/steam.sh            background (no window) — normal use
#   scripts/steam.sh --login    with window — first login / account changes
#   scripts/steam.sh --show     open the running client's main window (launcher "Show Steam")
. "$(dirname "$0")/_env.sh"; . "$(dirname "$0")/_tuned.sh"; cd "$STEAM_DIR" || exit 1
mkdir -p "$CSS_HOME/logs"
if [ "${1:-}" = --show ]; then   # launcher "Show Steam": bring up the running client's main window
  steam_running || { echo "steam is not running"; exit 1; }
  follow_session_sync; "$WINE" steam.exe steam://open/main >/dev/null 2>&1; exit 0
fi
# leftovers of a crashed session (orphans of a dead wineserver) stop a new session from starting: sweep first
"$CSSMT_ROOT/scripts/wine-sweep.sh" >> "$CSS_HOME/logs/session.log" 2>&1
[ -n "$(wineserver_pid)" ] || { mkdir -p "$CSS_HOME/cache"; [ "${WINEMSYNC:-0}" = 1 ] && echo msync > "$CSS_SESSION_SYNC" || echo none > "$CSS_SESSION_SYNC"; }
follow_session_sync
silent=-silent; [ "${1:-}" = --login ] && silent=
mkdir -p "$CSS_HOME/logs"; "$WINE" steam.exe $silent -no-cef-sandbox >"$CSS_HOME/logs/steam.log" 2>&1 &
disown
echo "steam started (log: $CSS_HOME/logs/steam.log)"
