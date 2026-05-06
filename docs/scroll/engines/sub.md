# Scroll Sub Engine

This page is a practical guide to using the Sub engine from setup through production patterns.
Read [Scroll Engines Overview](overview.md) when you want side-by-side comparisons and tradeoffs.

The Scroll Sub Engine uses Elm subscriptions to update scroll state on every frame. This provides full programmatic control over scroll animations, including mid-scroll queries, events, and interruption controls.


## Example

??? example "View Example"

    <iframe src="../../../examples/src/Scroll/Sub/FirstScroll/index.html" style="width: 100%; height: 460px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Full Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Sub/FirstScroll/Main.elm"
    ```

📖 See [Your First Scrolls](../first-scrolls.md) for a step-by-step breakdown.


## Quick Walkthrough

Get up and running in minutes.

### 1. Initialize

Store the `ScrollState` in your model and initialize it with `Sub.init`:

??? example "View Source Code"

    ```elm
    import Scroll.Engine.Sub as Sub

    type alias Model =
        { scrollState : Sub.ScrollState }

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { scrollState = Sub.init }, Cmd.none )
    ```

### 2. Subscribe

Wire up subscriptions so the engine receives animation frame updates:

??? example "View Source Code"

    ```elm
    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions ScrollMsg model.scrollState
    ```

The subscription only activates while a scroll animation is running — it does nothing when idle.

### 3. Trigger

Call `scroll` from your `update` function. It returns the updated `ScrollState` and a `Cmd`:

??? example "View Source Code"

    ```elm
    import Scroll.Builder as Scroll
    import Easing exposing (Easing(..))

    type Msg
        = ScrollTo String
        | ScrollMsg Sub.ScrollMsg

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollTo targetId ->
                let
                    ( newState, cmd ) =
                        Sub.scroll ScrollMsg model.scrollState <|
                            Scroll.forContainer "scroll-container"
                                >> Scroll.toElement targetId
                                >> Scroll.easing BounceOut
                                >> Scroll.speed 400
                                >> Scroll.build
                in
                ( { model | scrollState = newState }, cmd )
    ```

Sub-driven scrolls advance on each animation frame, so configured speed and duration are applied consistently.

### 4. Update

Handle the engine's internal messages to advance the animation each frame:

??? example "View Source Code"

    ```elm
            ScrollMsg scrollMsg ->
                let
                    ( newState, events, cmd ) =
                        Sub.update ScrollMsg scrollMsg model.scrollState
                in
                ( { model | scrollState = newState }, cmd )
    ```

The `events` list lets you react to scroll lifecycle — see [Events](#events) below.


---

## In Detail

### Events

The `update` function returns a list of `ScrollEvent`s.
Each event includes a `Container` identifying the scroll surface (`Document` or `Container "element-id"`).

| Event | Payload | Meaning |
| ----- | ------- | ------- |
| `Started` | `Container` | The scroll has begun. |
| `Ended` | `Container` | The scroll completed naturally. |
| `Progress` | `Container`, `{ x : Float, y : Float }`, `Float` | Live scroll update with container, current position, and overall progress from `0.0` to `1.0`. |
| `Stopped` | `Container` | The scroll was stopped before completion. |
| `Paused` | `Container` | The scroll paused at its current position. |
| `Resumed` | `Container` | The scroll resumed after a pause. |
| `Restarted` | `Container` | The scroll reset to start and began again. |

### Tracking Live Progress

The `Progress` event makes it straightforward to build position indicators, scrollbars, or percentage readouts:

??? example "View Source Code"

    ```elm
    handleEvent event model =
        { model
            | status =
                case event of
                    Sub.Progress _ position progress ->
                        -- position.x and position.y are the current scroll coordinates
                        -- progress goes from 0.0 to 1.0
                        ShowingProgress position <|
                            round (progress * 100)

                    _ ->
                        model.status
        }
    ```


### Controls

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
                        Sub.stop Sub.Document ScrollMsg model.scrollState
                in
                ( { model | scrollState = newState }, cmd )
    ```

**Pause/Resume** return just `ScrollState` — no commands needed:

??? example "View Source Code"

    ```elm
            PauseScroll ->
                ( { model | scrollState = Sub.pause (Sub.Container "sidebar") model.scrollState }, Cmd.none )

            ResumeScroll ->
                ( { model | scrollState = Sub.resume (Sub.Container "sidebar") model.scrollState }, Cmd.none )
    ```

📖 See [Controlling Scroll Animations](../concepts/controlling-scroll.md) for live examples and complete code patterns.


### Querying State

Query scroll animation state and position during execution:

??? example "View Source Code"

    ```elm
    -- Is any scroll animation running?
    Sub.anyRunning model.scrollState  -- Maybe Bool

    -- Is a specific container's scroll running?
    Sub.isRunning Sub.Document model.scrollState  -- Maybe Bool

    -- Get current scroll position
    Sub.getPosition Sub.Document model.scrollState  -- Maybe { x : Float, y : Float }

    -- Get individual axis positions
    Sub.getPositionX Sub.Document model.scrollState  -- Maybe Float
    Sub.getPositionY Sub.Document model.scrollState  -- Maybe Float
    ```

All query functions return `Maybe` — `Nothing` means no animation exists for that container.

Multiple scroll targets can run at the same time inside the same `ScrollState`. They remain independently queryable, emit their own events, and complete separately.


### API Quick Reference

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

For complete API details, see the [Scroll.Engine.Sub](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Scroll-Engine-Sub) documentation.

### Next Steps

Now that you've learnt about the Scroll Engines, learn about interrupting your scrolls mid-flight.

[Interrupting Scrolls →](../concepts/interrupting-scrolls.md){ .md-button .md-button--primary }
