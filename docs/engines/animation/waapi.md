# WAAPI Engine

This page focuses on what makes this Engine different, read [Engines Overview](overview.md) for features that are shared across all Engines.

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

Or using a script tag (CDN, no bundler required):

??? example "View Source Code"

    ```html
    <script src="https://unpkg.com/elm-animate-waapi/dist/elm-animate-waapi.js"></script>
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

<iframe src="../../../examples/src/Engines/WAAPI/HelloText/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm"
    ```

## Initialize

WAAPI's `init` requires the port functions as parameters:

??? example "View Source Code"

    ```elm
    init : ( Model, Cmd Msg )
    init =
        ( { animState =
                WAAPI.init waapiCommand waapiEvent
                    [ Opacity.init "fadeAnim" 0
                    , Translate.initXY "slideAnim" 100 50
                    ]
          }
        , Cmd.none
        )
    ```


## Trigger

The WAPPI engine has a `fireAndForget` function as well as `animate` to trigger animations.

The difference between the two is that `fireAndForget` is stateless.

If you want an animation to run without tracking its state — a one-shot effect where you don't need to pause, resume, query progress, or interrupt it later. WAAPI offers this via `fireAndForget`:

??? example "View Source Code"

    ```elm
    port waapiCommand : Encode.Value -> Cmd msg

    update msg model =
        case msg of
            FlashNotification ->
                ( model
                , WAAPI.fireAndForget waapiCommand flashAnim
                )
    ```

Unlike `animate`, `fireAndForget` takes the port function directly instead of `AnimState` — it doesn't need one. It returns a bare `Cmd msg` with no state to store.

This is useful for:

- **Decorative effects** — ripples, flashes, pulses that don't affect application logic
- **Notifications** — brief visual feedback that runs once and is done
- **Keeping your model lean** — no `AnimState` needed for throwaway animations

!!! warning "No state, no control"
    Since `fireAndForget` bypasses `AnimState`, you can't pause, resume, stop, restart, interrupt, or query these animations. If you need any of those, use `animate` instead.


## Subscriptions

The WAAPI Engine requires a subscription to receive animation events from JavaScript:

??? example "View Source Code"

    ```elm
    type Msg
        = GotAnimMsg WAAPI.AnimMsg
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotAnimMsg model.animState
    ```

Without this subscription, animations will still play visually in the browser, but Elm won't receive events — so your `AnimState` will be out of sync with what's actually happening on screen.

## Update

Handle animation messages in your update function. The `update` function returns the new state, and the corresponding event:

??? example "View Source Code"

    ```elm
    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( animState, event ) =
                        WAAPI.update animMsg model.animState
                in
                handleEvent event { model | animState = animState }

            ...
    ```

## Events

| Event | Fires when... |
| ----- | ------------- |
| `Started` | The animation begins playing |
| `Ended` | The animation completes (after all iterations) |
| `Cancelled` | The animation is stopped, reset, or interrupted |
| `Paused` | `pause` is called |
| `Resumed` | `resume` is called |
| `Restarted` | `restart` is called |
| `Iteration` | Each loop cycle completes (carries iteration count) |
| `Progress` | Each animation frame, with current progress (0.0 to 1.0) |

??? example "View Source Code"

    ```elm
    handleEvent : WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleEvent event model =
        case event of
            WAAPI.Started _ _ ->
                ( model, Cmd.none )

            WAAPI.Ended _ _ ->
                ( model, Cmd.none )

            WAAPI.Cancelled _ _ { progress } ->
                ( model, Cmd.none )

            WAAPI.Paused _ _ { progress } ->
                ( model, Cmd.none )

            WAAPI.Resumed _ _ ->
                ( model, Cmd.none )

            WAAPI.Restarted _ _ ->
                ( model, Cmd.none )

            WAAPI.Iteration _ _ iterationCount ->
                ( model, Cmd.none )

            WAAPI.Progress _ _ { progress } ->
                ( { model | progressBar = progress }, Cmd.none )
    ```


## Interrupting Animations

Start a new animation at any time — the WAAPI Engine handles smooth transitions from the current position.

📖 See [Interrupting Animations](../../concepts/interruptions.md/) for more info.

## Freezing Axes

When interrupting an animation, you may want to hold certain axes at their current animated values while animating others. Use `freeze` functions to lock specific axes:

??? example "View Source Code"

    ```elm
    -- Freeze the X axis of translate, then animate only Y
    WAAPI.animate model.animState <|
        WAAPI.freezeX [ WAAPI.translate ]
            >> Translate.for "move"
            >> Translate.toY 200
            >> Translate.build
    ```

    Available freeze functions: `freezeX`, `freezeY`, `freezeZ`, `freezeXY`, `freezeXZ`, `freezeYZ`, `freezeXYZ`.

    Each takes a list of properties to freeze: `WAAPI.translate`, `WAAPI.rotate`, `WAAPI.scale`.

    Corresponding unfreeze functions (`unfreezeX`, `unfreezeY`, etc.) release previously frozen axes.

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

## Property Queries

