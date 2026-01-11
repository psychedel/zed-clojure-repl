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
| `Ctrl+X Ctrl+E` | Eval selection/form |
| `Ctrl+X Ctrl+B` | Eval buffer |

### ClojureScript
| Key | Action |
|-----|--------|
| `Ctrl+C Ctrl+B` | Start shadow-cljs watch |
| `Ctrl+C Ctrl+L` | Init ClojureScript REPL |
| `Ctrl+X Ctrl+D` | Eval selection (ClojureScript) |

## ClojureScript Setup

1. Start shadow-cljs: `Ctrl+C Ctrl+B`
2. Open your app in browser (connects JS runtime)
3. Init CLJS session: `Ctrl+C Ctrl+L` — enter build id (e.g., `app`)
4. Eval code: `Ctrl+X Ctrl+D`

The build id is saved to `.zed-repl` for future use:
```
cljs-build=app
```

## How it Works

- **Clojure**: Rebel REPL starts embedded nREPL. Evals from Zed go through nREPL and appear in REPL via `tap>`.
- **ClojureScript**: `cljs-init.sh` creates nREPL session, runs `(shadow/repl :build)`, saves session to `.zed-cljs-session`. Subsequent evals use this session.

## Requirements

- Clojure CLI (`clojure`)
- For ClojureScript: `shadow-cljs` in project
- `nc` (netcat) for port checking

## Uninstall

```bash
~/.zed-clojure-repl/uninstall.sh
```
