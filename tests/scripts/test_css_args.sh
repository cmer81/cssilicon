# scripts/css.sh launch arguments (CSS_DRY_RUN=1 prints the game command line instead of starting it).
# CSS_DISPLAYMODE = a fake displaymode tool whose `current` prints "3008 1692 144" (a display that isn't the owner's).
css_cmd() {
  tmp_home; . scripts/_env.sh; mkdir -p "$CSSDIR"
  [ -n "${NO_TOOL:-}" ] || { printf '#!/bin/bash\n[ "$1" = current ] && echo "3008 1692 144"\n' > "$TEST_TMP/dm"; chmod +x "$TEST_TMP/dm"; }
  CSS_DISPLAYMODE="${NO_TOOL:-$TEST_TMP/dm}" CSS_DRY_RUN=1 CSS_TUNED=0 bash scripts/css.sh "$@" 2>/dev/null | grep '^game:'
}
has() { case "$1" in *"$2"*) ;; *) assert_eq "$2" "$1" "$3";; esac; }
hasnt() { case "$1" in *"$2"*) assert_eq "no $2" "$1" "$3";; esac; }
test_native_size_and_refresh_from_display() {
  out=$(css_cmd)
  has "$out" "-w 3008 -h 1692" "native size of the display, whatever it is"
  has "$out" "-refresh 144" "fullscreen at the display's rate (the engine would take the first, 60 Hz, mode)"
}
test_resolution_setting() {
  out=$(CSS_WIDTH=1920 CSS_HEIGHT=1080 css_cmd)
  has "$out" "-w 1920 -h 1080" "launcher resolution setting"
}
test_user_resolution_wins() {
  out=$(CSS_WIDTH=1600 CSS_HEIGHT=900 css_cmd -w 1920 -h 1080)
  hasnt "$out" "-w 1600" "Source takes the first -w, so ours must not be there"
  hasnt "$out" "-w 3008" "nor the native size"
  has "$out" "-w 1920 -h 1080" "player's size kept"
}
test_without_display_tool() {
  out=$(NO_TOOL=/nonexistent css_cmd)
  hasnt "$out" "-refresh" "no tool: the game decides"
  hasnt "$out" "-w " "no tool: the game decides"
}
test_metal_renderer_keeps_color_correction() {
  tmp_home; . scripts/_env.sh; mkdir -p "$CSSDIR" "$CSS_HOME/wine/lib/wine/x86_64-windows" "$CSS_HOME/wine/lib/wine/x86_64-unix" \
    "$WINEPREFIX/drive_c/windows/system32"
  out=$(CSS_RENDERER=tf2mt CSS_DISPLAYMODE=/nonexistent CSS_DRY_RUN=1 CSS_TUNED=0 bash scripts/css.sh 2>/dev/null | grep '^game:')
  # the blue image on ze_ffxii_mt_bur_snow_v6fix5 is the map's own colour grading (same on DXVK, 2026-10-28): the
  # Metal renderer must not turn colour correction off
  hasnt "$out" "mat_colorcorrection" "Metal renderer args"
}
