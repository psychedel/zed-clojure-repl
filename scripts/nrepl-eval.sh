#!/usr/bin/env bash
# nREPL client for Zed - REPL-driven Clojure development

set -e

SCRIPT_DIR="$(dirname "$0")"
PORT=""

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

# Extract first symbol from expression like "(+ 2 3)" -> "+"
extract_symbol() {
    local input="$1"
    # Remove leading whitespace and opening parens/brackets
    local cleaned=$(echo "$input" | sed 's/^[[:space:]]*[([\{#'\''`~@]*//; s/[[:space:]].*$//')
    echo "$cleaned"
}

EXPLICIT_PORT=""
USE_CLJS=false

while [[ "$1" =~ ^- ]]; do
    case "$1" in
        -p|--port) EXPLICIT_PORT="$2"; shift 2 ;;
        --cljs) USE_CLJS=true; shift ;;
        *) break ;;
    esac
done

[ -n "$EXPLICIT_PORT" ] && PORT="$EXPLICIT_PORT" || { [ "$USE_CLJS" = true ] && PORT=$(find_port cljs) || PORT=$(find_port clj); }

case "$1" in
    -f|--file) CODE="(load-file \"$2\")" ;;
    -r|--reload) CODE="(require '[$2] :reload)" ;;
    -t|--test) CODE="(do (require 'clojure.test) (require '[$2] :reload) (clojure.test/run-tests '$2))" ;;
    -d|--doc)
        SYM=$(extract_symbol "$2")
        CODE="(do (require 'clojure.repl) (clojure.repl/doc $SYM))"
        ;;
    -s|--source)
        SYM=$(extract_symbol "$2")
        CODE="(do (require 'clojure.repl) (clojure.repl/source $SYM))"
        ;;
    -a|--apropos) CODE="(do (require 'clojure.repl) (clojure.repl/apropos \"$2\"))" ;;
    -e|--pst) CODE="(do (require 'clojure.repl) (clojure.repl/pst))" ;;
    --dir) CODE="(do (require 'clojure.repl) (clojure.repl/dir $2))" ;;
    --status) CODE="(println \"nREPL connected. Clojure\" (clojure-version))" ;;
    --cljs-status) PORT=$(find_port cljs); CODE="(do (require '[shadow.cljs.devtools.api :as shadow]) (println \"Builds:\" (shadow/get-build-ids)))" ;;
    -h|--help)
        cat << HELP
nREPL client for Zed

Usage:
  nrepl-eval.sh '<code>'           Evaluate Clojure code
  nrepl-eval.sh -f <file.clj>      Load file
  nrepl-eval.sh -r <ns>            Reload namespace
  nrepl-eval.sh -t <ns>            Run tests
  nrepl-eval.sh -d <symbol>        Show documentation (extracts symbol from expression)
  nrepl-eval.sh -s <symbol>        Show source (extracts symbol from expression)
  nrepl-eval.sh -a <pattern>       Apropos search
  nrepl-eval.sh -e                 Print last exception
  nrepl-eval.sh --cljs '<code>'    Eval in shadow-cljs
HELP
        exit 0 ;;
    *) CODE="$1" ;;
esac

[ -z "$CODE" ] && echo "Usage: nrepl-eval.sh '<code>'" && exit 1
[ -z "$PORT" ] && echo "Error: No nREPL. Start with: lein repl :headless" && exit 1

clojure -M "$SCRIPT_DIR/nrepl-client.clj" "$PORT" "$CODE"
