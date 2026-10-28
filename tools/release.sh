#!/bin/bash
# Publish a CSSilicon release on GitHub (cmer81/cssilicon): tag, build, upload CSSilicon-app.zip.
#   tools/release.sh v0.1.0 [notes-file]
# The in-app updater offers non-draft, non-prerelease releases whose tag is newer than the installed app and that carry
# an asset named exactly CSSilicon-app.zip; the app's version comes from `git describe --tags`, so the tag is created
# before the build. The Wine runtime is not part of a release: setup.sh downloads tf2mt's (config/release.conf).
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
tools/launcher/build.sh --no-install
zip=build/launcher/CSSilicon-app.zip
v=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" build/launcher/CSSilicon.app/Contents/Info.plist)
[ "$v" = "$tag" ] || { echo "built version $v, expected $tag"; git tag -d "$tag"; exit 1; }

git push -q origin "$tag"
args=(--title "CSSilicon $tag")
if [ -n "$notes" ]; then args+=(--notes-file "$notes"); else args+=(--generate-notes); fi
gh release create "$tag" "$zip" --repo cmer81/cssilicon "${args[@]}"
echo "released $tag ($(shasum -a 256 "$zip" | cut -d' ' -f1))"
