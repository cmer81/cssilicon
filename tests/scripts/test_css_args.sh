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
