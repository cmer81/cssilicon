#!/bin/bash
# launch CS:S (64-bit) via its stub; extra args are passed through
. "$(dirname "$0")/_env.sh"; . "$(dirname "$0")/_tuned.sh"; cd "$CSSDIR" || exit 1
mkdir -p "$CSS_HOME/logs"
follow_session_sync

# Steam Friends offline while the game runs (upstream docs/loadout-stall.md: TF2's main-menu friends panel re-queried
# all friends over Steam IPC on every friend status change -> 2-4 fps in menus under Wine). Off by default for CS:S:
# opt in with CSS_FRIENDS_ONLINE=0 if menus stall the same way. Skipped for benchmark runs (CSS_TUNED=0).
steam_url() { (cd "$STEAM_DIR" && "$WINE" steam.exe "$1" >/dev/null 2>&1); }
friends_offline=0
if [ "${CSS_FRIENDS_ONLINE:-1}" != 1 ] && [ "${CSS_TUNED:-1}" = 1 ] && pgrep -f steamwebhelper >/dev/null; then
  steam_url steam://friends/status/offline; friends_offline=1
  mkdir -p "$CSS_HOME/run"; touch "$CSS_HOME/run/friends-offline"   # session-end.sh restores it
  sleep 5   # let the status flip settle before the game starts listening
fi

# Renderer: CSS_RENDERER=tf2mt runs the game on the tf2mt Metal renderer instead of DXVK. The layer is installed
# for this session only and removed when the game exits (also after a crash), so DXVK is always back afterwards.
# Runs VAC-secured like DXVK.
renderer=${CSS_RENDERER:-dxvk}
# leftovers from a session that ended without cleanup (e.g. the Mac shut down mid-game) would break the next one
css_running || { "$CSSMT_ROOT/scripts/layer-uninstall.sh" >/dev/null 2>&1; rm -f "$CSSDIR/d3d9_ref.dll"; }
# Frame-time recording on DXVK (CSS_FRAMELOG=1): the timing proxy (tools/trace, Phase 0 benchmarks) wraps DXVK for
# this session and is removed on exit. Output: $CSS_HOME/logs/dxvk/<timestamp>/frames-session.csv
if [ "$renderer" = dxvk ] && [ "${CSS_FRAMELOG:-0}" = 1 ] && [ -f "$CSSMT_ROOT/build/trace/d3d9.dll" ]; then
  sess="$CSS_HOME/logs/dxvk/$(date +%Y%m%d-%H%M%S)"; mkdir -p "$sess"
  cp "$CSSMT_ROOT/build/trace/d3d9.dll" "$CSSDIR/d3d9.dll"
  cp "$CSS_HOME/wine/share/dxvk/x86_64-windows/d3d9.dll" "$CSSDIR/d3d9_ref.dll"
  export TF2MT_TRACE_DIR="Z:${sess//\//\\}" TF2MT_TAG=session
  "$CSSMT_ROOT/scripts/presets.sh" status > "$sess/preset.txt" 2>/dev/null
  renderer=dxvk-logged
