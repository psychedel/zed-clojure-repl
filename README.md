# Zed Clojure REPL

CIDER-like Clojure development for [Zed editor](https://zed.dev) via nREPL.

## Features

- **Eval selection** (`Ctrl+X Ctrl+E`)
- **Eval form at point** (`Ctrl+C Ctrl+C`)
- **Eval buffer** (`Ctrl+C Ctrl+K`)
- **Reload namespace** (`Ctrl+C Ctrl+N`)
- **Run tests** (`Ctrl+C Ctrl+T`)
- **Documentation lookup** (`Ctrl+C Ctrl+D`)
- **Portal data inspector** integration
- **ClojureScript** support (shadow-cljs)

## Requirements

- [Zed editor](https://zed.dev)
- [Clojure CLI](https://clojure.org/guides/install_clojure) or Leiningen
- Running nREPL server

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/zed-clojure-repl.git
cd zed-clojure-repl
./install.sh
```

Restart Zed after installation.

## Usage

1. Start nREPL in your project:
   ```bash
   # Leiningen
   lein repl :headless
   
   # Clojure CLI (with nREPL dependency)
   clj -M:nrepl
   ```

2. Open your project in Zed

3. Use keyboard shortcuts or `Ctrl+Shift+P` then type "Clojure:"

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+X Ctrl+E` | Eval selection |
| `Ctrl+C Ctrl+C` | Eval form at point |
| `Ctrl+C Ctrl+K` | Eval buffer |
| `Ctrl+C Ctrl+N` | Reload file |
| `Ctrl+C Ctrl+R` | Smart reload |
| `Ctrl+C Ctrl+T` | Run tests |
| `Ctrl+C Shift+T` | Run all tests |
| `Ctrl+C Ctrl+D` | Documentation |
| `Ctrl+C Ctrl+S` | Show source |
| `Ctrl+C Ctrl+E` | Last exception |
| `Ctrl+C Ctrl+M` | Macroexpand |
| `Ctrl+C Ctrl+O` | Open Portal |
| `Ctrl+C Ctrl+P` | Tap to Portal |

## Portal Integration

Add Portal to your project:

```clojure
;; deps.edn
{:deps {djblue/portal {:mvn/version "0.58.2"}}}

;; project.clj
[djblue/portal "0.58.2"]
```

Use `Ctrl+C Ctrl+O` to open Portal in browser.

## ClojureScript

For `.cljs` files, eval uses shadow-cljs nREPL. Start watch first:

```bash
npx shadow-cljs watch app
```

## Uninstall

```bash
./uninstall.sh
```

## License

MIT
