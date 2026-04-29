# Scroll Sub Engine

This page focuses on what makes this engine different, read [Scroll Engines Overview](overview.md) for features that are shared across all Scroll engines.

The Scroll Sub Engine uses Elm subscriptions to update scroll state on every frame. This provides full programmatic control over scroll animations, including mid-scroll queries, events, and interruption controls.


## Live Example

<iframe src="../../../examples/src/Engines/Scroll/Sub/FirstScroll/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Full Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/Sub/FirstScroll/Main.elm"
    ```

📖 See [Your First Scrolls](../first-scrolls.md) for a step-by-step breakdown.


## Usage

### 1. Initialize

Store the `ScrollState` in your model and initialize it with `Scroll.init`:

??? example "View Source Code"

    ```elm
    import Scroll.Engine.Sub as Scroll
    import Scroll.Builder as ScrollTo
    import Easing exposing (Easing(..))

    type alias Model =
        { scrollState : Scroll.ScrollState }

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { scrollState = Scroll.init }, Cmd.none )
    ```

### 2. Subscribe

Wire up subscriptions so the engine receives animation frame updates:

??? example "View Source Code"

    ```elm
    subscriptions : Model -> Sub Msg
    subscriptions model =
        Scroll.subscriptions ScrollMsg model.scrollState
    ```

The subscription only activates while a scroll animation is running — it does nothing when idle.

### 3. Trigger

Call `scroll` from your `update` function. It returns the updated `ScrollState` and a `Cmd`:

??? example "View Source Code"

    ```elm
    type Msg
        = ScrollTo String
        | ScrollMsg Scroll.ScrollMsg

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollTo targetId ->
                let
                    ( newState, cmd ) =
                        Scroll.scroll ScrollMsg model.scrollState <|
                            ScrollTo.forContainer "scroll-container"
                                >> ScrollTo.toElement targetId
                                >> ScrollTo.easing BounceOut
                                >> ScrollTo.build
                in
                ( { model | scrollState = newState }, cmd )
    ```

### 4. Update

Handle the engine's internal messages to advance the animation each frame:

??? example "View Source Code"

    ```elm
            ScrollMsg scrollMsg ->
                let
                    ( newState, events, cmd ) =
                        Scroll.update ScrollMsg scrollMsg model.scrollState
                in
                ( { model | scrollState = newState }, cmd )
    ```

The `events` list lets you react to scroll lifecycle — see [Events](#events) below.


## Events

The `update` function returns a list of `ScrollEvent`s. Each event carries a `Container` identifying the scroll surface:

| Event | When It Fires |
| ----- | ------------- |
| `Started` | Scroll animation begins |
| `Ended` | Scroll reaches its target |
| `Progress` | Every frame during scrolling |
| `Stopped` | Scroll was stopped programmatically |
| `Paused` | Scroll was paused |
| `Resumed` | Scroll was resumed after pause |
| `Restarted` | Scroll was restarted |

??? example "View Source Code"

    ```elm
            ScrollMsg scrollMsg ->
                let
                    ( newState, events, cmd ) =
                        Scroll.update ScrollMsg scrollMsg model.scrollState

                    isEnded event =
                        case event of
                            Scroll.Ended _ ->
                                True

                            _ ->
                                False
                in
                ( { model
                    | scrollState = newState
                    , status =
                        if List.any isEnded events then
                            "Scroll complete!"

                        else
                            model.status
                  }
                , cmd
                )
    ```

### ScrollEvent Reference

| Event | Payload | Description |
| ----- | ------- | ----------- |
| `Started` | `Container` | The scroll has begun. Payload is `Document` or `Container "element-id"`. |
| `Ended` | `Container` | The scroll completed naturally. Payload is `Document` or `Container "element-id"`. |
| `Stopped` | `Container` | The scroll was stopped before completion. Payload is `Document` or `Container "element-id"`. |
| `Restarted` | `Container` | The scroll was restarted from the beginning. Payload is `Document` or `Container "element-id"`. |
| `Paused` | `Container` | The scroll was paused. Payload is `Document` or `Container "element-id"`. |
| `Resumed` | `Container` | The scroll was resumed after a pause. Payload is `Document` or `Container "element-id"`. |
| `Progress` | `Container`, `{ x : Float, y : Float }`, `Float` | Live scroll position update. Payloads are the scroll surface, the current scroll coordinates, and overall progress from `0.0` to `1.0`. |

### Tracking Live Progress

The `Progress` event makes it straightforward to build position indicators, scrollbars, or percentage readouts:

??? example "View Source Code"

    ```elm
    handleEvent event model =
        { model
            | status =
                case event of
                    Scroll.Progress _ position progress ->
                        -- position.x and position.y are the current scroll coordinates
                        -- progress goes from 0.0 to 1.0
                        ShowingProgress position <|
                            round (progress * 100)

                    _ ->
                        model.status
        }
    ```


## Controls

Control scroll animations at any time by passing a `Container` value.

| Function | Behavior |
| -------- | -------- |
| `stop` | Jump instantly to the scroll **target position** and complete |
| `pause` | Freeze the scroll at its current position |
| `resume` | Continue a paused scroll from where it was frozen |
| `reset` | Jump instantly to the **start position** and stop |
| `restart` | Reset to start position, then begin scrolling again |

**Stop/Reset/Restart** return `( ScrollState, Cmd msg )` because they issue immediate scroll commands:

??? example "View Source Code"

    ```elm
            StopScroll ->
                let
                    ( newState, cmd ) =
                        Scroll.stop Scroll.Document ScrollMsg model.scrollState
                in
                ( { model | scrollState = newState }, cmd )
    ```

**Pause/Resume** return just `ScrollState` — no commands needed:

??? example "View Source Code"

    ```elm
            PauseScroll ->
                ( { model | scrollState = Scroll.pause (Scroll.Container "sidebar") model.scrollState }, Cmd.none )

            ResumeScroll ->
                ( { model | scrollState = Scroll.resume (Scroll.Container "sidebar") model.scrollState }, Cmd.none )
    ```

📖 See [Controlling Scroll Animations](../concepts/controlling-scroll.md) for live examples and complete code patterns.


## Querying State

Query scroll animation state and position during execution:

??? example "View Source Code"

    ```elm
    -- Is any scroll animation running?
    Scroll.anyRunning model.scrollState  -- Maybe Bool

    -- Is a specific container's scroll running?
    Scroll.isRunning Scroll.Document model.scrollState  -- Maybe Bool

    -- Get current scroll position
    Scroll.getPosition Scroll.Document model.scrollState  -- Maybe { x : Float, y : Float }

    -- Get individual axis positions
    Scroll.getPositionX Scroll.Document model.scrollState  -- Maybe Float
    Scroll.getPositionY Scroll.Document model.scrollState  -- Maybe Float
    ```

All query functions return `Maybe` — `Nothing` means no animation exists for that container.


## Under The Hood

??? info "How Subscription-based Animation Works"

    **Single scroll target:**

    1. DOM queries retrieve current scroll position and target element position
    2. Distance is calculated from current to target position
    3. Animation state is initialized with scroll configuration
    4. `AnimState` is updated with animation data
    5. Initial `Cmd` is returned to query DOM positions
    6. `subscriptions` listen for animation frame updates
    7. Each frame: calculates new position using delta-time and easing, then scrolls
    8. Animation continues until progress reaches 1.0

    **Multiple scroll targets:**

    - Each scroll independently goes through steps 1-7 above
    - All scroll animations are tracked in the same `AnimState`
    - `subscriptions` handle all animations simultaneously
    - All scroll animations run concurrently
    - Each animation can be queried independently during execution
    - Animations complete independently as they reach their targets

    **State management:**

    - Returns updated `AnimState` that must be stored in your model
    - Requires `subscriptions` to be active for animation to progress
    - Enables real-time queries during animation (position, duration, status)
    - Allows intervention and reaction to ongoing animations


## API Quick Reference

| Function / Type | Type | Description |
| ---------- | ------ | ------------- |
| `ScrollState` | type alias | Scroll animation state for your model |
| `ScrollMsg` | type alias | Internal message type |
| `ScrollEvent` | type | `Started`, `Ended`, `Progress`, `Stopped`, `Paused`, `Resumed`, `Restarted` |
| `Container` | type | `Document` or `Container "element-id"` |
| `init` | `ScrollState` | Create initial state |
| `scroll` | `(ScrollMsg -> msg) -> ScrollState -> (ScrollBuilder -> ScrollBuilder) -> ( ScrollState, Cmd msg )` | Trigger stateful scroll |
| `update` | `(ScrollMsg -> msg) -> ScrollMsg -> ScrollState -> ( ScrollState, List ScrollEvent, Cmd msg )` | Handle scroll messages |
| `subscriptions` | `(ScrollMsg -> msg) -> ScrollState -> Sub msg` | Animation frame subscription |
| `duration` | `Int -> ScrollBuilder -> ScrollBuilder` | Set default duration (ms) |
| `speed` | `Float -> ScrollBuilder -> ScrollBuilder` | Set default speed (px/sec) |
| `easing` | `Easing -> ScrollBuilder -> ScrollBuilder` | Set default easing |
| `delay` | `Int -> ScrollBuilder -> ScrollBuilder` | Set default delay (ms) |
| `stop` | `Container -> (ScrollMsg -> msg) -> ScrollState -> ( ScrollState, Cmd msg )` | Jump to target position |
| `pause` | `Container -> ScrollState -> ScrollState` | Freeze at current position |
| `resume` | `Container -> ScrollState -> ScrollState` | Continue paused scroll |
| `reset` | `Container -> (ScrollMsg -> msg) -> ScrollState -> ( ScrollState, Cmd msg )` | Jump to start position |
| `restart` | `Container -> (ScrollMsg -> msg) -> ScrollState -> ( ScrollState, Cmd msg )` | Reset and replay |
| `anyRunning` | `ScrollState -> Maybe Bool` | Check if any scrolls are running |
| `isRunning` | `Container -> ScrollState -> Maybe Bool` | Check specific container |
| `getPosition` | `Container -> ScrollState -> Maybe { x : Float, y : Float }` | Current scroll position |
| `getPositionX` | `Container -> ScrollState -> Maybe Float` | Current X position |
| `getPositionY` | `Container -> ScrollState -> Maybe Float` | Current Y position |

For complete API details, see the [Scroll.Engine.Sub](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Scroll-Sub) documentation.

## Next Steps

Now that you've learnt about the Scroll Engines, learn about interrupting your scrolls mid-flight.

[Interrupting Scrolls →](../concepts/interrupting-scrolls.md){ .md-button .md-button--primary }
