#!/bin/bash

# Elm Animate Examples Format Script
# This script formats all example files using elm-format
# 
# Usage: ./scripts/format.sh

echo "🎨 Formatting Elm Animate Examples..."

# Change to examples directory (parent of scripts)
cd "$(dirname "$0")/.."

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
echo "🎨 Formatting ElmUI examples..."

# Format all ElmUI examples
format_files "src/ElmUI" "ElmUI examples"

# Format Common modules
format_files "src/Common" "Common modules"

echo ""
echo "📊 Format Summary:"
echo "✅ Successfully formatted: ${#FORMATTED_FILES[@]} files"
echo "❌ Failed to format: ${#FAILED_FILES[@]} files"

if [ ${#FAILED_FILES[@]} -eq 0 ]; then
    echo ""
    echo "🎉 All files formatted successfully!"
else
    echo ""
    echo "❌ The following files failed to format:"
    for file in "${FAILED_FILES[@]}"; do
        echo "   - $file"
    done
    exit 1
fi