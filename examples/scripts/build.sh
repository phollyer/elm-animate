#!/bin/bash

# Elm Animate Examples Build Script
# This script compiles all examples to their respective JavaScript files
# 
# IMPORTANT: Always use specific output paths ending in .js
# NEVER use --output=index.html as it would overwrite dashboard files!

echo "🚀 Building Elm Animate Examples..."

# Change to examples directory (parent of scripts)
cd "$(dirname "$0")/.."

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
done < <(find src/ElmUI -name "*.elm" -type f -print0 2>/dev/null)

while IFS= read -r -d '' file; do
    if elm-format --yes "$file" > /dev/null 2>&1; then
        FORMATTED_FILES+=("$file")
    else
        FAILED_FORMAT+=("$file")
    fi
done < <(find src/Common -name "*.elm" -type f -print0 2>/dev/null)

while IFS= read -r -d '' file; do
    if elm-format --yes "$file" > /dev/null 2>&1; then
        FORMATTED_FILES+=("$file")
    else
        FAILED_FORMAT+=("$file")
    fi
done < <(find src/Docs -name "*.elm" -type f -print0 2>/dev/null)

echo "🔨 Starting compilation..."

# Track build results
FAILED_BUILDS=()
SUCCESSFUL_BUILDS=()

# Function to build and track results
build_example() {
    local src_file=$1
    local output_file=$2
    local display_name=${3:-$src_file}
    
    # Convert display name from dots to slashes to match file path format
    display_name="${display_name//.//}.elm"
    
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

# Note: HTML examples have been consolidated into ElmUI examples
# All examples now use the ElmUI framework for consistent UI patterns

# Build ElmUI examples
echo ""
echo "🎨 Building ElmUI examples..."

# ElmUI Scroll examples (Task-based API)
echo "  📜 ElmUI Scroll examples (Anim.Scroll - Task-based API)..."
build_example "src/ElmUI/Scroll/Document/Position/X/Main.elm" "src/ElmUI/Scroll/Document/Position/X/index.js" "ElmUI.Scroll.Document.Position.X.Main"
build_example "src/ElmUI/Scroll/Document/Position/Y/Main.elm" "src/ElmUI/Scroll/Document/Position/Y/index.js" "ElmUI.Scroll.Document.Position.Y.Main"
build_example "src/ElmUI/Scroll/Document/Position/Both/Main.elm" "src/ElmUI/Scroll/Document/Position/Both/index.js" "ElmUI.Scroll.Document.Position.Both.Main"
build_example "src/ElmUI/Scroll/Container/Position/X/Main.elm" "src/ElmUI/Scroll/Container/Position/X/index.js" "ElmUI.Scroll.Container.Position.X.Main"
build_example "src/ElmUI/Scroll/Container/Position/Y/Main.elm" "src/ElmUI/Scroll/Container/Position/Y/index.js" "ElmUI.Scroll.Container.Position.Y.Main"
build_example "src/ElmUI/Scroll/Container/Position/Both/Main.elm" "src/ElmUI/Scroll/Container/Position/Both/index.js" "ElmUI.Scroll.Container.Position.Both.Main"


# ElmUI CSS examples (CSS Transition-based API)
echo "  🎨 ElmUI CSS Transitions examples (Anim.Engine.CSS - Browser-native transitions)..."
build_example "src/ElmUI/CSS/Transitions/Position/Main.elm" "src/ElmUI/CSS/Transitions/Position/index.js" "ElmUI.CSS.Transitions.Position.Main"
build_example "src/ElmUI/CSS/Transitions/Opacity/Main.elm" "src/ElmUI/CSS/Transitions/Opacity/index.js" "ElmUI.CSS.Transitions.Opacity.Main"
build_example "src/ElmUI/CSS/Transitions/Scale/Main.elm" "src/ElmUI/CSS/Transitions/Scale/index.js" "ElmUI.CSS.Transitions.Scale.Main"
build_example "src/ElmUI/CSS/Transitions/Rotate/Main.elm" "src/ElmUI/CSS/Transitions/Rotate/index.js" "ElmUI.CSS.Transitions.Rotate.Main"
build_example "src/ElmUI/CSS/Transitions/Color/Main.elm" "src/ElmUI/CSS/Transitions/Color/index.js" "ElmUI.CSS.Transitions.Color.Main"
build_example "src/ElmUI/CSS/Transitions/Events/Main.elm" "src/ElmUI/CSS/Transitions/Events/index.js" "ElmUI.CSS.Transitions.Events.Main"
build_example "src/ElmUI/CSS/Transitions/Controls/Main.elm" "src/ElmUI/CSS/Transitions/Controls/index.js" "ElmUI.CSS.Transitions.Controls.Main"
build_example "src/ElmUI/CSS/Transitions/Mixed/Main.elm" "src/ElmUI/CSS/Transitions/Mixed/index.js" "ElmUI.CSS.Transitions.Mixed.Main"
build_example "src/ElmUI/CSS/Transitions/Choreography/Main.elm" "src/ElmUI/CSS/Transitions/Choreography/index.js" "ElmUI.CSS.Transitions.Choreography.Main"

# ElmUI CSS Keyframes examples (CSS Keyframes-based API)
echo "  🎯 ElmUI CSS Keyframes examples (Anim.Engine.CSS - Advanced keyframes control)..."
build_example "src/ElmUI/CSS/Keyframes/Position/Main.elm" "src/ElmUI/CSS/Keyframes/Position/index.js" "ElmUI.CSS.Keyframes.Position.Main"
build_example "src/ElmUI/CSS/Keyframes/Opacity/Main.elm" "src/ElmUI/CSS/Keyframes/Opacity/index.js" "ElmUI.CSS.Keyframes.Opacity.Main"
build_example "src/ElmUI/CSS/Keyframes/Scale/Main.elm" "src/ElmUI/CSS/Keyframes/Scale/index.js" "ElmUI.CSS.Keyframes.Scale.Main"
build_example "src/ElmUI/CSS/Keyframes/Rotate/Main.elm" "src/ElmUI/CSS/Keyframes/Rotate/index.js" "ElmUI.CSS.Keyframes.Rotate.Main"
build_example "src/ElmUI/CSS/Keyframes/Cube/Main.elm" "src/ElmUI/CSS/Keyframes/Cube/index.js" "ElmUI.CSS.Keyframes.Cube.Main"
build_example "src/ElmUI/CSS/Keyframes/Color/Main.elm" "src/ElmUI/CSS/Keyframes/Color/index.js" "ElmUI.CSS.Keyframes.Color.Main"
build_example "src/ElmUI/CSS/Keyframes/Events/Main.elm" "src/ElmUI/CSS/Keyframes/Events/index.js" "ElmUI.CSS.Keyframes.Events.Main"
build_example "src/ElmUI/CSS/Keyframes/Controls/Main.elm" "src/ElmUI/CSS/Keyframes/Controls/index.js" "ElmUI.CSS.Keyframes.Controls.Main"
build_example "src/ElmUI/CSS/Keyframes/Mixed/Main.elm" "src/ElmUI/CSS/Keyframes/Mixed/index.js" "ElmUI.CSS.Keyframes.Mixed.Main"
build_example "src/ElmUI/CSS/Keyframes/Choreography/Main.elm" "src/ElmUI/CSS/Keyframes/Choreography/index.js" "ElmUI.CSS.Keyframes.Choreography.Main"


# ElmUI Sub examples (Subscription-based API)
echo "  ⚡ ElmUI Sub examples (Anim.Engine.Sub - Frame-rate independent timing)..."
build_example "src/ElmUI/Sub/Position/Main.elm" "src/ElmUI/Sub/Position/index.js" "ElmUI.Sub.Position.Main"
build_example "src/ElmUI/Sub/Opacity/Main.elm" "src/ElmUI/Sub/Opacity/index.js" "ElmUI.Sub.Opacity.Main"
build_example "src/ElmUI/Sub/Scale/Main.elm" "src/ElmUI/Sub/Scale/index.js" "ElmUI.Sub.Scale.Main"
build_example "src/ElmUI/Sub/Rotation/Main.elm" "src/ElmUI/Sub/Rotation/index.js" "ElmUI.Sub.Rotation.Main"
build_example "src/ElmUI/Sub/Color/Main.elm" "src/ElmUI/Sub/Color/index.js" "ElmUI.Sub.Color.Main"
build_example "src/ElmUI/Sub/Events/Main.elm" "src/ElmUI/Sub/Events/index.js" "ElmUI.Sub.Events.Main"
build_example "src/ElmUI/Sub/Controls/Main.elm" "src/ElmUI/Sub/Controls/index.js" "ElmUI.Sub.Controls.Main"
build_example "src/ElmUI/Sub/Mixed/Main.elm" "src/ElmUI/Sub/Mixed/index.js" "ElmUI.Sub.Mixed.Main"
build_example "src/ElmUI/Sub/Choreography/Main.elm" "src/ElmUI/Sub/Choreography/index.js" "ElmUI.Sub.Choreography.Main"
build_example "src/ElmUI/Sub/Size/Main.elm" "src/ElmUI/Sub/Size/index.js" "ElmUI.Sub.Size.Main"
# build_example "src/ElmUI/Sub/Timing/Main.elm" "src/ElmUI/Sub/Timing/index.js" "ElmUI.Sub.Timing.Main"

# ElmUI WAAPI examples (JavaScript Web Animations API)
# echo "  🌐 ElmUI WAAPI examples (Anim.Engine.WAAPI - Web Animations API integration)..."
build_example "src/ElmUI/WAAPI/Position/Main.elm" "src/ElmUI/WAAPI/Position/index.js" "ElmUI.WAAPI.Position.Main"
build_example "src/ElmUI/WAAPI/Opacity/Main.elm" "src/ElmUI/WAAPI/Opacity/index.js" "ElmUI.WAAPI.Opacity.Main"
build_example "src/ElmUI/WAAPI/Scale/Main.elm" "src/ElmUI/WAAPI/Scale/index.js" "ElmUI.WAAPI.Scale.Main"
build_example "src/ElmUI/WAAPI/Rotate/Main.elm" "src/ElmUI/WAAPI/Rotate/index.js" "ElmUI.WAAPI.Rotate.Main"
build_example "src/ElmUI/WAAPI/Color/Main.elm" "src/ElmUI/WAAPI/Color/index.js" "ElmUI.WAAPI.Color.Main"
build_example "src/ElmUI/WAAPI/Events/Main.elm" "src/ElmUI/WAAPI/Events/index.js" "ElmUI.WAAPI.Events.Main"
build_example "src/ElmUI/WAAPI/Controls/Main.elm" "src/ElmUI/WAAPI/Controls/index.js" "ElmUI.WAAPI.Controls.Main"
build_example "src/ElmUI/WAAPI/Mixed/Main.elm" "src/ElmUI/WAAPI/Mixed/index.js" "ElmUI.WAAPI.Mixed.Main"
build_example "src/ElmUI/WAAPI/Choreography/Main.elm" "src/ElmUI/WAAPI/Choreography/index.js" "ElmUI.WAAPI.Choreography.Main"

# Documentation examples (code used in GitHub Pages docs)
echo ""
echo "📚 Building Documentation examples..."

# Getting Started
echo "  📖 Getting Started examples..."
build_example "src/Docs/GettingStarted/FirstAnimation/Main.elm" "src/Docs/GettingStarted/FirstAnimation/index.js" "Docs.GettingStarted.FirstAnimation.Main"

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
    echo "🌐 Open index.html to view the examples dashboard"
    echo ""
    echo "🎨 ElmUI examples available at:"
    echo "   📜 Scroll (Task-based): src/ElmUI/Scroll/"
    echo "   🎨 CSS (Transitions): src/ElmUI/CSS/"
    echo "   ⚡ Sub (Subscriptions): src/ElmUI/Sub/"
    echo "   🌐 WAAPI (Web Animations): src/ElmUI/WAAPI/"
    echo ""
    echo "   Animation properties covered:"
    echo "   - Position (X/Y coordinates)"
    echo "   - Opacity (fade in/out)"
    echo "   - Scale (size transformations)"
    echo "   - Rotation (angular animations)"
    echo "   - Color (background transitions)"
    echo "   - Events (transition lifecycle)"
    echo "   - Controls (animation lifecycle controls)"
    echo "   - Mixed (multi-property coordination)"
    echo "   - Choreography (6-element formations)"
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
            # Strip src/ prefix for consistency with build output
            display_path="${failed_file#src/}"
            echo "   - $display_path"
        done
    fi
    
    echo ""
    echo "💡 See error details above for each failed build."
    echo "🔧 Fix the errors and run the build script again."
    exit 1
fi
