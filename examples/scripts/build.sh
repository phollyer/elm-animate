#!/bin/bash

# Elm Smooth Move Examples Build Script
# This script compiles all examples to their respective JavaScript files
# 
# IMPORTANT: Always use specific output paths ending in .js
# NEVER use --output=index.html as it would overwrite dashboard files!

echo "🚀 Building Elm Smooth Move Examples..."

# Change to examples directory (parent of scripts)
cd "$(dirname "$0")/.."

# Track build results
FAILED_BUILDS=()
SUCCESSFUL_BUILDS=()

# Function to build and track results
build_example() {
    local src_file=$1
    local output_file=$2
    local display_name=${3:-$src_file}
    
    echo "Building $display_name..."
    if elm make "$src_file" --output="$output_file" > /dev/null 2>&1; then
        echo "✅ $display_name → $output_file"
        SUCCESSFUL_BUILDS+=("$display_name")
        elm-format --yes "$src_file" > /dev/null
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
# echo "  📜 ElmUI Scroll examples (Anim.Scroll - Task-based API)..."
# build_example "src/ElmUI/Scroll/Document/Position/X/Main.elm" "src/ElmUI/Scroll/Document/Position/X/index.js" "ElmUI.Scroll.Document.Position.X.Main"
# build_example "src/ElmUI/Scroll/Document/Position/Y/Main.elm" "src/ElmUI/Scroll/Document/Position/Y/index.js" "ElmUI.Scroll.Document.Position.Y.Main"
# build_example "src/ElmUI/Scroll/Document/Position/Both/Main.elm" "src/ElmUI/Scroll/Document/Position/Both/index.js" "ElmUI.Scroll.Document.Position.Both.Main"
# build_example "src/ElmUI/Scroll/Container/Position/X/Main.elm" "src/ElmUI/Scroll/Container/Position/X/index.js" "ElmUI.Scroll.Container.Position.X.Main"
# build_example "src/ElmUI/Scroll/Container/Position/Y/Main.elm" "src/ElmUI/Scroll/Container/Position/Y/index.js" "ElmUI.Scroll.Container.Position.Y.Main"
# build_example "src/ElmUI/Scroll/Container/Position/Both/Main.elm" "src/ElmUI/Scroll/Container/Position/Both/index.js" "ElmUI.Scroll.Container.Position.Both.Main"
# build_example "src/ElmUI/Scroll/ScrollIntoView/Main.elm" "src/ElmUI/Scroll/ScrollIntoView/index.js" "ElmUI.Scroll.ScrollIntoView.Main"

# ElmUI CSS examples (CSS Transition-based API)
# echo "  🎨 ElmUI CSS examples (Anim.CSS - Browser-native transitions)..."
build_example "src/ElmUI/CSS/Position/Main.elm" "src/ElmUI/CSS/Position/index.js" "ElmUI.CSS.Position.Main"
# build_example "src/ElmUI/CSS/Opacity/Main.elm" "src/ElmUI/CSS/Opacity/index.js" "ElmUI.CSS.Opacity.Main"
# build_example "src/ElmUI/CSS/Scale/Main.elm" "src/ElmUI/CSS/Scale/index.js" "ElmUI.CSS.Scale.Main"
build_example "src/ElmUI/CSS/Rotation/Main.elm" "src/ElmUI/CSS/Rotation/index.js" "ElmUI.CSS.Rotation.Main"
build_example "src/ElmUI/CSS/Color/Main.elm" "src/ElmUI/CSS/Color/index.js" "ElmUI.CSS.Color.Main"
# build_example "src/ElmUI/CSS/Mixed/Main.elm" "src/ElmUI/CSS/Mixed/index.js" "ElmUI.CSS.Mixed.Main"
# build_example "src/ElmUI/CSS/Choreography/Main.elm" "src/ElmUI/CSS/Choreography/index.js" "ElmUI.CSS.Choreography.Main"

# ElmUI Sub examples (Subscription-based API)
#echo "  ⚡ ElmUI Sub examples (Anim.Sub - Frame-rate independent timing)..."
#build_example "src/ElmUI/Sub/Position/Main.elm" "src/ElmUI/Sub/Position/index.js" "ElmUI.Sub.Position.Main"
#build_example "src/ElmUI/Sub/Opacity/Main.elm" "src/ElmUI/Sub/Opacity/index.js" "ElmUI.Sub.Opacity.Main"
#build_example "src/ElmUI/Sub/Scale/Main.elm" "src/ElmUI/Sub/Scale/index.js" "ElmUI.Sub.Scale.Main"
#build_example "src/ElmUI/Sub/Rotation/Main.elm" "src/ElmUI/Sub/Rotation/index.js" "ElmUI.Sub.Rotation.Main"
#build_example "src/ElmUI/Sub/Color/Main.elm" "src/ElmUI/Sub/Color/index.js" "ElmUI.Sub.Color.Main"
#build_example "src/ElmUI/Sub/Mixed/Main.elm" "src/ElmUI/Sub/Mixed/index.js" "ElmUI.Sub.Mixed.Main"
#build_example "src/ElmUI/Sub/Choreography/Main.elm" "src/ElmUI/Sub/Choreography/index.js" "ElmUI.Sub.Choreography.Main"

# ElmUI Ports examples (JavaScript Web Animations API)
# echo "  🌐 ElmUI Ports examples (Anim.Ports - Web Animations API integration)..."
# build_example "src/ElmUI/Ports/Position/Main.elm" "src/ElmUI/Ports/Position/index.js" "ElmUI.Ports.Position.Main"
# build_example "src/ElmUI/Ports/Opacity/Main.elm" "src/ElmUI/Ports/Opacity/index.js" "ElmUI.Ports.Opacity.Main"
# build_example "src/ElmUI/Ports/Scale/Main.elm" "src/ElmUI/Ports/Scale/index.js" "ElmUI.Ports.Scale.Main"
# build_example "src/ElmUI/Ports/Rotation/Main.elm" "src/ElmUI/Ports/Rotation/index.js" "ElmUI.Ports.Rotation.Main"
# build_example "src/ElmUI/Ports/Color/Main.elm" "src/ElmUI/Ports/Color/index.js" "ElmUI.Ports.Color.Main"
# build_example "src/ElmUI/Ports/Mixed/Main.elm" "src/ElmUI/Ports/Mixed/index.js" "ElmUI.Ports.Mixed.Main"
# build_example "src/ElmUI/Ports/Choreography/Main.elm" "src/ElmUI/Ports/Choreography/index.js" "ElmUI.Ports.Choreography.Main"

# Report results
echo ""
echo "📊 Build Summary:"
echo "✅ Successful builds: ${#SUCCESSFUL_BUILDS[@]}"
echo "❌ Failed builds: ${#FAILED_BUILDS[@]}"

if [ ${#FAILED_BUILDS[@]} -eq 0 ]; then
    echo ""
    echo "🎉 All examples built successfully!"
    echo "🌐 Open index.html to view the examples dashboard"
    echo ""
    echo "🎨 ElmUI examples available at:"
    echo "   📜 Scroll (Task-based): src/ElmUI/Scroll/"
    echo "   🎨 CSS (Transitions): src/ElmUI/CSS/"
    echo "   ⚡ Sub (Subscriptions): src/ElmUI/Sub/"
    echo "   🌐 Ports (Web Animations): src/ElmUI/Ports/"
    echo ""
    echo "   Animation properties covered:"
    echo "   - Position (X/Y coordinates)"
    echo "   - Opacity (fade in/out)"
    echo "   - Scale (size transformations)"
    echo "   - Rotation (angular animations)"
    echo "   - Color (background transitions)"
    echo "   - Mixed (multi-property coordination)"
    echo "   - Choreography (6-element formations)"
else
    echo ""
    echo "🚨 Some examples failed to build:"
    for failed_build in "${FAILED_BUILDS[@]}"; do
        echo "   - $failed_build"
    done
    echo ""
    echo "💡 See error details above for each failed build."
    echo "🔧 Fix the errors and run the build script again."
    exit 1
fi
