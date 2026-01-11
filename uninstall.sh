#!/usr/bin/env bash
# Zed Clojure REPL - Uninstall Script

INSTALL_DIR="$HOME/.zed-clojure-repl"

# Detect Zed config location (macOS vs Linux)
if [ "$(uname)" = "Darwin" ]; then
    ZED_CONFIG="$HOME/Library/Application Support/Zed"
else
    ZED_CONFIG="$HOME/.config/zed"
fi

echo "=== Zed Clojure REPL Uninstaller ==="
echo ""

# Remove install directory
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing: $INSTALL_DIR"
    rm -rf "$INSTALL_DIR"
    echo "  Done"
else
    echo "Install directory not found (already removed?)"
fi

# Clean up temporary config files created by installer
for f in "$ZED_CONFIG/tasks.clojure.json" "$ZED_CONFIG/keymap.clojure.json"; do
    if [ -f "$f" ]; then
        rm "$f"
        echo "Removed: $(basename "$f")"
    fi
done

echo ""
echo "Uninstall complete."
echo ""
echo "NOTE: Clojure tasks/keybindings remain in Zed config."
echo "To remove them, edit these files manually:"
echo "  $ZED_CONFIG/tasks.json"
echo "  $ZED_CONFIG/keymap.json"
echo "Remove entries containing 'Clojure:' or 'ClojureScript:'"
