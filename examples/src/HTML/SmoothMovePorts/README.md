# SmoothMovePorts Integration Guide

SmoothMovePorts provides high-performance animations using the Web Animations API through Elm ports. This approach offers the best of both worlds: type-safe Elm code with native JavaScript performance.

## Features

✅ **Web Animations API** - Hardware acceleration when available  
✅ **Type-safe ports** - Clean integration between Elm and JavaScript  
✅ **High performance** - Native browser optimization  
✅ **Consistent API** - Same interface as other SmoothMove modules  
✅ **Custom easing** - Access to CSS easing functions and cubic-bezier curves

## Quick Start

### 1. Include the JavaScript file

```html
<script src="smooth-move-ports.js"></script>
```

### 2. Define ports in your Elm application

```elm
port module YourApp exposing (main)

import Json.Decode as Decode
import SmoothMovePorts

-- Required ports
port animateElement : String -> Cmd msg
port stopElementAnimation : String -> Cmd msg  
port positionUpdates : (Decode.Value -> msg) -> Sub msg
```

### 3. Initialize the JavaScript integration

```javascript
const app = Elm.YourApp.init({ node: document.getElementById('app') });
SmoothMovePorts.init(app.ports);
```

### 4. Use in your Elm code

```elm
type Msg
    = MoveElement
    | PositionUpdate Decode.Value

update msg model =
    case msg of
        MoveElement ->
            let
                ( newAnimations, command ) =
                    SmoothMovePorts.animateTo "my-element" 200 300 model.animations
            in
            ( { model | animations = newAnimations }
            , animateElement (SmoothMovePorts.encodeAnimationCommand command)
            )

        PositionUpdate value ->
            case Decode.decodeValue positionDecoder value of
                Ok posUpdate ->
                    let
                        newAnimations =
                            SmoothMovePorts.handlePositionUpdate
                                posUpdate.elementId
                                posUpdate.x
                                posUpdate.y  
                                posUpdate.isAnimating
                                model.animations
                    in
                    ( { model | animations = newAnimations }, Cmd.none )
```

### 5. Add element IDs to your HTML

```elm
div 
    [ Html.Attributes.id "my-element"  -- IMPORTANT: JavaScript needs this ID
    , style "transform" (SmoothMovePorts.transformElement "my-element" model.animations)
    ] 
    [ text "Animated element" ]
```

## Advanced Usage

### Custom Easing Functions

```javascript
// Add custom easing after initialization
SmoothMovePorts.addEasingFunction('bounce', 'cubic-bezier(0.68, -0.55, 0.265, 1.55)');
SmoothMovePorts.addEasingFunction('elastic', 'cubic-bezier(0.175, 0.885, 0.32, 1.275)');
```

```elm
-- Use in Elm configuration
bouncyConfig = 
    { axis = SmoothMovePorts.Both
    , duration = 800
    , easing = "bounce"  -- Custom easing function
    }
```

### Error Handling

The JavaScript code includes console warnings for missing elements and unsupported browsers:

```javascript
// Check initialization success
if (SmoothMovePorts.init(app.ports)) {
    console.log('SmoothMovePorts ready!');
} else {
    console.error('Failed to initialize SmoothMovePorts');
}
```

## API Reference

### Elm Functions

Same as other SmoothMove modules:

- `animateTo : String -> Float -> Float -> Model -> ( Model, AnimationCommand )`
- `stopAnimation : String -> Model -> ( Model, Maybe String )`
- `getPosition : String -> Model -> Maybe { x : Float, y : Float }`
- `isAnimating : Model -> Bool`
- `transformElement : String -> Model -> String`

### Helper Functions

- `encodeAnimationCommand : AnimationCommand -> String` - Convert command to string for port
- `handlePositionUpdate : String -> Float -> Float -> Bool -> Model -> Model` - Handle JS updates

### JavaScript API

- `SmoothMovePorts.init(ports)` - Initialize with Elm ports
- `SmoothMovePorts.addEasingFunction(name, cssValue)` - Add custom easing
- `SmoothMovePorts.getCurrentPosition(element)` - Get element position
- `SmoothMovePorts.stopAnimation(elementId)` - Stop specific animation

## Browser Support

- **Modern browsers**: Full Web Animations API support
- **Older browsers**: Consider including a [Web Animations API polyfill](https://github.com/web-animations/web-animations-js)

## Performance Comparison

| Approach | CPU Usage | Smoothness | Hardware Acceleration |
|----------|-----------|------------|----------------------|
| SmoothMoveSub/State | Higher | Good | No |
| SmoothMoveCSS | Lower | Very Good | Yes (CSS) |
| **SmoothMovePorts** | **Lowest** | **Excellent** | **Yes (Web API)** |

SmoothMovePorts offers the best performance by leveraging the browser's native Web Animations API while maintaining full control through Elm ports.