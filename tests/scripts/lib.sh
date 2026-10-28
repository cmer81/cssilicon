# Assertions and fixtures for tests/scripts (sourced by run.sh). A failing assertion prints why and exits the
# test's subshell with 1.
assert_eq() {   # <expected> <actual> <message>
  [ "$1" = "$2" ] && return 0
  printf '  %s\n    expected: %s\n    actual:   %s\n' "$3" "$1" "$2"; exit 1
}
assert_file_eq() {   # <fileA> <fileB>
  cmp -s "$1" "$2" && return 0
  printf '  files differ: %s %s\n' "$1" "$2"; diff "$1" "$2" | head -10 | sed 's/^/    /'; exit 1
}
tmp_home() {   # fresh CSS_HOME whose path contains a space (removed by run.sh)
  CSS_HOME="$TEST_TMP/css home"; mkdir -p "$CSS_HOME"; export CSS_HOME
}
