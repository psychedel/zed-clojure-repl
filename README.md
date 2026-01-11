# Zed Clojure REPL

Clojure/ClojureScript development environment for [Zed editor](https://zed.dev/) using [rebel-readline](https://github.com/bhauman/rebel-readline) and [Portal](https://github.com/djblue/portal).

> **Early draft** — works but rough around the edges.

![Screenshot](docs/screenshot.png)

## Features

- **Rebel REPL** with syntax highlighting, completion, and inline docs
- **Eval from editor** — results appear in REPL via `tap>`
- **ClojureScript support** — shadow-cljs with persistent sessions
- **Portal integration** — visual data inspector

## Installation

```bash
git clone https://github.com/piotrklibert/zed-clojure-repl ~/.zed-clojure-repl
~/.zed-clojure-repl/install.sh
```

## Keybindings

### Clojure
| Key | Action |
|-----|--------|
| `Ctrl+C Ctrl+R` | Start Rebel REPL |
| `Ctrl+X Ctrl+E` | Eval selection |
| `Ctrl+C Ctrl+C` | Eval form at point |
| `Ctrl+C Ctrl+K` | Eval buffer |
| `Ctrl+C Ctrl+D` | Show documentation |
| `Ctrl+C Ctrl+O` | Start Portal |

### ClojureScript
| Key | Action |
|-----|--------|
| `Ctrl+C Ctrl+B` | Start shadow-cljs watch |
| `Ctrl+C Ctrl+J` | Start Rebel REPL (for viewing results) |
| `Ctrl+C Ctrl+L` | Init ClojureScript session |
| `Ctrl+X Ctrl+D` | Eval selection |

## ClojureScript Setup

1. `Ctrl+C Ctrl+B` — Start shadow-cljs watch
2. Open your app in browser (connects JS runtime)
3. `Ctrl+C Ctrl+J` — Start Rebel REPL (to see eval results via tap>)
4. `Ctrl+C Ctrl+L` — Init ClojureScript session (enter build id, e.g., `game`)
5. `Ctrl+X Ctrl+D` — Eval code (results appear in Rebel)

The build id is saved to `.zed-repl` for future use:
```
cljs-build=game
```

## How it Works

- **Clojure**: Rebel REPL starts embedded nREPL. Evals from Zed go through nREPL and appear in REPL via `tap>`.
- **ClojureScript**: 
  1. Rebel connects to shadow-cljs nREPL and listens for `tap>` 
  2. `cljs-init.sh` creates a separate session, switches to CLJS REPL
  3. Evals from Zed use this session and send results via `tap>` to Rebel

## Requirements

- Clojure CLI (`clojure`)
- For ClojureScript: `shadow-cljs` in project
- `nc` (netcat) for port checking

## Uninstall

```bash
~/.zed-clojure-repl/uninstall.sh
```
