# Scroll Sub Engine

This page focuses on what makes this engine different, read [Scroll Engines Overview](overview.md) for features that are shared across all Scroll engines.

The Scroll Sub Engine uses Elm subscriptions to update scroll state on every frame. This provides full programmatic control over scroll animations, including mid-scroll queries, events, and interruption controls.


## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Engine.Scroll.Sub as Scroll
    import Anim.Engine.Scroll.Builder as ScrollTo

    type alias Model =
        { scrollState : Scroll.AnimState }

    type Msg
        = ScrollToSection
        | ScrollMsg Scroll.AnimMsg

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollToSection ->
                let
                    ( newState, cmd ) =
                        Scroll.animate ScrollMsg model.scrollState <|
                            ScrollTo.forDocument
                                >> ScrollTo.toElement "target-section"
                                >> ScrollTo.build
                in
                ( { model | scrollState = newState }, cmd )

            ScrollMsg scrollMsg ->
                let
                    ( newState, _, cmd ) =
                        Scroll.update ScrollMsg scrollMsg model.scrollState
                in
                ( { model | scrollState = newState }, cmd )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Scroll.subscriptions ScrollMsg model.scrollState
    ```


## Events

The `update` function returns a list of `AnimEvent`s for each scroll animation:

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


## Controls

You can `stop`, `reset`, `restart`, `pause` and `resume` scroll animations at any time. Each control function has a document and container variant:

| Document | Container | Behavior |
| -------- | --------- | -------- |
| `stop` | `stopContainer` | Jump instantly to the scroll **target position** and complete |
| `pause` | `pauseContainer` | Freeze the scroll at its current position |
| `resume` | `resumeContainer` | Continue a paused scroll from where it was frozen |
| `reset` | `resetContainer` | Jump instantly to the **start position** and stop |
| `restart` | `restartContainer` | Reset to start position, then begin scrolling again |

📖 See [Controlling Scroll Animations](../../concepts/controlling-scroll.md) for live examples and code patterns.


## Querying State

Query scroll animation state and position during execution:

??? example "View Source Code"

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


## How To Use

**Single scroll:**

1. Add `AnimState` to your model
2. Add `subscriptions` to your subscriptions function
3. Configure one scroll target in your `AnimBuilder` pipeline
4. Call `animate` with your message constructor
5. Store the returned `AnimState` in your model
6. Handle animation messages in your update function with `update`

**Multiple concurrent scrolls:**

1. Add `AnimState` to your model
2. Add `subscriptions` to your subscriptions function
3. Configure multiple scroll targets in the same `AnimBuilder` pipeline
4. Call `animate` with your message constructor
5. Store the returned `AnimState` in your model
6. Handle animation messages in your update function with `update`
7. Use query functions to track individual scroll progress


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
