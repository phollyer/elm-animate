# Elm Smooth Move Examples

Interactive examples showcasing all 4 animation approaches. Each example is compiled and ready to run directly in your browser!

## 🚀 Quick Start

**Just open `src/ElmUI/index.html`** in your browser to see the ElmUI examples dashboard, or open any specific example directly:

**ElmUI Examples** (Modern, responsive UI):
- `src/ElmUI/Scroll/Basic/index.html` - Basic scrolling with ElmUI
- `src/ElmUI/Sub/Basic/index.html` - Subscription-based element movement
- `src/ElmUI/CSS/Basic/index.html` - Hardware-accelerated animations
- `src/ElmUI/Ports/Basic/index.html` - Web Animations API integration
- And more in `src/ElmUI/`

**HTML Examples** (Pure HTML/CSS):  
- `src/HTML/SmoothMoveScroll/basic.html` - Basic scrolling
- `src/HTML/SmoothMoveSub/basic.html` - Subscription-based element movement  
- `src/HTML/SmoothMoveCSS/basic.html` - Hardware-accelerated animations
- `src/HTML/SmoothMovePorts/basic.html` - Web Animations API integration
- And more in `src/HTML/`

## 🔧 Rebuilding Examples

If you modify any `.elm` files, run the build script to recompile:

```bash
./scripts/build.sh
```

This will regenerate all the `.js` files needed by the HTML examples.

## 📚 Example Structure

The examples are now organized into two main categories:

```
examples/
├── scripts/            - Build scripts
│   └── build.sh
├── js/                 - JavaScript companion files
│   ├── smooth-move-waapi.js
│   └── smooth-move-ports.js (legacy)
└── src/
    ├── ElmUI/          - Modern ElmUI examples (recommended)
    │   ├── Scroll/     - Task-based scrolling examples
    │   ├── Sub/        - Subscription-based element positioning
    │   ├── CSS/        - CSS transition-based examples
    │   └── Ports/      - Web Animations API examples
    ├── HTML/           - Pure HTML examples  
    │   ├── SmoothMoveScroll/
    │   ├── SmoothMoveSub/
    │   ├── SmoothMoveCSS/
    │   └── SmoothMovePorts/
    └── Common/         - Shared utilities
```

## Running Examples

From the `examples/` directory:

```bash
# Single ElmUI example  
elm make src/ElmUI/SmoothMoveScrollUI/Basic.elm --output=basic.html

# Single HTML example
elm make src/HTML/SmoothMoveScroll/Basic.elm --output=basic.html

# With live server (python 3)
python -m http.server 8000
# Then navigate to http://localhost:8000/index.html

# Build all examples using the provided script
./scripts/build.sh
```

## Module Hierarchy

All examples use proper hierarchical module names based on their category:

**ElmUI Examples:**
- `ElmUI.Scroll.Basic`
- `ElmUI.Sub.Multiple` 
- `ElmUI.CSS.Basic`
- `ElmUI.Ports.Multiple`
- etc.

**HTML Examples:**
- `HTML.SmoothMoveScroll.Basic`
- `HTML.SmoothMoveSub.Multiple`
- etc.

This organization makes it clear which UI framework each example uses while following Elm's module naming conventions.

## Getting Started

1. **Open the main dashboard**: Open `index.html` in your browser
2. **Choose your approach**: 
   - Click "Explore ElmUI Examples" for modern, production-ready examples
   - Scroll down to "HTML Examples Overview" for fundamental concepts
3. **Run examples**: Each example is pre-built and ready to run in your browser

## JavaScript Integration

The `SmoothMovePorts` examples require JavaScript integration:
- **For Production**: Install via npm: `npm install elm-smooth-move`
- **For Development**: Available in `examples/js/smooth-move-ports.js`
- **HTML Examples**: Local copy at `examples/src/HTML/SmoothMovePorts/smooth-move-ports.js`
- **CDN Option**: `https://unpkg.com/elm-smooth-move/dist/smooth-move-ports.js`  
- **Documentation**: See the respective README.md files for detailed integration guides
- **Purpose**: Provides Web Animations API integration for hardware-accelerated animations