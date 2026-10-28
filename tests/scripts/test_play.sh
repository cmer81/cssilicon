# scripts/play.sh tells the terminal what it is doing (notifications can be off for the terminal)
test_play_prints_when_already_running() {
  . scripts/_env.sh
  ( exec -a "C:\\x\\$CSS_EXE -steam" sleep 3 ) & p=$!
  sleep 0.3
  out=$(bash scripts/play.sh 2>&1); kill $p
  assert_eq "CS:S is already running." "$out" "message on stdout"
}
