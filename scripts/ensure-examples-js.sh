#!/bin/bash
#
# Ensures docs/examples/js/elm-motion.js is up-to-date with the master
# sources in js/src/. Rebuilds the rollup bundle (dist/elm-motion.js)
# whenever any js/src/**/*.js file is newer than dist/elm-motion.js,
# and copies the bundle into docs/examples/js/ whenever the dist file
# is newer than the copy.
#
# Sourced or invoked by build-docs-examples.sh and build-example.sh so
# the WAAPI examples always load the latest companion JS after any edit
# under js/src/.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$REPO_ROOT/js/src"
DIST_FILE="$REPO_ROOT/dist/elm-motion.js"
EXAMPLES_FILE="$REPO_ROOT/docs/examples/js/elm-motion.js"

mkdir -p "$(dirname "$EXAMPLES_FILE")"

# Find the newest mtime under js/src/ (epoch seconds).
newest_src_mtime() {
    find "$SRC_DIR" -type f -name '*.js' -exec stat -f %m {} + 2>/dev/null \
        | sort -nr | head -1
}

file_mtime() {
    [ -f "$1" ] && stat -f %m "$1" 2>/dev/null || echo 0
}

SRC_MTIME=$(newest_src_mtime)
DIST_MTIME=$(file_mtime "$DIST_FILE")
EXAMPLES_MTIME=$(file_mtime "$EXAMPLES_FILE")

NEED_BUILD=0
if [ ! -f "$DIST_FILE" ] || [ "${SRC_MTIME:-0}" -gt "$DIST_MTIME" ]; then
    NEED_BUILD=1
fi

if [ "$NEED_BUILD" -eq 1 ]; then
    echo "📦 js/src/ is newer than dist/elm-motion.js - running 'npm run build'..."
    (cd "$REPO_ROOT" && npm run build) || {
        echo "❌ npm run build failed - cannot refresh dist/elm-motion.js"
        exit 1
    }
    DIST_MTIME=$(file_mtime "$DIST_FILE")
fi

if [ ! -f "$EXAMPLES_FILE" ] || [ "$DIST_MTIME" -gt "$EXAMPLES_MTIME" ]; then
    cp "$DIST_FILE" "$EXAMPLES_FILE"
    echo "✅ Copied dist/elm-motion.js → docs/examples/js/elm-motion.js"
else
    echo "✅ docs/examples/js/elm-motion.js is up-to-date"
fi
