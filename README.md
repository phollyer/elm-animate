# Smooth Animations And Scrolling

A comprehensive Elm package providing **3 different animation modules** for smooth animations, and
**4 different scrolling modules** for Document and Container scrolling. 
Choose the approach that best fits your performance needs and use case.

> **Credits**: This package builds upon the excellent foundation of [`linuss/smooth-scroll`](https://package.elm-lang.org/packages/linuss/smooth-scroll/latest/) by expanding it into a multi-approach animation and scrolling library.

## 🎯 Animation Modules

All 3 modules provide virtually identical API's, it is the underlying implementations that differ. This is deliberate so that it becomes fairly easy to swap one out for another, should your requirements change.


### 1. **Anim.CSS** - Transition-Based
**API Style:** Model-based state with CSS generation, browser handles animation  
**Benefits:** "Fire and forget", hardware acceleration, multiple elements, battery efficient  
**Drawbacks:** No access to intermediate values, limited control once started  
```elm
-- Update the position in your model
{ model | animations = CSS.animateTo "my-element" 100 200 model.animations }

-- Apply in your view  
div 
    [ style "transform" (CSS.transformElement "my-element" model.animations)
    , style "transition" (CSS.transition CSS.defaultConfig) 
    ] 
    [ text "Smooth!" ]
```
### 2. **Anim.Sub** - Subscription-Based  
**API Style:** Subscription-driven with model state  
**Benefits:** Full programmatic control, access to current positions, mid-animation changes  
**Drawbacks:** Requires subscription management, more complex setup  
```elm
-- Update the position in your model
{ model | animations = Sub.animateTo "my-element" 100 200 model.animations }

-- Apply in your view
div 
    [ style "transform" (Sub.transformElement "my-element" model.animations) ] 
    [ text "Smooth!" ]

```

### 3. **Anim.Ports** - Web Animations API
**API Style:** JavaScript integration with ports  
**Benefits:** Maximum performance, complex animation sequences, Web Animations API access  
**Drawbacks:** Requires JavaScript setup, more complex architecture  

```elm
-- Update the position in your model
let
    ( animations, cmd ) = 
        Ports.animateTo "my-element" 100 200 model.animations
in 
({ model | animations = animations }
, cmd
)

-- Apply in your view
div 
    [ style "transform" (Ports.transformElement "my-element" model.animations) ] 
    [ text "Smooth!" ]
```


## 🎯 Scrolling Modules

### Container


### 1. **Scroll.Container.Cmd** - Container Scrolling  
**API Style:** Simple `Cmd msg`   
**Benefits:** Simple integration, X, Y and Both axes scrolling   
**Drawbacks:** Limited to scrolling operations only, no Error handling  
```elm
scrollCmd NoOp "target-element-id"  -- returns `Cmd msg`
scrollTask "target-element-id" -- returns `Task Dom.Error (List ())`
```

### 2. **Scroll.Container.Task** - Container Scrolling  
**API Style:** Simple `Cmd msg`   
**Benefits:** Simple integration, X, Y and Both axes scrolling   
**Drawbacks:** Limited to scrolling operations only, no Error handling  
```elm
scrollCmd NoOp "target-element-id"  -- returns `Cmd msg`
scrollTask "target-element-id" -- returns `Task Dom.Error (List ())`
```

### Document


### 1. **Container.Cmd** - Container Scrolling  
**API Style:** Simple `Cmd msg`   
**Benefits:** Simple integration, X, Y and Both axes scrolling   
**Drawbacks:** Limited to scrolling operations only, no Error handling  
```elm
scrollCmd NoOp "target-element-id"  -- returns `Cmd msg`
scrollTask "target-element-id" -- returns `Task Dom.Error (List ())`
```

### 2. **Container.Task** - Container Scrolling  
**API Style:** Simple `Cmd msg`   
**Benefits:** Simple integration, X, Y and Both axes scrolling   
**Drawbacks:** Limited to scrolling operations only, no Error handling  
```elm
scrollCmd NoOp "target-element-id"  -- returns `Cmd msg`
scrollTask "target-element-id" -- returns `Task Dom.Error (List ())`
```

###  need own Bed
:

## 🚀 Quick Start

### 1. Install the package
```bash
elm install phollyer/elm-smooth-move
```

**For SmoothMovePorts (Web Animations API), also install the JavaScript companion:**
```bash
npm install elm-smooth-move
```

### 2. Choose your module

**For page scrolling:**  
```elm
import SmoothMoveScroll exposing (scrollCmd)

-- In your update function (simple!)
SmoothScroll elementId ->
    ( model, scrollCmd NoOp elementId )
```

**For moving UI elements (CSS approach - simplest):**
```elm
import SmoothMoveCSS

-- In your model 
type alias Model = 
    { -- Handle element positions yourself
      element1 : SmoothMoveCSS.Position

    -- Or, use SmoothMoveCSS.Model for all your elements
    , smoothMove : SmoothMoveCSS.Model
    , ... 
    }

-- In your init
init = 
    { -- initialize the element's starting position
      element1 = SmoothMoveCSS.Position 50 50   

    -- Or, initialize SmoothMoveCSS 
    , smoothMove = 
        SmoothMoveCSS.init
            -- initialize the starting positions for your elements
            |> SmoothMoveCSS.setPosition "element-2" 100 100
            |> SmoothMoveCSS.setPosition "element-3" 200 200
            |> SmoothMoveCSS.setPosition "element-4" 300 300
     
    , ...
    }

-- In your update function (just update position(s)!)
AnimateElement ->
    { model 
    | element1 = SmoothMoveCSS.Position 100 100
    , smoothMove = 
        model.smoothMove
            |> SmoothMoveCSS.animateTo "element-1" 200 300  
            |> SmoothMoveCSS.animateTo "element-2" 300 600
            |> SmoothMoveCSS.animateTo "element-3" 100 900
    }

-- In your view (browser handles animation)
-- User manages position
div 
  [ style "transform" <|
        SmoothMoveCSS.transform model.element1.x model.element1.y
  , style "transition" <|
        SmoothMoveCSS.transition SmoothMoveCSS.defaultConfig
  ] 
  [ text "Animated element 1" ]

-- SmoothMoveCSS manages position
div 
  [ style "transform" <|
        SmoothMoveCSS.transformElement "element-2" model.smoothMove
  , style "transition" <|
        SmoothMoveCSS.transition SmoothMoveCSS.defaultConfig
  ] 
  [ text "Animated element 2" ]
```

**For moving UI elements (subscription approach):**
```elm
import SmoothMoveSub

-- In your model
type alias Model = 
    { smoothMove : SmoothMoveSub.Model
    , ... 
    }

-- In your init
init = 
    { smoothMove =
        SmoothMoveSub.init
            -- initialize the starting positions for one or more elements
            |> SmoothMoveSub.setPosition "element-1" 100 100
            |> SmoothMoveSub.setPosition "element-2" 200 200
            |> SmoothMoveSub.setPosition "element-3" 300 300
    }

-- In your update  
AnimateElement ->
    { model 
    | smoothMove = 
        model.smoothMove
            -- move one or more elements
            |> SmoothMoveSub.animateTo "element-1" 200 300 
            |> SmoothMoveSub.animateTo "element-2" 300 500
    }

AnimationFrame deltaMs ->
    { model | smoothMove = SmoothMoveSub.step deltaMs model.smoothMove }

-- Don't forget subscriptions!
subscriptions model = SmoothMoveSub.subscriptions AnimationFrame model.smoothMove
```

### 3. Explore the examples

Interactive examples are ready to run! Open `examples/index.html` to see the main dashboard, or browse the examples:

- **`ElmUI/Scroll/`**
- **`ElmUI/Sub/`**
- **`ElmUI/CSS/`**
- **`ElmUI/Ports/`**
- **`HTML/SmoothMoveScroll/`**
- **`HTML/SmoothMoveSub/`**
- **`HTML/SmoothMoveCSS/`**
- **`HTML/SmoothMovePorts/`**

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
# Navigate to: http://localhost:8000/index.html
```

## ⚙️ Configuration & Migration

### Switching Between Approaches
The modules share similar configuration patterns, making migration straightforward:

```elm
-- All modules support similar config options
{ defaultConfig | timing = Duration 400, easing = Ease.outCubic, axis = Both }
```

**Easy migrations:**
- **Scrolling**: `SmoothMoveScroll.scrollCmd NoOp elementId` 
- **CSS**: Update `{ model | position = { x = 100, y = 200 } }` in model
- **Subscription**: `SmoothMoveSub.animateTo "elem" 100 200 model.animations`

**Requires setup:**
- **SmoothMovePorts**: Returns `( Model, Cmd )` + JavaScript setup required

### Common Configuration Options
```elm
-- SmoothMoveScroll, SmoothMoveSub, SmoothMovePorts
{ defaultConfig 
    | timing = Speed 400        -- or Duration 300 (milliseconds)
    | easing = Ease.outCubic   -- Animation curve (Elm easing functions)
    | axis = Both              -- X, Y, or Both (movement constraint)
}

-- SmoothMoveCSS (simpler - no axis constraint needed)
{ defaultConfig 
    | timing = Duration 400     -- Duration in milliseconds
    | easing = "ease-out"       -- CSS easing function
}
```

## 🔧 Troubleshooting

**Animation not starting?**
- Verify element IDs exist in DOM
- Check subscriptions are wired (`SmoothMoveSub` only)
- Ensure `position: relative/absolute` for transforms

**Performance issues?**  
- Try `SmoothMoveCSS` first (hardware accelerated)
- Use `axis` constraints (`X` or `Y` only)  

**SmoothMovePorts setup:**
```bash
npm install elm-smooth-move
```
Include `SmoothMovePorts.init(app.ports)` in JavaScript.

## �🙏 Credits

This package builds upon the excellent foundation of [`linuss/smooth-scroll`](https://package.elm-lang.org/packages/linuss/smooth-scroll/latest/). The original design and architecture provided the inspiration for this expanded multi-approach animation library.

## 📄 License

BSD-3-Clause
