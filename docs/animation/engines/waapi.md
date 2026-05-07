# WAAPI Engine

This page is a practical guide to using the WAAPI engine from setup through advanced usage.
Read [Engines Overview](overview.md) when you want side-by-side comparisons and tradeoffs.

The WAAPI Engine uses the Web Animations API via Elm ports and a JavaScript companion. It combines browser-native performance with programmatic control.

## Example

3D animation - rotating cube with expanding sides.

??? example "View Example"

    --8<-- "docs/animation/concepts/3d/rotating-cube/waapi.md:example"

??? example "View Source Code"

    --8<-- "docs/animation/concepts/3d/rotating-cube/waapi.md:code"

---

## Quick Walkthrough

Get up and running in minutes.

### 1. Build

??? example "View Source Code"

    ```elm
    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Opacity as Opacity


    fadeIn : String -> WAAPI.AnimBuilder -> WAAPI.AnimBuilder
    fadeIn animGroup =
        Opacity.for animGroup
            >> Opacity.to 1
            >> Opacity.duration 300
            >> Opacity.build
    ```

### 2. Initialize

Define ports and pass them to `init`. Your module declaration must use `port module` to define ports. See [Initialize](#initialize) for full details.

??? example "View Source Code"

    ```elm
    port module Main exposing (main)

    import Json.Decode
    import Json.Encode


    type alias Model =
        { animState : WAAPI.AnimState Msg }


    port waapiCommand : Json.Encode.Value -> Cmd msg
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg


    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = WAAPI.init waapiCommand waapiEvent [ Opacity.init "card" 0 ] }
        , Cmd.none
        )
    ```

### 3. Render

Render WAAPI attributes on the animated element.

??? example "View Source Code"

    ```elm
    view : Model -> Html Msg
    view model =
        div []
            [ button [ onClick TriggerFadeIn ] [ text "Fade In" ]
            , div (WAAPI.attributes "card" model.animState) [ text "Animated card" ]
            ]
    ```

### 4. Trigger with `animate`

Call `animate` to start a state-tracked animation. See [Trigger](#trigger) for `fireAndForget` and other options.

??? example "View Source Code"

    ```elm
    TriggerFadeIn ->
        let
            ( animState, cmd ) =
                WAAPI.animate model.animState fadeIn
        in
        ( { model | animState = animState }, cmd )
    ```

### 5. React

Subscribe to events, then process messages with `update`. See [Subscriptions](#subscriptions) and [Update](#update) for full details.

??? example "View Source Code"

    ```elm
    type Msg
        = TriggerFadeIn
        | GotAnimMsg WAAPI.AnimMsg


    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotAnimMsg model.animState


    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( animState, maybeEvent ) =
                        WAAPI.update animMsg model.animState
                in
                ( { model | animState = animState }, Cmd.none )

            _ ->
                ( model, Cmd.none )
    ```

---

## In Detail

### Initialize

The WAAPI engine communicates through two ports: one outgoing (Elm → JS) and one incoming (JS → Elm). Define them in your port module, then pass them to `init` along with property initializers.

📖 See [WAAPI JavaScript](../../installation.md#waapi-javascript) for install instructions.

??? example "View Source Code"

    ```elm
    port module Main exposing (main)

    import Json.Encode

    -- Outgoing port (Elm → JS): sends all animation commands
    port waapiCommand : Json.Encode.Value -> Cmd msg

    -- Incoming port (JS → Elm): receives all animation events
    port waapiEvent : (Json.Encode.Value -> msg) -> Sub msg

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

### Trigger

The WAAPI engine offers two trigger functions: `animate` for state-tracked animations and `fireAndForget` for fire-and-forget effects.

Triggering a new `animate` animation while one is already running smoothly transitions from the current mid-flight position to the new end values.

📖 See [Interrupting Animations](../concepts/interrupting-animations.md/) for more info.

### `animate`

Use `animate` when you need state-tracked animations. The engine tracks start values, so subsequent animations always start from the last known position.

??? example "View Source Code"

    ```elm
    TriggerFadeIn ->
        let
            ( animState, cmd ) =
                WAAPI.animate model.animState fadeIn
        in
        ( { model | animState = animState }, cmd )
    ```

### `fireAndForget`

Use `fireAndForget` for one-shot effects where you don't need to pause, resume, query, or interrupt. It takes the port function directly and returns a bare `Cmd msg` with no state to store.

Because there is no state tracking, explicit `from` and `to` values are required.

??? example "View Source Code"

    ```elm
    TriggerFadeIn ->
        ( model
        , WAAPI.fireAndForget waapiCommand fadeIn
        )
    ```

!!! warning "No state, no control"
    Since `fireAndForget` bypasses `AnimState`, you can't pause, resume, stop, restart, interrupt, or query these animations. Use `animate` if you need any of those.

### Events

`update` returns a `Maybe AnimEvent` per call — `Nothing` means no event occurred this message. Some events carry additional values:

- `Cancelled` and `Paused` include the progress at the moment of cancellation/pause (`Float`, 0.0–1.0)
- `Iteration` includes the iteration count (`Int`)
- `Progress` fires every frame with the current progress (`Float`, 0.0–1.0)
- `AnimError` carries an error string from the JavaScript layer

??? example "View Source Code"

    ```elm
    handleEvent : Maybe AnimEvent -> Model -> ( Model, Cmd Msg )
    handleEvent maybeEvent model =
        case maybeEvent of
            Just (Started "box") ->
                ( model, Cmd.none )

            Just (Ended "box") ->
                ( model, Cmd.none )

            Just (AnimError err) ->
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )
    ```

### Update

Use `update` to process incoming WAAPI messages. It returns the updated `AnimState` and a `Maybe AnimEvent`.

??? example "View Source Code"

    ```elm
    GotAnimMsg animMsg ->
        let
            ( animState, maybeEvent ) =
                WAAPI.update animMsg model.animState
        in
        handleEvent maybeEvent { model | animState = animState }
    ```

### Subscriptions

The WAAPI engine requires a subscription to receive animation events from JavaScript. Without it, animations still play visually but Elm won't receive events and `AnimState` will be out of sync.

??? example "View Source Code"

    ```elm
    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions GotAnimMsg model.animState
    ```

### View

Apply `attributes` to the animated element to set its initial inline styles.

??? example "View Source Code"

    ```elm
    div (WAAPI.attributes "card" model.animState) [ text "Animated card" ]
    ```

### Playback

Set `iterations`, `loopForever`, and `alternate` in the animation builder.

??? example "View Source Code"

    ```elm
    spinForever =
        Rotate.for "icon"
            >> Rotate.toZ 360
            >> Rotate.duration 1000
            >> WAAPI.loopForever
            >> WAAPI.alternate
            >> Rotate.build
    ```

### Timing

Set `duration`, `speed`, and `delay` in the animation builder.

- `duration` — animation length in milliseconds.
- `speed` — alternative to `duration`; set a rate in property units per second.
- `delay` — wait before the animation begins, in milliseconds.

### Easing

WAAPI animations use the full Easing library with exact mathematical curves — including bounce and elastic.

📖 See [Easing](../concepts/easing.md) for all available easing functions.

### Controls

WAAPI control functions return `( AnimState msg, Cmd msg )` — the `Cmd` sends the command to JavaScript.

??? example "View Source Code"

    ```elm
    Pause ->
        let
            ( animState, cmd ) =
                WAAPI.pause "box" model.animState
        in
        ( { model | animState = animState }, cmd )

    Resume ->
        let
            ( animState, cmd ) =
                WAAPI.resume "box" model.animState
        in
        ( { model | animState = animState }, cmd )

    Stop ->
        let
            ( animState, cmd ) =
                WAAPI.stop "box" model.animState
        in
        ( { model | animState = animState }, cmd )

    Reset ->
        let
            ( animState, cmd ) =
                WAAPI.reset "box" model.animState
        in
        ( { model | animState = animState }, cmd )

    Restart ->
        let
            ( animState, cmd ) =
                WAAPI.restart "box" model.animState
        in
        ( { model | animState = animState }, cmd )
    ```

### Discrete Properties

The WAAPI engine manages discrete properties as inline styles. `discreteEntry` values are applied from the first animation frame, and `discreteExit` values flip on the last frame. No additional view setup is needed.

📖 See [Discrete Properties](../concepts/discrete-properties.md) for the full API, live examples, and source code.

### Transform Order

Use `transformOrder` to set the order in which transform properties are applied for the next animation.

??? example "View Source Code"

    ```elm
    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    animateBox =
        WAAPI.transformOrder [ Scale, Rotate, Translate ]
            >> Translate.for "box"
            >> ...
    ```

📖 See [Transform Order](../concepts/transform-order.md) for full details.

### Freeze Axes

Freeze individual axes of transform properties so they remain fixed during an animation. This is useful when animating one axis while holding another in place.

`FreezeProperty` values: `translate`, `rotate`, `scale`, `skew`.

??? example "View Source Code"

    ```elm
    -- Animate translate X, freeze Y so the element only moves horizontally
    slideRight : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
    slideRight =
        WAAPI.freezeY [ WAAPI.translate ]
            >> Translate.for "box"
            >> Translate.toX 200
            >> Translate.duration 400
            >> Translate.build
    ```

Call `unfreezeY` (or the matching `unfreeze*` variant) in a subsequent animation to release the frozen axis.

### State Queries

Query animation state at any time without waiting for events.

??? example "View Source Code"

    ```elm
    WAAPI.anyRunning model.animState           -- Maybe Bool
    WAAPI.isRunning "box" model.animState      -- Maybe Bool
    WAAPI.allComplete model.animState          -- Maybe Bool
    WAAPI.isComplete "box" model.animState     -- Maybe Bool
    WAAPI.isCancelled "box" model.animState    -- Maybe Bool
    WAAPI.getProgress "box" model.animState    -- Maybe Float (0.0–1.0)
    ```

`Nothing` is returned when no animation exists for the given group.

### Property Queries

Query the current, start, and end values for any animated property.

??? example "View Source Code"

    ```elm
    WAAPI.getOpacityStart "box" model.animState    -- Maybe Float
    WAAPI.getOpacityEnd "box" model.animState      -- Maybe Float
    WAAPI.getOpacityCurrent "box" model.animState  -- Maybe Float
    WAAPI.getTranslateCurrent "box" model.animState -- Maybe { x, y, z }
    ```

`Nothing` is returned when no animation exists for the given group.

### When to Choose This Engine

Choose WAAPI when you want browser-native playback with the broadest state-tracked feature set.

- Best for: production animations that need strong control, events, and current-value queries.
- Avoid when: you do not want JavaScript ports or companion setup.
- Prefer: [Sub](sub.md) for pure Elm frame-loop control, or timeline engines for fire-and-forget scroll-driven playback.

### API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState msg` | Tracks animations and their states |
| `AnimBuilder` | Carries all animation configurations |
| `AnimMsg` | Messages from WAAPI subscription |
| `AnimEvent` | Events returned by `update` |
| `AnimGroupName` | `String` type alias for the animation group name |
| `TransformProperty` | Custom transform ordering |
| `FreezeProperty` | Identifies a transform axis to freeze |

### Initialize

| Function | Type | Description |
| -------- | ---- | ----------- |
| `init` | `(Value -> Cmd msg) -> ((Value -> msg) -> Sub msg) -> List (AnimBuilder -> AnimBuilder) -> AnimState msg` | Create initial animation state with ports |

### Trigger

| Function | Type | Description |
| -------- | ---- | ----------- |
| `animate` | `AnimState msg -> (AnimBuilder -> AnimBuilder) -> ( AnimState msg, Cmd msg )` | Apply a state-tracked animation |
| `fireAndForget` | `(Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg` | Fire a stateless animation |

### Events

| Event | Description |
| ----- | ----------- |
| `Started AnimGroupName` | Animation begins playing |
| `Ended AnimGroupName` | Animation completes |
| `Cancelled AnimGroupName Float` | Animation cancelled; `Float` is progress at cancellation |
| `Restarted AnimGroupName` | Animation is restarted |
| `Paused AnimGroupName Float` | Animation paused; `Float` is progress at pause |
| `Resumed AnimGroupName` | Animation resumed |
| `Iteration AnimGroupName Int` | Loop iteration completes; `Int` is iteration count |
| `Progress AnimGroupName Float` | Each frame; `Float` is current progress (0.0–1.0) |
| `AnimError String` | JavaScript-layer error |

### Update

| Function | Type | Description |
| -------- | ---- | ----------- |
| `update` | `AnimMsg -> AnimState msg -> ( AnimState msg, Maybe AnimEvent )` | Process WAAPI messages |

### Subscriptions

| Function | Type | Description |
| -------- | ---- | ----------- |
| `subscriptions` | `(AnimMsg -> msg) -> AnimState msg -> Sub msg` | Subscribe to WAAPI events from JavaScript |

### View

| Function | Type | Description |
| -------- | ---- | ----------- |
| `attributes` | `AnimGroupName -> AnimState msg -> List (Html.Attribute msg)` | Get animation attributes for an element |

### Playback

| Function | Type | Description |
| -------- | ---- | ----------- |
| `iterations` | `Int -> AnimBuilder -> AnimBuilder` | Set number of iterations |
| `loopForever` | `AnimBuilder -> AnimBuilder` | Loop animation infinitely |
| `alternate` | `AnimBuilder -> AnimBuilder` | Reverse direction on each iteration |

### Timing

| Function | Type | Description |
| -------- | ---- | ----------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set speed (property units/sec) |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set delay before animation starts (ms) |

### Easing

| Function | Type | Description |
| -------- | ---- | ----------- |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set easing function |

### Controls

| Function | Type | Description |
| -------- | ---- | ----------- |
| `pause` | `AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )` | Freeze at current position |
| `resume` | `AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )` | Continue from paused position |
| `stop` | `AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )` | Jump to end state and stop |
| `reset` | `AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )` | Jump to start state and stop |
| `restart` | `AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )` | Reset and begin playing again |

### Discrete Properties

| Function | Type | Description |
| -------- | ---- | ----------- |
| `discreteEntry` | `String -> String -> AnimBuilder -> AnimBuilder` | Set a CSS property value when the animation starts |
| `discreteExit` | `String -> String -> String -> AnimBuilder -> AnimBuilder` | Set a CSS property value during and after the animation |

### Transform Order

| Function | Type | Description |
| -------- | ---- | ----------- |
| `transformOrder` | `List TransformProperty -> AnimBuilder -> AnimBuilder` | Set custom transform order |

### Freeze Axes

| Function | Type | Description |
| -------- | ---- | ----------- |
| `translate` | `FreezeProperty` | Target translate for freezing |
| `rotate` | `FreezeProperty` | Target rotate for freezing |
| `scale` | `FreezeProperty` | Target scale for freezing |
| `skew` | `FreezeProperty` | Target skew for freezing |
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

| Function | Type | Description |
| -------- | ---- | ----------- |
| `anyRunning` | `AnimState msg -> Maybe Bool` | Check if any animation is running |
| `isRunning` | `AnimGroupName -> AnimState msg -> Maybe Bool` | Check if a specific group is animating |
| `allComplete` | `AnimState msg -> Maybe Bool` | Check if all animations are complete |
| `isComplete` | `AnimGroupName -> AnimState msg -> Maybe Bool` | Check if a specific group's animation is complete |
| `isCancelled` | `AnimGroupName -> AnimState msg -> Maybe Bool` | Check if a specific group's animation was cancelled |
| `getProgress` | `AnimGroupName -> AnimState msg -> Maybe Float` | Get current progress (0.0–1.0) |

### Property Queries

| Function | Type | Description |
| -------- | ---- | ----------- |
| `getOpacityStart` | `AnimGroupName -> AnimState msg -> Maybe Float` | Get start opacity |
| `getOpacityEnd` | `AnimGroupName -> AnimState msg -> Maybe Float` | Get end opacity |
| `getOpacityCurrent` | `AnimGroupName -> AnimState msg -> Maybe Float` | Get current opacity |
| `getTranslateStart` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get start translate |
| `getTranslateEnd` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get end translate |
| `getTranslateCurrent` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get current translate |
| `getRotateStart` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get start rotate |
| `getRotateEnd` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get end rotate |
| `getRotateCurrent` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get current rotate |
| `getScaleStart` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get start scale |
| `getScaleEnd` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get end scale |
| `getScaleCurrent` | `AnimGroupName -> AnimState msg -> Maybe { x, y, z }` | Get current scale |
| `getSizeStart` | `AnimGroupName -> AnimState msg -> Maybe { width, height }` | Get start size |
| `getSizeEnd` | `AnimGroupName -> AnimState msg -> Maybe { width, height }` | Get end size |
| `getSizeCurrent` | `AnimGroupName -> AnimState msg -> Maybe { width, height }` | Get current size |
| `getSkewStart` | `AnimGroupName -> AnimState msg -> Maybe { x, y }` | Get start skew |
| `getSkewEnd` | `AnimGroupName -> AnimState msg -> Maybe { x, y }` | Get end skew |
| `getSkewCurrent` | `AnimGroupName -> AnimState msg -> Maybe { x, y }` | Get current skew |
| `getPropertyStart` | `AnimGroupName -> String -> AnimState msg -> Maybe Float` | Get start value for a custom numeric property |
| `getPropertyEnd` | `AnimGroupName -> String -> AnimState msg -> Maybe Float` | Get end value for a custom numeric property |
| `getPropertyCurrent` | `AnimGroupName -> String -> AnimState msg -> Maybe Float` | Get current value for a custom numeric property |
| `getColorPropertyStart` | `AnimGroupName -> String -> AnimState msg -> Maybe Color` | Get start value for a custom color property |
| `getColorPropertyEnd` | `AnimGroupName -> String -> AnimState msg -> Maybe Color` | Get end value for a custom color property |
| `getColorPropertyCurrent` | `AnimGroupName -> String -> AnimState msg -> Maybe Color` | Get current value for a custom color property |

`Nothing` is returned when no animation exists for the given group.

For complete API details, see the [Anim.Engine.WAAPI](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-WAAPI) documentation.

### Next Steps

Explore the related timeline engines:

[Scroll Timeline Engine](scroll-timeline.md){ .md-button .md-button--primary }
Or
[View Timeline Engine](view-timeline.md){ .md-button .md-button--primary }

Or review migration paths and tradeoffs.

[Migration Guide →](migration-guide.md){ .md-button .md-button--primary }
