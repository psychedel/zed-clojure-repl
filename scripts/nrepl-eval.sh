#!/usr/bin/env bash
# nREPL client for Zed - sends code to running nREPL
# For ClojureScript: uses session from .zed-cljs-session

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

find_project_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        [ -f "$dir/shadow-cljs.edn" ] || [ -f "$dir/deps.edn" ] || [ -f "$dir/project.clj" ] && echo "$dir" && return 0
        dir="$(dirname "$dir")"
    done
    echo "$PWD"
}

find_port() {
    local port_type="${1:-clj}"
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ "$port_type" = "cljs" ]; then
            [ -f "$dir/.shadow-cljs/nrepl.port" ] && cat "$dir/.shadow-cljs/nrepl.port" && return 0
        else
            [ -f "$dir/.nrepl-port" ] && cat "$dir/.nrepl-port" && return 0
        fi
        dir="$(dirname "$dir")"
    done
    [ -f "$HOME/.nrepl-port" ] && cat "$HOME/.nrepl-port" && return 0
    echo ""
}

find_cljs_session() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        [ -f "$dir/.zed-cljs-session" ] && echo "$dir/.zed-cljs-session" && return 0
        dir="$(dirname "$dir")"
    done
    echo ""
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

# Determine port
if [ -n "$EXPLICIT_PORT" ]; then
    PORT="$EXPLICIT_PORT"
elif [ "$USE_CLJS" = true ]; then
    PORT=$(find_port cljs)
else
    PORT=$(find_port clj)
fi

# Commands that shouldn't use tap>
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

# Check port
if [ -z "$PORT" ]; then
    if [ "$USE_CLJS" = true ]; then
        echo -e "${RED}Error: No shadow-cljs nREPL found${NC}"
        echo "Start shadow-cljs first with Ctrl+C Ctrl+B"
    else
        echo -e "${RED}Error: No nREPL server found${NC}"
        echo "Start the REPL first with Ctrl+C Ctrl+R"
    fi
    exit 1
fi

if ! check_port_alive "$PORT"; then
    echo -e "${YELLOW}nREPL port $PORT not responding${NC}"
    exit 1
fi

# Wrap in tap> for visibility in Rebel REPL
if [ "$USE_TAP" = true ] && [ "$NO_TAP_COMMANDS" = false ]; then
    CODE="(tap> (do $CODE))"
fi

# For ClojureScript, use session file
if [ "$USE_CLJS" = true ]; then
    SESSION_FILE=$(find_cljs_session)
    if [ -z "$SESSION_FILE" ]; then
        echo -e "${RED}Error: No ClojureScript session found${NC}"
        echo "Initialize first with Ctrl+C Ctrl+L"
        exit 1
    fi
    exec clojure -M "$SCRIPT_DIR/nrepl-client.clj" "$PORT" --session "$SESSION_FILE" "$CODE"
else
    exec clojure -M "$SCRIPT_DIR/nrepl-client.clj" "$PORT" "$CODE"
fi
