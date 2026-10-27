#!/bin/bash
# Builds build/FinderNewFile.app (with its Finder extension) for Apple Silicon.
# Set SIGN_IDENTITY to a codesigning identity to sign with it (default: ad-hoc).
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/FinderNewFile.app"
APPEX="$APP/Contents/PlugIns/FinderNewFileExtension.appex"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
SWIFTC=(xcrun swiftc -O -swift-version 5 -target arm64-apple-macos13.0 -parse-as-library)

if [ ! -f Resources/AppIcon.icns ]; then
    ICONSET="$(mktemp -d)/AppIcon.iconset"
    swift scripts/make-icon.swift "$ICONSET"
    iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APPEX/Contents/MacOS" "$APPEX/Contents/Resources"

# The extension has no main(): the system's NSExtensionMain starts it.
"${SWIFTC[@]}" -application-extension -module-name FinderNewFileExtension \
    -Xlinker -e -Xlinker _NSExtensionMain \
    Sources/Extension/*.swift -o "$APPEX/Contents/MacOS/FinderNewFileExtension"
cp Resources/Extension-Info.plist "$APPEX/Contents/Info.plist"
cp -R Resources/Localizations/*.lproj "$APPEX/Contents/Resources/"

"${SWIFTC[@]}" -module-name FinderNewFile Sources/App/*.swift -o "$APP/Contents/MacOS/FinderNewFile"
cp Resources/App-Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp -R Resources/Localizations/*.lproj "$APP/Contents/Resources/"

# Sign the extension first, then the app around it.
codesign --force --sign "$SIGN_IDENTITY" --entitlements Resources/Extension.entitlements \
    --identifier com.matteonardone.FinderNewFile.Extension "$APPEX"
codesign --force --sign "$SIGN_IDENTITY" --identifier com.matteonardone.FinderNewFile "$APP"

echo "Built $APP"