This Engine supports querying start, end and current values, with all the functions following the same pattern:

`get[Property][Position] : AnimGroupName -> AnimState msg -> Maybe [value]`

where:

- `Property` is the property name: `Opacity`, `Scale`, etc
- `Position` is the property value to query: `Start`, `End`, `Current`
- `value` is a property-specific value

When no animation exists, `Nothing` is returned.

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `getOpacityStart` | `AnimGroupName -> AnimState msg -> Maybe Float` | Get start opacity |
| `getOpacityEnd` | `AnimGroupName -> AnimState msg -> Maybe Float` | Get end opacity |
| `getOpacityCurrent` | `AnimGroupName -> AnimState msg -> Maybe Float` | Get current opacity |
| `getRotateStart` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get start rotate value |
| `getRotateEnd` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get end rotate value |
| `getRotateCurrent` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get current rotate value |
| `get*Start` | `AnimGroupName -> AnimState msg -> Maybe *` | Get start value |
| `get*End` | `AnimGroupName -> AnimState msg -> Maybe *` | Get end value |
| `get*Current` | `AnimGroupName -> AnimState msg -> Maybe *` | Get current value |

## Composite Keys

The WAAPI Engine provides the option of using Composite Keys instead of simple animation group names to group and manipulate property animations.

A Composite Key is of the format: `"elementId:animGroup"`, and enables running **multiple independent animation groups on the same element**, giving you granular control over each one.

### Creating

It is created by the Engine when `forElement` is used to group animations by `elementId`:

??? example "View Source Code"

    ```elm
    WAAPI.animate model.animState <|
        WAAPI.forElement "box"
            >> Translate.for "position"
            >> Translate.toX 500
            >> Translate.duration 5000
            >> Translate.build
            >> Opacity.for "fade"
            >> Opacity.to 0
            >> Opacity.duration 5000
            >> Opacity.build
    ```

    This creates two independent animation groups on the same element: `"box:position"` and `"box:fade"`.

### Matching

Composite Keys follow these rules:

- `"box"` or `"box:*"` will match all animations created for the element with an `id` of `box`
- `"box:fade"` will only match the `"fade"` animation created for the `"box"` element
- `"fade"` will only match a `"fade"` animation that has **not been created** in a `forElement` pipeline, there will only ever be one - this is the default behaviour of all Engines
- `"*:fade"` is not supported

### Using

You use key matching to render, control and query animations.

#### Render

??? example "View Source Code"

    ```elm
    -- Render all animations defined for the "box" element
    WAAPI.attributes "box" model.animState

    -- Or for explicitness
    WAAPI.attributes "box:*" model.animState 

    -- Render only the fade animation defined for the "box" element
    WAAPI.attributes "box:fade" model.animState

    -- Render a generic fade animation not defined for a specific element
    WAAPI.attributes "fade" model.animState
    ```

#### Control

??? example "View Source Code"

    ```elm
    -- Stop all animations defined for the "box" element
    WAAPI.stop "box" model.animState

    -- Or for explicitness
    WAAPI.stop "box:*" model.animState 

    -- Pause only the fade animation defined for the "box" element
    WAAPI.pause "box:fade" model.animState

    -- Reset a generic fade animation not defined for a specific element
    WAAPI.reset "fade" model.animState
    ```

#### Query

