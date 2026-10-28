---
paths:
  - "scripts/**"
  - "tests/scripts/**"
  - "config/**"
---

# Shell scripts and their tests

## Session lifecycle

`play.sh` → `css.sh` → `session-helper.sh` → `session-end.sh`.

- `play.sh`: restores a display mode an earlier session left behind, switches the display only if `CSS_REFRESH`
  or a size was chosen, then waits for a *new* Steam "Logged On" line. A game started before Steam logs on runs
  `-insecure` and crashes.
- `css.sh`: installs or uninstalls the renderer layer, sets the microphone in the registry, runs `presets.sh auto`,
  builds the game arguments, then launches.
- `session-helper.sh`: watches the session and ends it when the game exits, or when the launcher is gone with no
  game running.
- `session-end.sh`: puts Friends back online, shuts Steam down, kills wineserver, sweeps orphans, restores the
  display and removes the layer. It is idempotent and locked; keep it that way.

## Environment contract

Every option the launcher sets reaches the scripts as an environment variable:

| Variable | Values |
|---|---|
| `CSS_RENDERER` | `tf2mt` or `dxvk` |
| `CSS_WIDTH`, `CSS_HEIGHT` | game size; empty = the display's own |
| `CSS_REFRESH` | refresh rate; empty = unchanged |
| `CSS_MIC_UID` | microphone |
| `CSS_FRIENDS_ONLINE` | defaults to `1` |
| `CSS_STEAM_OVERLAY` | DXVK only |
| `CSS_FRAMELOG` | frame-time recording |
| `CSS_TUNED` | `0` for benchmarks |

`DXVK_*` and `TF2MT_*` variables are passed through as well.

A new launcher option needs:
1. a `CSS_*` variable read here;
2. the value set in `CSSLauncher.swift` `play()`;
3. a test.

## Game arguments

`css.sh` always passes `-refresh <display rate>` from `displaymode current`. Without it, fullscreen picks the first
mode of that size, which is the 60 Hz one under the Metal renderer.

A `-w`/`-h` in the player's launch options replaces ours: Source reads only the first occurrence.

## Process matching

- Use the helpers in `_env.sh`: `css_pids`, `css_running`, `steam_running`, `wineserver_pid`.
- Process command lines contain spaces, so a path is never a single awk field.
- `CSS_HOME` can contain regex characters such as `CS (old)`. Never write `pgrep -f "$CSS_HOME/..."`: compare with
  `case` on a quoted prefix, as `wineserver_pid` does.

## Presets

`presets.sh` keeps the player's `autoexec.cfg` intact except for one line.

- Our line `exec cssmt_preset // cssmt` goes at the **top**, so the player's lines run after it and win.
- `set none` must restore the file byte for byte. Markers in `$CSS_HOME/config` record what we changed:
  `autoexec-created`, `autoexec-no-newline` and `presets-auto-done`.
- `conflicts <preset>` lists the values from the player's `config.cfg` that the preset would override. It ignores
  values that come from the installed preset, because the game writes cvars back into `config.cfg` on exit.
- Never cap `fps_max` at the refresh rate: vsync paces frames, as tf2mt measured.

## Tests

Tests are plain bash.

- Each `test_*` function runs in a subshell with `TEST_TMP`.
- `lib.sh` provides `assert_eq` and `assert_file_eq`. `tmp_home` creates a `CSS_HOME` that contains a space.
- Inject behaviour through seams, not mocks:
  - `CSS_DRY_RUN=1`: `play.sh` stops before Steam, and `css.sh` prints `game: <args>`;
  - `CSS_DISPLAYMODE=<fake script>`;
  - `exec -a "<argv>" sleep 3` creates a fake process.
- Tests that depend on no real game running return early when `css_running` is true.
- A test that passes before the code exists is not a test: make it fail first. An assertion such as "function is
  defined" catches vacuous passes.

## macOS shell gotchas

- bash 3.2.
- `wc -l` pads its output with spaces: pipe it through `tr -d ' '`.
- BSD `sed` has no `\b`.
- There is no `timeout` command.
- zsh treats `echo ====` as an error.
