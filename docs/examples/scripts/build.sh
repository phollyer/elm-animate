#!/bin/bash

# Elm Animate Documentation Examples Build Script
# This script compiles all documentation examples to their respective JavaScript files
# 
# IMPORTANT: Always use specific output paths ending in .js
# NEVER use --output=index.html as it would overwrite dashboard files!

echo "🚀 Building Elm Animate Documentation Examples..."

# Change to examples directory (parent of scripts)
cd "$(dirname "$0")/.."

# Copy JS from dist to ensure we have the latest version
echo "📦 Copying JS from dist..."
mkdir -p js
cp ../../dist/elm-animate-waapi.js js/
echo "✅ Copied elm-animate-waapi.js to js/"
echo ""

# Track build and format results
FAILED_BUILDS=()
SUCCESSFUL_BUILDS=()
FORMATTED_FILES=()
FAILED_FORMAT=()

# Format all files before building
echo "🎨 Formatting all files..."
echo ""

while IFS= read -r -d '' file; do
    if elm-format --yes "$file" > /dev/null 2>&1; then
        FORMATTED_FILES+=("$file")
    else
        FAILED_FORMAT+=("$file")
    fi
done < <(find src -name "*.elm" -type f -print0 2>/dev/null)

while IFS= read -r -d '' file; do
    if elm-format --yes "$file" > /dev/null 2>&1; then
        FORMATTED_FILES+=("$file")
    else
        FAILED_FORMAT+=("$file")
    fi
done < <(find src/GettingStarted -name "*.elm" -type f -print0 2>/dev/null)

echo "🔨 Starting compilation..."

# Function to build and track results
build_example() {
    local src_file=$1
    local output_file=$2
    local display_name=$3
    
    echo "Building $display_name..."
    if elm make "$src_file" --output="$output_file" > /dev/null 2>&1; then
        echo "✅ $display_name → $output_file"
        SUCCESSFUL_BUILDS+=("$display_name")
    else
        echo "❌ $display_name FAILED"
        echo "   Error details:"
        elm make "$src_file" --output="$output_file" 2>&1 | sed 's/^/   /'
        FAILED_BUILDS+=("$display_name")
    fi
}

# Dynamically find and build all Main.elm files
echo ""
echo "📚 Building all documentation examples..."

# Find all Main.elm files and build them
while IFS= read -r -d '' main_file; do
    # Get the directory containing the Main.elm
    dir=$(dirname "$main_file")
    
    # Create output path (replace Main.elm with index.js)
    output_file="${dir}/index.js"
    
    # Create display name from path (e.g., "Engines/CSS/BasicUsage/Main.elm")
    display_name="${main_file#src/}"
    
    build_example "$main_file" "$output_file" "$display_name"
done < <(find src -name "Main.elm" -type f -print0 2>/dev/null | sort -z)

# Report results
echo ""
echo "📊 Build Summary:"
echo "✅ Successful builds: ${#SUCCESSFUL_BUILDS[@]}"
echo "❌ Failed builds: ${#FAILED_BUILDS[@]}"
echo ""
echo "📊 Format Summary:"
echo "✅ Successfully formatted: ${#FORMATTED_FILES[@]} files"
echo "❌ Failed to format: ${#FAILED_FORMAT[@]} files"

if [ ${#FAILED_BUILDS[@]} -eq 0 ] && [ ${#FAILED_FORMAT[@]} -eq 0 ]; then
    echo ""
    echo "🎉 All examples built successfully!"
    echo ""
    echo "📚 Documentation examples available at:"
    echo "   📖 GettingStarted/ - Introduction examples"
    echo "   ⚙️  Engines/ - Engine-specific examples (CSS, Sub, etc.)"
    echo ""
    echo "💡 To view examples:"
    echo "   mkdocs serve   # From the project root"
    echo "   Then open http://localhost:8000"
else
    echo ""
    if [ ${#FAILED_BUILDS[@]} -gt 0 ]; then
        echo "🚨 Some examples failed to build:"
        for failed_build in "${FAILED_BUILDS[@]}"; do
            echo "   - $failed_build"
        done
    fi
    
    if [ ${#FAILED_FORMAT[@]} -gt 0 ]; then
        echo ""
        echo "⚠️  Some files failed to format:"
        for failed_file in "${FAILED_FORMAT[@]}"; do
            display_path="${failed_file#src/}"
            echo "   - $display_path"
        done
    fi
    
    echo ""
    echo "💡 See error details above for each failed build."
    echo "🔧 Fix the errors and run the build script again."
    exit 1
fi
