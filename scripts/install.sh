#!/bin/bash
# Builds FinderNewFile, installs it to /Applications, turns on its Finder extension and opens it.
set -euo pipefail
cd "$(dirname "$0")/.."

EXTENSION_ID="com.matteonardone.FinderNewFile.Extension"

./scripts/build.sh

pkill -x FinderNewFile 2>/dev/null || true
rm -rf /Applications/FinderNewFile.app
cp -R build/FinderNewFile.app /Applications/

# Register only the installed copy, so Finder doesn't pick the one in build/.
pluginkit -r "$PWD/build/FinderNewFile.app/Contents/PlugIns/FinderNewFileExtension.appex" 2>/dev/null || true
pluginkit -a /Applications/FinderNewFile.app/Contents/PlugIns/FinderNewFileExtension.appex
pluginkit -e use -i "$EXTENSION_ID"

# Relaunch Finder so it loads the new extension.
killall Finder 2>/dev/null || true

open /Applications/FinderNewFile.app
echo "Installed /Applications/FinderNewFile.app — right-click empty space in Finder and choose New File."
