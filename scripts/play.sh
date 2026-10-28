#!/bin/bash
# One-click launch (used by cssmt.app): Steam if needed (waits for login), then CS:S.
. "$(dirname "$0")/_env.sh"
# progress goes to the terminal too: macOS notifications can be off for the app running this script
notify() { echo "$1"; osascript -e "display notification \"$1\" with title \"Counter-Strike: Source\"" >/dev/null 2>&1; }
if css_running; then notify "CS:S is already running."; exit 0; fi
RUN="$CSS_HOME/run"; mkdir -p "$RUN"
# a session that is still shutting down (quit + Play right away) must finish first, or it would close our Steam
for _ in $(seq 45); do p=$(cat "$RUN/teardown.lock/pid" 2>/dev/null); [ -n "$p" ] && kill -0 "$p" 2>/dev/null || break; sleep 1; done
# display: first put back a mode an earlier session left behind (crash, Mac asleep), then 120 Hz for this session
# (launcher option CSS_DISPLAY_120, default on); session-end.sh restores it. CSS_DISPLAY120 overrides the tool (tests).
D120="${CSS_DISPLAY120:-$CSSMT_ROOT/build/tools/display120}"
if [ -x "$D120" ]; then
  mkdir -p "$CSS_HOME/logs"
  "$D120" restore "$RUN/display-before" >> "$CSS_HOME/logs/session.log" 2>&1
  [ "${CSS_DISPLAY_120:-1}" = 1 ] && "$D120" set "$RUN/display-before" >> "$CSS_HOME/logs/session.log" 2>&1
fi
[ "${CSS_DRY_RUN:-0}" = 1 ] && exit 0   # tests: stop before Steam and the game
echo $$ > "$RUN/launch-pending"; trap 'rm -f "$RUN/launch-pending"' EXIT   # tells session-helper.sh a launch is in progress
if ! steam_running; then
  n=$(wc -l < "$STEAM_DIR/logs/connection_log.txt" 2>/dev/null || echo 0)
  notify "Starting Steam… (waiting for it to log on, up to a minute)"
  # game-only options (Metal HUD, DXVK config) must not leak into the Steam client session
  env -u MTL_HUD_ENABLED -u DXVK_CONFIG_FILE "$CSSMT_ROOT/scripts/steam.sh" >/dev/null
  # a game started before Steam has logged on runs -insecure and crashes during load: wait for a fresh "Logged On"
  for _ in $(seq 120); do
    tail -n +$((n + 1)) "$STEAM_DIR/logs/connection_log.txt" 2>/dev/null | grep -q 'Logged On' && break
    sleep 2
  done
  tail -n +$((n + 1)) "$STEAM_DIR/logs/connection_log.txt" 2>/dev/null | grep -q 'Logged On' \
    || { notify "Steam did not log in within 4 minutes — open the Steam window to check."; exit 1; }
  sleep 5
fi
echo "Steam is logged on; starting CS:S…"
"$CSSMT_ROOT/scripts/css.sh" "$@"
for _ in $(seq 60); do css_running && exit 0; sleep 1; done
notify "CS:S did not start — see $CSS_HOME/logs/css.log"; exit 1
