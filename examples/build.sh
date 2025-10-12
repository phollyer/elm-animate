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
elm make src/ElmUI/SmoothMoveScrollUI/Basic.elm --output=src/ElmUI/SmoothMoveScrollUI/basic.js
elm make src/ElmUI/SmoothMoveScrollUI/Container.elm --output=src/ElmUI/SmoothMoveScrollUI/container.js
elm make src/ElmUI/SmoothMoveScrollUI/HorizontalBasic.elm --output=src/ElmUI/SmoothMoveScrollUI/horizontalbasic.js
elm make src/ElmUI/SmoothMoveScrollUI/HorizontalContainer.elm --output=src/ElmUI/SmoothMoveScrollUI/horizontalcontainer.js
elm make src/ElmUI/SmoothMoveScrollUI/DiagonalBoth.elm --output=src/ElmUI/SmoothMoveScrollUI/diagonalboth.js
elm make src/ElmUI/SmoothMoveSubUI/Basic.elm --output=src/ElmUI/SmoothMoveSubUI/basic.js
elm make src/ElmUI/SmoothMoveSubUI/Multiple.elm --output=src/ElmUI/SmoothMoveSubUI/multiple.js
elm make src/ElmUI/SmoothMoveStateUI/Basic.elm --output=src/ElmUI/SmoothMoveStateUI/basic.js
elm make src/ElmUI/SmoothMoveStateUI/Multiple.elm --output=src/ElmUI/SmoothMoveStateUI/multiple.js
elm make src/ElmUI/SmoothMoveCSSUI/Basic.elm --output=src/ElmUI/SmoothMoveCSSUI/basic.js
elm make src/ElmUI/SmoothMoveCSSUI/Multiple.elm --output=src/ElmUI/SmoothMoveCSSUI/multiple.js
elm make src/ElmUI/SmoothMovePortsUI/Basic.elm --output=src/ElmUI/SmoothMovePortsUI/basic.js
elm make src/ElmUI/SmoothMovePortsUI/Multiple.elm --output=src/ElmUI/SmoothMovePortsUI/multiple.js

echo "✅ All examples built successfully!"
echo "🌐 Open index.html to view the examples dashboard"
echo "📦 HTML examples available at:"
echo "   - http://localhost:8080/src/HTML/SmoothMoveScroll/basic.html"
echo "   - http://localhost:8080/src/HTML/SmoothMoveScroll/container.html"
echo "   - And more in src/HTML/"
echo "🎨 ElmUI examples available at:"
echo "   - http://localhost:8080/src/ElmUI/SmoothMoveScrollUI/basic.html"
echo "   - http://localhost:8080/src/ElmUI/SmoothMoveScrollUI/container.html"
echo "   - http://localhost:8080/src/ElmUI/SmoothMoveScrollUI/horizontalbasic.html"
echo "   - And more in src/ElmUI/"