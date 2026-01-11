#!/usr/bin/env bash
# nREPL client for Zed - sends code to running nREPL
# For ClojureScript: uses --session to maintain cljs context per-project

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

find_port() {
    local port_type="${1:-clj}"
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ "$port_type" = "cljs" ]; then
            [ -f "$dir/.shadow-cljs/nrepl.port" ] && echo "$dir/.shadow-cljs/nrepl.port" && return 0
        else
            [ -f "$dir/.nrepl-port" ] && cat "$dir/.nrepl-port" && return 0
        fi
        dir="$(dirname "$dir")"
    done
    [ -f "$HOME/.nrepl-port" ] && cat "$HOME/.nrepl-port" && return 0
    echo ""
}

find_shadow_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        [ -f "$dir/shadow-cljs.edn" ] && echo "$dir" && return 0
        dir="$(dirname "$dir")"
    done
    echo ""
}

find_cljs_build() {
    local shadow_root="$1"
    [ -z "$shadow_root" ] && echo "app" && return
    
    local edn_file="$shadow_root/shadow-cljs.edn"
    [ ! -f "$edn_file" ] && echo "app" && return
    
    # Find :builds line, then extract build ids (lines with 1-2 space indent + :keyword)
    local builds_line
    builds_line=$(grep -n "^ *:builds" "$edn_file" 2>/dev/null | head -1 | cut -d: -f1)
    
    if [ -n "$builds_line" ]; then
        local build
        build=$(awk -v start="$builds_line" 'NR > start && /^[[:space:]]{1,2}:[a-zA-Z]/ { 
            gsub(/^[[:space:]]+/, ""); 
            gsub(/[[:space:]].*/, ""); 
            gsub(":", ""); 
            print; exit
        }' "$edn_file")
        [ -n "$build" ] && echo "$build" && return
    fi
    
    echo "app"
}

get_session_file() {
    local shadow_root="$1"
    if [ -n "$shadow_root" ]; then
        # Use hash of path for unique session file per project
        local hash
        if command -v md5sum >/dev/null 2>&1; then
            hash=$(echo "$shadow_root" | md5sum | cut -c1-8)
        elif command -v md5 >/dev/null 2>&1; then
            hash=$(echo "$shadow_root" | md5 | cut -c1-8)
        else
            hash=$(echo "$shadow_root" | cksum | cut -d' ' -f1)
        fi
        echo "$HOME/.zed-cljs-session-$hash"
    else
        echo "$HOME/.zed-cljs-session"
    fi
}

check_port_alive() {
    local port="$1"
    (nc -z 127.0.0.1 "$port" >/dev/null 2>&1) && return 0
    return 1
}

extract_symbol() {
    local input="$1"
    echo "$input" | head -1 | sed 's/^[[:space:]]*[([\{#'\''`~@]*//; s/[[:space:]].*$//'
}

print_no_repl_error() {
    local repl_type="$1"
    if [ "$repl_type" = "cljs" ]; then
        echo -e "${RED}Error: No shadow-cljs nREPL found${NC}"
        echo ""
        echo "Start shadow-cljs first with Ctrl+C Ctrl+B"
    else
        echo -e "${RED}Error: No nREPL server found${NC}"
        echo ""
        echo "Start the REPL first with Ctrl+C Ctrl+R"
    fi
}

EXPLICIT_PORT=""
USE_CLJS=false
USE_TAP=true

while [[ "$1" =~ ^- ]]; do
    case "$1" in
        -p|--port) EXPLICIT_PORT="$2"; shift 2 ;;
        --cljs) USE_CLJS=true; shift ;;
        --no-tap) USE_TAP=false; shift ;;
        *) break ;;
    esac
done

if [ -n "$EXPLICIT_PORT" ]; then
    PORT="$EXPLICIT_PORT"
elif [ "$USE_CLJS" = true ]; then
    PORT_FILE=$(find_port cljs)
    [ -n "$PORT_FILE" ] && PORT=$(cat "$PORT_FILE") || PORT=""
else
    PORT=$(find_port clj)
fi

NO_TAP_COMMANDS=false

case "$1" in
    -f|--file) CODE="(load-file \"$2\")"; NO_TAP_COMMANDS=true ;;
    -r|--reload) CODE="(require '[$2] :reload)"; NO_TAP_COMMANDS=true ;;
    -t|--test) CODE="(do (require 'clojure.test) (require '[$2] :reload) (clojure.test/run-tests '$2))"; NO_TAP_COMMANDS=true ;;
    -d|--doc) SYM=$(extract_symbol "$2"); CODE="(do (require 'clojure.repl) (clojure.repl/doc $SYM))"; NO_TAP_COMMANDS=true ;;
    -s|--source) SYM=$(extract_symbol "$2"); CODE="(do (require 'clojure.repl) (clojure.repl/source $SYM))"; NO_TAP_COMMANDS=true ;;
    -a|--apropos) CODE="(do (require 'clojure.repl) (clojure.repl/apropos \"$2\"))"; NO_TAP_COMMANDS=true ;;
    -e|--pst) CODE="(do (require 'clojure.repl) (clojure.repl/pst))"; NO_TAP_COMMANDS=true ;;
    --dir) CODE="(do (require 'clojure.repl) (clojure.repl/dir $2))"; NO_TAP_COMMANDS=true ;;
    --status) CODE="(println \"nREPL connected. Clojure\" (clojure-version))"; NO_TAP_COMMANDS=true ;;
    -h|--help) echo "Usage: nrepl-eval.sh [--cljs] '<code>'"; exit 0 ;;
    *) CODE="$1" ;;
esac

[ -z "$CODE" ] && echo "Usage: nrepl-eval.sh [--cljs] '<code>'" && exit 1

if [ -z "$PORT" ]; then
    [ "$USE_CLJS" = true ] && print_no_repl_error "cljs" || print_no_repl_error "clj"
    exit 1
fi

if ! check_port_alive "$PORT"; then
    echo -e "${YELLOW}nREPL port $PORT not responding${NC}"
    [ "$USE_CLJS" = true ] && print_no_repl_error "cljs" || print_no_repl_error "clj"
    exit 1
fi

if [ "$USE_TAP" = true ] && [ "$NO_TAP_COMMANDS" = false ]; then
    CODE="(tap> (do $CODE))"
fi

if [ "$USE_CLJS" = true ]; then
    SHADOW_ROOT=$(find_shadow_root)
    BUILD=$(find_cljs_build "$SHADOW_ROOT")
    SESSION_FILE=$(get_session_file "$SHADOW_ROOT")
    exec clojure -M "$SCRIPT_DIR/nrepl-client.clj" "$PORT" --session "$SESSION_FILE" --init-cljs "$BUILD" "$CODE"
else
    exec clojure -M "$SCRIPT_DIR/nrepl-client.clj" "$PORT" "$CODE"
fi
