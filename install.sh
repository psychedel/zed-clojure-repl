#!/usr/bin/env bash
# Zed Clojure REPL - Installation Script

set -e

INSTALL_DIR="$HOME/.zed-clojure-repl"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Detect Zed config location (macOS vs Linux)
if [ "$(uname)" = "Darwin" ]; then
    ZED_CONFIG="$HOME/Library/Application Support/Zed"
else
    ZED_CONFIG="$HOME/.config/zed"
fi

echo "=== Zed Clojure REPL Installer ==="
echo ""

# Check dependencies
echo "Checking dependencies..."
command -v clojure >/dev/null 2>&1 || { echo "Error: Clojure CLI required. Install: https://clojure.org/guides/install_clojure"; exit 1; }
command -v nc >/dev/null 2>&1 || { echo "Warning: netcat (nc) not found. Port checking may not work."; }
echo "  clojure: OK"

# Create install directory
echo ""
echo "Installing scripts to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR/scripts"
cp "$SCRIPT_DIR/scripts/"* "$INSTALL_DIR/scripts/"
chmod +x "$INSTALL_DIR/scripts/"*.sh 2>/dev/null || true
chmod +x "$INSTALL_DIR/scripts/"*.clj 2>/dev/null || true

# Configure Zed
echo ""
echo "Configuring Zed ($ZED_CONFIG)..."
mkdir -p "$ZED_CONFIG"

NEED_MANUAL=false

# Tasks
if [ -f "$ZED_CONFIG/tasks.json" ]; then
    if grep -q "Clojure: Start Rebel REPL" "$ZED_CONFIG/tasks.json"; then
        echo "  tasks.json: Clojure tasks already present (up to date)"
    elif grep -q "Clojure:" "$ZED_CONFIG/tasks.json"; then
        echo "  tasks.json: Old Clojure tasks found"
        cp "$SCRIPT_DIR/config/tasks.json" "$ZED_CONFIG/tasks.clojure.json"
        echo "  Created tasks.clojure.json - replace old entries manually"
        NEED_MANUAL=true
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
    if grep -q "Clojure: Start Rebel REPL" "$ZED_CONFIG/keymap.json"; then
        echo "  keymap.json: Clojure bindings already present (up to date)"
    elif grep -q "Clojure:" "$ZED_CONFIG/keymap.json"; then
        echo "  keymap.json: Old Clojure bindings found"
        cp "$SCRIPT_DIR/config/keymap.json" "$ZED_CONFIG/keymap.clojure.json"
        echo "  Created keymap.clojure.json - replace old entries manually"
        NEED_MANUAL=true
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
    echo "  Merge contents of *.clojure.json files into corresponding Zed config files"
    echo "  Then delete the .clojure.json files"
fi

echo ""
echo "Restart Zed, then:"
echo "  1. Open .clj file"
echo "  2. Press Ctrl+C Ctrl+R to start Rebel REPL"
echo "  3. Select code, press Ctrl+X Ctrl+E to eval"
echo ""
