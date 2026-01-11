#!/usr/bin/env bash
# Initialize ClojureScript REPL session
# Reads build from .zed-repl or prompts user
# Saves session-id to .zed-cljs-session

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

find_project_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        [ -f "$dir/shadow-cljs.edn" ] && echo "$dir" && return 0
        dir="$(dirname "$dir")"
    done
    echo "$PWD"
}

find_shadow_port() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        [ -f "$dir/.shadow-cljs/nrepl.port" ] && cat "$dir/.shadow-cljs/nrepl.port" && return 0
        dir="$(dirname "$dir")"
    done
    echo ""
}

PROJECT_ROOT=$(find_project_root)
cd "$PROJECT_ROOT"

# Find shadow-cljs port
PORT=$(find_shadow_port)
if [ -z "$PORT" ]; then
    echo -e "${RED}Error: shadow-cljs not running${NC}"
    echo "Start it first with: npx shadow-cljs watch <build>"
    exit 1
fi

# Check port is alive
if ! nc -z 127.0.0.1 "$PORT" 2>/dev/null; then
    echo -e "${RED}Error: shadow-cljs nREPL on port $PORT not responding${NC}"
    exit 1
fi

# Get build id from .zed-repl or argument
BUILD="$1"

if [ -z "$BUILD" ] && [ -f ".zed-repl" ]; then
    BUILD=$(grep "^cljs-build=" .zed-repl 2>/dev/null | cut -d= -f2)
fi

if [ -z "$BUILD" ]; then
    echo -e "${YELLOW}Enter ClojureScript build id (e.g., app, game, main):${NC}"
    read -r BUILD
fi

if [ -z "$BUILD" ]; then
    echo -e "${RED}Error: build id required${NC}"
    exit 1
fi

echo -e "${CYAN}Initializing ClojureScript REPL for build: $BUILD${NC}"

# Clone session and initialize cljs repl
INIT_CODE="
(require '[clojure.java.io :as io])
(import '[java.net Socket] '[java.io PushbackInputStream])

(defn bencode-string [s] (str (count s) \":\" s))
(defn bencode-map [m]
  (str \"d\" (apply str (map (fn [[k v]] (str (bencode-string (name k)) (bencode-string (str v)))) m)) \"e\"))

(defn read-byte [in] (let [b (.read in)] (when (neg? b) (throw (Exception. \"EOF\"))) b))
(defn read-char [in] (char (read-byte in)))
(defn read-num [in c] (loop [cs [c]] (let [ch (read-char in)] (if (or (= ch \\:) (= ch \\e)) [(Long/parseLong (apply str cs)) ch] (recur (conj cs ch))))))
(defn read-str [in len] (let [buf (byte-array len)] (.read in buf 0 len) (String. buf \"UTF-8\")))
(defn read-int [in] (loop [cs []] (let [c (read-char in)] (if (= c \\e) (Long/parseLong (apply str cs)) (recur (conj cs c))))))
(defn read-bencode [in]
  (let [c (read-char in)]
    (cond
      (= c \\d) (loop [m {}] (let [nc (read-char in)] (if (= nc \\e) m (let [[len _] (read-num in nc)] (recur (assoc m (keyword (read-str in len)) (read-bencode in)))))))
      (= c \\l) (loop [l []] (let [v (read-bencode in)] (if (= v :end) l (recur (conj l v)))))
      (= c \\i) (read-int in)
      (= c \\e) :end
      (Character/isDigit c) (let [[len _] (read-num in c)] (read-str in len))
      :else (throw (Exception. (str \"Unknown: \" c))))))

(defn send-recv [port msg]
  (with-open [sock (Socket. \"127.0.0.1\" port) out (io/output-stream sock) in (PushbackInputStream. (io/input-stream sock))]
    (.write out (.getBytes (bencode-map msg))) (.flush out)
    (loop [rs []] (let [r (try (read-bencode in) (catch Exception _ nil))]
      (if (nil? r) rs (let [rs2 (conj rs r)] (if (and (:status r) (some #{\"done\"} (:status r))) rs2 (recur rs2))))))))

(let [clone-result (send-recv $PORT {:op \"clone\"})
      session-id (some :new-session clone-result)]
  (if session-id
    (do
      ;; Initialize cljs repl in this session
      (send-recv $PORT {:op \"eval\" :session session-id :code \"(shadow.cljs.devtools.api/repl :$BUILD)\"})
      ;; Save session to file
      (spit \".zed-cljs-session\" session-id)
      (println session-id))
    (do
      (println \"ERROR: Failed to create session\")
      (System/exit 1))))
"

# Replace placeholders
INIT_CODE="${INIT_CODE//\$PORT/$PORT}"
INIT_CODE="${INIT_CODE//\$BUILD/$BUILD}"

SESSION_ID=$(clojure -M -e "$INIT_CODE" 2>&1)

if [ -f ".zed-cljs-session" ]; then
    echo -e "${GREEN}ClojureScript REPL ready!${NC}"
    echo "Session: $(cat .zed-cljs-session)"
    echo ""
    echo "Use Ctrl+X Ctrl+D to eval ClojureScript"
    
    # Save build to .zed-repl for future use
    if [ ! -f ".zed-repl" ] || ! grep -q "^cljs-build=" .zed-repl 2>/dev/null; then
        echo "cljs-build=$BUILD" >> .zed-repl
        echo -e "${CYAN}Saved build to .zed-repl${NC}"
    fi
else
    echo -e "${RED}Error initializing ClojureScript REPL${NC}"
    echo "$SESSION_ID"
    exit 1
fi
