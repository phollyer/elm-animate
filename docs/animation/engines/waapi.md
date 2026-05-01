# WAAPI Engine

This page focuses on what makes this Engine different, read [Engines Overview](overview.md) for features that are shared across all Engines.

The WAAPI Engine uses the Web Animations API via Elm ports and a JavaScript companion. It combines browser-native performance with programmatic control.

## Setup

### Simplest - CDN, no bundler

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


### NPM

=== "npm"
    ```bash
    npm install elm-animate-waapi
    ```

=== "yarn"
    ```bash
    yarn add elm-animate-waapi
    ```

??? example "View Source Code"

    ```javascript
    import ElmAnimateWAAPI from 'elm-animate-waapi';

    const app = Elm.Main.init({
        node: document.getElementById('app')
    });

    ElmAnimateWAAPI.init(app.ports);
    ```


### Define ports in Elm

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

### `animate`

Use `animate` when you need state-tracked animations. Even if you don't need to control the
animation mid-flight, this is useful because the Engine will manage the start values of your
animations. So all you need to do is direct the animation where to go, not where to start from.
This in turn makes your animations more portable and reusable.

??? example "View Source Code"

    ```elm
    fadeIn : String -> AnimBuilder -> AnimBuilder
    fadeIn animGroupName =
        Opacity.for animGroupName
            >> Opacity.to 1
            >> Opacity.duration 800
            >> Opacity.build

    update msg model =
        case msg of
            TriggerFadeIn ->
                let
                    (animState, cmd) =
                        WAAPI.animate model.animState fadeIn
                in
                ( { model | animState = animState }
                , cmd
                )
    ```
    The animation only needs a `to` value, the Engine tracks current state so subsequent animations
    will always start from the current value.


### `fireAndForget`

If you want an animation to run without tracking its state — a one-shot effect where you don't need to pause, resume, query progress, or interrupt it later. WAAPI offers this via `fireAndForget`.

Unlike `animate`, `fireAndForget` takes the port function directly instead of `AnimState` — it doesn't need it. It returns a bare `Cmd msg` with no state to store.

??? example "View Source Code"

    ```elm
    port waapiCommand : Encode.Value -> Cmd msg

    fadeIn : String -> AnimBuilder -> AnimBuilder
    fadeIn animGroupName =
        Opacity.for animGroupName
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.duration 800
            >> Opacity.build

    update msg model =
        case msg of
            TriggerFadeIn ->
                ( model
                , WAAPI.fireAndForget waapiCommand fadeIn
                )
    ```
    The animation requires explicit `from` and `to` values as there's no state-tracking, so this
    animation will always go from fully transparent to fully opaque. 

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

## Interrupting Animations

Start a new animation at any time — the WAAPI Engine handles smooth transitions from the current position.

📖 See [Interrupting Animations](../concepts/interrupting-animations.md/) for more info.

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

## Discrete Properties

The WAAPI engine manages discrete properties as inline styles. `discreteEntry` values are applied from the first animation frame, and `discreteExit` values flip on the last frame. No additional view setup is needed.

📖 See [Discrete Properties](../concepts/discrete-properties.md) for the full API, live examples, and source code.

## Related Engines

The JavaScript companion also powers two fire-and-forget engines that use the browser's scroll-driven animation APIs — no `AnimState`, `update`, or `subscriptions` required:

