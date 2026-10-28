#!/bin/bash
# Publish a CSSilicon release on GitHub (cmer81/cssilicon): tag, build, upload CSSilicon-app.zip.
#   tools/release.sh v0.1.0 [notes-file]
# The in-app updater offers non-draft, non-prerelease releases whose tag is newer than the installed app and that carry
# an asset named exactly CSSilicon-app.zip; the app's version comes from `git describe --tags`, so the tag is created
# before the build (and deleted again if anything fails before it is pushed). The Wine runtime is not part of a
# release: setup.sh downloads tf2mt's (config/release.conf).

# A releasable app carries the Metal renderer (the default; build.sh only warns when it fails to build) and the
# display tool. Returns 1 and names what is missing otherwise.
check_bundle() {
  local r="$1/Contents/Resources/cssmt" f missing=0
  for f in build/tf2mt/tf2mt.dll build/tf2mt/tf2mt.so build/tf2mt/d3d9.dll build/tools/displaymode scripts/play.sh; do
    [ -f "$r/$f" ] || { echo "missing from the app: $f"; missing=1; }
  done
  return $missing
}

[ -n "${RELEASE_LIB:-}" ] && return 0   # tests: functions only

set -euo pipefail
cd "$(dirname "$0")/.."
tag=${1:?usage: tools/release.sh vX.Y.Z [notes-file]}; notes=${2:-}
[[ $tag =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "tag must look like v1.2.3"; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "working tree not clean"; exit 1; }
git fetch -q origin
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || { echo "HEAD is not origin/main — push first"; exit 1; }
git rev-parse -q --verify "refs/tags/$tag" >/dev/null && { echo "tag $tag already exists"; exit 1; }

make -s test-scripts test-display test-launcher >/dev/null || { echo "tests failed"; exit 1; }
git tag -a "$tag" -m "CSSilicon $tag"
trap 'echo "release failed: removing local tag $tag"; git tag -d "$tag" >/dev/null' EXIT
tools/launcher/build.sh --no-install
app=build/launcher/CSSilicon.app; zip=build/launcher/CSSilicon-app.zip
check_bundle "$app" || exit 1
v=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$app/Contents/Info.plist")
[ "$v" = "$tag" ] || { echo "built version $v, expected $tag"; exit 1; }

git push -q origin "$tag"
trap - EXIT   # the tag is published now
args=(--title "CSSilicon $tag")
if [ -n "$notes" ]; then args+=(--notes-file "$notes"); else args+=(--generate-notes); fi
gh release create "$tag" "$zip" --repo cmer81/cssilicon "${args[@]}"
echo "released $tag ($(shasum -a 256 "$zip" | cut -d' ' -f1))"
