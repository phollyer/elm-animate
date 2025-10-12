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
elm make src/ElmUI/SmoothMoveScroll/Basic/Main.elm --output=src/ElmUI/SmoothMoveScroll/Basic/index.js
elm make src/ElmUI/SmoothMoveScroll/Container/Main.elm --output=src/ElmUI/SmoothMoveScroll/Container/index.js
elm make src/ElmUI/SmoothMoveScroll/HorizontalBasic/Main.elm --output=src/ElmUI/SmoothMoveScroll/HorizontalBasic/index.js
elm make src/ElmUI/SmoothMoveScroll/HorizontalContainer/Main.elm --output=src/ElmUI/SmoothMoveScroll/HorizontalContainer/index.js
elm make src/ElmUI/SmoothMoveScroll/DiagonalBoth/Main.elm --output=src/ElmUI/SmoothMoveScroll/DiagonalBoth/index.js
elm make src/ElmUI/SmoothMoveSub/Basic/Main.elm --output=src/ElmUI/SmoothMoveSub/Basic/index.js
elm make src/ElmUI/SmoothMoveSub/Multiple/Main.elm --output=src/ElmUI/SmoothMoveSub/Multiple/index.js
elm make src/ElmUI/SmoothMoveCSS/Basic/Main.elm --output=src/ElmUI/SmoothMoveCSS/Basic/index.js
elm make src/ElmUI/SmoothMoveCSS/Multiple/Main.elm --output=src/ElmUI/SmoothMoveCSS/Multiple/index.js
elm make src/ElmUI/SmoothMovePorts/Basic/Main.elm --output=src/ElmUI/SmoothMovePorts/Basic/index.js
elm make src/ElmUI/SmoothMovePorts/Multiple/Main.elm --output=src/ElmUI/SmoothMovePorts/Multiple/index.js

echo "✅ All examples built successfully!"
echo "🌐 Open index.html to view the examples dashboard"
echo "📦 HTML examples available at:"
echo "   - http://localhost:8080/src/HTML/SmoothMoveScroll/basic.html"
echo "   - http://localhost:8080/src/HTML/SmoothMoveScroll/container.html"
echo "   - And more in src/HTML/"
echo "🎨 ElmUI examples available at:"
echo "   - http://localhost:8080/src/ElmUI/SmoothMoveScroll/Basic/index.html"
echo "   - http://localhost:8080/src/ElmUI/SmoothMoveScroll/Container/index.html"
echo "   - http://localhost:8080/src/ElmUI/SmoothMoveScroll/HorizontalBasic/index.html"
echo "   - And more in src/ElmUI/"