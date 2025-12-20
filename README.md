# Smooth Animations And Scrolling

A comprehensive Elm package providing 
- **3 different animation approaches** optimized for different use cases, and  
- **4 different scrolling modules** for Document and Container scrolling.

Choose the approach that best fits your performance needs and architectural preferences.

## 🎯 Animation Approaches

This project takes the approach that an animation is an animation regardless of what techniques are used to play the animation. The animation should be able to be described in a single way, and then that description should be able to be passed off to different playback techniques. 

Therefore, all 3 approaches share a **unified fluent API** with type-safe and property-specific builders. This consistent design makes it easy to switch between approaches as your requirements evolve, while the underlying implementations are optimized for different performance characteristics.

(Stay tuned for WebGL and Canvas integration)

**Unified API Pattern:**
```elm
-- All modules follow the same builder pattern
animations
    |> CSS.builder                    -- or Sub.builder, Ports.builder
    |> Position.for "element-id" 
    |> Position.toXY 100 200
    |> Position.duration 500          -- or .speed 200
    |> Position.easing EaseInOut
    |> Position.build
    |> CSS.animate                    -- or Sub.animate, Ports.animate  
```

### 1. **Anim.Engine.CSS** - Browser-Native Transitions
**API Style:** CSS generation with hardware acceleration  
**Benefits:** Maximum performance, battery efficient, "fire and forget", multiple elements  
**Drawbacks:** No intermediate values, limited control once started  

```elm
-- Update animation state in your model  
{ model | animations = 
    model.animations
        |> CSS.builder
        |> Position.for "my-element"
        |> Position.toXY 100 200
        |> Position.speed 150           -- pixels per second
        |> Position.easing EaseInOut
        |> Position.build
        |> CSS.animate
}

-- Apply in your view with generated CSS
div 
    (CSS.htmlAttributes "my-element" model.animations)
    [ text "Hardware accelerated!" ]
```

### 2. **Anim.Engine.Sub** - Subscription-Driven Control  
**API Style:** Frame-based updates with full programmatic control  
**Benefits:** Access to current values, mid-animation changes, precise timing control  
**Drawbacks:** Requires subscription management, more CPU intensive  

```elm
-- Update animation state in your model
{ model | animations = 
    model.animations
        |> Sub.builder  
        |> Position.for "my-element"
        |> Position.toXY 100 200
        |> Position.duration 1000       -- milliseconds
        |> Position.easing BounceOut
        |> Position.build
        |> Sub.animate
}

-- Handle animation updates in your subscriptions
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions model.animations
        |> Sub.map AnimationMsg

-- Apply in your view with live position tracking  
div 
    (Sub.htmlAttributes "my-element" model.animations)
    [ text "Full control!" ]
```

### 3. **Anim.Engine.WAAPI** - Web Animations API Integration
**API Style:** JavaScript ports with maximum performance  
**Benefits:** Web Animations API access, complex sequences, timeline control  
**Drawbacks:** Requires JavaScript setup, more complex architecture  

```elm
-- Define ports for JavaScript integration
port sendAnimationCommand : Encode.Value -> Cmd msg
port positionUpdates : (Decode.Value -> msg) -> Sub msg
port animationComplete : (String -> msg) -> Sub msg

-- Update animation state with port commands
let
    (newAnimations, animationCmd) = 
        model.animations
            |> Ports.builder
            |> Position.for "my-element"  
            |> Position.toXY 100 200
            |> Position.speed 200
            |> Position.easing (Bezier 0.4 0 0.6 1)
            |> Position.build
            |> Ports.animate sendAnimationCommand
in
({ model | animations = newAnimations }
, animationCmd
)

-- Handle animation updates in subscriptions
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ positionUpdates PositionUpdateReceived
        , animationComplete AnimationComplete
        ]

-- Apply in your view with optimized transforms
div 
    (Ports.htmlAttributes "my-element" model.animations)
    [ text "Web Animations API!" ]
```


## 🎯 Scrolling Modules

All modules provide X, Y and Both axes scrolling.

### Document Scrolling


### 1. **Scroll.Document.Cmd** 
**API Style:** All functions return `Cmd msg`    
**Benefits:** Simple integration, fire-and-forget  
**Drawbacks:** No Error handling 
```elm
scrollToTop NoOp  -- returns `Cmd msg`
```

### 2. **Scroll.Document.Task**  
**API Style:** All functions return `Task Browser.Dom.Error [() | List ()]`   
**Benefits:** Composable with access to Errors   
**Drawbacks:** More complex - must handle the `Task`
```elm
scrollToTop NoOp -- returns `Task Error (List ())`
```


### Container Scrolling


### 1. **Scroll.Container.Cmd**   
**API Style:** All functions return `Cmd msg`   
**Benefits:** Simple integration, fire-and-forget  
**Drawbacks:** No Error handling  
```elm
scrollToTop "container-id" NoOp  -- returns `Cmd msg`
```

### 2. **Scroll.Container.Task**  
**API Style:** All functions return `Task Browser.Dom.Error [() | List ()]`   
**Benefits:** Composable with access to Errors   
**Drawbacks:** More complex - must handle the `Task`
```elm
scrollToTop "container-id" NoOp -- returns `Task Dom.Error (List ())`
```


## 🚀 Quick Start

### Install the package
```bash
elm install phollyer/elm-smooth-move
```

**To utilise the Web Animations API with the `Anim.Engine.WAAPI` module, you also need to install the JavaScript companion:**
```bash
npm install elm-smooth-move
```

## 📚 Explore the examples


Interactive examples are ready to run! Open `examples/index.html` to see the main dashboard, or browse the examples:

- **`ElmUI/Scroll/`**
- **`ElmUI/Sub/`**
- **`ElmUI/CSS/`**
- **`ElmUI/Ports/`**

**Option A: Direct HTML files (recommended)**
```bash
cd examples/

# Open the main examples page in your browser
open index.html 

# Or open any specific example directly
open src/ElmUI/CSS/Color/index.html
```

**Option B: Using elm reactor**
```bash
cd examples/
elm reactor
# Navigate to: http://localhost:8000/index.html
```


## 🙏 Credits

This package builds upon the excellent foundation of [`linuss/smooth-scroll`](https://package.elm-lang.org/packages/linuss/smooth-scroll/latest/). The original design and architecture provided the starting point for this expanded multi-approach animation library.

## 📄 License

BSD-3-Clause
