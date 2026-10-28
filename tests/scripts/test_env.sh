# scripts/_env.sh: CS:S paths and game constants
test_env_defaults() {
  unset CSS_HOME; . scripts/_env.sh
  assert_eq "$HOME/Games/css" "$CSS_HOME" "CSS_HOME default"
  assert_eq 240 "$CSS_APPID" "appid"
  assert_eq "$CSS_HOME/prefix/drive_c/Program Files (x86)/Steam/steamapps/common/Counter-Strike Source" "$CSSDIR" "CSSDIR"
  assert_eq cstrike "$CSS_GAME" "game dir"
}
test_env_paths_with_spaces() {
  tmp_home; . scripts/_env.sh
  assert_eq "$TEST_TMP/css home/prefix" "$WINEPREFIX" "prefix follows CSS_HOME with a space"
}
test_css_pids_ignores_shells() {
  . scripts/_env.sh
  assert_eq function "$(type -t css_pids)" "css_pids is defined"
  ( exec -a "bash -c echo $CSS_EXE" sleep 3 ) & p=$!
  sleep 0.3
  found=$(css_pids | grep -x "$p"); kill $p
  assert_eq "" "$found" "a shell mentioning the exe is not the game"
}
test_steam_running_with_spaces_in_path() {
  . scripts/_env.sh
  ( exec -a 'C:\Program Files (x86)\Steam\steam.exe -silent -no-cef-sandbox' sleep 3 ) & p=$!
  sleep 0.3
  steam_running; r=$?; kill $p
  assert_eq 0 "$r" "steam.exe under Program Files (x86) is detected"
}
test_steam_running_ignores_webhelper() {
  . scripts/_env.sh
  steam_running && return 0   # a real Steam is up: this check can't be isolated
  ( exec -a 'C:\Program Files (x86)\Steam\bin\cef\cef.win64\steamwebhelper.exe -steampath=C:\Program Files (x86)\Steam\steam.exe -launcher=0' sleep 3 ) & p=$!
  sleep 0.3
  steam_running; r=$?; kill $p
  assert_eq 1 "$r" "steamwebhelper alone is not Steam"
}
test_exe_names() {
  unset CSS_STUB CSS_EXE; . scripts/_env.sh
  assert_eq cstrike.exe "$CSS_STUB" "stub started by Steam (seen 2026-10-28)"
  assert_eq cstrike_win64.exe "$CSS_EXE" "64-bit game process (seen 2026-10-28)"
}
test_metal_pipeline_cache_under_css_home() {
  unset TF2MT_CACHE_DIR; tmp_home; . scripts/_env.sh
  # src/unixlib/render.mm falls back to ~/Games/tf2/cache/tf2mt (never created here), so cssmt must point it at CSS_HOME
  assert_eq "$CSS_HOME/cache/tf2mt" "$TF2MT_CACHE_DIR" "Metal renderer pipeline cache"
}
test_wineserver_found_with_regex_chars_in_path() {
  # a game folder like "CS (old)" must not break wineserver detection (pgrep -f used to treat CSS_HOME as a regex)
  CSS_HOME="$TEST_TMP/CS (old)+[1]"; export CSS_HOME; . scripts/_env.sh
  assert_eq function "$(type -t wineserver_pid)" "wineserver_pid is defined"
  ( exec -a "$CSS_HOME/wine/bin/wineserver" sleep 3 ) & p=$!
  sleep 0.3
  found=$(wineserver_pid); kill $p
  assert_eq "$p" "$found" "our wineserver is found"
}
test_other_wineserver_ignored() {
  tmp_home; . scripts/_env.sh
  ( exec -a "/Applications/CrossOver.app/wine/bin/wineserver" sleep 3 ) & p=$!
  sleep 0.3
  found=$(wineserver_pid | grep -x "$p"); kill $p
  assert_eq "" "$found" "another Wine's server is not ours"
}
