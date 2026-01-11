#!/usr/bin/env bash
# Start shadow-cljs watch with auto-detected builds

set -e

find_config() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        [ -f "$dir/shadow-cljs.edn" ] && echo "$dir/shadow-cljs.edn" && return 0
        dir="$(dirname "$dir")"
    done
    echo ""
}

CONFIG=$(find_config)

if [ -z "$CONFIG" ]; then
    echo "Error: shadow-cljs.edn not found"
    exit 1
fi

cd "$(dirname "$CONFIG")"

# Check if already running
if [ -f ".shadow-cljs/nrepl.port" ]; then
    PORT=$(cat .shadow-cljs/nrepl.port)
    if nc -z 127.0.0.1 "$PORT" 2>/dev/null; then
        echo "shadow-cljs already running on port $PORT"
        echo "Use Ctrl+C Ctrl+L to connect REPL"
        exit 0
    fi
fi

# Find :builds line, then extract build ids (lines with 1-2 space indent + :keyword)
BUILDS_LINE=$(grep -n "^ *:builds" shadow-cljs.edn 2>/dev/null | head -1 | cut -d: -f1)

if [ -n "$BUILDS_LINE" ]; then
    BUILDS=$(awk -v start="$BUILDS_LINE" 'NR > start && /^[[:space:]]{1,2}:[a-zA-Z]/ { 
        gsub(/^[[:space:]]+/, ""); 
        gsub(/[[:space:]].*/, ""); 
        gsub(":", ""); 
        print
    }' shadow-cljs.edn | tr '\n' ' ')
fi

if [ -z "$BUILDS" ]; then
    echo "No builds found in shadow-cljs.edn, trying 'app'..."
    BUILDS="app"
fi

echo "Starting shadow-cljs watch for: $BUILDS"
exec npx shadow-cljs watch $BUILDS
