#!/bin/bash

# Serve documentation with live examples embedded via iframes.
#
# mkdocs serve cannot serve the standalone example HTML files (they live outside
# its page pipeline), so this script builds the site, serves the output with a
# static HTTP server, and optionally watches for file changes to rebuild.
#
# Usage:
#   ./scripts/serve-docs.sh              # build + serve on port 8001
#   ./scripts/serve-docs.sh --watch      # build + serve + rebuild on changes
#   ./scripts/serve-docs.sh --port 8080  # use a custom port
#   ./scripts/serve-docs.sh --help

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT=8001
WATCH=false
SERVER_PID=""

usage() {
    echo "Usage: $(basename "$0") [--watch] [--port PORT]"
    echo ""
    echo "Build and serve Elm Animate documentation with embedded live examples."
    echo ""
    echo "Options:"
    echo "  --watch    Watch for file changes and rebuild automatically"
    echo "  --port N   Port to serve on (default: 8001)"
    echo "  --help     Show this help"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --watch) WATCH=true; shift ;;
        --port)  PORT="$2"; shift 2 ;;
        --help)  usage; exit 0 ;;
        *)       echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

cd "$PROJECT_ROOT"

# ---------- Build ----------

build() {
    echo "📦 Building documentation..."
    mkdocs build --quiet 2>&1
    echo "✅ Site built → http://localhost:${PORT}/"
}

build

# ---------- Serve ----------

cleanup() {
    [[ -n "$SERVER_PID" ]] && kill "$SERVER_PID" 2>/dev/null
    [[ -n "${MARKER:-}" ]] && rm -f "$MARKER"
}
trap cleanup EXIT INT TERM

# Kill any previous server on this port
lsof -ti:"$PORT" 2>/dev/null | xargs kill -9 2>/dev/null || true
sleep 0.5

python3 -m http.server "$PORT" --directory site --bind 127.0.0.1 >/dev/null 2>&1 &
SERVER_PID=$!
echo "🌐 Server running at http://localhost:${PORT}/  (PID $SERVER_PID)"

if [[ "$WATCH" == false ]]; then
    echo "   Press Ctrl+C to stop."
    wait "$SERVER_PID"
    exit 0
fi

# ---------- Watch ----------

echo "👀 Watching for changes in docs/ and src/..."
echo "   Press Ctrl+C to stop."
echo ""

# Directories to watch
WATCH_DIRS=("docs" "src")

# Snapshot modification times
snapshot() {
    for dir in "${WATCH_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            find "$dir" -type d \( -name 'elm-stuff' -o -name 'node_modules' \) -prune -o \
                -type f \( -name '*.md' -o -name '*.yml' -o -name '*.py' \
                -o -name '*.elm' -o -name '*.html' -o -name '*.css' \) \
                -newer "$1" -print 2>/dev/null
        fi
    done
}

# Create a timestamp marker file
MARKER=$(mktemp)
touch "$MARKER"

while true; do
    sleep 2

    CHANGED=$(snapshot "$MARKER")
    if [[ -n "$CHANGED" ]]; then
        echo ""
        echo "🔄 Changes detected — rebuilding..."
        touch "$MARKER"
        build
    fi
done
