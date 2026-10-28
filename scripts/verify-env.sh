#!/bin/bash
. "$(dirname "$0")/_env.sh"
ok(){ [ -e "$1" ] && echo "ok   $1" || { echo "MISSING $1"; rc=1; }; }
rc=0
ok "$WINE"; ok "$STEAM_DIR/steam.exe"; ok "$STEAM_DIR/steamapps/appmanifest_$CSS_APPID.acf"; ok "$CSSDIR/$CSS_EXE"
ok "$CSSDIR/bin/x64/shaderapidx9.dll"; ok "$CSSDIR/$CSS_GAME/cfg/config.cfg"
"$WINE" --version; "$WINE" cmd /c ver 2>/dev/null | tail -1; "$WINESERVER" -k 2>/dev/null; exit $rc
