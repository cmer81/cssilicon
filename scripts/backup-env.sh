#!/bin/bash
# instant APFS copy-on-write backup of the whole game environment
. "$(dirname "$0")/_env.sh"; "$WINESERVER" -k 2>/dev/null
D="$CSS_HOME.backup-$(date +%Y%m%d-%H%M%S)"; cp -cR "$CSS_HOME" "$D" && echo "backup: $D"
