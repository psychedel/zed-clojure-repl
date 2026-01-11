#!/usr/bin/env bash
# Zed Clojure REPL - Installation Script

set -e

INSTALL_DIR="$HOME/.zed-clojure-repl"
ZED_CONFIG="$HOME/.config/zed"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Zed Clojure REPL Installer ==="
echo ""

# Check dependencies
echo "Checking dependencies..."
command -v clojure >/dev/null 2>&1 || { echo "Error: Clojure CLI required. Install: https://clojure.org/guides/install_clojure"; exit 1; }
echo "  clojure: OK"

# Create install directory
echo ""
echo "Installing scripts to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR/scripts"
cp "$SCRIPT_DIR/scripts/"* "$INSTALL_DIR/scripts/"
chmod +x "$INSTALL_DIR/scripts/"*.sh

# Configure Zed
echo ""
echo "Configuring Zed..."
mkdir -p "$ZED_CONFIG"

NEED_MANUAL=false

# Tasks
if [ -f "$ZED_CONFIG/tasks.json" ]; then
    if grep -q "Clojure: Eval Selection" "$ZED_CONFIG/tasks.json"; then
        echo "  tasks.json: Clojure tasks already present"
    else
        echo "  tasks.json: exists with other tasks"
        cp "$SCRIPT_DIR/config/tasks.json" "$ZED_CONFIG/tasks.clojure.json"
        echo "  Created tasks.clojure.json - merge manually"
        NEED_MANUAL=true
    fi
else
    cp "$SCRIPT_DIR/config/tasks.json" "$ZED_CONFIG/tasks.json"
    echo "  Created tasks.json"
fi

# Keymap
if [ -f "$ZED_CONFIG/keymap.json" ]; then
    if grep -q "Clojure: Eval Selection" "$ZED_CONFIG/keymap.json"; then
        echo "  keymap.json: Clojure bindings already present"
    else
        echo "  keymap.json: exists with other bindings"
        cp "$SCRIPT_DIR/config/keymap.json" "$ZED_CONFIG/keymap.clojure.json"
        echo "  Created keymap.clojure.json - merge manually"
        NEED_MANUAL=true
    fi
else
    cp "$SCRIPT_DIR/config/keymap.json" "$ZED_CONFIG/keymap.json"
    echo "  Created keymap.json"
fi

echo ""
echo "=== Installation Complete ==="

if [ "$NEED_MANUAL" = true ]; then
    echo ""
    echo "MANUAL STEPS REQUIRED:"
    echo "  Merge contents of tasks.clojure.json into tasks.json"
    echo "  Merge contents of keymap.clojure.json into keymap.json"
    echo "  Then delete the .clojure.json files"
fi

echo ""
echo "Quick start:"
echo "  1. Start nREPL: lein repl :headless"
echo "  2. Open .clj file in Zed"
echo "  3. Select code, press Ctrl+X Ctrl+E"
echo ""
echo "Key bindings:"
echo "  Ctrl+X Ctrl+E  - Eval selection"
echo "  Ctrl+C Ctrl+C  - Eval form at cursor"
echo "  Ctrl+C Ctrl+K  - Eval buffer"
echo "  Ctrl+C Ctrl+D  - Documentation"
echo "  Ctrl+C Ctrl+T  - Run tests"
echo ""
