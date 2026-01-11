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
command -v clojure >/dev/null 2>&1 || { echo "Error: Clojure CLI not found. Install from https://clojure.org/guides/install_clojure"; exit 1; }
echo "  clojure: OK"

# Create install directory
echo ""
echo "Installing scripts to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR/scripts"
cp "$SCRIPT_DIR/scripts/"* "$INSTALL_DIR/scripts/"
chmod +x "$INSTALL_DIR/scripts/"*.sh

# Backup and merge Zed config
echo ""
echo "Configuring Zed..."
mkdir -p "$ZED_CONFIG"

# Tasks
if [ -f "$ZED_CONFIG/tasks.json" ]; then
    echo "  tasks.json exists - backing up to tasks.json.bak"
    cp "$ZED_CONFIG/tasks.json" "$ZED_CONFIG/tasks.json.bak"
    echo "  Merging Clojure tasks..."
    # Simple merge: append our tasks if not already present
    if grep -q "Clojure: Eval Selection" "$ZED_CONFIG/tasks.json"; then
        echo "  Clojure tasks already present - skipping"
    else
        # Remove closing bracket, append our tasks, close bracket
        sed -i '$ d' "$ZED_CONFIG/tasks.json"
        echo "," >> "$ZED_CONFIG/tasks.json"
        tail -n +2 "$SCRIPT_DIR/config/tasks.json" >> "$ZED_CONFIG/tasks.json"
    fi
else
    cp "$SCRIPT_DIR/config/tasks.json" "$ZED_CONFIG/tasks.json"
    echo "  Created tasks.json"
fi

# Keymap
if [ -f "$ZED_CONFIG/keymap.json" ]; then
    echo "  keymap.json exists - backing up to keymap.json.bak"
    cp "$ZED_CONFIG/keymap.json" "$ZED_CONFIG/keymap.json.bak"
    if grep -q "Clojure: Eval Selection" "$ZED_CONFIG/keymap.json"; then
        echo "  Clojure keybindings already present - skipping"
    else
        sed -i '$ d' "$ZED_CONFIG/keymap.json"
        echo "," >> "$ZED_CONFIG/keymap.json"
        tail -n +2 "$SCRIPT_DIR/config/keymap.json" >> "$ZED_CONFIG/keymap.json"
    fi
else
    cp "$SCRIPT_DIR/config/keymap.json" "$ZED_CONFIG/keymap.json"
    echo "  Created keymap.json"
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Quick start:"
echo "  1. Start nREPL in your project: lein repl :headless"
echo "  2. Open a .clj file in Zed"
echo "  3. Select code and press Ctrl+X Ctrl+E to evaluate"
echo ""
echo "Key bindings:"
echo "  Ctrl+X Ctrl+E  - Eval selection"
echo "  Ctrl+C Ctrl+C  - Eval form at cursor"
echo "  Ctrl+C Ctrl+K  - Eval buffer"
echo "  Ctrl+C Ctrl+D  - Show documentation"
echo "  Ctrl+C Ctrl+T  - Run tests"
echo ""
