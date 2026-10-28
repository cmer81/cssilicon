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
  setup_game; echo 'fps_max 144' > "$AE"; presets set high >/dev/null
  # ours first: the preset runs, then the player's own lines, which win (their fps_max stays 144)
  assert_eq "$LINE" "$(sed -n 1p "$AE")" "our line first"
  assert_eq "fps_max 144" "$(sed -n 2p "$AE")" "player's line after it, unchanged"
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
  assert_eq "$LINE" "$(head -1 "$AE")" "preset line added on top"
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
# `presets.sh conflicts <preset>`: cvars the preset would replace in the player's config.cfg (the game reads config.cfg
# before autoexec.cfg, so preset values win over it); one name per line, nothing when there is no conflict
test_conflicts_lists_changed_cvars() {
  setup_game; printf 'bind "f4" "kill"\nfps_max "144"\nrate "786432"\ncl_interp_ratio "1"\n' > "$CSSDIR/cstrike/cfg/config.cfg"
  assert_eq "cl_interp_ratio fps_max" "$(presets conflicts balanced | sort | tr '\n' ' ' | sed 's/ $//')" "changed values only (rate is the same)"
}
test_conflicts_ignores_cvars_set_in_autoexec() {
  setup_game; printf 'fps_max "144"\n' > "$CSSDIR/cstrike/cfg/config.cfg"; echo 'fps_max 144' > "$AE"
  assert_eq "" "$(presets conflicts balanced)" "the player's autoexec runs after the preset and wins"
}
test_conflicts_none_without_config() {
  setup_game
  assert_eq "" "$(presets conflicts high)" "fresh install: nothing to replace"
}
test_conflicts_numeric_equal() {
  setup_game; printf 'mat_forceaniso "4.000000"\n' > "$CSSDIR/cstrike/cfg/config.cfg"
  assert_eq "" "$(presets conflicts balanced)" "4.000000 equals 4"
}
test_conflicts_ignores_values_from_current_preset() {
  # the game writes the running preset's values back into config.cfg on exit: they aren't the player's settings
  setup_game; presets set balanced >/dev/null
  printf 'mat_forceaniso "4"\nfps_max "144"\n' > "$CSSDIR/cstrike/cfg/config.cfg"
  assert_eq "fps_max" "$(presets conflicts low)" "aniso 4 came from Balanced; fps_max 144 is the player's"
}
