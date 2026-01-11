#!/usr/bin/env clojure
;; Simple nREPL client for one-shot evaluation
;; Usage: clj -M ~/.claude/scripts/nrepl-client.clj PORT CODE

(require '[clojure.java.io :as io])
(import '[java.net Socket]
        '[java.io PushbackInputStream])

;; Minimal bencode implementation
(defn bencode-string [s]
  (str (count s) ":" s))

(defn bencode-map [m]
  (str "d"
       (apply str (map (fn [[k v]]
                         (str (bencode-string (name k))
                              (bencode-string (str v))))
                       m))
       "e"))

(defn read-bencode-byte [in]
  (let [b (.read in)]
    (when (neg? b) (throw (ex-info "Unexpected EOF" {})))
    b))

(defn read-bencode-char [in]
  (char (read-bencode-byte in)))

(defn read-bencode-number [in first-char]
  (loop [chars [first-char]]
    (let [c (read-bencode-char in)]
      (if (or (= c \:) (= c \e))
        [(Long/parseLong (apply str chars)) c]
        (recur (conj chars c))))))

(defn read-bencode-string [in len]
  (let [buf (byte-array len)]
    (.read in buf 0 len)
    (String. buf "UTF-8")))

(defn read-bencode [in]
  (let [c (read-bencode-char in)]
    (cond
      (= c \d) ;; dictionary
      (loop [m {}]
        (let [next-c (read-bencode-char in)]
          (if (= next-c \e)
            m
            (let [[len _] (read-bencode-number in next-c)
                  key (keyword (read-bencode-string in len))
                  val (read-bencode in)]
              (recur (assoc m key val))))))
      
      (= c \l) ;; list
      (loop [l []]
        (let [val (read-bencode in)]
          (if (= val :end)
            l
            (recur (conj l val)))))
      
      (= c \e) :end
      
      (Character/isDigit c) ;; string
      (let [[len _] (read-bencode-number in c)]
        (read-bencode-string in len))
      
      :else (throw (ex-info (str "Unknown bencode type: " c) {})))))

(defn nrepl-eval [port code]
  (with-open [sock (Socket. "127.0.0.1" (Integer/parseInt port))
              out (io/output-stream sock)
              in (PushbackInputStream. (io/input-stream sock))]
    (.write out (.getBytes (bencode-map {:op "eval" :code code})))
    (.flush out)
    
    ;; Read responses until we get status:done
    (loop [results []]
      (let [response (try (read-bencode in) (catch Exception _ nil))]
        (if (nil? response)
          results
          (let [new-results (conj results response)
                status (:status response)]
            (if (and status (some #{"done"} status))
              new-results
              (recur new-results))))))))

(defn -main [& args]
  (when (< (count args) 2)
    (println "Usage: nrepl-client.clj PORT CODE")
    (System/exit 1))
  
  (let [[port & code-parts] args
        code (clojure.string/join " " code-parts)]
    (try
      (let [results (nrepl-eval port code)]
        (doseq [r results]
          (when-let [out (:out r)] (print out))
          (when-let [err (:err r)] (binding [*out* *err*] (print err)))
          (when-let [val (:value r)] (println val))
          (when-let [ex (:ex r)] (println "Exception:" ex))))
      (catch Exception e
        (println "Error:" (.getMessage e))
        (System/exit 1)))))

(apply -main *command-line-args*)
