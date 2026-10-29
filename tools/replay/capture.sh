#!/bin/bash
# Capture a CS:S demo playback as a .t9 call stream (tools/trace capture mode) for tools/replay.
#   tools/replay/capture.sh <tag> <demo>      (<demo> = cstrike/<demo>.dem, e.g. a demo the owner recorded online)
# Env: SECS (default 30) seconds of playback after the map is loaded, then the game is stopped.
#      ARGS="+mat_hdr_level 2 ..." adds launch cvars (the owner's config.cfg is restored afterwards).
#      W, H (default 1920x1080) window size.
# Output: $CSS_HOME/cache/traces/<tag>/capture-<tag>.t9 (+ frames-<tag>.info.txt with the capture summary).
# Upstream's TF2 scenarios drove bots over RCON, which doesn't listen on this CS:S build: demos only.
# Safety: demo playback never connects anywhere; a "Connected to" a non-local address still kills the game.
set -u
cd "$(dirname "$0")/../.."; . scripts/_env.sh; CSS_TUNED=0 . scripts/_tuned.sh
tag=$1; demo=${2%.dem}
SECS=${SECS:-30}
G=$CSSDIR/$CSS_GAME
[ -f "$G/$demo.dem" ] || { echo "no demo $G/$demo.dem"; exit 2; }
R=$CSS_HOME/cache/traces/$tag; rm -rf "$R"; mkdir -p "$R"

for p in $(css_pids); do kill "$p"; done; while css_running; do sleep 1; done
ensure_steam || { echo "Steam did not log in"; exit 1; }
make -s trace
cp build/trace/d3d9.dll "$CSSDIR/d3d9.dll"; cp "$CSS_HOME/wine/share/dxvk/x86_64-windows/d3d9.dll" "$CSSDIR/d3d9_ref.dll"
cp "$G/cfg/config.cfg" "$R/config.cfg.orig"
trap 'rm -f "$CSSDIR/d3d9.dll" "$CSSDIR/d3d9_ref.dll"; cp "$R/config.cfg.orig" "$G/cfg/config.cfg"' EXIT
: > "$G/console.log"
win() { echo "Z:${1//\//\\}"; }
follow_session_sync   # msync must match Steam's wineserver, or the game exits silently
# started directly, not through css.sh: its leftover cleanup deletes d3d9.dll/d3d9_ref.dll when no game runs
( cd "$CSSDIR" && TF2MT_TRACE_MODE=capture TF2MT_TAG=$tag TF2MT_TRACE_DIR="$(win "$R")" \
  "$WINE" "$CSS_STUB" -steam -game "$CSS_GAME" -novid -insecure -condebug -windowed -noborder \
  -w "${W:-1920}" -h "${H:-1080}" +fps_max 60 ${ARGS:-} +playdemo "$demo" >"$R/wine.log" 2>&1 & )
for _ in $(seq 60); do css_running && break; sleep 1; done
( while css_running; do
    if grep -aE 'Connected to [0-9]' "$G/console.log" | grep -qvE '(127\.0\.0\.1|localhost|loopback)'; then
      echo "GUARD: non-local server connection — killing CS:S"; for p in $(css_pids); do kill -9 "$p"; done; exit 0
    fi
    sleep 1
  done ) &
for _ in $(seq 200); do grep -aq 'Playing demo from' "$G/console.log" && break; css_running || break; sleep 2; done
sleep "$SECS"
for p in $(css_pids); do kill "$p"; done
for _ in $(seq 30); do css_running || break; sleep 1; done
cp "$G/console.log" "$R/console.log"
grep -h "capture:" "$R"/frames-*.info.txt 2>/dev/null | tail -3
ls -la "$R"
