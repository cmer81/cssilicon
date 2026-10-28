# scripts/play.sh switches the display through display120 (CSS_DISPLAY120 = a fake that logs its calls)
fake_display120() {
  tmp_home; mkdir -p "$CSS_HOME/run"; LOG="$TEST_TMP/display120.log"
  printf '#!/bin/bash\necho "$1" >> "%s"\n' "$LOG" > "$TEST_TMP/display120"; chmod +x "$TEST_TMP/display120"
  export CSS_DISPLAY120="$TEST_TMP/display120" CSS_DRY_RUN=1
}
game_up() { . scripts/_env.sh; css_running; }
test_stale_restore() {
  game_up && return 0   # a real game is running: play.sh would stop before the display step
  fake_display120; touch "$CSS_HOME/run/display-before"
  bash scripts/play.sh >/dev/null 2>&1
  assert_eq "restore set" "$(tr '\n' ' ' < "$LOG" | sed 's/ $//')" "restore leftovers first, then switch"
}
test_display_opt_out() {
  game_up && return 0
  fake_display120; CSS_DISPLAY_120=0 bash scripts/play.sh >/dev/null 2>&1
  assert_eq "restore" "$(tr '\n' ' ' < "$LOG" | sed 's/ $//')" "opt-out: only the leftover restore"
}
