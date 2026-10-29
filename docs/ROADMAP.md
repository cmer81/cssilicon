# CSSilicon roadmap

What is left after v0.1.2 (2026-10-29). Design background: `docs/superpowers/specs/2026-10-28-cssmt-design.md`.

## Metal renderer: validate on CS:S (design phase 2)

The renderer runs CS:S as is — SM2 path (`mat_dxlevel 95`), no stalls, owner-tested on de_dust2, ze_surf_luna,
ze_simpsons, ze_ffxii_mt_bur_snow and online. It has not been validated as systematically as tf2mt did for TF2:

- [x] **CS:S census.** No table merge needed (2026-10-29). Balanced (5 owner sessions: de_dust2, ZE maps, online)
      and High (MSAA 4x confirmed by a `ms 4` backbuffer reset, HDR 2) on de_dust2, cs_office, de_nuke, de_inferno:
      CS:S asks the same 39 `CheckDeviceFormat` questions outside the OK table, and DXVK answered all 39 "no" to TF2
      (`tests/golden/adapter_queries.tsv`). No depth-stencil, device-type or multisample query is unseen; 0 stalls,
      0 upload failures. Re-check `UNSEEN` lines in `tf2mt-session.log` if a map or setting ever behaves oddly.
- [ ] **Golden images.** SSIM against DXVK on CS:S maps (de_dust2, cs_office, de_nuke, de_inferno; water, smoke,
      flashbang, AWP scope, HDR maps), target ≥ 0.997 as in tf2mt's M6/M7. Started 2026-10-29: `capture.sh <tag>
      <demo>` captures a demo playback, `goldens.sh` compares (`tests/golden/frames.tsv`). `ze-mako` (owner's demo
      on a full ZE server, 30 s, 865 frames, 7.5 GB) passes at 0.9991–0.9994. Still to capture: the maps and effects
      above.
- [ ] **Shader corpus.** Translator corpus tests (`make test-translate`) only have TF2's corpus; build a CS:S one.
- [ ] Stage-8 env-map type mismatch (maps shipping a 2D texture as their cubemap): black, same as DXVK — keep unless
      a map shows a visible difference.
- [ ] Steam Overlay doesn't work on the Metal renderer (DXVK only), as in tf2mt.

## Smoothness at high refresh rates (design phase 4)

- [x] Measure frame start → on-screen latency and pacing on CS:S (`TF2MT_LATENCY_LOG=1`, `latency:` lines); try
      the queue drain (`TF2MT_DRAIN=1`, docs/mouse-input.md) at 120 Hz and decide whether to enable it. Done
      2026-10-29 with `tools/bench/latency-css.sh mako` (owner's full-server ZE demo, 243 s, Balanced, M1,
      1920×1080@120, 2 runs each): latency p50 32.4–32.6 ms default vs 32.7–32.9 ms drain, ~71 fps either way.
      **Drain stays off**: it only helps a game that keeps up with the refresh. Per frame (p50 / p90): game
      9.5 / 12.1 ms, GPU 7.3 ms (windows 5.1–12.1), encode 0.05 ms, submit → screen 19.6 / 24.0 ms. On a busy ZE
      server the limit is the game thread (x86 under Rosetta, includes tf2mt's frontend), then the GPU.
- [ ] Write the M1 measurements report the Balanced preset refers to (`docs/phase1-css-m1-report.md`): owner's M1,
      ZE server — DXVK ~60 fps; Metal 1440p GPU 11–12 ms (51–56 fps), 1080p 7.6–8 ms (66–80 fps).
- [ ] Smoke-test on other Macs: MacBook built-in displays (ProMotion and not, odd HiDPI sizes like 1512×982) and a
      laptop with an external monitor in both orders.

## Minor fixes from the v0.1.0 review

- [ ] `css.sh`: skip `-refresh` when the display reports 0 Hz; let a player's `-refresh` win; detect
      `-width`/`-height` too.
- [ ] When the requested size has no display mode, fall back to the native size (fullscreen would switch the display
      itself, with no state to restore).
- [ ] `install-css.sh`: use `steam_running` instead of a loose `pgrep 'steam.exe'`.
- [ ] `stop.sh`: restore the display and remove the renderer layer too.
- [ ] Dev tools still aimed at TF2: `tools/bench/gen-nav.sh`, `night-bots.sh`, `mouse-test.sh` (CS:S has built-in bot
      navigation; RCON doesn't listen, use `-condebug`).
- [ ] README: describe the updater's trust model (GitHub TLS + published sha256; the app is unsigned).
