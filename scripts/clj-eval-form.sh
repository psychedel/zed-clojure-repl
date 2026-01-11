#!/usr/bin/env bash
# Evaluate Clojure form at cursor position
# Usage: clj-eval-form.sh <file> <row> <col>

set -e

FILE="$1"
ROW="$2"
COL="${3:-1}"

if [ -z "$FILE" ] || [ -z "$ROW" ]; then
    echo "Usage: clj-eval-form.sh <file> <row> [col]"
    exit 1
fi

SCRIPT_DIR="$(dirname "$0")"

# Write Clojure code to a temp file to avoid escaping issues
TEMP_CLJ=$(mktemp /tmp/eval-form-XXXXXX.clj)
cat > "$TEMP_CLJ" << 'CLOJURE_CODE'
(let [file (first *command-line-args*)
      target-row (parse-long (second *command-line-args*))
      target-col (parse-long (nth *command-line-args* 2))
      lines (vec (clojure.string/split-lines (slurp file)))
      line-idx (dec target-row)]
  
  (letfn [(find-form-start [lines row col]
            (loop [r row c col depth 0]
              (if (< r 0)
                nil
                (let [line (get lines r "")
                      ch (when (and (>= c 0) (< c (count line)))
                           (nth line c))]
                  (cond
                    (and (#{\( \[ \{} ch) (zero? depth))
                    [r c]
                    
                    (#{\) \] \}} ch)
                    (recur r (dec c) (inc depth))
                    
                    (#{\( \[ \{} ch)
                    (recur r (dec c) (dec depth))
                    
                    (< c 0)
                    (recur (dec r) (dec (count (get lines (dec r) ""))) depth)
                    
                    :else
                    (recur r (dec c) depth))))))
          
          (find-matching-close [lines start-row start-col opener]
            (let [closer (case opener \( \) \[ \] \{ \})]
              (loop [r start-row c (inc start-col) depth 1 in-str false esc false]
                (if (>= r (count lines))
                  nil
                  (let [line (get lines r "")
                        ch (when (< c (count line)) (nth line c))]
                    (cond
                      (nil? ch)
                      (recur (inc r) 0 depth false false)
                      
                      esc
                      (recur r (inc c) depth in-str false)
                      
                      (and (= ch \") (not esc))
                      (recur r (inc c) depth (not in-str) false)
                      
                      (and (= ch \\) in-str)
                      (recur r (inc c) depth in-str true)
                      
                      in-str
                      (recur r (inc c) depth in-str false)
                      
                      (and (= ch closer) (= depth 1))
                      [r c]
                      
                      (= ch opener)
                      (recur r (inc c) (inc depth) in-str false)
                      
                      (= ch closer)
                      (recur r (inc c) (dec depth) in-str false)
                      
                      :else
                      (recur r (inc c) depth in-str false)))))))
          
          (extract-region [lines sr sc er ec]
            (if (= sr er)
              (subs (get lines sr) sc (inc ec))
              (let [first-line (subs (get lines sr) sc)
                    middle (for [r (range (inc sr) er)] (get lines r ""))
                    last-line (subs (get lines er) 0 (inc ec))]
                (clojure.string/join "\n" (concat [first-line] middle [last-line])))))]
    
    (if-let [[sr sc] (find-form-start lines line-idx (dec target-col))]
      (let [opener (nth (get lines sr) sc)]
        (if-let [[er ec] (find-matching-close lines sr sc opener)]
          (println (extract-region lines sr sc er ec))
          (println ";; Error: unbalanced form")))
      ;; Try to get symbol at point
      (let [line (get lines line-idx "")
            delims #{\space \( \) \[ \] \{ \} \" \' \` \, \; \newline}
            start (loop [i (min (dec target-col) (dec (count line)))]
                    (if (or (< i 0) (delims (nth line i)))
                      (inc i)
                      (recur (dec i))))
            end (loop [i (min (dec target-col) (dec (count line)))]
                  (if (or (>= i (count line)) (delims (nth line i)))
                    i
                    (recur (inc i))))]
        (if (< start end)
          (println (subs line start end))
          (println ";; No form at point"))))))
CLOJURE_CODE

# Get the form using clojure
FORM=$(clojure -M "$TEMP_CLJ" "$FILE" "$ROW" "$COL" 2>/dev/null)
rm -f "$TEMP_CLJ"

if [ -z "$FORM" ] || [[ "$FORM" == ";;"* ]]; then
    echo "$FORM"
    exit 1
fi

# Now evaluate the found form
echo "=> $FORM"
echo "---"
"$SCRIPT_DIR/nrepl-eval.sh" "$FORM"
