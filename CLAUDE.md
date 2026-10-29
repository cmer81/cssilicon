# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

CSSilicon runs the **Windows** Counter-Strike: Source (appid 240, `cstrike.exe` → 64-bit `cstrike_win64.exe`) on Apple
Silicon Macs under Wine + Rosetta, with tf2mt's Direct3D 9 → Metal renderer (default) or DXVK. Fork of
[tf2mt](https://github.com/HorrorPills/tf2mt): remote `upstream` (fetched with `--no-tags`). Work on branch `cssmt`,
pushed as `main` of `origin` (github.com/cmer81/cssilicon, public). Area-specific rules live in `.claude/rules/`.
Design decisions: `docs/superpowers/specs/2026-10-28-cssmt-design.md` — its "Avenant" at the top overrides the rest.
**What is left to do: `docs/ROADMAP.md`** — check it before proposing work, tick items off as they land.

## Commands

```bash
make test-scripts                 # bash tests, temp dirs only
tests/scripts/run.sh presets      # one test file (substring of its name)
make test-display                 # displaymode logic (Swift)
make test-launcher                # updater version comparison (Swift)
make translate-tools && build/tools/opcodes   # renderer translator opcode tests
make frontend unixlib trace       # Metal renderer + DXVK timing proxy
tools/launcher/build.sh [--no-install]        # CSSilicon.app + CSSilicon-app.zip (installs to /Applications)
tools/release.sh vX.Y.Z [notes]   # the only way to release (see .claude/rules/release.md)
```

Prerequisites: Xcode Command Line Tools only (no Xcode), `brew install mingw-w64`, `.venv` with Pillow (app icon),
numpy and pandas (`tools/replay/ssim.py`, `tools/bench/analyze.py`).
`make test-translate` also runs corpus steps that need a TF2-generated `corpus/` (git-ignored): only the opcode part
applies to this repo. Run all three `make test-*` targets before committing script, display or launcher changes.

## Rules for every change

- **Never touch the game.** No patching of game files or memory; the only thing placed next to the game is a
  `d3d9.dll`, for the session. Presets write only `cstrike/custom/cssmt/` and one line in `autoexec.cfg`.
- **Never join an online server** from an automated run: local maps (`+sv_lan 1`) or demos only. Online tests are done
  by the owner. RCON does not listen on this CS:S build — use `-condebug` console logs.
- **No per-machine constants.** Defaults follow the player's display and hardware (the owner's M1 + 1440p@160 Hz
  monitor is one setup among many; 1920x1080@120 Hz is the owner's launcher choice, not a default).
- **Keep internal names**: renderer `tf2mt.dll`/`tf2mt.so`/`TF2MT_*`/`src/**`, and `cssmt` identifiers (`CSSMT_ROOT`,
  `cstrike/custom/cssmt`, `~/Games/css`). Renaming breaks upstream merges and existing installs. User-facing text says
  CSSilicon / CS:S.
- No TF2 leftovers in `scripts/`, `config/`, `tools/wine-patches`: `tests/scripts/test_no_tf2_refs.sh` enforces it
  (the word "TF2" is allowed only on lines explaining an upstream finding).
- Paths have spaces (`Program Files (x86)`, `Counter-Strike Source`) and `CSS_HOME` is player-chosen: quote
  everything and match paths literally, never as regex.
- Commits use the GitHub noreply address configured in this repo; end messages with the session attribution line
  when one is provided.

## Where things are

- `scripts/` — all the work (setup, Steam, launch, session lifecycle, presets); `scripts/_env.sh` holds every game
  constant and process helper.
- `tools/launcher/` — SwiftUI app that only passes options to the scripts; `tools/display/` — display-mode CLI.
- `src/` — the Metal renderer from tf2mt; its own docs are in `docs/` (reports, ADRs) and `PLAN.md`.
- Runtime data and logs: `~/Games/css` (`logs/session.log`, `logs/css.log`, `logs/tf2mt/<session>/unix.log`).
