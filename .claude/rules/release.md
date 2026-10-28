---
paths:
  - "tools/release.sh"
  - "tools/launcher/build.sh"
  - "config/release.conf"
  - "tests/scripts/test_release.sh"
---

# Releases

## The only way to release

Release with `tools/release.sh vX.Y.Z [notes-file]`. Never tag or upload by hand.

The app's version comes from `git describe --tags`, so the tag must exist before the build.

`release.sh` runs these steps in order:

1. Checks that the working tree is clean.
2. Checks that `HEAD == origin/main`.
3. Runs all three `make test-*` targets.
4. Tags.
5. Builds.
6. Checks the bundle with `check_bundle`. The Metal renderer is the default, so an app without it must never ship.
7. Checks the version.
8. Pushes the tag.
9. Runs `gh release create` with `build/launcher/CSSilicon-app.zip`.

If any step before the push fails, the local tag is deleted.

## Constraints

- **Asset name.** The asset must be named exactly `CSSilicon-app.zip`, or the in-app updater won't see the release.
  Draft and prerelease releases are ignored by the updater.
- **Version numbering.** CSSilicon numbers its own versions from v0.1.0. tf2mt's tags are never fetched
  (`remote.upstream.tagOpt=--no-tags`). They would make `git describe` report tf2mt's version.
- **Wine runtime.** The runtime is not in releases. `setup.sh` downloads tf2mt's published runtime from
  `config/release.conf`, which holds the URL and SHA-256.
- **Owner approval.** Releasing, force-pushing and changing repository visibility are outward-facing: do them only
  when the owner asks.
