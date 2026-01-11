#!/usr/bin/env bash
# rebel-repl.sh — Start or connect to nREPL with rebel-readline

set -e

REBEL_VERSION="0.1.5"
NREPL_VERSION="1.3.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

find_project_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        [ -f "$dir/deps.edn" ] || [ -f "$dir/project.clj" ] || [ -f "$dir/shadow-cljs.edn" ] && echo "$dir" && return 0
        dir="$(dirname "$dir")"
    done
    echo "$PWD"
}

find_nrepl_port() {
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
    echo ""
}

check_port_alive() {
    local port="$1"
    (nc -z 127.0.0.1 "$port" >/dev/null 2>&1) && return 0
    return 1
}

USE_CLJS=false
EXPLICIT_PORT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --cljs) USE_CLJS=true; shift ;;
        --help|-h) echo "rebel-repl — Start or connect to nREPL"; exit 0 ;;
        *) EXPLICIT_PORT="$1"; shift ;;
    esac
done

PROJECT_ROOT=$(find_project_root)
cd "$PROJECT_ROOT"

# ClojureScript mode
if [ "$USE_CLJS" = true ]; then
    PORT=$(find_nrepl_port cljs)
    if [ -z "$PORT" ]; then
        echo -e "${RED}Error: No shadow-cljs nREPL found${NC}"
        echo "Start shadow-cljs first: npx shadow-cljs watch <build>"
        exit 1
    fi
    
    echo -e "${CYAN}Connecting to shadow-cljs nREPL on port $PORT...${NC}"
    echo ""
    echo "To start ClojureScript REPL, run:"
    echo "  (zed/cljs :your-build)"
    echo ""
    echo "This will switch to CLJS and save session for Zed evals."
    echo "Eval results from Zed will appear here via tap>"
    echo ""
    
    # Inject zed/cljs helper before starting rebel
    INIT_CODE='
(do
  (ns zed)
  (defn cljs
    "Switch to ClojureScript REPL and save session for Zed.
     Usage: (zed/cljs :app)"
    [build-id]
    (require (quote shadow.cljs.devtools.api))
    ;; Get session-id by sending a describe op and checking response
    ;; For now, we create a marker file and let nrepl-client clone from here
    (spit ".zed-cljs-ready" (str build-id))
    ((resolve (quote shadow.cljs.devtools.api/repl)) build-id))
  
  ;; Add tap listener
  (add-tap (fn [x]
             (println "")
             (print "\033[36m;; => \033[0m")
             (clojure.pprint/pprint x)
             (flush)))
  
  (in-ns (quote user))
  nil)
'
    
    exec clojure -Sdeps "{:deps {com.bhauman/rebel-readline-nrepl {:mvn/version \"$REBEL_VERSION\"}}}" \
        -M -e "$INIT_CODE" -m rebel-readline.nrepl.main --port "$PORT"
fi

# Clojure mode
if [ -n "$EXPLICIT_PORT" ]; then
    PORT="$EXPLICIT_PORT"
else
    PORT=$(find_nrepl_port clj)
fi

# Connect to existing nREPL
if [ -n "$PORT" ] && check_port_alive "$PORT"; then
    echo -e "${GREEN}Connecting to existing nREPL on port $PORT...${NC}"
    echo "TAB for completion, Ctrl+D to exit"
    echo ""
    exec clojure -Sdeps "{:deps {com.bhauman/rebel-readline-nrepl {:mvn/version \"$REBEL_VERSION\"}}}" \
        -M -m rebel-readline.nrepl.main --port "$PORT"
fi

# No nREPL - start rebel with embedded nREPL
echo -e "${YELLOW}No nREPL found. Starting rebel-readline with embedded nREPL server...${NC}"
echo ""

DEPS="{:deps {com.bhauman/rebel-readline {:mvn/version \"$REBEL_VERSION\"} nrepl/nrepl {:mvn/version \"$NREPL_VERSION\"}}}"

read -r -d '' STARTUP_CODE << 'CLOJURE' || true
(require '[nrepl.server :as nrepl-server])
(require '[rebel-readline.clojure.main :as rebel])

(let [server (nrepl-server/start-server :port 0)
      port (:port server)]
  (spit ".nrepl-port" (str port))
  (println "")
  (println (str "nREPL server started on port " port))
  (println (str "Port written to " (System/getProperty "user.dir") "/.nrepl-port"))
  (println "")
  (println "Zed eval results will appear here via tap>")
  (println "TAB for completion, Ctrl+D to exit")
  (println "")

  ;; Add tap listener to show eval results from Zed
  (add-tap (fn [x]
             (println "")
             (print "\033[36m;; => \033[0m")
             (prn x)
             (flush)))

  (.addShutdownHook (Runtime/getRuntime)
    (Thread. (fn []
               (try
                 (clojure.java.io/delete-file ".nrepl-port" true)
                 (nrepl-server/stop-server server)
                 (catch Exception _)))))

  (rebel/repl))
CLOJURE

exec clojure -Sdeps "$DEPS" -M -e "$STARTUP_CODE"
