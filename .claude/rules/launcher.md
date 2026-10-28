---
paths:
  - "tools/launcher/**"
  - "tests/unit/version_tests.swift"
---

# SwiftUI launcher (CSSilicon.app)

## Build

- Built with `swiftc` only: `tools/launcher/build.sh`, with Command Line Tools and no Xcode.
- The `@State` macro is unavailable, so use `@AppStorage` or `@StateObject`.
- The launcher is one large file, `CSSLauncher.swift`, plus `Version.swift`, which is unit-tested by
  `make test-launcher`.

## How it talks to the scripts

The app never does game work itself. It runs `scripts/*.sh` through `SessionRunner`, which opens the invisible
`CSSilicon Session.app` helper with `open -n -g -j --env …`. This exists because macOS 27 attributes processes to
the app that started them.

`SessionRunner` forwards only environment variables with known prefixes: `CSS`, `TF2MT`, `DXVK`, `MTL_`, `WINE`,
`MVK` and `DYLD`. A new prefix must be added to that filter.

## Settings

- Settings live in `UserDefaults` under the bundle id `io.github.cssilicon.launcher`.
- Settings from the earlier bundle id `local.cssmt.launcher` are imported once at startup (`importedCssmtSettings`).
- Defaults must suit any Mac:
  - Metal renderer on;
  - Resolution `""`, which means native;
  - Refresh `0`, which means unchanged;
  - Friends offline off.
- The Resolution and Refresh pickers list what the main display actually offers (`DisplayOptions`).

## Updater

The `Updater` class, which comes from tf2mt, reads the latest release of `cmer81/cssilicon`. Before installing, it
needs:
- an asset named exactly `CSSilicon-app.zip`;
- GitHub's `sha256:` digest for that asset;
- the bundle id;
- the version matching the tag;
- `codesign --verify`.

It never updates while the game runs.

To test it locally:
- the defaults key `updateFeedURL` accepts a `file://` feed;
- `CSSILICON_UPDATE_AUTOINSTALL=1` installs without asking;
- run the copy from a temp folder, not from `/Applications`;
- delete `updateFeedURL` afterwards.

## Visuals and text

- Valve art (`library_hero.jpg`, `logo.png`) is read from the player's Steam library cache at runtime, never bundled.
- CS:S ships only icon fonts, so the UI uses system fonts.
- UI text is English: CSSilicon, CS:S.
