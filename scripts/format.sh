#!/bin/bash

# Elm Motion Examples Format Script
# This script formats all example files using elm-format
# 
# Usage: ./scripts/format.sh

echo "🎨 Formatting Elm Motion Examples..."

# Change to docs/examples directory from project root
cd "$(dirname "$0")/../docs/examples"

# Check if elm-format is installed
if ! command -v elm-format &> /dev/null; then
    echo "❌ elm-format is not installed!"
    echo "   Please install it with: npm install -g elm-format"
    echo "   Or via other package managers"
    exit 1
fi

# Track formatting results
FORMATTED_FILES=()
FAILED_FILES=()

# Function to format files and track results
format_files() {
    local pattern=$1
    local description=$2
    
    echo "  📝 Formatting $description..."
    
    # Find all .elm files matching the pattern
    while IFS= read -r -d '' file; do
        echo "    Formatting $(basename "$file")..."
        if elm-format --yes "$file" > /dev/null 2>&1; then
            FORMATTED_FILES+=("$file")
        else
            echo "    ❌ Failed to format: $file"
            FAILED_FILES+=("$file")
        fi
    done < <(find "$pattern" -name "*.elm" -type f -print0 2>/dev/null)
}

echo ""
echo "🎨 Formatting documentation examples..."

# Format all Engines examples
format_files "src/Engines" "Engines examples"

# Format GettingStarted examples
format_files "src/GettingStarted" "GettingStarted examples"

# Always exit successfully so build can continue
exit 0
