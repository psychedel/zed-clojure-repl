#!/usr/bin/env bash
# Zed Clojure REPL - Uninstall Script

INSTALL_DIR="$HOME/.zed-clojure-repl"
ZED_CONFIG="$HOME/.config/zed"

echo "=== Zed Clojure REPL Uninstaller ==="
echo ""

# Remove install directory
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo "Removed $INSTALL_DIR"
fi

# Restore backups if they exist
if [ -f "$ZED_CONFIG/tasks.json.bak" ]; then
    mv "$ZED_CONFIG/tasks.json.bak" "$ZED_CONFIG/tasks.json"
    echo "Restored tasks.json from backup"
fi

if [ -f "$ZED_CONFIG/keymap.json.bak" ]; then
    mv "$ZED_CONFIG/keymap.json.bak" "$ZED_CONFIG/keymap.json"
    echo "Restored keymap.json from backup"
fi

echo ""
echo "Uninstall complete. Restart Zed to apply changes."
