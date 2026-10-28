# scripts/, config/ and the bundled wine patch tool must not target TF2 any more (comments included: they'd mislead)
test_no_tf2_refs() {
  hits=$(grep -rnIiE 'tf_win64|tf\.exe|\b440\b|Team Fortress|-game tf\b|/tf/|TF2_|tf2_running|tf2_pids|mastercomfig|tf2\.sh|install-tf2' \
           scripts config tools/wine-patches | grep -v 'tf2mt-runtime')
  # "TF2" as a word (messages, comments) is only allowed where it explains an upstream finding
  words=$(grep -rnIw 'TF2' scripts config tools/wine-patches | grep -v 'upstream')
  hits="$hits$words"
  assert_eq "" "$hits" "TF2 leftovers"
}
