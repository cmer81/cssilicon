---
paths:
  - "tools/display/**"
  - "tests/unit/display_modes_tests.swift"
---

# displaymode tool

`displaymode` has three subcommands, used by `play.sh`, `css.sh` and `session-end.sh`:

```
displaymode current
displaymode set <statefile> <hz|current> [<w> <h>]
displaymode restore <statefile>
```

## Code layout

- `DisplayModes.swift` holds pure logic with no CoreGraphics: `pickMode`, `restoreMode` and the state-file format.
  Unit-test everything here.
- `main.swift` is the thin CoreGraphics CLI. It has to be called `main.swift`, because Swift only allows top-level
  code there when several files are compiled together.

## Behaviour

- **Switches.** Switches use `.forSession`, so a logout or reboot also brings the previous mode back.
- **Mode choice for a different size.** When the game asks for another size, pick that size at **1x** pixels. Source's
  fullscreen sets that mode itself. Switching first keeps the game window from ending up misplaced and cropped.
- **Mode choice for the same size.** At the same size, keep the current pixel density (a HiDPI mode stays HiDPI).
- **State file.** Format: `<display uuid> <id> <w> <h> <pw> <ph> <hz>`. Restore acts only on the display with that
  UUID, and finds the mode by its values: mode ids are per display. The state file is deleted before anything is
  applied.
- **No matching mode or display.** Change nothing, write no state, print a line (it ends up in `session.log`) and
  exit 0.
- **UUID source.** `CGDisplayCreateUUIDFromDisplayID` needs `import ColorSync`.

## Live checks

A live check changes the owner's screen. Run one only when no game is running, and always restore afterwards.
