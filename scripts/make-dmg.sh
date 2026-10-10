#!/bin/bash
# Builds Plug.app and packs it into build/Plug-<version>.dmg: the app plus an
# Applications shortcut to drag it onto. Runs on macOS (uses hdiutil).
set -euo pipefail

cd "$(dirname "$0")/.."

scripts/bundle.sh
version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' build/Plug.app/Contents/Info.plist)"

staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
ditto build/Plug.app "$staging/Plug.app"
ln -s /Applications "$staging/Applications"

dmg="build/Plug-$version.dmg"
rm -f "$dmg"
hdiutil create -volname "Plug $version" -srcfolder "$staging" -fs HFS+ -format UDZO -ov "$dmg" >/dev/null
echo "Built $dmg"
