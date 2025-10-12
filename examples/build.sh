#!/bin/bash

# Elm Smooth Move Examples Build Script
# This script compiles all examples to their respective JavaScript files

echo "🚀 Building Elm Smooth Move Examples..."

# Change to examples directory
cd "$(dirname "$0")"

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
elm make src/ElmUI/Scroll/Basic/Main.elm --output=src/ElmUI/Scroll/Basic/index.js
elm make src/ElmUI/Scroll/Container/Main.elm --output=src/ElmUI/Scroll/Container/index.js
elm make src/ElmUI/Scroll/HorizontalBasic/Main.elm --output=src/ElmUI/Scroll/HorizontalBasic/index.js
elm make src/ElmUI/Scroll/HorizontalContainer/Main.elm --output=src/ElmUI/Scroll/HorizontalContainer/index.js
elm make src/ElmUI/Scroll/DiagonalBoth/Main.elm --output=src/ElmUI/Scroll/DiagonalBoth/index.js
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
echo "   - http://localhost:8080/src/ElmUI/Scroll/Basic/index.html"
echo "   - http://localhost:8080/src/ElmUI/Scroll/Container/index.html"
echo "   - http://localhost:8080/src/ElmUI/Scroll/HorizontalBasic/index.html"
echo "   - And more in src/ElmUI/"