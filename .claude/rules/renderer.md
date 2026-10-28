---
paths:
  - "src/**"
  - "tools/trace/**"
  - "tools/translate/**"
  - "tests/unit/opcodes.mm"
  - "Makefile"
---

# Metal renderer (from tf2mt)

## How the pieces connect

1. The `d3d9.dll` forwarder sits next to the game.
2. It forwards to the builtin `tf2mt.dll` (`src/frontend`, a PE built with mingw-w64).
3. That dll makes Wine unix calls into `tf2mt.so` (`src/unixlib`, Metal, built for x86_64 under Rosetta).
4. Shaders go through the D3D9 → MSL translator (`src/translate`).

`scripts/layer-install.sh` installs the layer for one session; it is removed when the game exits. tf2mt's design
and measurements are in `docs/` (ADR-001…005, m*-reports) and `PLAN.md`. Read them before changing behaviour.

## Facts established on CS:S

- **Shader path.** CS:S takes the SM2 path (`mat_dxlevel 95`), like TF2. SM3 opcodes are stubs, so ask the owner
  before starting SM3 work.
- **Caps tables.** `src/frontend/caps_table.h` comes from TF2 census runs. A combination of formats or caps that
  CS:S asks for and TF2 never did shows up as an "unseen" or "unsupported" line in the logs. On CS:S (Balanced and
  High, 2026-10-29) every `UNSEEN` line is a query DXVK also answered "no" to TF2: check a new one against
  `tests/golden/adapter_queries.tsv` before touching the tables. `backbuffer … ms N` in `tf2mt-session.log` shows
  the MSAA level actually in use.
- **Texture-type mismatches.**
  - `texture_mismatch` logs each (shader, stage) pair once, with details of the bound texture.
  - Set `TF2MT_DUMP_DIR` to dump the shader's MSL.
  - Maps that ship a 2D texture as their env map hit this on stage 8. The black dummy texture matches what DXVK
    shows, so this is not a bug.
- **Colour.** A blue image on a map was that map's own colour grading; DXVK shows it the same way. Always compare
  with `CSS_RENDERER=dxvk` on the same map before calling a colour bug.
- **Pipeline cache.** The cache lives in `TF2MT_CACHE_DIR`, which `_env.sh` sets under `CSS_HOME`. The renderer's
  fallback, `~/Games/tf2/...`, doesn't exist here.

## Upstream merges

Keep internal names (`tf2mt`, `TF2MT_*`) so upstream merges stay easy.

## Logs and measurement

- Per session: `~/Games/css/logs/tf2mt/<session>/unix.log`.
- `present:`, `ledger-perf:` and `latency:` lines appear every 600 frames.
- GPU ms/frame against the refresh budget (8.3 ms at 120 Hz) tells you whether the GPU is the limit.
- Exactly 60.0 fps with vsync at 120 Hz means frames are missing the budget. It is not a cap.
