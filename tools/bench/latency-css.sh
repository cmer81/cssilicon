#!/bin/bash
# Frame start -> on screen latency and pacing on CS:S (design phase 4): plays a demo fullscreen on the Metal renderer
# with vsync, once per variant, in a fresh game process. The display is switched for the runs and restored afterwards.
#   tools/bench/latency-css.sh <demo>      (cstrike/<demo>.dem)
# Env: VARIANTS (default "base drain base drain"): base = renderer defaults, drain = TF2MT_DRAIN=1 (docs/mouse-input.md).
#      MODE (default "1920 1080 120"): display size and refresh rate for the runs.
# Output: $CSS_HOME/logs/lat-<n>-<variant>/ (unix.log with "latency:" lines, latency.csv, frames.csv);
#         summary: python3 tools/bench/latency-summary.py <dirs...>
# Demo playback only: nothing connects anywhere. The game's config.cfg is restored after each run.
set -u
cd "$(dirname "$0")/../.."; . scripts/_env.sh
demo=${1%.dem}; G=$CSSDIR/$CSS_GAME
[ -f "$G/$demo.dem" ] || { echo "no demo $G/$demo.dem"; exit 2; }
read -r w h hz <<< "${MODE:-1920 1080 120}"
DM=build/tools/displaymode; mkdir -p "$CSS_HOME/run"; state="$CSS_HOME/run/display-latency"
if [ -x build/tools/displaystate ] && ! build/tools/displaystate >/dev/null 2>&1; then echo "display asleep/locked"; exit 1; fi
caffeinate -d -w $$ &
make -s frontend unixlib
for p in $(css_pids); do kill "$p"; done; while css_running; do sleep 1; done
ensure_steam || { echo "Steam did not log in"; exit 1; }
cp "$G/cfg/config.cfg" "$CSS_HOME/run/config.cfg.latency"
"$DM" set "$state" "$hz" "$w" "$h" || { echo "display mode ${w}x${h}@${hz} not available"; exit 1; }
trap '"$DM" restore "$state"; cp "$CSS_HOME/run/config.cfg.latency" "$G/cfg/config.cfg"' EXIT
n=0
for v in ${VARIANTS:-base drain base drain}; do
  n=$((n + 1)); out="$CSS_HOME/logs/lat-$n-$v"; rm -rf "$out"
  case $v in base) drain=0 ;; drain) drain=1 ;; *) echo "unknown variant $v"; continue ;; esac
  echo "=== $n $v $(date +%H:%M:%S)"
  : > "$G/console.log"
  before=$(ls -t "$CSS_HOME/logs/tf2mt" 2>/dev/null | head -1)
  CSS_TUNED=0 CSS_RENDERER=tf2mt TF2MT_LATENCY_LOG=1 TF2MT_DRAIN=$drain \
    scripts/css.sh -insecure -condebug +demo_quitafterplayback 1 +playdemo "$demo" >/dev/null
  for _ in $(seq 60); do css_running && break; sleep 1; done
  for _ in $(seq 450); do css_running || break; sleep 2; done   # the demo quits the game when it ends
  css_running && { echo "still running after 15 min: stopping"; for p in $(css_pids); do kill "$p"; done; sleep 5; }
  cp "$CSS_HOME/run/config.cfg.latency" "$G/cfg/config.cfg"
  sess=$(ls -t "$CSS_HOME/logs/tf2mt" | head -1)
  [ "$sess" = "$before" ] && { echo "no new tf2mt session (renderer not used?)"; continue; }
  cp -R "$CSS_HOME/logs/tf2mt/$sess" "$out"; cp "$G/console.log" "$out/console.log"
  grep -h '^latency:' "$out/unix.log" | tail -1 | cut -c1-200
  sleep 5
done
