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
    else
        echo "❌ $display_name FAILED"
        echo "   Error details:"
        elm make "$src_file" --output="$output_file" 2>&1 | sed 's/^/   /'
        FAILED_BUILDS+=("$display_name")
    fi
}

# Build HTML examples
echo ""
echo "📦 Building HTML examples..."
build_example "src/HTML/SmoothMoveScroll/Basic.elm" "src/HTML/SmoothMoveScroll/basic.js" "HTML.SmoothMoveScroll.Basic"
build_example "src/HTML/SmoothMoveScroll/Container.elm" "src/HTML/SmoothMoveScroll/container.js" "HTML.SmoothMoveScroll.Container"
build_example "src/HTML/SmoothMoveSub/Basic.elm" "src/HTML/SmoothMoveSub/basic.js" "HTML.SmoothMoveSub.Basic"
build_example "src/HTML/SmoothMoveSub/Multiple.elm" "src/HTML/SmoothMoveSub/multiple.js" "HTML.SmoothMoveSub.Multiple"
build_example "src/HTML/SmoothMoveCSS/Basic.elm" "src/HTML/SmoothMoveCSS/basic.js" "HTML.SmoothMoveCSS.Basic"
build_example "src/HTML/SmoothMoveCSS/Multiple.elm" "src/HTML/SmoothMoveCSS/multiple.js" "HTML.SmoothMoveCSS.Multiple"
build_example "src/HTML/SmoothMovePorts/Basic.elm" "src/HTML/SmoothMovePorts/basic.js" "HTML.SmoothMovePorts.Basic"
build_example "src/HTML/SmoothMovePorts/Multiple.elm" "src/HTML/SmoothMovePorts/multiple.js" "HTML.SmoothMovePorts.Multiple"

# Build ElmUI examples
echo ""
echo "🎨 Building ElmUI examples..."
build_example "src/ElmUI/Scroll/DocumentY/Main.elm" "src/ElmUI/Scroll/DocumentY/index.js" "ElmUI.Scroll.DocumentY.Main"
build_example "src/ElmUI/Scroll/ContainerY/Main.elm" "src/ElmUI/Scroll/ContainerY/index.js" "ElmUI.Scroll.ContainerY.Main"
build_example "src/ElmUI/Scroll/DocumentX/Main.elm" "src/ElmUI/Scroll/DocumentX/index.js" "ElmUI.Scroll.DocumentX.Main"
build_example "src/ElmUI/Scroll/ContainerX/Main.elm" "src/ElmUI/Scroll/ContainerX/index.js" "ElmUI.Scroll.ContainerX.Main"
build_example "src/ElmUI/Scroll/DocumentXY/Main.elm" "src/ElmUI/Scroll/DocumentXY/index.js" "ElmUI.Scroll.DocumentXY.Main"
build_example "src/ElmUI/Scroll/ContainerXY/Main.elm" "src/ElmUI/Scroll/ContainerXY/index.js" "ElmUI.Scroll.ContainerXY.Main"
build_example "src/ElmUI/Scroll/ScrollIntoView/Main.elm" "src/ElmUI/Scroll/ScrollIntoView/index.js" "ElmUI.Scroll.ScrollIntoView.Main"
build_example "src/ElmUI/Sub/Basic/Main.elm" "src/ElmUI/Sub/Basic/index.js" "ElmUI.Sub.Basic.Main"
build_example "src/ElmUI/Sub/Multiple/Main.elm" "src/ElmUI/Sub/Multiple/index.js" "ElmUI.Sub.Multiple.Main"
build_example "src/ElmUI/CSS/Basic/Main.elm" "src/ElmUI/CSS/Basic/index.js" "ElmUI.CSS.Basic.Main"
build_example "src/ElmUI/CSS/Multiple/Main.elm" "src/ElmUI/CSS/Multiple/index.js" "ElmUI.CSS.Multiple.Main"
build_example "src/ElmUI/Ports/Basic/Main.elm" "src/ElmUI/Ports/Basic/index.js" "ElmUI.Ports.Basic.Main"
build_example "src/ElmUI/Ports/Multiple/Main.elm" "src/ElmUI/Ports/Multiple/index.js" "ElmUI.Ports.Multiple.Main"

# Report results
echo ""
echo "📊 Build Summary:"
echo "✅ Successful builds: ${#SUCCESSFUL_BUILDS[@]}"
echo "❌ Failed builds: ${#FAILED_BUILDS[@]}"

if [ ${#FAILED_BUILDS[@]} -eq 0 ]; then
    echo ""
    echo "🎉 All examples built successfully!"
    echo "🌐 Open index.html to view the examples dashboard"
    echo "📦 HTML examples available at:"
    echo "   - http://localhost:8080/src/HTML/SmoothMoveScroll/basic.html"
    echo "   - http://localhost:8080/src/HTML/SmoothMoveScroll/container.html"
    echo "   - And more in src/HTML/"
    echo "🎨 ElmUI examples available at:"
    echo "   - http://localhost:8080/src/ElmUI/Scroll/DocumentY/index.html"
    echo "   - http://localhost:8080/src/ElmUI/Scroll/ContainerY/index.html"
    echo "   - http://localhost:8080/src/ElmUI/Scroll/DocumentX/index.html"
    echo "   - And more in src/ElmUI/"
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