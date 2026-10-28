# CSSilicon roadmap

What is left after v0.1.2 (2026-10-29). Design background: `docs/superpowers/specs/2026-10-28-cssmt-design.md`.

## Metal renderer: validate on CS:S (design phase 2)

The renderer runs CS:S as is — SM2 path (`mat_dxlevel 95`), no stalls, owner-tested on de_dust2, ze_surf_luna,
ze_simpsons, ze_ffxii_mt_bur_snow and online. It has not been validated as systematically as tf2mt did for TF2:

- [ ] **CS:S census.** `src/frontend/caps_table.h` only accepts format/caps combinations TF2 asked for. Run a census
      on CS:S (tools/census, DXVK as oracle) over several maps and merge the tables; check `unix.log` for
      `unseen`/`unsupported` lines meanwhile.
- [ ] **Golden images.** SSIM against DXVK on CS:S maps (de_dust2, cs_office, de_nuke, de_inferno; water, smoke,
      flashbang, AWP scope, HDR maps), target ≥ 0.997 as in tf2mt's M6/M7.
- [ ] **Shader corpus.** Translator corpus tests (`make test-translate`) only have TF2's corpus; build a CS:S one.
- [ ] Stage-8 env-map type mismatch (maps shipping a 2D texture as their cubemap): black, same as DXVK — keep unless
      a map shows a visible difference.
- [ ] Steam Overlay doesn't work on the Metal renderer (DXVK only), as in tf2mt.

## Smoothness at high refresh rates (design phase 4)

- [ ] Measure frame start → on-screen latency and pacing on CS:S (`TF2MT_LATENCY_LOG=1`, `latency:` lines); try
      the queue drain (`TF2MT_DRAIN=1`, docs/mouse-input.md) at 120 Hz and decide whether to enable it.
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
