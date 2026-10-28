#!/bin/bash
# Build cssmt.app (native SwiftUI launcher) and install it to /Applications (--no-install to only build).
# The app is self-contained: it bundles the cssmt scripts/configs/patch tool, the display120 tool and an original
# icon. No Valve content is bundled — CS:S library art is loaded at runtime from the user's own install.
set -euo pipefail
cd "$(dirname "$0")"; ROOT="$(cd ../.. && pwd)"
OUT="$ROOT/build/launcher"; APP="$OUT/cssmt.app"; RES="$APP/Contents/Resources"
VERSION="$(git -C "$ROOT" describe --tags --always 2>/dev/null || echo 0.1)"
rm -rf "$OUT"; mkdir -p "$APP/Contents/MacOS" "$RES/cssmt/tools"
swiftc -O -parse-as-library -target arm64-apple-macos13 CSSLauncher.swift -o "$APP/Contents/MacOS/cssmt"
"$ROOT/.venv/bin/python" make_icon.py "$OUT/cssmt.iconset" "$OUT/icon-preview.png"
iconutil -c icns "$OUT/cssmt.iconset" -o "$RES/cssmt.icns"
# bundled cssmt: only what the launcher runs (scripts, configs, wine patch tool, display120, licence notes)
cp -R "$ROOT/scripts" "$ROOT/config" "$RES/cssmt/"
cp -R "$ROOT/tools/wine-patches" "$RES/cssmt/tools/"
cp "$ROOT/THIRD_PARTY.md" "$ROOT/LICENSE" "$RES/cssmt/"
make -C "$ROOT" -s display120
mkdir -p "$RES/cssmt/build/tools"; cp "$ROOT/build/tools/display120" "$RES/cssmt/build/tools/"
# experimental Metal renderer (tf2mt): prebuilt layer files, installed per session by scripts/css.sh (CSS_RENDERER=tf2mt)
if make -C "$ROOT" -s frontend unixlib >/dev/null 2>&1; then
  mkdir -p "$RES/cssmt/build/tf2mt"
  cp "$ROOT/build/tf2mt/tf2mt.dll" "$ROOT/build/tf2mt/tf2mt.so" "$ROOT/build/tf2mt/d3d9.dll" "$RES/cssmt/build/tf2mt/"
else
  echo "WARNING: Metal renderer build failed; the app will fall back to DXVK" >&2
fi
# frame-time recording proxy for DXVK sessions (CSS_FRAMELOG=1, launcher Debug tab)
if make -C "$ROOT" -s trace >/dev/null 2>&1 && [ -f "$ROOT/build/trace/d3d9.dll" ]; then
  mkdir -p "$RES/cssmt/build/trace"; cp "$ROOT/build/trace/d3d9.dll" "$RES/cssmt/build/trace/"
fi
find "$RES/cssmt" -name '__pycache__' -prune -exec rm -rf {} +
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>cssmt</string>
  <key>CFBundleDisplayName</key><string>cssmt</string>
  <key>CFBundleIdentifier</key><string>local.cssmt.launcher</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleExecutable</key><string>cssmt</string>
  <key>CFBundleIconFile</key><string>cssmt</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.games</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSMicrophoneUsageDescription</key><string>CS:S voice chat uses your microphone.</string>
</dict></plist>
PLIST
# invisible session helper app (macOS 27: Steam/Wine/the game must not be attributed to the launcher, see CSSSession.swift)
SES="$APP/Contents/Helpers/cssmt Session.app"; mkdir -p "$SES/Contents/MacOS"
swiftc -O -target arm64-apple-macos13 session/CSSSession.swift -o "$SES/Contents/MacOS/cssmt-session"
cat > "$SES/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>cssmt Session</string>
  <key>CFBundleIdentifier</key><string>local.cssmt.session</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleExecutable</key><string>cssmt-session</string>
  <key>LSUIElement</key><true/>
  <key>NSMicrophoneUsageDescription</key><string>CS:S voice chat uses your microphone.</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
</dict></plist>
PLIST
codesign -f -s - --deep "$APP" >/dev/null 2>&1
echo "built $APP"
if [ "${1:-}" != --no-install ]; then
  rm -rf "/Applications/cssmt.app"; cp -R "$APP" /Applications/
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/cssmt.app
  echo "installed /Applications/cssmt.app"
fi
