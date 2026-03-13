# WAAPI Engine

!!! info "Prerequisites"
    This page assumes you've completed [Getting Started](../getting-started/installation.md) and are familiar with [animation concepts](../concepts/controlling-animations.md) like the builder pattern, AnimState, and property initializers.

    It focuses on what makes this Engine different, read [Engines Overview](overview.md) for how to use the features that are shared across all Engines.

The WAAPI Engine uses the Web Animations API via Elm ports and a JavaScript companion. It combines browser-native performance with programmatic control.

## Setup

### 1. Install the JavaScript package

=== "npm"
    ```bash
    npm install elm-animate-waapi
    ```

=== "yarn"
    ```bash
    yarn add elm-animate-waapi
    ```

### 2. Initialize in JavaScript

??? example "View Source Code"

    ```javascript
    import ElmAnimateWAAPI from 'elm-animate-waapi';

    const app = Elm.Main.init({
        node: document.getElementById('app')
    });

    ElmAnimateWAAPI.init(app.ports);
    ```

Or using a script tag (legacy/no-bundler):

??? example "View Source Code"

    ```html
    <script src="node_modules/elm-animate-waapi/dist/elm-animate-waapi.js"></script>
    <script>
        const app = Elm.Main.init({
            node: document.getElementById('app')
        });

        ElmAnimateWAAPI.init(app.ports);
    </script>
    ```

### 3. Define ports in Elm

The WAAPI engine uses just two ports - one for outgoing commands and one for incoming events:

??? example "View Source Code"

    ```elm
    port module Main exposing (main)

    import Json.Encode


    -- Outgoing port (Elm → JS): sends all animation commands
    port waapiCommand : Json.Encode.Value -> Cmd msg


    -- Incoming port (JS → Elm): receives all animation events
    port waapiEvent : (Json.Encode.Value -> msg) -> Sub msg
    ```

## Basic Usage

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/WAAPI/HelloText/index.html){ .md-button target="_blank" }

## Targeting Elements

WAAPI sends animation commands to JavaScript which targets DOM elements directly.
Therefore, the Engine needs to know which element id to apply which animations to.

Use `forElement` to specify the element id:

??? example "View Source Code"

    ```elm
    WAAPI.animate model.animState <|
        WAAPI.forElement "header"  -- Target the DOM element with id="header"
            >> fadeIn
    ```

    Target multiple elements

    ```elm
    WAAPI.animate model.animState <|
        WAAPI.forElement "header"  -- Target the DOM element with id="header"
            >> fadeIn
            >> slideDown
            >> WAAPI.forElement "sidebar" -- Next, target the sidebar element
            >> fadeIn
            >> slideRight
    ```

    The header will `fadeIn` and `slideDown`; the sidebar will `fadeIn` and `slideRight`.

Don't do this:

??? example "View Source Code"

    ```elm
    fadeIn =
        WAAPI.forElement "header"
            >> Opacity.for "fadeAnim"
            >> Opacity.to 1
            >> Opacity.duration 500
            >> Opacity.build

    WAAPI.animate model.animState fadeIn
    ```

    !!! tip "It works"
        If you include `forElement` in an animation configuration and pass it to the CSS or Sub engines, they simply ignore it.

    **But** after a refactor or two, it will likely result in something like this:

    ```elm
    fadeIn elementId =
        WAAPI.forElement elementId
            >> Opacity.for "entranceAnim"
            >> Opacity.to 1
            >> Opacity.duration 500
            >> Opacity.build

    slideIn elementId =
        WAAPI.forElement elementId
            >> Translate.for "entranceAnim"
            >> Translate.toX 0
            >> Translate.duration 500
            >> Translate.build

    WAAPI.animate model.animState <|
        fadeIn "box" >> slideIn "box"
    ```

    !!! warning "It works, but..."
        Now your animation configuration is no longer so easily portable between Engines.

        Now, whenever these animation configurations are consumed, they will need an element id - something which is completely irrelevant to all the other engines.

    WAAPI is the only Engine that cares about element id's, so probably best to keep it in the family:

    ```elm
    WAAPI.animate model.animState <|
        WAAPI.forElement "sidebar"
            >> fadeIn
            >> slideIn
    ```

## Composite Keys and Animation Groups

WAAPI tracks animations using **composite keys** that combine the element ID with the group name. This enables multiple independent animation groups per element.

### Why Use Animation Groups?

Animation groups give you **granular control** over independent animations on the same element:

- **Pause one, continue others** - Pause position animation while fade keeps going
- **Independent state queries** - Check if just the position animation is complete
- **Selective restart** - Restart only the fade animation without affecting position

