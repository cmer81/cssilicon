#!/bin/bash
# cssmt graphics presets for CS:S (replaces tf2mt's mastercomfig, which only exists for TF2). Used by the launcher.
#   scripts/presets.sh status         -> "preset=<low|balanced|high|none> own=<yes|no> pending=<yes|no>"
#   scripts/presets.sh set <preset>   -> low | balanced | high | none
#   scripts/presets.sh auto           -> before each launch: installs Balanced on a brand-new install only
# A preset is config/presets/<name>.cfg, copied to cstrike/custom/cssmt/cfg/cssmt_preset.cfg (first line
# "// cssmt preset: <name>") and run by one line appended to cstrike/cfg/autoexec.cfg. The player's own lines in
# autoexec.cfg are never touched; `set none` takes our line out again and leaves the file as it was (deleted if we
# created it). own=yes: autoexec.cfg has lines of the player's. pending=yes: `auto` would install Balanced next launch.
# `auto` decides once (marker in $CSS_HOME/config): never after the player picked a preset or None, and never for a
# game that already ran (cstrike/cfg/config.cfg) or has its own autoexec. Takes effect the next time the game starts.
set -u
. "$(dirname "$0")/_env.sh"
CFG="$CSSDIR/$CSS_GAME/cfg"; AE="$CFG/autoexec.cfg"
PRESET="$CSSDIR/$CSS_GAME/custom/cssmt/cfg/cssmt_preset.cfg"
LINE='exec cssmt_preset // cssmt'
CONF="$CSS_HOME/config"; DONE="$CONF/presets-auto-done"; CREATED="$CONF/autoexec-created"; NONL="$CONF/autoexec-no-newline"

current() { sed -n '1s#^// cssmt preset: ##p' "$PRESET" 2>/dev/null | grep . || echo none; }
own() { [ -f "$AE" ] && grep -vxF "$LINE" "$AE" | grep -q . && echo yes || echo no; }
pending() {
  [ -f "$DONE" ] || [ "$(current)" != none ] || [ -f "$CFG/config.cfg" ] || [ "$(own)" = yes ] && echo no || echo yes
}
add_line() {
  mkdir -p "$CFG" "$CONF"
  [ -f "$AE" ] && grep -qxF "$LINE" "$AE" && return 0
  if [ ! -f "$AE" ]; then touch "$CREATED"; : > "$AE"
  elif [ -s "$AE" ] && [ -n "$(tail -c 1 "$AE")" ]; then touch "$NONL"; echo >> "$AE"   # file ended without newline
  fi
  echo "$LINE" >> "$AE"
}
remove_line() {
  [ -f "$AE" ] || return 0
  grep -vxF "$LINE" "$AE" > "$AE.cssmt-tmp"
  if [ -f "$NONL" ]; then printf '%s' "$(cat "$AE.cssmt-tmp")" > "$AE.cssmt-tmp"; rm -f "$NONL"; fi
  mv "$AE.cssmt-tmp" "$AE"
  if [ -f "$CREATED" ] && [ ! -s "$AE" ]; then rm -f "$AE"; fi
  rm -f "$CREATED"
}
set_preset() {   # $1 = low | balanced | high | none
  mkdir -p "$CONF"; touch "$DONE"   # the player chose: auto never overrides it
  if [ "$1" = none ]; then
    remove_line; rm -rf "$CSSDIR/$CSS_GAME/custom/cssmt"; echo "preset: none"; return 0
  fi
  local src="$CSSMT_ROOT/config/presets/$1.cfg"
  [ -f "$src" ] || { echo "unknown preset $1 (low | balanced | high | none)"; exit 2; }
  mkdir -p "$(dirname "$PRESET")"
  { echo "// cssmt preset: $1"; cat "$src"; } > "$PRESET"
  add_line; echo "preset: $1"
}

case "${1:-status}" in
  status) echo "preset=$(current) own=$(own) pending=$(pending)" ;;
  set)    [ $# = 2 ] || { echo "usage: $0 set low|balanced|high|none"; exit 2; }; set_preset "$2" ;;
  auto)   if [ "$(pending)" = yes ]; then set_preset balanced; else mkdir -p "$CONF"; touch "$DONE"; fi ;;
  *)      echo "usage: $0 status | set <preset> | auto"; exit 2 ;;
esac
