#!/bin/bash

# Elm Smooth Move Examples Build Script
# This script compiles all examples to their respective JavaScript files
# 
# IMPORTANT: Always use specific output paths ending in .js
# NEVER use --output=index.html as it would overwrite dashboard files!

echo "🚀 Building Elm Smooth Move Examples..."

# Change to examples directory (parent of scripts)
cd "$(dirname "$0")/.."

# Build HTML examples
echo "📦 Building HTML examples..."
elm make src/HTML/SmoothMoveScroll/Basic.elm --output=src/HTML/SmoothMoveScroll/basic.js
elm make src/HTML/SmoothMoveScroll/Container.elm --output=src/HTML/SmoothMoveScroll/container.js
elm make src/HTML/SmoothMoveSub/Basic.elm --output=src/HTML/SmoothMoveSub/basic.js
elm make src/HTML/SmoothMoveSub/Multiple.elm --output=src/HTML/SmoothMoveSub/multiple.js
elm make src/HTML/SmoothMoveCSS/Basic.elm --output=src/HTML/SmoothMoveCSS/basic.js
elm make src/HTML/SmoothMoveCSS/Multiple.elm --output=src/HTML/SmoothMoveCSS/multiple.js
elm make src/HTML/SmoothMovePorts/Basic.elm --output=src/HTML/SmoothMovePorts/basic.js
elm make src/HTML/SmoothMovePorts/Multiple.elm --output=src/HTML/SmoothMovePorts/multiple.js

# Build ElmUI examples
echo "🎨 Building ElmUI examples..."
elm make src/ElmUI/Scroll/PageY/Main.elm --output=src/ElmUI/Scroll/PageY/index.js
elm make src/ElmUI/Scroll/ContainerY/Main.elm --output=src/ElmUI/Scroll/ContainerY/index.js
elm make src/ElmUI/Scroll/PageX/Main.elm --output=src/ElmUI/Scroll/PageX/index.js
elm make src/ElmUI/Scroll/ContainerX/Main.elm --output=src/ElmUI/Scroll/ContainerX/index.js
elm make src/ElmUI/Scroll/PageXY/Main.elm --output=src/ElmUI/Scroll/PageXY/index.js
elm make src/ElmUI/Sub/Basic/Main.elm --output=src/ElmUI/Sub/Basic/index.js
elm make src/ElmUI/Sub/Multiple/Main.elm --output=src/ElmUI/Sub/Multiple/index.js
elm make src/ElmUI/CSS/Basic/Main.elm --output=src/ElmUI/CSS/Basic/index.js
elm make src/ElmUI/CSS/Multiple/Main.elm --output=src/ElmUI/CSS/Multiple/index.js
elm make src/ElmUI/Ports/Basic/Main.elm --output=src/ElmUI/Ports/Basic/index.js
elm make src/ElmUI/Ports/Multiple/Main.elm --output=src/ElmUI/Ports/Multiple/index.js

echo "✅ All examples built successfully!"
echo "🌐 Open index.html to view the examples dashboard"
echo "📦 HTML examples available at:"
echo "   - http://localhost:8080/src/HTML/SmoothMoveScroll/basic.html"
echo "   - http://localhost:8080/src/HTML/SmoothMoveScroll/container.html"
echo "   - And more in src/HTML/"
echo "🎨 ElmUI examples available at:"
echo "   - http://localhost:8080/src/ElmUI/Scroll/PageY/index.html"
echo "   - http://localhost:8080/src/ElmUI/Scroll/ContainerY/index.html"
echo "   - http://localhost:8080/src/ElmUI/Scroll/PageX/index.html"
echo "   - And more in src/ElmUI/"