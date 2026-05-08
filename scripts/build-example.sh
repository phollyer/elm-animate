#!/bin/bash

# Elm Motion Single File Build Script
# This script compiles a single Elm example file to its corresponding JavaScript output
#
# Usage: ./scripts/build-single.sh Engines/CSS/HelloText/Main.elm
#        ./scripts/build-single.sh GettingStarted/FadeInOut/Main.elm


set -e  # Exit on any error

# Check if path argument is provided
if [ $# -eq 0 ]; then
    echo "❌ Error: No file path provided"
    echo ""
    echo "Usage: $0 <elm-file-path>"
    echo ""
    echo "Examples:"
    echo "  $0 Engines/CSS/HelloText/Main.elm"
    echo "  $0 Engines/CSS/HelloText"
    echo "  $0 Engines/Animation/Sub/HelloText/"
    echo "  $0 Engines/Animation/Sub/InterruptingAnimations/Main.elm"
    echo "  $0 GettingStarted/FadeInOut"
    echo ""
    echo "The path should be relative to the src/ directory and typically follows:"
    echo "  Engines/{Engine}/{ExampleName}/Main.elm"
    echo "  GettingStarted/{ExampleName}/Main.elm"
    echo ""
    echo "Where:"
    echo "  {Engine} = CSS, Sub, WAAPI, or Scroll"
    echo "  {ExampleName} = HelloText, InterruptingAnimations, etc."
    echo ""
    echo "Note: If the path doesn't end with .elm, Main.elm will be automatically appended."
    exit 1
fi

INPUT_PATH="$1"

# Change to docs/examples directory from project root
cd "$(dirname "$0")/../docs/examples"

# Track formatting results
FORMATTED_FILES=()
FAILED_FORMAT=()

# Format all files before building
echo "🎨 Formatting all files..."

while IFS= read -r -d '' file; do
    if elm-format --yes "$file" > /dev/null 2>&1; then
        FORMATTED_FILES+=("$file")
    else
        FAILED_FORMAT+=("$file")
    fi
done < <(find src/Engines -name "*.elm" -type f -print0 2>/dev/null)

while IFS= read -r -d '' file; do
    if elm-format --yes "$file" > /dev/null 2>&1; then
        FORMATTED_FILES+=("$file")
    else
        FAILED_FORMAT+=("$file")
    fi
done < <(find src -name "*.elm" -type f -print0 2>/dev/null)

echo ""

# Normalize the input path (remove leading/trailing slashes, src/ prefix)
INPUT_PATH=$(echo "$INPUT_PATH" | sed 's|^src/||' | sed 's|^/||' | sed 's|/$||')

# If the path doesn't end with .elm, append /Main.elm
if [[ ! "$INPUT_PATH" =~ \.elm$ ]]; then
    INPUT_PATH="$INPUT_PATH/Main.elm"
fi

# Validate the input file exists
SRC_FILE="src/$INPUT_PATH"
if [ ! -f "$SRC_FILE" ]; then
    echo "❌ Error: File not found: $SRC_FILE"
    echo ""
    echo "Make sure the file exists and the path is correct."
    echo "Path should be relative to: $(pwd)/src/"
    exit 1
fi

# Generate output path by replacing /Main.elm with /index.js
OUTPUT_FILE=$(echo "$SRC_FILE" | sed 's|/Main\.elm$|/index.js|' | sed 's|\.elm$|.js|')

# Create output directory if it doesn't exist
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR"

# Display what we're building
echo "🚀 Building single Elm file..."
echo "📁 Working directory: $(pwd)"
echo "📄 Source: $SRC_FILE"
echo "📤 Output: $OUTPUT_FILE"
echo ""

# Function to build with detailed error reporting
build_single() {
    local src_file=$1
    local output_file=$2
    
    echo "🔨 Compiling..."
    if elm make "$src_file" --output="$output_file" 2>&1; then
        echo ""
        echo "✅ Build successful!"
        echo "📤 Output: $output_file"
        echo ""
        echo "📊 Format Summary:"
        echo "✅ Successfully formatted: ${#FORMATTED_FILES[@]} files"
        if [ ${#FAILED_FORMAT[@]} -gt 0 ]; then
            echo "⚠️  Failed to format: ${#FAILED_FORMAT[@]} files"
            for failed_file in "${FAILED_FORMAT[@]}"; do
                # Strip src/ prefix for consistency
                display_path="${failed_file#src/}"
                echo "   - $display_path"
            done
        else
            echo "❌ Failed to format: 0 files"
        fi
        echo ""
        echo "🎉 Single file build complete!"
        echo ""
        echo "💡 To view the example:"
        echo "   1. Open your browser"
        echo "   2. Navigate to the directory containing index.js"
        echo "   3. Open index.html (if it exists) or serve the files locally"
        echo ""
        echo "🔧 For development:"
        echo "   cd examples && elm reactor"
        echo "   Then navigate to: http://localhost:8000"
        
    else
        echo ""
        echo "❌ Build failed!"
        echo ""
        echo "💡 Common issues:"
        echo "   - Check for syntax errors in the Elm file"
        echo "   - Ensure all imports are correct"
        echo "   - Verify the file structure matches the module declaration"
        echo ""
        echo "🔍 Try running 'elm make $src_file' separately for more detailed error information"
        exit 1
    fi
}

# Build the file
build_single "$SRC_FILE" "$OUTPUT_FILE"
