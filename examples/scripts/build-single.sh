#!/bin/bash

# Elm Animate Single File Build Script
# This script compiles a single Elm example file to its corresponding JavaScript output
#
# Usage: ./scripts/build-single.sh ElmUI/CSS/Transitions/Position/Main.elm
#        ./scripts/build-single.sh ElmUI/WAAPI/Controls/Main.elm
#
# IMPORTANT: Always uses specific output paths ending in .js
# NEVER uses --output=index.html as it would overwrite dashboard files!

set -e  # Exit on any error

# Check if path argument is provided
if [ $# -eq 0 ]; then
    echo "❌ Error: No file path provided"
    echo ""
    echo "Usage: $0 <elm-file-path>"
    echo ""
    echo "Examples:"
    echo "  $0 ElmUI/CSS/Transitions/Position/Main.elm"
    echo "  $0 ElmUI/CSS/Transitions/Position"
    echo "  $0 ElmUI/WAAPI/Controls/"
    echo "  $0 ElmUI/WAAPI/Controls/Main.elm"
    echo "  $0 ElmUI/Sub/Position"
    echo "  $0 ElmUI/Scroll/Document/Position/X"
    echo ""
    echo "The path should be relative to the src/ directory and typically follows:"
    echo "  ElmUI/{Engine}/{Category}/{Property}/Main.elm"
    echo "  ElmUI/{Engine}/{Category}/{Property}/"
    echo "  ElmUI/{Engine}/{Category}/{Property}"
    echo ""
    echo "Where:"
    echo "  {Engine} = CSS, Sub, WAAPI, or Scroll"
    echo "  {Category} = Transitions, Keyframes, Position, etc."
    echo "  {Property} = Position, Opacity, Scale, etc."
    echo ""
    echo "Note: If the path doesn't end with .elm, Main.elm will be automatically appended."
    exit 1
fi

INPUT_PATH="$1"

# Change to examples directory (parent of scripts)
cd "$(dirname "$0")/.."

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
        
        # Format the source file
        echo "🎨 Formatting source file..."
        if elm-format --yes "$src_file" > /dev/null 2>&1; then
            echo "✅ File formatted successfully"
        else
            echo "⚠️  Warning: elm-format failed (file still compiled successfully)"
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