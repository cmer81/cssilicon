# tools/release.sh: a release must carry the default (Metal) renderer and the display tool
fake_app() {   # $@ = bundled files to leave out
  APP="$TEST_TMP/CSSilicon.app"; R="$APP/Contents/Resources/cssmt"
  mkdir -p "$R/build/tf2mt" "$R/build/tools" "$R/scripts"
  for f in build/tf2mt/tf2mt.dll build/tf2mt/tf2mt.so build/tf2mt/d3d9.dll build/tools/displaymode scripts/play.sh; do touch "$R/$f"; done
  for f in "$@"; do rm -f "$R/$f"; done
}
test_release_rejects_app_without_metal_renderer() {
  fake_app build/tf2mt/tf2mt.so
  RELEASE_LIB=1 . tools/release.sh
  assert_eq function "$(type -t check_bundle)" "check_bundle is defined"
  check_bundle "$APP" >/dev/null 2>&1; r=$?
  assert_eq 1 "$r" "no tf2mt.so: not releasable"
}
test_release_accepts_complete_app() {
  fake_app
  RELEASE_LIB=1 . tools/release.sh
  check_bundle "$APP" >/dev/null 2>&1; r=$?
  assert_eq 0 "$r" "complete bundle"
}
