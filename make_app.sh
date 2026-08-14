#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP="Switchsmith.app"
BIN_NAME="Switchsmith"

echo "Building for production..."
swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp ".build/release/$BIN_NAME" "$APP/Contents/MacOS/$BIN_NAME"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Switchsmith</string>
    <key>CFBundleDisplayName</key>
    <string>Switchsmith</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.switchsmith</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>$BIN_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.5</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP"
echo "Built $APP"
