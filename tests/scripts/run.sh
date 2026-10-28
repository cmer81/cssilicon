#!/bin/bash
# Runs every test_* function of tests/scripts/test_*.sh, each in its own subshell from the repo root.
#   tests/scripts/run.sh [file-filter]
cd "$(dirname "$0")/../.." || exit 1
pass=0; fail=0
for f in tests/scripts/test_*.sh; do
  [ -n "${1:-}" ] && [[ $f != *"$1"* ]] && continue
  for t in $(bash -c ". '$f'; declare -F" | awk '$3 ~ /^test_/ {print $3}'); do
    tmp=$(mktemp -d)
    if ( export TEST_TMP="$tmp"; . tests/scripts/lib.sh; . "$f"; "$t" ) ; then echo "PASS $t"; pass=$((pass + 1))
    else echo "FAIL $t ($f)"; fail=$((fail + 1)); fi
    rm -rf "$tmp"
  done
done
echo "$pass passed, $fail failed"
[ $fail = 0 ]