fi
if [ "$renderer" = tf2mt ]; then
  if "$CSSMT_ROOT/scripts/layer-install.sh" >/dev/null 2>&1; then
    sess="$CSS_HOME/logs/tf2mt/$(date +%Y%m%d-%H%M%S)"; mkdir -p "$sess"
    ls -dt "$CSS_HOME/logs/tf2mt"/*/ 2>/dev/null | tail -n +6 | xargs rm -rf 2>/dev/null   # keep the last 5 sessions
    export TF2MT_UNIX_LOG="$sess/unix.log" TF2MT_TRACE_DIR="Z:${sess//\//\\}" TF2MT_TAG=session
    export TF2MT_FRAME_LOG="Z:${sess//\//\\}\\frames.csv"   # per-frame times (tools/bench/session_report.py)
    # per-frame start / display / camera timing (docs/mouse-input.md); ~30 MB per hour, so opt-in
    { [ "${TF2MT_LATENCY_LOG:-0}" = 1 ] || [ -f "$CSS_HOME/config/latency-log" ]; } && export TF2MT_LATENCY_CSV="$sess/latency.csv"
    "$CSSMT_ROOT/scripts/presets.sh" status > "$sess/preset.txt" 2>/dev/null
  else
    echo "tf2mt layer not available (build it: make frontend unixlib) — starting with DXVK"; renderer=dxvk
  fi
fi

# Microphone (launcher setting, CSS_MIC_UID = CoreAudio device UID; empty = the Mac's default input). Wine follows the
# macOS default input unless winecoreaudio.drv's DefaultInput / DefaultVoiceInput name an endpoint
# ("{0.0.1.00000000}.{GUID}", Wine 10 mmdevapi/devenum.c). A capture device's GUID lives under devices\1,<UID>
# (winecoreaudio.drv/mmdevdrv.c get_device_guid): reuse Wine's if it has one, else write a stable one derived from the
# UID. An unplugged device falls back to the Mac default. Only written when the choice changes.
apply_mic() {
  local uid="${CSS_MIC_UID:-}" stamp="$CSS_HOME/config/mic-applied" reg="$CSS_HOME/run/mic.reg"
  local drv='HKEY_CURRENT_USER\Software\Wine\Drivers\winecoreaudio.drv'
  [ -f "$stamp" ] && [ "$(cat "$stamp")" = "$uid" ] && return 0
  mkdir -p "$CSS_HOME/run" "$CSS_HOME/config"
  if [ -z "$uid" ]; then
    printf 'REGEDIT4\n\n[%s]\n"DefaultInput"=-\n"DefaultVoiceInput"=-\n' "$drv" > "$reg"
  else
    local hex b id
    hex=$(grep -F -A3 "[Software\\\\Wine\\\\Drivers\\\\winecoreaudio.drv\\\\devices\\\\1,$uid]" "$WINEPREFIX/user.reg" 2>/dev/null |
          grep -oE '"guid"=hex:[0-9a-f,]{47}' | head -1 | sed 's/.*hex://' | tr -d ,)
    [ ${#hex} = 32 ] || hex=$(printf 'tf2mt-mic:%s' "$uid" | md5 -q)
    b=$(echo "$hex" | sed 's/../& /g')
    set -- $b   # GUID struct bytes: Data1-3 little-endian, Data4 as is
    id=$(printf '{0.0.1.00000000}.{%s%s%s%s-%s%s-%s%s-%s%s-%s%s%s%s%s%s}' $4 $3 $2 $1 $6 $5 $8 $7 $9 ${10} ${11} ${12} ${13} ${14} ${15} ${16} | tr a-f A-F)
    printf 'REGEDIT4\n\n[%s\\devices\\1,%s]\n"guid"=hex:%s\n\n[%s]\n"DefaultInput"="%s"\n"DefaultVoiceInput"="%s"\n' \
      "$drv" "$uid" "$(echo "$hex" | sed 's/../&,/g; s/,$//')" "$drv" "$id" "$id" > "$reg"
  fi
  "$WINE" regedit /S "Z:${reg//\//\\}" >/dev/null 2>&1 && printf '%s' "$uid" > "$stamp"
  rm -f "$reg"
}
[ "${CSS_TUNED:-1}" = 1 ] && apply_mic

# graphics preset: Balanced once on a brand-new install (scripts/presets.sh); never for benchmark runs
[ "${CSS_TUNED:-1}" = 1 ] && "$CSSMT_ROOT/scripts/presets.sh" auto >/dev/null 2>&1

# game window: 2560x1440 by default (the M1 can't drive the 5K backing store at 120 fps)
game_args=(-novid -nojoy -nosteamcontroller -nohltv -w "${CSS_WIDTH:-2560}" -h "${CSS_HEIGHT:-1440}")

# Steam overlay (launcher setting, CSS_STEAM_OVERLAY=1, DXVK only): Steam only injects its overlay into games it starts
# itself, and the in-game store needs the overlay to confirm purchases. The game then inherits Steam's environment
# instead of this script's (DXVK pacing config and frame-time recording don't apply). Not on the Metal renderer: the
# overlay only detects a d3d9.dll in system32, and hooked into tf2mt it blanked the menu background (2026-10-12).
if [ "${CSS_STEAM_OVERLAY:-0}" = 1 ] && [ "$renderer" = dxvk ]; then
  ( cd "$STEAM_DIR" && "$WINE" steam.exe -applaunch "$CSS_APPID" "${game_args[@]}" "$@" ) >"$CSS_HOME/logs/css.log" 2>&1 &
else
  "$WINE" "$CSS_STUB" -steam -game "$CSS_GAME" "${game_args[@]}" "$@" >"$CSS_HOME/logs/css.log" 2>&1 &
fi
disown

if [ "$renderer" = dxvk-logged ]; then   # remove the timing proxy when the game is gone
  ( for _ in $(seq 120); do css_running && break; sleep 1; done
    while css_running; do sleep 5; done
    rm -f "$CSSDIR/d3d9.dll" "$CSSDIR/d3d9_ref.dll" ) >/dev/null 2>&1 &
  disown
  echo "renderer: DXVK with frame-time recording; logs: $sess"
fi
if [ "$renderer" = tf2mt ]; then   # remove the layer when the game is gone (normal exit or crash)
  (
    for _ in $(seq 120); do css_running && break; sleep 1; done
    while css_running; do sleep 5; done
    "$CSSMT_ROOT/scripts/layer-uninstall.sh" >/dev/null 2>&1
  ) >/dev/null 2>&1 &
  disown
  echo "renderer: tf2mt; logs: $sess"
fi

if [ $friends_offline = 1 ]; then   # restore Friends when the game is gone
  (
    for _ in $(seq 120); do css_running && break; sleep 1; done
    while css_running; do sleep 5; done
    # the launcher's session helper (session-end.sh) restores Friends and shuts Steam down; this is only the
    # fallback for terminal use. Never start Steam just for this (that left a background Steam running).
    sleep 4
    h=$(cat "$CSS_HOME/run/helper.pid" 2>/dev/null)
    if ! { [ -n "$h" ] && kill -0 "$h" 2>/dev/null; } && [ -f "$CSS_HOME/run/friends-offline" ] && steam_running; then
      steam_url steam://friends/status/online; rm -f "$CSS_HOME/run/friends-offline"
    fi
  ) >/dev/null 2>&1 &
  disown
  echo "CS:S started (Friends set offline until the game exits) (log: $CSS_HOME/logs/css.log)"
else
  echo "CS:S started (log: $CSS_HOME/logs/css.log)"
fi
