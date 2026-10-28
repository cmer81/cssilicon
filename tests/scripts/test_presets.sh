# scripts/presets.sh on a fake game folder (CSSDIR under a temporary CSS_HOME)
LINE='exec cssmt_preset // cssmt'
setup_game() {
  tmp_home; . scripts/_env.sh
  AE="$CSSDIR/cstrike/cfg/autoexec.cfg"; mkdir -p "$CSSDIR/cstrike/cfg" "$CSSDIR/cstrike/custom"
}
presets() { bash scripts/presets.sh "$@"; }
test_set_creates_autoexec() {
  setup_game; presets set balanced >/dev/null
  assert_eq "$LINE" "$(cat "$AE")" "autoexec.cfg holds only our line"
  assert_eq "preset=balanced own=no pending=no" "$(presets status)" "status"
}
test_preset_keeps_user_autoexec() {
  setup_game; echo 'bind f4 kill' > "$AE"; presets set high >/dev/null
  assert_eq "bind f4 kill" "$(sed -n 1p "$AE")" "user line first, unchanged"
  assert_eq "$LINE" "$(sed -n 2p "$AE")" "our line second"
  assert_eq 2 "$(wc -l < "$AE" | tr -d ' ')" "two lines"
  assert_eq "preset=high own=yes pending=no" "$(presets status)" "status with own autoexec"
}
test_set_twice_no_duplicate() {
  setup_game; presets set low >/dev/null; presets set high >/dev/null
  assert_eq 1 "$(grep -cxF "$LINE" "$AE")" "one exec line"
  assert_eq "// cssmt preset: high" "$(head -1 "$CSSDIR/cstrike/custom/cssmt/cfg/cssmt_preset.cfg")" "preset file header"
}
test_none_restores_exactly() {
  setup_game; printf 'bind f4 kill\nsensitivity 2\n' > "$AE"; cp "$AE" "$TEST_TMP/orig"
  presets set balanced >/dev/null
  assert_eq "$LINE" "$(tail -1 "$AE")" "preset line appended"
  presets set none >/dev/null
  assert_file_eq "$TEST_TMP/orig" "$AE"
  assert_eq no "$([ -e "$CSSDIR/cstrike/custom/cssmt" ] && echo yes || echo no)" "custom/cssmt removed"
}
test_none_removes_created_autoexec() {
  setup_game; presets set low >/dev/null; presets set none >/dev/null
  assert_eq no "$([ -e "$AE" ] && echo yes || echo no)" "autoexec.cfg we created is removed"
  assert_eq "preset=none own=no pending=no" "$(presets status)" "status after none"
}
test_auto_once() {
  setup_game; assert_eq "preset=none own=no pending=yes" "$(presets status)" "pending before first auto"
  presets auto >/dev/null; assert_eq "preset=balanced own=no pending=no" "$(presets status)" "auto installs balanced"
  presets set none >/dev/null; presets auto >/dev/null
  assert_eq "preset=none own=no pending=no" "$(presets status)" "auto never reinstalls"
}
test_auto_skips_existing_game() {
  setup_game; echo 'name x' > "$CSSDIR/cstrike/cfg/config.cfg"; presets auto >/dev/null
  assert_eq "preset=none own=no pending=no" "$(presets status)" "game already ran: auto does nothing"
}
test_none_restores_file_without_trailing_newline() {
  setup_game; printf 'bind f4 kill' > "$AE"; cp "$AE" "$TEST_TMP/orig"
  presets set low >/dev/null; presets set none >/dev/null
  assert_file_eq "$TEST_TMP/orig" "$AE"
}
