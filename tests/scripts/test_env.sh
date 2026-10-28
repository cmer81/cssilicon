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
  assert_eq "" "$(css_pids)" "a shell mentioning the exe is not the game"; kill $p
}
