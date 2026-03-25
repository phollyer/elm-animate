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

<iframe src="../../examples/src/Engines/WAAPI/HelloText/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm"
    ```

## Initializing

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

Your animations will not run without this subscription.

## Update

Handle animation messages in your update function. The `update` function returns the new state, and the corresponding event:

??? example "View Source Code"

    ```elm
    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( newAnimState, maybeEvent ) =
                        WAAPI.update animMsg model.animState
                in
                handleEvent event { model | animState = newAnimState }

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

📖 See [Interrupting Animations](../concepts/interruptions.md/) for more info.

## Targeting Elements

Like the other engines, WAAPI uses a `data-anim-target` attribute (set by the `attributes` function) for the JavaScript companion to locate DOM elements. When you use a plain animation group name, the group name itself serves as the target identifier — just like every other engine:

??? example "View Source Code"

    ```elm
    WAAPI.animate model.animState <|
        Opacity.for "header"
            >> Opacity.to 1
            >> Opacity.build

    -- In the view, the attributes function sets data-anim-target="header"
    div (WAAPI.attributes "header" model.animState) [ text "Header" ]
    ```

### Composite Keys with `forElement`

When you need **multiple independent animation groups on the same element**, use `forElement` to opt into composite keys. This combines the element ID with the group name (e.g., `"box:fadeGroup"`), enabling granular control over each group:

- **Pause one, continue others** — pause position animation while fade keeps going
- **Independent state queries** — check if just the position animation is complete
- **Selective restart** — restart only the fade animation without affecting position

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

    -- Pause only position — fade continues
    WAAPI.pause "box:position" state

    -- Or pause everything on that element
    WAAPI.pause "box" state
    ```

You can also target multiple elements in a single `animate` call:

??? example "View Source Code"

    ```elm
    WAAPI.animate model.animState <|
        WAAPI.forElement "header"
            >> fadeIn
            >> slideDown
            >> WAAPI.forElement "sidebar"
            >> fadeIn
            >> slideRight
    ```

    The header will `fadeIn` and `slideDown`; the sidebar will `fadeIn` and `slideRight`.

### How Composite Keys Work

When you use `forElement "box"` with a group name `"fadeGroup"`, the animation is stored with the composite key `"box:fadeGroup"`.

Control and query functions accept either format:

- **Element ID** (`"box"`) — affects all animation groups for that element
- **Composite key** (`"box:fadeGroup"`) — affects only that specific group

The `attributes` function also accepts both formats. When given a plain element ID, it merges states from all animation groups.

!!! tip "Keep `forElement` at the call site"
    `forElement` is only relevant to WAAPI — other engines ignore it. Keep it in your `animate` calls rather than baking it into reusable animation configs to keep your configs portable across engines.

## Property Queries

The WAAPI engine supports querying start, end, and **current** values. Unlike CSS-based engines, the "current" getters return the actual animated value at any point during the animation — true mid-flight values.

All property query functions follow the same pattern:

`get[Property][Position] : AnimGroupName -> AnimState msg -> Maybe [value]`

where:

- `Property` is the property name: `Opacity`, `Scale`, etc
- `Position` is the property value to query: `Start`, `End`, `Current`
- `value` is a property-specific value

When no animation exists, `Nothing` is returned.

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

## Freezing Axes

When interrupting an animation, you may want to hold certain axes at their current animated values while animating others. Use `freeze` functions to lock specific axes:

??? example "View Source Code"

    ```elm
    -- Freeze the X axis of translate, then animate only Y
    WAAPI.animate model.animState <|
        WAAPI.freezeX [ WAAPI.translate ]
            >> WAAPI.forElement "box"
            >> Translate.for "move"
            >> Translate.toY 200
            >> Translate.build
    ```

    Available freeze functions: `freezeX`, `freezeY`, `freezeZ`, `freezeXY`, `freezeXZ`, `freezeYZ`, `freezeXYZ`.

    Each takes a list of properties to freeze: `WAAPI.translate`, `WAAPI.rotate`, `WAAPI.scale`.

    Corresponding unfreeze functions (`unfreezeX`, `unfreezeY`, etc.) release previously frozen axes.

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

## Fire and Forget

Sometimes you want an animation to run without tracking its state — a one-shot effect where you don't need to pause, resume, query progress, or interrupt it later. WAAPI is the only engine that offers this via `fireAndForget`:

??? example "View Source Code"

    ```elm
    port waapiCommand : Encode.Value -> Cmd msg

    update msg model =
        case msg of
            FlashNotification ->
                ( model
                , WAAPI.fireAndForget waapiCommand <|
                    WAAPI.forElement "notification"
                        >> Opacity.for "flash"
                        >> Opacity.to 1
                        >> Opacity.duration 300
                        >> Opacity.easing EaseOut
                        >> Opacity.build
                )
    ```

Unlike `animate`, `fireAndForget` takes the port function directly instead of `AnimState` — it doesn't need one. It returns a bare `Cmd msg` with no state to store.

This is useful for:

- **Decorative effects** — ripples, flashes, pulses that don't affect application logic
- **Notifications** — brief visual feedback that runs once and is done
- **Keeping your model lean** — no `AnimState` needed for throwaway animations

!!! warning "No state, no control"
    Since `fireAndForget` bypasses `AnimState`, you can't pause, resume, stop, restart, interrupt, or query these animations. If you need any of those, use `animate` instead.

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

### Element Targeting

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `forElement` | `String -> AnimBuilder -> AnimBuilder` | Opt into composite keys by setting a target element ID |

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

The Scroll Engine which provides smooth scrolling animations for the Document or containers.

[Scroll Engine →](scroll.md){ .md-button .md-button--primary }
