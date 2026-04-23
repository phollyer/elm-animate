# Scroll Sub Engine

This page focuses on what makes this engine different, read [Scroll Engines Overview](overview.md) for features that are shared across all Scroll engines.

The Scroll Sub Engine uses Elm subscriptions to update scroll state on every frame. This provides full programmatic control over scroll animations, including mid-scroll queries, events, and interruption controls.


## Live Example

<iframe src="../../../examples/src/Engines/Scroll/Sub/FirstScroll/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Full Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/Sub/FirstScroll/Main.elm"
    ```

📖 See [Your First Scrolls](../../getting-started/first-scrolls.md) for a step-by-step breakdown.


## Usage

### 1. Initialize

Store the `AnimState` in your model and initialize it with `Scroll.init`:

```elm
import Anim.Engine.Scroll.Sub as Scroll
import Anim.Engine.Scroll.Builder as ScrollTo
import Anim.Extra.Easing exposing (Easing(..))

type alias Model =
    { scrollState : Scroll.AnimState }

init : () -> ( Model, Cmd Msg )
init _ =
    ( { scrollState = Scroll.init }, Cmd.none )
```

### 2. Subscribe

Wire up subscriptions so the engine receives animation frame updates:

```elm
subscriptions : Model -> Sub Msg
subscriptions model =
    Scroll.subscriptions ScrollMsg model.scrollState
```

The subscription only activates while a scroll animation is running — it does nothing when idle.

### 3. Trigger

Call `animate` from your `update` function. It returns the updated `AnimState` and a `Cmd`:

```elm
type Msg
    = ScrollTo String
    | ScrollMsg Scroll.AnimMsg

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScrollTo targetId ->
            let
                ( newState, cmd ) =
                    Scroll.animate ScrollMsg model.scrollState <|
                        ScrollTo.forContainer "scroll-container"
                            >> ScrollTo.toElement targetId
                            >> ScrollTo.easing BounceOut
                            >> ScrollTo.build
            in
            ( { model | scrollState = newState }, cmd )
```

### 4. Update

Handle the engine's internal messages to advance the animation each frame:

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

The `update` function returns a list of `AnimEvent`s. Each event carries a `String` identifying the container:

| Event | When It Fires |
| ----- | ------------- |
| `Started` | Scroll animation begins |
| `Ended` | Scroll reaches its target |
| `Progress` | Every frame during scrolling |
| `Stopped` | Scroll was stopped programmatically |
| `Paused` | Scroll was paused |
| `Resumed` | Scroll was resumed after pause |
| `Restarted` | Scroll was restarted |

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

### AnimEvent Reference

| Event | Payload | Description |
| ----- | ------- | ----------- |
| `Started` | `String` | The scroll has begun. Payload is the container ID. |
| `Ended` | `String` | The scroll completed naturally. Payload is the container ID. |
| `Stopped` | `String` | The scroll was stopped before completion. Payload is the container ID. |
| `Restarted` | `String` | The scroll was restarted from the beginning. Payload is the container ID. |
| `Paused` | `String` | The scroll was paused. Payload is the container ID. |
| `Resumed` | `String` | The scroll was resumed after a pause. Payload is the container ID. |
| `Progress` | `String`, `{ x : Float, y : Float }`, `Float` | Live scroll position update. Payloads are the container ID, the current scroll coordinates, and overall progress from `0.0` to `1.0`. |

### Tracking Live Progress

The `Progress` event makes it straightforward to build position indicators, scrollbars, or percentage readouts:

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

Control scroll animations at any time. Each function has a document and container variant:

| Document | Container | Behavior |
| -------- | --------- | -------- |
| `stop` | `stopContainer` | Jump instantly to the scroll **target position** and complete |
| `pause` | `pauseContainer` | Freeze the scroll at its current position |
| `resume` | `resumeContainer` | Continue a paused scroll from where it was frozen |
| `reset` | `resetContainer` | Jump instantly to the **start position** and stop |
| `restart` | `restartContainer` | Reset to start position, then begin scrolling again |

**Stop/Reset/Restart** return `( AnimState, Cmd msg )` because they issue immediate scroll commands:

```elm
        StopScroll ->
            let
                ( newState, cmd ) =
                    Scroll.stop ScrollMsg model.scrollState
            in
            ( { model | scrollState = newState }, cmd )
```

**Pause/Resume** return just `AnimState` — no commands needed:

```elm
        PauseScroll ->
            ( { model | scrollState = Scroll.pause model.scrollState }, Cmd.none )

        ResumeScroll ->
            ( { model | scrollState = Scroll.resume model.scrollState }, Cmd.none )
```

For container scrolling, use the `*Container` variants with the container ID:

```elm
Scroll.stopContainer "sidebar" ScrollMsg model.scrollState
Scroll.pauseContainer "sidebar" model.scrollState
```

📖 See [Controlling Scroll Animations](../../concepts/controlling-scroll.md) for live examples and complete code patterns.


## Querying State

Query scroll animation state and position during execution:

```elm
-- Is any scroll animation running?
Scroll.anyRunning model.scrollState  -- Maybe Bool

-- Is a specific container's scroll running?
Scroll.isRunning "document" model.scrollState  -- Maybe Bool

-- Get current scroll position
Scroll.getPosition "document" model.scrollState  -- Maybe { x : Float, y : Float }

-- Get individual axis positions
Scroll.getPositionX "document" model.scrollState  -- Maybe Float
Scroll.getPositionY "document" model.scrollState  -- Maybe Float
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
| `AnimState` | type alias | Scroll animation state for your model |
| `AnimMsg` | type alias | Internal message type |
| `AnimEvent` | type | `Started`, `Ended`, `Progress`, `Stopped`, `Paused`, `Resumed`, `Restarted` |
| `init` | `AnimState` | Create initial state |
| `animate` | `(AnimMsg -> msg) -> AnimState -> (AnimBuilder -> AnimBuilder) -> ( AnimState, Cmd msg )` | Trigger stateful scroll |
| `update` | `(AnimMsg -> msg) -> AnimMsg -> AnimState -> ( AnimState, List AnimEvent, Cmd msg )` | Handle scroll messages |
| `subscriptions` | `(AnimMsg -> msg) -> AnimState -> Sub msg` | Animation frame subscription |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (px/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |
| `stop` / `stopContainer` | | Jump to target position |
| `pause` / `pauseContainer` | | Freeze at current position |
| `resume` / `resumeContainer` | | Continue paused scroll |
| `reset` / `resetContainer` | | Jump to start position |
| `restart` / `restartContainer` | | Reset and replay |
| `anyRunning` | `AnimState -> Maybe Bool` | Check if any scrolls are running |
| `isRunning` | `String -> AnimState -> Maybe Bool` | Check specific container |
| `getPosition` | `String -> AnimState -> Maybe { x : Float, y : Float }` | Current scroll position |
| `getPositionX` | `String -> AnimState -> Maybe Float` | Current X position |
| `getPositionY` | `String -> AnimState -> Maybe Float` | Current Y position |

For complete API details, see the [Anim.Engine.Scroll.Sub](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Scroll-Sub) documentation.
