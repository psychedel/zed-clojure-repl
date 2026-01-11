#!/usr/bin/env bash
# Zed Clojure REPL - Uninstall Script

INSTALL_DIR="$HOME/.zed-clojure-repl"
ZED_CONFIG="$HOME/.config/zed"

echo "=== Zed Clojure REPL Uninstaller ==="
echo ""

# Remove install directory
if [ -d "$INSTALL_DIR" ]; then
    echo "Will remove: $INSTALL_DIR"
    rm -rf "$INSTALL_DIR"
    echo "  Removed"
else
    echo "Install directory not found (already removed?)"
fi

# Clean up temporary config files created by installer
if [ -f "$ZED_CONFIG/tasks.clojure.json" ]; then
    rm "$ZED_CONFIG/tasks.clojure.json"
    echo "Removed tasks.clojure.json"
fi

if [ -f "$ZED_CONFIG/keymap.clojure.json" ]; then
    rm "$ZED_CONFIG/keymap.clojure.json"
    echo "Removed keymap.clojure.json"
fi

echo ""
echo "Uninstall complete."
echo ""
echo "NOTE: If you want to remove Clojure tasks/keybindings from Zed,"
echo "manually edit ~/.config/zed/tasks.json and keymap.json"
echo "to remove entries containing 'Clojure:' or 'ClojureScript:'"
