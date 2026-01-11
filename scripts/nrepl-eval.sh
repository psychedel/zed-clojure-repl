#!/usr/bin/env bash
# nREPL client for Zed - sends code to running nREPL

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
            [ -f "$dir/.shadow-cljs/nrepl.port" ] && cat "$dir/.shadow-cljs/nrepl.port" && return 0
        else
            [ -f "$dir/.nrepl-port" ] && cat "$dir/.nrepl-port" && return 0
        fi
        dir="$(dirname "$dir")"
    done
    [ -f "$HOME/.nrepl-port" ] && cat "$HOME/.nrepl-port" && return 0
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

print_no_repl_error() {
    echo -e "${RED}Error: No nREPL server found${NC}"
    echo ""
    echo "Start the REPL first with Ctrl+C Ctrl+R"
}

EXPLICIT_PORT=""
USE_CLJS=false
USE_TAP=true  # Wrap in tap> by default for visibility in Rebel

while [[ "$1" =~ ^- ]]; do
    case "$1" in
        -p|--port) EXPLICIT_PORT="$2"; shift 2 ;;
        --cljs) USE_CLJS=true; shift ;;
        --no-tap) USE_TAP=false; shift ;;
        *) break ;;
    esac
done

[ -n "$EXPLICIT_PORT" ] && PORT="$EXPLICIT_PORT" || { [ "$USE_CLJS" = true ] && PORT=$(find_port cljs) || PORT=$(find_port clj); }

# Commands that shouldn't use tap> (they have their own output)
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
    -h|--help) echo "Usage: nrepl-eval.sh '<code>'"; exit 0 ;;
    *) CODE="$1" ;;
esac

[ -z "$CODE" ] && echo "Usage: nrepl-eval.sh '<code>'" && exit 1

if [ -z "$PORT" ]; then
    print_no_repl_error
    exit 1
fi

if ! check_port_alive "$PORT"; then
    echo -e "${YELLOW}nREPL port $PORT not responding${NC}"
    print_no_repl_error
    exit 1
fi

# Wrap in tap> for visibility in Rebel REPL (unless it's a special command)
if [ "$USE_TAP" = true ] && [ "$NO_TAP_COMMANDS" = false ]; then
    CODE="(tap> (do $CODE))"
fi

exec clojure -M "$SCRIPT_DIR/nrepl-client.clj" "$PORT" "$CODE"
