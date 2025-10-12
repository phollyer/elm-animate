# Elm Smooth Move

A comprehensive Elm package providing **4 different animation approaches** for smooth DOM element movement. Choose the approach that best fits your performance needs and use case.

> **Credits**: This package builds upon the excellent foundation of [`linuss/smooth-scroll`](https://package.elm-lang.org/packages/linuss/smooth-scroll/latest/) by expanding it into a multi-approach animation library.

## 🎯 Four Animation Approaches

### 1. **SmoothMoveScroll** - Scrolling (Simple & Advanced)
Perfect for **document/container scrolling** with both simple and advanced APIs.
```elm
import SmoothMoveScroll exposing (animateTo, animateToWithConfig)

-- Simple usage (recommended for most users)
animateTo "target-element-id"  -- Returns Cmd ()

-- Simple with configuration
animateToWithConfig 
    { defaultConfig | offset = 60, speed = 15 } 
    "target-element-id"

-- Advanced: Task-based for composition/error handling
import SmoothMoveScroll exposing (animateToTask)
import Task

animateToTask "target-element-id"
    |> Task.attempt HandleScrollError
```

### 2. **SmoothMoveSub** - Subscription-Based Positioning  
Ideal for **multiple simultaneous element animations** with frame-rate independence.
```elm
import SmoothMoveSub exposing (animateTo, transform)
import Html.Attributes exposing (style)

-- Animate an element to position (100, 200)
{ model | animations = animateTo "my-element" 100 200 model.animations }

-- Apply in view with CSS transform
style "transform" (transform "my-element" model.animations)
```

### 3. **SmoothMoveCSS** - CSS Transition-Based
Uses **native browser CSS transitions** for optimal performance and battery efficiency.
```elm
import SmoothMoveCSS exposing (animateTo, transform)
import Html exposing (div, text)
import Html.Attributes exposing (style)

-- Animate an element to position (100, 200)
{ model | animations = animateTo "my-element" 100 200 model.animations }

-- Apply CSS transition in view
div [ style "transform" (transform "my-element" model.animations) ] [ text "Smooth!" ]
```

### 4. **SmoothMovePorts** - Web Animations API
**JavaScript integration** for maximum performance and complex animations.
```elm
import SmoothMovePorts exposing (animateTo, animateBatchWithPort)

-- Single element animation
( newAnimations, cmd ) = animateTo "my-element" 100 200 model.animations

-- Batch multiple animations (new!)
( newAnimations, cmd ) = animateBatchWithPort myPort 
    [ ("box1", 100, 150), ("box2", 200, 250), ("box3", 300, 350) ] 
    model.animations

-- Requires companion JavaScript: npm install elm-smooth-move
```

## 🚀 Quick Start

### 1. Install the package
```bash
elm install phollyer/elm-smooth-move
```

**For SmoothMovePorts (Web Animations API), also install the JavaScript companion:**
```bash
npm install elm-smooth-move
```

### 2. Choose your first approach (we recommend starting simple)

**For page scrolling:**  
```elm
import SmoothMoveScroll exposing (animateTo)

-- In your update function (simple!)
SmoothScroll elementId ->
    ( model, animateTo elementId )
```

**For moving UI elements:**
```elm
import SmoothMoveSub exposing (animateTo, init, subscriptions)

-- In your model
type alias Model = { animations : SmoothMoveSub.Model, ... }

-- In your init (prevent jump to 0,0)
initialAnimations = 
    SmoothMoveSub.init
        |> SmoothMoveSub.setInitialPosition "my-element" 100 100

-- In your update  
AnimateElement ->
    { model | animations = animateTo "my-element" 200 300 model.animations }

-- Don't forget subscriptions!
subscriptions model = SmoothMoveSub.subscriptions model.animations AnimationFrame
```

### 3. Explore the examples

**Option A: Direct HTML files (recommended)**
```bash
cd examples/
open index.html  # Opens main examples page in your browser
# Or open any specific example directly, e.g.:
open src/ElmUI/Sub/Basic/index.html
```

**Option B: Using elm reactor**
```bash
cd examples/
elm reactor
# Navigate to: http://localhost:8000/src/SmoothMoveScroll/Basic.elm
```

### 4. Experiment with different approaches
Once you're comfortable, try switching `SmoothMoveSub` to `SmoothMoveCSS` in your imports for better performance, or `SmoothMovePorts` for maximum control!

## 📚 Examples

Interactive examples are ready to run! Open `examples/index.html` to see the main dashboard, or browse the organized examples:

- **`ElmUI/Scroll/`** - Task-based scrolling examples with modern UI
- **`ElmUI/Sub/`** - Subscription-based positioning examples  
- **`ElmUI/CSS/`** - CSS transition-based examples
- **`ElmUI/Ports/`** - JavaScript Web Animations API examples
- **`HTML/SmoothMoveScroll/`** - HTML task-based examples
- **`HTML/SmoothMoveSub/`** - HTML subscription examples
- **`HTML/SmoothMoveCSS/`** - HTML CSS examples
- **`HTML/SmoothMovePorts/`** - HTML ports examples

**🎯 Start here: [examples/index.html](examples/index.html)** - Main examples dashboard

## 🎨 Choosing the Right Approach

### Quick Decision Guide
- **Scrolling a page?** → Use `SmoothMoveScroll`
- **Moving multiple elements?** → Use `SmoothMoveSub` 
- **Need best battery life?** → Use `SmoothMoveCSS` or `SmoothMovePorts`
- **Complex animations?** → Use `SmoothMovePorts`
- **Simple frame-based control?** → Use `SmoothMoveSub`

### Detailed Comparison

| Approach | Best For | Performance | Battery | Complexity |
|----------|----------|-------------|---------|------------|
| **SmoothMoveScroll** | Document/container scrolling | Good | Medium | Simple |
| **SmoothMoveSub** | Multiple simultaneous elements | Good | Medium | Medium |
| **SmoothMoveCSS** | Battery efficiency, simple UI | Excellent* | Best* | Simple |
| **SmoothMovePorts** | Maximum control & performance | Excellent* | Best* | Complex |

_*Hardware accelerated when available_

### Axis Control
All approaches support constraining movement to specific axes:
```elm
{ defaultConfig | axis = X }     -- Horizontal only
{ defaultConfig | axis = Y }     -- Vertical only  
{ defaultConfig | axis = Both }  -- Both directions (default)
```

## ⚙️ Configuration & Switching Between Approaches

### Consistent Configuration
All approaches use similar configuration patterns, making it easy to switch:

```elm
-- Task-based scrolling
{ defaultConfig | offset = 60, speed = 400, easing = Ease.outCubic, axis = Y }

-- Element positioning (Sub/State)
{ defaultConfig | speed = 400, easing = Ease.outCubic, axis = Both }

-- CSS transitions
{ defaultConfig | duration = 400, easing = "cubic-bezier(0.4, 0.0, 0.2, 1)", axis = Both }

-- Web Animations API (Ports)
{ defaultConfig | duration = 400, easing = "ease-out", axis = Both }
```

### Migration Between Approaches
Most approaches now share very similar APIs!

**✅ Easy transitions (consistent Cmd-based patterns):**
```elm
-- Scrolling (simple Cmd-based)
ScrollTo elementId -> ( model, SmoothMoveScroll.animateTo elementId )

-- Element positioning (state-based)
MoveElement -> { model | animations = SmoothMoveSub.animateTo "elem" 100 200 model.animations }
MoveElement -> { model | animations = SmoothMoveCSS.animateTo "elem" 100 200 model.animations }
```

**⚠️ Requires additional changes:**
- **SmoothMovePorts**: Returns `( Model, Cmd )` - needs tuple destructuring + JavaScript setup
- **Subscriptions**: SmoothMoveSub/State/CSS need subscriptions, Task/Ports don't
- **Advanced Task API**: Use `SmoothMoveScroll.animateToTask` for composition/error handling

## 📖 API Documentation

- **SmoothMoveScroll**: `animateTo`, `animateToWithConfig`, `containerElement`, `containerElementWithConfig` (simple Cmd-based) + `animateToTask`, `animateToTaskWithConfig`, `containerElementTask`, `containerElementTaskWithConfig` (advanced Task-based)
- **SmoothMoveSub**: `animateTo`, `animateToWithConfig`, `subscriptions`, `transform`, `setInitialPosition`

- **SmoothMoveCSS**: `animateTo`, `animateToWithConfig`, `cssTransitionStyle`, `setInitialPosition`
- **SmoothMovePorts**: `animateTo`, `animateToWithConfig`, `animateBatch`, `animateBatchWithPort`, `setInitialPosition`, `stopBatch`, `stopBatchWithPort`

## � Troubleshooting

### Animation not working?
- **Check element IDs**: Make sure the element ID exists in your DOM
- **Missing subscriptions**: For `SmoothMoveSub`/`SmoothMoveCSS`, ensure you have `subscriptions` wired up
- **CSS positioning**: Elements need `position: absolute` or `position: relative` for transforms to work
- **JavaScript setup**: For `SmoothMovePorts`, install via npm (`npm install elm-smooth-move`) and include the script

### Performance issues?
- Try `SmoothMoveCSS` for hardware acceleration
- Use `axis` constraints to animate fewer dimensions
- Consider `SmoothMovePorts` for complex animations

### Need help choosing an approach?
- Start with `SmoothMoveSub` for general element animations
- Move to `SmoothMoveCSS` when you need better performance
- Use `SmoothMoveScroll` for scrolling
- Use `SmoothMovePorts` when you need maximum control

## � JavaScript Setup (SmoothMovePorts)

For the `SmoothMovePorts` approach, you need the JavaScript companion library:

### Installation
```bash
# Install the npm package
npm install elm-smooth-move

# Or use CDN
<script src="https://unpkg.com/elm-smooth-move/dist/smooth-move-ports.js"></script>
```

### Usage
```html
<!DOCTYPE html>
<html>
<head>
    <script src="./node_modules/elm-smooth-move/dist/smooth-move-ports.js"></script>
    <!-- Or from CDN: -->
    <!-- <script src="https://unpkg.com/elm-smooth-move/dist/smooth-move-ports.js"></script> -->
</head>
<body>
    <div id="my-elm-app"></div>
    <script src="your-elm-app.js"></script>
    <script>
        var app = Elm.YourApp.init({ node: document.getElementById('my-elm-app') });
        
        // Initialize SmoothMovePorts
        if (window.SmoothMovePorts && app.ports) {
            window.SmoothMovePorts.init(app.ports);
        }
    </script>
</body>
</html>
```

## �🙏 Credits

This package builds upon the excellent foundation of [`linuss/smooth-scroll`](https://package.elm-lang.org/packages/linuss/smooth-scroll/latest/). The original design and architecture provided the inspiration for this expanded multi-approach animation library.

## 📄 License

BSD-3-Clause
