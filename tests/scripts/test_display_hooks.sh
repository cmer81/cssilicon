# scripts/play.sh switches the display through displaymode (CSS_DISPLAYMODE = a fake that logs its calls)
fake_displaymode() {
  tmp_home; mkdir -p "$CSS_HOME/run"; LOG="$TEST_TMP/displaymode.log"
  printf '#!/bin/bash\necho "$*" >> "%s"\n' "$LOG" > "$TEST_TMP/dm"; chmod +x "$TEST_TMP/dm"
  export CSS_DISPLAYMODE="$TEST_TMP/dm" CSS_DRY_RUN=1; unset CSS_REFRESH CSS_WIDTH CSS_HEIGHT
}
game_up() { . scripts/_env.sh; css_running; }
calls() { sed "s|$CSS_HOME/run/display-before|STATE|" "$LOG" | tr '\n' ';'; }
test_stale_restore() {
  game_up && return 0   # a real game is running: play.sh would stop before the display step
  fake_displaymode; touch "$CSS_HOME/run/display-before"
  bash scripts/play.sh >/dev/null 2>&1
  assert_eq "restore STATE;" "$(calls)" "restore leftovers; display left as it is by default"
}
test_refresh_setting() {
  game_up && return 0
  fake_displaymode; CSS_REFRESH=120 bash scripts/play.sh >/dev/null 2>&1
  assert_eq "restore STATE;set STATE 120;" "$(calls)" "launcher refresh setting"
}
test_display_follows_game_size() {
  game_up && return 0
  fake_displaymode; CSS_REFRESH=120 bash scripts/play.sh -w 1920 -h 1080 >/dev/null 2>&1
  assert_eq "restore STATE;set STATE 120 1920 1080;" "$(calls)" "display switched to the game's size and rate"
}
test_size_without_refresh_keeps_rate() {
  game_up && return 0
  fake_displaymode; CSS_WIDTH=1920 CSS_HEIGHT=1080 bash scripts/play.sh >/dev/null 2>&1
  assert_eq "restore STATE;set STATE current 1920 1080;" "$(calls)" "resolution setting alone keeps the display's rate"
}
