#!/bin/bash
# Build bearcli and package into app bundle
#
# Source code lives in ~/Developer/bearcli/
# Executable app bundle lives in ~/development/bearcli/bearcli.app/

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/development/bearcli"

cd "$SCRIPT_DIR"

echo "Building bearcli..."
swift build

echo "Packaging app bundle..."
mkdir -p "$INSTALL_DIR/bearcli.app/Contents/MacOS"
cp .build/debug/bearcli "$INSTALL_DIR/bearcli.app/Contents/MacOS/bearcli"
cp Sources/bearcli/Info.plist "$INSTALL_DIR/bearcli.app/Contents/Info.plist"

echo "Registering URL scheme..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$INSTALL_DIR/bearcli.app"

echo "Done!"
echo "  Source:     $SCRIPT_DIR/"
echo "  Executable: $INSTALL_DIR/bearcli.app/Contents/MacOS/bearcli"
