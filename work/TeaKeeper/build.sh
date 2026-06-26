#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/../../outputs/TeaKeeper.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"
python3 "$ROOT/generate_icon.py" "$APP/Contents/Resources/AppIcon.icns" "$ROOT/../../outputs/TeaKeeperIconPreview.png"

swiftc \
  -target arm64-apple-macosx13.0 \
  "$ROOT"/Sources/*.swift \
  -framework AppKit \
  -framework IOKit \
  -framework ServiceManagement \
  -o "$APP/Contents/MacOS/TeaKeeper"

chmod +x "$APP/Contents/MacOS/TeaKeeper"
codesign --force --sign - "$APP" >/dev/null

echo "$APP"
