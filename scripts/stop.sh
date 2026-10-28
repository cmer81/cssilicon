#!/bin/bash
. "$(dirname "$0")/_env.sh"; "$WINESERVER" -k 2>/dev/null; rm -f "$CSS_HOME/cache/wine-session-sync"; echo "wine stopped"
