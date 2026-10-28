#!/bin/bash
# cssmt setup — idempotent: every step checks first and skips what is already done.
#   scripts/setup.sh [--runtime <path-or-url to tf2mt-runtime-*.tar.xz>]
# Steps: rosetta → wine runtime → prefix + DXVK → Steam (Windows) → cssmt configs → mouse patch.
# Afterwards: log in to Steam once (scripts/steam.sh --login) and install CS:S (steam://install/240).
# Output lines starting with "==>" are step headers, "OK"/"SKIP"/"FAIL"/"TODO" are results (parsed by the launcher).
set -u
. "$(dirname "$0")/_env.sh"
. "$CSSMT_ROOT/config/release.conf" 2>/dev/null || true   # RUNTIME_URL / RUNTIME_SHA256 of the published runtime

RUNTIME_SRC="${TF2MT_RUNTIME:-${RUNTIME_URL:-}}"
while [ $# -gt 0 ]; do
  case $1 in --runtime) RUNTIME_SRC=$2; shift 2 ;; *) echo "unknown option $1"; exit 2 ;; esac
done

step() { echo "==> $1"; }
ok()   { echo "OK   $1"; }
skip() { echo "SKIP $1"; }
todo() { echo "TODO $1"; }
fail() { echo "FAIL $1"; exit 1; }

mkdir -p "$CSS_HOME"/{logs,config,cache,backups}

step "Rosetta 2"
if [ -e /Library/Apple/usr/libexec/oah/libRosettaRuntime ]; then skip "installed"
else
  softwareupdate --install-rosetta --agree-to-license >/dev/null 2>&1 \
    && ok "installed" || fail "could not install Rosetta — run: softwareupdate --install-rosetta --agree-to-license"
fi

step "Wine runtime ($CSS_HOME/wine)"
if [ -x "$WINE" ]; then skip "present ($("$WINE" --version 2>/dev/null))"
else
  [ -n "$RUNTIME_SRC" ] || fail "no runtime source — pass --runtime <tf2mt-runtime-*.tar.xz path or URL> (see README)"
  tarball="$RUNTIME_SRC"
  if [[ $RUNTIME_SRC == http* ]]; then
    tarball="$CSS_HOME/cache/$(basename "$RUNTIME_SRC")"
    echo "     downloading $RUNTIME_SRC"
    curl -fsSL --retry 3 -o "$tarball.part" "$RUNTIME_SRC" && mv "$tarball.part" "$tarball" || fail "download failed"
  fi
  if [ -n "${RUNTIME_SHA256:-}" ]; then
    echo "$RUNTIME_SHA256  $tarball" | shasum -a 256 -c - >/dev/null || fail "runtime checksum mismatch"
  fi
  tar -xJf "$tarball" -C "$CSS_HOME" || fail "could not unpack $tarball"
  xattr -dr com.apple.quarantine "$CSS_HOME/wine" 2>/dev/null
  [ -x "$WINE" ] && ok "installed ($("$WINE" --version))" || fail "runtime unpacked but $WINE missing"
fi

step "Wine prefix + DXVK ($WINEPREFIX)"
if [ ! -f "$WINEPREFIX/system.reg" ]; then
  WINEDLLOVERRIDES="mscoree,mshtml=" "$WINE" wineboot -u >/dev/null 2>&1
  "$WINESERVER" -w
  [ -f "$WINEPREFIX/system.reg" ] || fail "wineboot did not create the prefix"
fi
dx="$CSS_HOME/wine/share/dxvk"
cp "$dx/x86_64-windows/d3d9.dll" "$WINEPREFIX/drive_c/windows/system32/d3d9.dll" || fail "DXVK x64 copy"
cp "$dx/i386-windows/d3d9.dll" "$WINEPREFIX/drive_c/windows/syswow64/d3d9.dll" || fail "DXVK x86 copy"
for exe in "$CSS_EXE" "$CSS_STUB"; do
  "$WINE" reg add "HKCU\\Software\\Wine\\AppDefaults\\$exe\\DllOverrides" /v d3d9 /t REG_SZ /d native /f >/dev/null 2>&1 \
  || fail "registry override"
done
ok "prefix ready, DXVK d3d9 installed for $CSS_EXE"

step "Steam for Windows"
if [ -f "$STEAM_DIR/steam.exe" ]; then skip "installed"
else
  inst="$CSS_HOME/cache/SteamSetup.exe"
  curl -fsSL --retry 3 -o "$inst" https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe || fail "Steam installer download failed"
  "$WINE" "$inst" /S >/dev/null 2>&1      # NSIS silent install; the installer starts Steam afterwards
  for _ in $(seq 60); do [ -f "$STEAM_DIR/steam.exe" ] && break; sleep 2; done
  "$WINESERVER" -k 2>/dev/null           # stop the auto-started Steam; first login is done via the launcher
  [ -f "$STEAM_DIR/steam.exe" ] && ok "installed" || fail "Steam installer did not finish"
fi

step "cssmt configs"
for f in dxvk.conf dxvk-immediate.conf; do cp "$CSSMT_ROOT/config/$f" "$CSS_HOME/config/$f"; done
ok "DXVK configs → $CSS_HOME/config"

step "Smooth mouse fix (Wine patch)"
st=$(/bin/bash "$CSSMT_ROOT/tools/wine-patches/winemac_warp_nodiscard.sh" status 2>&1)
case $st in
  patched*)  skip "already applied" ;;
  original*) /bin/bash "$CSSMT_ROOT/tools/wine-patches/winemac_warp_nodiscard.sh" apply >/dev/null && ok "applied" || fail "patch failed" ;;
  *)         todo "this Wine build is not the tested one — patch not applied (mouse may feel ~40 Hz)" ;;
esac

step "Steam login + Counter-Strike: Source"
if grep -q '"StateFlags"[[:space:]]*"4"' "$STEAM_DIR/steamapps/appmanifest_$CSS_APPID.acf" 2>/dev/null; then skip "CS:S installed"
elif grep -q 'Logged On' "$STEAM_DIR/logs/connection_log.txt" 2>/dev/null; then todo "install CS:S: in the launcher click “Install CS:S” (≈15 GB)"
else todo "log in to Steam once: in the launcher click “Log in to Steam”, then “Install CS:S”"
fi
echo "DONE"
