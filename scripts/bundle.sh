#!/bin/bash
# Builds Plug and wraps it in build/Plug.app with Bundle/Info.plist, so macOS
# can ask for audio-capture and microphone permission. Signs it ad hoc.
#
# Usage: scripts/bundle.sh [--debug] [--open]
#   --debug  debug build instead of release
#   --open   launch the app when done
# Set PLUG_BUNDLE_ID to change the bundle identifier (default com.erdoar.plug).
set -euo pipefail

cd "$(dirname "$0")/.."

config=release
open_app=false
for arg in "$@"; do
    case "$arg" in
        --debug) config=debug ;;
        --open) open_app=true ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

bundle_id="${PLUG_BUNDLE_ID:-com.erdoar.plug}"

swift build -c "$config" --product Plug
bin_dir="$(swift build -c "$config" --show-bin-path)"

app=build/Plug.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/Plug" "$app/Contents/MacOS/Plug"
sed "s/BUNDLE_ID/$bundle_id/" Bundle/Info.plist > "$app/Contents/Info.plist"
iconutil -c icns Bundle/AppIcon.iconset -o "$app/Contents/Resources/AppIcon.icns"
# The manual, for Help > Plug Help (works offline).
mkdir -p "$app/Contents/Resources/Manual"
cp Web/manual.html Web/plug.css Web/logo.png Web/favicon.svg Web/favicon-32.png Web/apple-touch-icon.png \
   "$app/Contents/Resources/Manual/"
plutil -lint "$app/Contents/Info.plist" >/dev/null

# Ad-hoc signature: enough to run locally. macOS keys permissions to the
# signature, so it may ask again after each rebuild.
codesign --force --sign - "$app"

echo "Built $app ($config, $bundle_id)"
if $open_app; then
    open "$app"
fi
