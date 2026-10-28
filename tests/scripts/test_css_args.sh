# scripts/css.sh launch arguments (CSS_DRY_RUN=1 prints the game command line instead of starting it)
css_cmd() { tmp_home; . scripts/_env.sh; mkdir -p "$CSSDIR"; CSS_DRY_RUN=1 CSS_TUNED=0 bash scripts/css.sh "$@" 2>/dev/null | grep '^game:'; }
test_refresh_follows_display_option() {
  out=$(CSS_DISPLAY_120=1 css_cmd)
  case "$out" in *"-refresh 120"*) ;; *) assert_eq "-refresh 120 in args" "$out" "fullscreen must ask for 120 Hz (the engine takes the first, 60 Hz, mode otherwise)";; esac
}
test_no_refresh_when_display_option_off() {
  out=$(CSS_DISPLAY_120=0 css_cmd)
  case "$out" in *"-refresh"*) assert_eq "no -refresh" "$out" "display option off";; esac
  case "$out" in *"-w 2560 -h 1440"*) ;; *) assert_eq "-w 2560 -h 1440" "$out" "window size";; esac
}
test_user_resolution_wins() {
  out=$(css_cmd -w 1920 -h 1080)
  case "$out" in *"-w 2560"*) assert_eq "only the player's -w/-h" "$out" "Source takes the first -w, so ours must not be there";; esac
  case "$out" in *"-w 1920 -h 1080"*) ;; *) assert_eq "-w 1920 -h 1080" "$out" "player's size kept";; esac
}
test_metal_renderer_turns_color_correction_off() {
  tmp_home; . scripts/_env.sh; mkdir -p "$CSSDIR" "$CSS_HOME/wine/lib/wine/x86_64-windows" "$CSS_HOME/wine/lib/wine/x86_64-unix" \
    "$WINEPREFIX/drive_c/windows/system32"
  out=$(CSS_RENDERER=tf2mt CSS_DRY_RUN=1 CSS_TUNED=0 bash scripts/css.sh 2>/dev/null | grep '^game:')
  # the renderer binds a dummy texture for color correction's lookup (2D bound where the shader wants a cube): blue image
  case "$out" in *"+mat_colorcorrection 0"*) ;; *) assert_eq "+mat_colorcorrection 0" "$out" "Metal renderer args";; esac
}