??? example "View Source Code"

    ```elm
    -- Check if all animations for "box" are complete
    WAAPI.isComplete "box" model.animState

    -- Or for explicitness
    WAAPI.isComplete "box:*" model.animState

    -- Check if a specific animation group is running
    WAAPI.isRunning "box:fade" model.animState

    -- Get the current opacity from the "box:fade" animation
    WAAPI.getOpacityCurrent "box:fade" model.animState

    -- Get the current translate from all "box" animations
    WAAPI.getTranslateCurrent "box" model.animState

    -- Query a generic fade animation not defined for a specific element
    WAAPI.isComplete "fade" model.animState
    ```

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState msg` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animation configurations |
| `AnimMsg` | Messages from WAAPI subscription |
| `AnimEvent` | Events returned by `update` (Started, Ended, etc.) |
| `TransformOrder` | Custom transform ordering (Translate, Rotate, Scale) |
| `FreezeProperty` | Identifies a property that can be frozen (translate, rotate, scale) |

### Core Functions

| Function | Type | Description |
| -------- | ---- | ----------- |
| `init` | `(Value -> Cmd msg) -> ((Value -> msg) -> Sub msg) -> List (AnimBuilder -> AnimBuilder) -> AnimState msg` | Create initial animation state with ports |
| `animate` | `AnimState msg -> (AnimBuilder -> AnimBuilder) -> ( AnimState msg, Cmd msg )` | Execute animation with state tracking |
| `fireAndForget` | `(Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg` | Execute animation without state tracking |
| `transformOrder` | `List TransformOrder -> AnimState msg -> AnimState msg` | Set custom transform order for future animations |
| `update` | `AnimMsg -> AnimState msg -> ( AnimState msg, Maybe AnimEvent )` | Process WAAPI messages and maybe return event |
| `subscriptions` | `(AnimMsg -> msg) -> AnimState msg -> Sub msg` | Subscribe to WAAPI events from JavaScript |

### View Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `attributes` | `AnimGroupName -> AnimState msg -> List (Html.Attribute msg)` | Get animation attributes for an element. Accepts composite key or element ID. |

### Independent Animation Groups

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `forElement` | `String -> AnimBuilder -> AnimBuilder` | Group animations by element for independent control via composite keys |

### Event Types

| Event | Fires when... |
| ----- | ------------- |
| `Started` | The animation begins playing |
| `Ended` | The animation completes (after all iterations) |
| `Cancelled` | The animation is stopped, reset, or interrupted |
| `Paused` | `pause` is called |
| `Resumed` | `resume` is called |
| `Restarted` | `restart` is called |
| `Iteration` | Each loop cycle completes |
| `Progress` | Each animation frame, with current progress (0.0 to 1.0) |

### Defaults

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (property units/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing function |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

### Playback

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `iterations` | `Int -> AnimBuilder -> AnimBuilder` | Set number of iterations |
| `loopForever` | `AnimBuilder -> AnimBuilder` | Loop animation infinitely |
| `alternate` | `AnimBuilder -> AnimBuilder` | Reverse direction on each iteration |

### Controls

All control functions accept either a composite key (`"elementId:groupName"`) or a plain element ID.

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `pause` | `AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )` | Freeze at current position |
| `resume` | `AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )` | Continue from paused position |
| `stop` | `AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )` | Jump to end state and stop |
| `reset` | `AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )` | Jump to start state and stop |
| `restart` | `AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )` | Reset and begin playing again |

### Freeze Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `translate` | `FreezeProperty` | Target translate for freezing |
| `rotate` | `FreezeProperty` | Target rotate for freezing |
| `scale` | `FreezeProperty` | Target scale for freezing |
| `freezeX` | `List FreezeProperty -> AnimBuilder -> AnimBuilder` | Freeze X axis of specified properties |
| `freezeY` | `List FreezeProperty -> AnimBuilder -> AnimBuilder` | Freeze Y axis |
| `freezeZ` | `List FreezeProperty -> AnimBuilder -> AnimBuilder` | Freeze Z axis |
| `freezeXY` | `List FreezeProperty -> AnimBuilder -> AnimBuilder` | Freeze X and Y axes |
| `freezeXZ` | `List FreezeProperty -> AnimBuilder -> AnimBuilder` | Freeze X and Z axes |
| `freezeYZ` | `List FreezeProperty -> AnimBuilder -> AnimBuilder` | Freeze Y and Z axes |
| `freezeXYZ` | `List FreezeProperty -> AnimBuilder -> AnimBuilder` | Freeze all axes |
| `unfreezeX` | `List FreezeProperty -> AnimBuilder -> AnimBuilder` | Unfreeze X axis |
| `unfreezeY` | `List FreezeProperty -> AnimBuilder -> AnimBuilder` | Unfreeze Y axis |
| `unfreezeZ` | `List FreezeProperty -> AnimBuilder -> AnimBuilder` | Unfreeze Z axis |
| `unfreezeXY` | `List FreezeProperty -> AnimBuilder -> AnimBuilder` | Unfreeze X and Y axes |
| `unfreezeXZ` | `List FreezeProperty -> AnimBuilder -> AnimBuilder` | Unfreeze X and Z axes |
| `unfreezeYZ` | `List FreezeProperty -> AnimBuilder -> AnimBuilder` | Unfreeze Y and Z axes |
| `unfreezeXYZ` | `List FreezeProperty -> AnimBuilder -> AnimBuilder` | Unfreeze all axes |

### State Queries

All query functions accept either a composite key or a plain element ID.

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `anyRunning` | `AnimState msg -> Maybe Bool` | Check if any animations are running |
| `isRunning` | `AnimGroupName -> AnimState msg -> Maybe Bool` | Check if a specific element is animating |
| `allComplete` | `AnimState msg -> Maybe Bool` | Check if all animations are complete |
| `isComplete` | `AnimGroupName -> AnimState msg -> Maybe Bool` | Check if a specific element's animation is complete |

### Property Queries

All property query functions accept either a composite key or a plain element ID.

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `getTranslateStart` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get start translate value |
| `getTranslateEnd` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get end translate value |
| `getTranslateCurrent` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get current translate value |
| `getRotateStart` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get start rotate value |
| `getRotateEnd` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get end rotate value |
| `getRotateCurrent` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get current rotate value |
| `get*Start` | (similar for Scale, Opacity, Size, BackgroundColor) | Get start value |
| `get*End` | (similar for Scale, Opacity, Size, BackgroundColor) | Get end value |
| `get*Current` | (similar for Scale, Opacity, Size, BackgroundColor) | Get current value |

For complete API details, see the [Anim.Engine.WAAPI](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-WAAPI) documentation.

## Next Steps

The Scroll Engines which provide smooth scrolling animations for the Document or containers.

[Scroll Engines →](../scroll/overview.md){ .md-button .md-button--primary }