- [Scroll Timeline Engine](scroll-timeline.md) — ties animation progress to the scroll position of a container
- [View Timeline Engine](view-timeline.md) — ties animation progress to an element's position within the viewport

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState msg` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animation configurations |
| `AnimMsg` | Messages from WAAPI subscription |
| `AnimEvent` | Events returned by `update` (Started, Ended, etc.) |
| `AnimGroup` | `String` type alias representing the animation group name |
| `TransformProperty` | Custom transform ordering (Translate, Rotate, Scale) |
| `FreezeProperty` | Identifies a property that can be frozen (translate, rotate, scale) |

### Initialize

| Function | Type | Description |
| -------- | ---- | ----------- |
| `init` | `(Value -> Cmd msg) -> ((Value -> msg) -> Sub msg) -> List (AnimBuilder -> AnimBuilder) -> AnimState msg` | Create initial animation state with ports |

### Trigger

| Function | Type | Description |
| -------- | ---- | ----------- |
| `animate` | `AnimState msg -> (AnimBuilder -> AnimBuilder) -> ( AnimState msg, Cmd msg )` | Execute animation with state tracking |
| `fireAndForget` | `(Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg` | Execute animation without state tracking |

### Update

| Function | Type | Description |
| -------- | ---- | ----------- |
| `update` | `AnimMsg -> AnimState msg -> ( AnimState msg, Maybe AnimEvent )` | Process WAAPI messages and maybe return event |
| `subscriptions` | `(AnimMsg -> msg) -> AnimState msg -> Sub msg` | Subscribe to WAAPI events from JavaScript |


### View

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `attributes` | `AnimGroup -> AnimState msg -> List (Html.Attribute msg)` | Get animation attributes for an element |

### Events

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
| `transformOrder` | `List TransformProperty -> AnimBuilder -> AnimBuilder` | Set custom transform order for future animations |

### Playback

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `iterations` | `Int -> AnimBuilder -> AnimBuilder` | Set number of iterations |
| `loopForever` | `AnimBuilder -> AnimBuilder` | Loop animation infinitely |
| `alternate` | `AnimBuilder -> AnimBuilder` | Reverse direction on each iteration |

### Controls

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `pause` | `AnimGroup -> AnimState msg -> ( AnimState msg, Cmd msg )` | Freeze at current position |
| `resume` | `AnimGroup -> AnimState msg -> ( AnimState msg, Cmd msg )` | Continue from paused position |
| `stop` | `AnimGroup -> AnimState msg -> ( AnimState msg, Cmd msg )` | Jump to end state and stop |
| `reset` | `AnimGroup -> AnimState msg -> ( AnimState msg, Cmd msg )` | Jump to start state and stop |
| `restart` | `AnimGroup -> AnimState msg -> ( AnimState msg, Cmd msg )` | Reset and begin playing again |


### Discrete Properties

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `discreteEntry` | `String -> String -> AnimBuilder -> AnimBuilder` | Set a CSS property value when the animation starts |
| `discreteExit` | `String -> String -> String -> AnimBuilder -> AnimBuilder` | Set a CSS property value during and after the animation |

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

All query functions accept an animation group name.

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `anyRunning` | `AnimState msg -> Maybe Bool` | Check if any animations are running |
| `isRunning` | `AnimGroup -> AnimState msg -> Maybe Bool` | Check if a specific element is animating |
| `allComplete` | `AnimState msg -> Maybe Bool` | Check if all animations are complete |
| `isComplete` | `AnimGroup -> AnimState msg -> Maybe Bool` | Check if a specific element's animation is complete |
| `getProgress` | `AnimGroup -> AnimState msg -> Maybe Float` | Get current progress (0.0 to 1.0) |

If no animation exisits `Nothing` is returned.

### Property Queries

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `getOpacityStart` | `AnimGroup -> AnimState -> Maybe Float` | Get start opacity |
| `getOpacityEnd` | `AnimGroup -> AnimState -> Maybe Float` | Get end opacity |
| `getOpacityCurrent` | `AnimGroup -> AnimState -> Maybe Float` | Get current opacity |
| `get*Start` | `AnimGroup -> AnimState -> Maybe *` | Get start * value |
| `get*End` | `AnimGroup -> AnimState -> Maybe *` | Get end * value |
| `get*Current` | `AnimGroup -> AnimState -> Maybe *` | Get current * value |

If no animation exisits `Nothing` is returned.

For complete API details, see the [Anim.Engine.WAAPI](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-WAAPI) documentation.

## Next Steps

Explore more WAAPI engines:

[Scroll Timeline Engine](scroll-timeline.md){ .md-button .md-button--primary }
Or
[View Timeline Engine](view-timeline.md){ .md-button .md-button--primary }

Or review migration paths and tradeoffs.

[Migration Guide →](migration-guide.md){ .md-button .md-button--primary }
