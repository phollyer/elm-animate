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
elm make src/HTML/SmoothMoveState/Basic.elm --output=src/HTML/SmoothMoveState/basic.js
elm make src/HTML/SmoothMoveState/Multiple.elm --output=src/HTML/SmoothMoveState/multiple.js
elm make src/HTML/SmoothMoveCSS/Basic.elm --output=src/HTML/SmoothMoveCSS/basic.js
elm make src/HTML/SmoothMoveCSS/Multiple.elm --output=src/HTML/SmoothMoveCSS/multiple.js
elm make src/HTML/SmoothMovePorts/Basic.elm --output=src/HTML/SmoothMovePorts/basic.js
elm make src/HTML/SmoothMovePorts/Multiple.elm --output=src/HTML/SmoothMovePorts/multiple.js

# Build ElmUI examples
echo "🎨 Building ElmUI examples..."
elm make src/ElmUI/SmoothMoveScroll/Basic.elm --output=src/ElmUI/SmoothMoveScroll/basic.js
elm make src/ElmUI/SmoothMoveScroll/Container.elm --output=src/ElmUI/SmoothMoveScroll/container.js
elm make src/ElmUI/SmoothMoveScroll/HorizontalBasic.elm --output=src/ElmUI/SmoothMoveScroll/horizontalbasic.js
elm make src/ElmUI/SmoothMoveScroll/HorizontalContainer.elm --output=src/ElmUI/SmoothMoveScroll/horizontalcontainer.js
elm make src/ElmUI/SmoothMoveScroll/DiagonalBoth.elm --output=src/ElmUI/SmoothMoveScroll/diagonalboth.js
elm make src/ElmUI/SmoothMoveSub/Basic.elm --output=src/ElmUI/SmoothMoveSub/basic.js
elm make src/ElmUI/SmoothMoveSub/Multiple.elm --output=src/ElmUI/SmoothMoveSub/multiple.js
elm make src/ElmUI/SmoothMoveState/Basic.elm --output=src/ElmUI/SmoothMoveState/basic.js
elm make src/ElmUI/SmoothMoveState/Multiple.elm --output=src/ElmUI/SmoothMoveState/multiple.js
elm make src/ElmUI/SmoothMoveCSS/Basic.elm --output=src/ElmUI/SmoothMoveCSS/basic.js
elm make src/ElmUI/SmoothMoveCSS/Multiple.elm --output=src/ElmUI/SmoothMoveCSS/multiple.js
elm make src/ElmUI/SmoothMovePorts/Basic.elm --output=src/ElmUI/SmoothMovePorts/basic.js
elm make src/ElmUI/SmoothMovePorts/Multiple.elm --output=src/ElmUI/SmoothMovePorts/multiple.js

echo "✅ All examples built successfully!"
echo "🌐 Open index.html to view the examples dashboard"
echo "📦 HTML examples available at:"
echo "   - http://localhost:8080/src/HTML/SmoothMoveScroll/basic.html"
echo "   - http://localhost:8080/src/HTML/SmoothMoveScroll/container.html"
echo "   - And more in src/HTML/"
echo "🎨 ElmUI examples available at:"
echo "   - http://localhost:8080/src/ElmUI/SmoothMoveScroll/basic.html"
echo "   - http://localhost:8080/src/ElmUI/SmoothMoveScroll/container.html"
echo "   - http://localhost:8080/src/ElmUI/SmoothMoveScroll/horizontalbasic.html"
echo "   - And more in src/ElmUI/"