??? example "View Source Code"

    ```elm
    -- Setup: two animation groups with different timings
    startAnimations : AnimState msg -> ( AnimState msg, Cmd msg )
    startAnimations state =
        WAAPI.animate state <|
            WAAPI.forElement "box"
                >> Translate.for "position"
                >> Translate.toX 500
                >> Translate.duration 5000  -- 5 seconds
                >> Translate.build
                >> Opacity.for "fade"
                >> Opacity.to 0
                >> Opacity.duration 5000    -- 5 seconds
                >> Opacity.build

    -- Pause only position - fade continues!
    pausePosition : AnimState msg -> ( AnimState msg, Cmd msg )
    pausePosition state =
        WAAPI.pause "box:position" state

    -- Resume position
    resumePosition : AnimState msg -> ( AnimState msg, Cmd msg )
    resumePosition state =
        WAAPI.resume "box:position" state

    -- Or pause everything at once
    pauseAll : AnimState msg -> ( AnimState msg, Cmd msg )
    pauseAll state =
        WAAPI.pause "box" state

    -- Query just the position group
    isPositionDone : AnimState msg -> Maybe Bool
    isPositionDone state =
        WAAPI.isComplete "box:position" state
    ```

Without separate groups, pausing would affect all properties at once. Groups let you control each animation stream independently.

### How Composite Keys Work

When you animate an element:

??? example "View Source Code"

    ```elm
    WAAPI.animate model.animState <|
        WAAPI.forElement "box"
            >> Opacity.for "fadeGroup"
            >> Opacity.to 1
            >> Opacity.duration 500
            >> Opacity.build
    ```

The animation is stored internally with the composite key `"box:fadeGroup"`.

### Multiple Animation Groups

You can have multiple independent animation groups on the same element:

??? example "View Source Code"

    ```elm
    WAAPI.animate model.animState <|
        WAAPI.forElement "box"
            >> Opacity.for "fadeGroup" -- First animation group
            >> Opacity.to 1
            >> Opacity.build
            >> Translate.for "moveGroup" -- Second animation group
            >> Translate.toX 100
            >> Translate.build
    ```

These create two independent animations: `"box:fadeGroup"` for opacity and `"box:moveGroup"` for translation.

### Using Composite Keys in Control Functions

Control and query functions accept either format:

??? example "View Source Code"

    **Element ID** - affects all animation groups for that element:

    ```elm
    -- Pause ALL animations on "box"
    WAAPI.pause "box" model.animState
    ```

    **Composite key** - affects only that specific group:

    ```elm
    -- Pause only the fade animation
    WAAPI.pause "box:fadeGroup" model.animState
    ```

### Using Composite Keys with `attributes`

The `attributes` function also accepts both formats:

??? example "View Source Code"

    **Element ID** - merges states from all animation groups:

    ```elm
    div
        (WAAPI.attributes "box" model.animState ++ [ id "box" ])
        [ text "Box" ]
    ```

    **Composite key** - applies only that group's state:

    ```elm
    div
        (WAAPI.attributes "box:fadeGroup" model.animState ++ [ id "box" ])
        [ text "Box (fade only)" ]
    ```

## Interrupting Animations

Start a new animation at any time — the WAAPI Engine handles smooth transitions:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/WAAPI/InterruptingAnimations/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/WAAPI/InterruptingAnimations/index.html){ .md-button target="_blank" }

The new animation starts from the current position, not the original start position.

## True Mid-Flight Values

Unlike CSS-based engines, the "current" getters return the actual animated value at any point during the animation:

??? example "View Source Code"

    ```elm
    view model =
        let
            positionText =
                case WAAPI.getTranslateCurrent "box" model.animState of
                    Just { x, y, z } ->
                        "Position: " ++ String.fromFloat x ++ ", " ++ String.fromFloat y

                    Nothing ->
                        "No translate animation"
        in
        div [] [ text positionText ]
    ```

Available getters: `getTranslateCurrent`, `getScaleCurrent`, `getRotateCurrent`, `getOpacityCurrent`, `getSizeCurrent`, `getBackgroundColorCurrent`.

## Animation Control

WAAPI control functions return both a new `AnimState` and a `Cmd` that sends commands to JavaScript:

??? example "View Source Code"

    ```elm
    update msg model =
        case msg of
            Pause ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.pause "box" model.animState
                in
                ( { model | animState = newAnimState }, cmd )

            Resume ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.resume "box" model.animState
                in
                ( { model | animState = newAnimState }, cmd )

            Stop ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.stop "box" model.animState
                in
                ( { model | animState = newAnimState }, cmd )

            Reset ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.reset "box" model.animState
                in
                ( { model | animState = newAnimState }, cmd )

            Restart ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.restart "box" model.animState
                in
                ( { model | animState = newAnimState }, cmd )
    ```

## Progress Tracking

The WAAPI engine sends `Changed` events during animation, letting you track real-time progress:

??? example "View Source Code"

    ```elm
    reactToEvent : WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
    reactToEvent event model =
        case event of
            WAAPI.Changed _ _ { progress } ->
                ( { model | progressBar = progress }, Cmd.none )

            WAAPI.Ended _ _ ->
                ( { model | progressBar = 1.0 }, Cmd.none )

            _ ->
                ( model, Cmd.none )
    ```

