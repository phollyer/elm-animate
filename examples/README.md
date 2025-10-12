# Elm Smooth Move Examples

Interactive examples showcasing all 5 animation approaches. Each example is compiled and ready to run directly in your browser!

> **Note**: If `index.html` gets accidentally overwritten, run `./restore-index.sh` to restore the dashboard.

## 🚀 Quick Start

**Just open `src/ElmUI/index.html`** in your browser to see the ElmUI examples dashboard, or open any specific example directly:

**ElmUI Examples** (Modern, responsive UI):
- `src/ElmUI/SmoothMoveScrollUI/basic.html` - Basic scrolling with ElmUI
- `src/ElmUI/SmoothMoveStateUI/basic.html` - Simple element movement
- `src/ElmUI/SmoothMoveCSSUI/basic.html` - Hardware-accelerated animations
- And more in `src/ElmUI/`

**HTML Examples** (Pure HTML/CSS):  
- `src/HTML/SmoothMoveScroll/basic.html` - Basic scrolling
- `src/HTML/SmoothMoveState/basic.html` - Simple element movement  
- `src/HTML/SmoothMoveCSS/basic.html` - Hardware-accelerated animations
- And more in `src/HTML/`

## 🔧 Rebuilding Examples

If you modify any `.elm` files, run the build script to recompile:

```bash
./build.sh
```

This will regenerate all the `.js` files needed by the HTML examples.

## 📚 Example Structure

The examples are now organized into two main categories:

```
examples/src/
├── ElmUI/              - Modern ElmUI examples (recommended)
│   ├── SmoothMoveScrollUI/
│   ├── SmoothMoveStateUI/ 
│   ├── SmoothMoveSubUI/
│   ├── SmoothMoveCSSUI/
│   └── SmoothMovePortsUI/
├── HTML/               - Pure HTML examples  
│   ├── SmoothMoveScroll/
│   ├── SmoothMoveState/
│   ├── SmoothMoveSub/
│   ├── SmoothMoveCSS/
│   └── SmoothMovePortsUI/
└── Common/             - Shared utilities
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
./build.sh
```

## Module Hierarchy

All examples use proper hierarchical module names based on their category:

**ElmUI Examples:**
- `ElmUI.SmoothMoveScrollUI.Basic`
- `ElmUI.SmoothMoveStateUI.Multiple` 
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
- **HTML Location**: `examples/src/HTML/SmoothMovePorts/smooth-move-ports.js`
- **ElmUI Location**: `examples/src/ElmUI/SmoothMovePortsUI/smooth-move-ports.js`  
- **Documentation**: See the respective README.md files for detailed integration guides
- **Purpose**: Provides Web Animations API integration for hardware-accelerated animations