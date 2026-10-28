# Shared environment for all cssmt scripts. Self-contained: works from a git checkout or from inside
# cssmt.app (scripts are bundled). The game install location is configurable via CSS_HOME.
_cssmt_src="${BASH_SOURCE[0]:-}"
[ -z "$_cssmt_src" ] && [ -n "${ZSH_VERSION:-}" ] && eval '_cssmt_src="${(%):-%x}"'   # sourced from zsh
CSSMT_ROOT="$(cd "$(dirname "$_cssmt_src")/.." && pwd)"; export CSSMT_ROOT; unset _cssmt_src
export CSS_HOME="${CSS_HOME:-$HOME/Games/css}"
export WINEPREFIX="$CSS_HOME/prefix"
export WINE="$CSS_HOME/wine/bin/wine"
export WINESERVER="$CSS_HOME/wine/bin/wineserver"
export STEAM_DIR="$WINEPREFIX/drive_c/Program Files (x86)/Steam"
# Counter-Strike: Source (Windows, 64-bit since the February 2025 update). CSS_STUB is what Steam starts; it hands
# over to CSS_EXE, the 64-bit game process.
export CSS_APPID=240
export CSS_GAME=cstrike
export CSSDIR="$STEAM_DIR/steamapps/common/Counter-Strike Source"
export CSS_STUB="${CSS_STUB:-cstrike.exe}"
export CSS_EXE="${CSS_EXE:-cstrike_win64.exe}"
export DYLD_FALLBACK_LIBRARY_PATH="$CSS_HOME/wine/lib:/usr/lib"   # FreeType etc. (lost if launched via SIP binaries like nohup)
export WINEDEBUG="${WINEDEBUG:--all}"
export MVK_CONFIG_LOG_LEVEL="${MVK_CONFIG_LOG_LEVEL:-0}"
# No Wine crash debugger: when the game crashes, winedbg (+ a conhost) stays attached to the dead game, keeping its
# network port open (the next game then moves to another port) and processes alive. Steam still writes crash dumps.
case "${WINEDLLOVERRIDES:-}" in *winedbg*) ;; *) export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:+$WINEDLLOVERRIDES;}winedbg.exe=d" ;; esac

# PIDs of the running game: only processes whose argv[0] is the Windows exe path (avoids matching shells or
# scripts that merely mention the name)
css_pids() { pgrep -fl "${CSS_EXE//./\\.}" | awk '$2 ~ /^C:/ {print $1}'; }
css_running() { [ -n "$(css_pids)" ]; }
# Steam client running in the prefix: argv[0] is steam.exe (with or without -silent)
steam_running() { pgrep -fl 'steam\.exe' | awk '$2 ~ /(^|\\)steam\.exe$/ {f=1} END {exit !f}'; }
# Start Steam if needed and wait for a NEW "Logged On" line (old lines from earlier sessions don't count). A game
# started before Steam has logged on runs -insecure and crashes during load (seen with TF2 upstream). Steam is shut
# down after every session, so test scripts must use this rather than grepping the whole connection log.
ensure_steam() {
  steam_running && return 0
  local n; n=$(wc -l < "$STEAM_DIR/logs/connection_log.txt" 2>/dev/null | tr -d ' '); n=${n:-0}
  "$CSSMT_ROOT/scripts/steam.sh" >/dev/null
  for _ in $(seq 120); do
    tail -n +$((n + 1)) "$STEAM_DIR/logs/connection_log.txt" 2>/dev/null | grep -q 'Logged On' && { sleep 8; return 0; }
    sleep 2
  done
  return 1
}