## Initializing

WAAPI's `init` requires the port functions as parameters:

??? example "View Source Code"

    ```elm
    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = WAAPI.init waapiCommand waapiEvent [] }
        , Cmd.none
        )
    ```

    With initial values (note the use of `forElement`):

    ```elm
    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState =
                WAAPI.init waapiCommand waapiEvent
                    [ WAAPI.forElement "box"
                        >> Opacity.init "fadeAnim" 0
                        >> Translate.initXY "slideAnim" 100 50
                    ]
          }
        , Cmd.none
        )
    ```

## Onload Animations

To animate elements immediately on page load:

1. Initialize properties to their starting values in `init`
2. Trigger the animation directly from `init`

```elm
init : () -> ( Model, Cmd Msg )
init _ =
    let
        animState =
            WAAPI.init waapiCommand waapiEvent
                [ WAAPI.forElement "box"
                    >> Opacity.init "fadeAnim" 0
                ]
        
        ( newAnimState, cmd ) =
            WAAPI.animate animState <|
                WAAPI.forElement "box"
                    >> fadeIn
    in
    ( { animState = newAnimState }, cmd )
```

The `attributes` function renders the initial state (opacity: 0) as inline styles on first render, so there's no flash. The animation command is processed after the first render, starting the animation smoothly from the initial state.

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState msg` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animation configurations |
| `AnimMsg` | Opaque message type for WAAPI subscription events |
| `AnimEvent` | Lifecycle events: `Started String String`, `Ended String String`, `Paused String String`, `Resumed String String`, `Cancelled String String`, `Restarted String String` |

### Core Functions

| Function | Type | Description |
| -------- | ---- | ----------- |
| `init` | `(Value -> Cmd msg) -> ((Value -> msg) -> Sub msg) -> List (AnimBuilder -> AnimBuilder) -> AnimState msg` | Create initial animation state with ports and optional property initializers. |
| `animate` | `AnimState msg -> (AnimBuilder -> AnimBuilder) -> ( AnimState msg, Cmd msg )` | Execute animation with state tracking |
| `fireAndForget` | `(Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg` | Execute animation without state tracking |
| `transformOrder` | `List TransformOrder -> AnimState msg -> AnimState msg` | Set custom transform order for future animations |
| `update` | `AnimMsg -> AnimState msg -> ( AnimState msg, Maybe AnimEvent )` | Process WAAPI messages and maybe return event |
| `subscriptions` | `(AnimMsg -> msg) -> AnimState msg -> Sub msg` | Subscribe to WAAPI events from JavaScript |

### View Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `attributes` | `AnimGroupName -> AnimState msg -> List (Html.Attribute msg)` | Apply initial animation state as inline styles. Accepts composite key or element ID. When given element ID, merges all animation groups for that element. |

### Control Functions

All control functions accept either a composite key (`"elementId:groupName"`) to target a specific animation group, or a plain element ID to target all animation groups for that element.

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `pause` | `AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )` | Pause animation |
| `resume` | `AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )` | Resume paused animation |
| `stop` | `AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )` | Jump to end state |
| `reset` | `AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )` | Return to start state |
| `restart` | `AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )` | Replay from beginning |
| `onResize` | `List { elementId, elementSize, oldContainerSize, newContainerSize } -> AnimState msg -> ( AnimState msg, Cmd msg )` | Handle container resize |

### State Query Functions

All query functions accept either a composite key (`"elementId:groupName"`) or a plain element ID. When given element ID, functions check/merge all animation groups for that element.

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `anyRunning` | `AnimState msg -> Maybe Bool` | Check if any animations are running |
| `isRunning` | `AnimGroupName -> AnimState msg -> Maybe Bool` | Check if a specific element is animating |
| `allComplete` | `AnimState msg -> Maybe Bool` | Check if all animations are complete |
| `isComplete` | `AnimGroupName -> AnimState msg -> Maybe Bool` | Check if a specific element's animation is complete |

### Property Query Functions

All property query functions accept either a composite key (`"elementId:groupName"`) or a plain element ID. When given element ID, returns the merged value from all animation groups for that element.

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `getTranslateStart` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get start translate value |
| `getTranslateEnd` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get end translate value |
| `getTranslateCurrent` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get current translate value |
| `get*Start` | (similar for Scale, Rotate, Opacity, Size, BackgroundColor) | Get start value |
| `get*End` | (similar for Scale, Rotate, Opacity, Size, BackgroundColor) | Get end value |
| `get*Current` | (similar for Scale, Rotate, Opacity, Size, BackgroundColor) | Get current value |

### Default Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (property units/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing function |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

For complete API details, see the [Anim.Engine.WAAPI](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-WAAPI) documentation.

## Next Steps

The Scroll Engine which provides smooth scrolling animations for the Document or containers.

[Scroll Engine →](scroll.md){ .md-button .md-button--primary }
