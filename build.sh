#!/bin/bash
# Build bear-cli and package into app bundle
#
# Source code lives in ~/Developer/bearcli/
# Executable app bundle lives in ~/development/bear-cli/BearCLI.app/

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/development/bear-cli"

cd "$SCRIPT_DIR"

echo "Building bear-cli..."
swift build

echo "Packaging app bundle..."
mkdir -p "$INSTALL_DIR/BearCLI.app/Contents/MacOS"
cp .build/debug/bear-cli "$INSTALL_DIR/BearCLI.app/Contents/MacOS/bear-cli"
cp Sources/BearCLI/Info.plist "$INSTALL_DIR/BearCLI.app/Contents/Info.plist"

echo "Registering URL scheme..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$INSTALL_DIR/BearCLI.app"

echo "Done!"
echo "  Source:     $SCRIPT_DIR/"
echo "  Executable: $INSTALL_DIR/BearCLI.app/Contents/MacOS/bear-cli"
