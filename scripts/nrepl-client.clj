#!/usr/bin/env clojure
;; nREPL client with optional session support
;; Usage: clj -M nrepl-client.clj PORT [--session FILE] CODE

(require '[clojure.java.io :as io])
(import '[java.net Socket]
        '[java.io PushbackInputStream])

;; Bencode implementation
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

(defn read-bencode-integer [in]
  (loop [chars []]
    (let [c (read-bencode-char in)]
      (if (= c \e)
        (Long/parseLong (apply str chars))
        (recur (conj chars c))))))

(defn read-bencode [in]
  (let [c (read-bencode-char in)]
    (cond
      (= c \d)
      (loop [m {}]
        (let [next-c (read-bencode-char in)]
          (if (= next-c \e)
            m
            (let [[len _] (read-bencode-number in next-c)
                  key (keyword (read-bencode-string in len))
                  val (read-bencode in)]
              (recur (assoc m key val))))))

      (= c \l)
      (loop [l []]
        (let [val (read-bencode in)]
          (if (= val :end)
            l
            (recur (conj l val)))))

      (= c \i)
      (read-bencode-integer in)

      (= c \e) :end

      (Character/isDigit c)
      (let [[len _] (read-bencode-number in c)]
        (read-bencode-string in len))

      :else (throw (ex-info (str "Unknown bencode type: " c) {})))))

(defn nrepl-send-recv [port msg]
  (with-open [sock (Socket. "127.0.0.1" port)
              out (io/output-stream sock)
              in (PushbackInputStream. (io/input-stream sock))]
    (.write out (.getBytes (bencode-map msg)))
    (.flush out)
    (loop [results []]
      (let [response (try (read-bencode in) (catch Exception _ nil))]
        (if (nil? response)
          results
          (let [new-results (conj results response)
                status (:status response)]
            (if (and status (some #{"done"} status))
              new-results
              (recur new-results))))))))

(defn read-session-file [path]
  (when (and path (.exists (io/file path)))
    (let [content (slurp path)]
      (when-not (clojure.string/blank? content)
        (clojure.string/trim content)))))

(defn nrepl-eval [port code session-id]
  (let [msg (cond-> {:op "eval" :code code}
              session-id (assoc :session session-id))]
    (nrepl-send-recv port msg)))

(defn parse-args [args]
  (loop [args args
         opts {:port nil :session-file nil :code-parts []}]
    (if (empty? args)
      (assoc opts :code (clojure.string/join " " (:code-parts opts)))
      (let [[arg & rest-args] args]
        (cond
          (nil? (:port opts))
          (recur rest-args (assoc opts :port (Integer/parseInt arg)))
          
          (= "--session" arg)
          (recur (rest rest-args) (assoc opts :session-file (first rest-args)))
          
          :else
          (recur rest-args (update opts :code-parts conj arg)))))))

(defn -main [& args]
  (when (< (count args) 2)
    (println "Usage: nrepl-client.clj PORT [--session FILE] CODE")
    (System/exit 1))

  (let [{:keys [port session-file code]} (parse-args args)]
    (when (clojure.string/blank? code)
      (println "Error: no code provided")
      (System/exit 1))
    
    (try
      (let [session-id (read-session-file session-file)
            results (nrepl-eval port code session-id)]
        (doseq [r results]
          (when-let [out (:out r)] (print out))
          (when-let [err (:err r)] (binding [*out* *err*] (print err)))
          (when-let [val (:value r)] (println val))
          (when-let [ex (:ex r)] (println "Exception:" ex))))
      (catch Exception e
        (println "Error:" (.getMessage e))
        (System/exit 1)))))

(apply -main *command-line-args*)
