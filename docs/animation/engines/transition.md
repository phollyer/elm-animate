# CSS Transition Engine

This page is a practical guide to using the Transition engine from setup through advanced usage.
Read [Engines Overview](overview.md) when you want side-by-side comparisons and tradeoffs.

This Engine uses native browser CSS transitions for simple A→B property animations. The browser handles all rendering, providing excellent performance with minimal setup.

## Example

Simple A→B button hover animations.

??? example "View Example"

    --8<-- "docs/animation/first-animations/button-hovers/transition.md:example"

??? example "View Source Code"

    --8<-- "docs/animation/first-animations/button-hovers/transition.md:code"

---

## Quick Walkthrough

Get up and running in minutes.

### 1. Build

??? example "View Source Code"

    ```elm
    import Anim.Engine.Transition as Transition
    import Anim.Property.Opacity as Opacity


    fadeIn : Transition.AnimBuilder mode -> Transition.AnimBuilder mode
    fadeIn =
        Opacity.for "card"
            >> Opacity.to 1
            >> Opacity.duration 300
            >> Opacity.build
    ```

### 2. Initialize

??? example "View Source Code"

    ```elm
    type alias Model =
        { animState : Transition.AnimState }


    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Transition.init [ Opacity.init "card" 0 ] }
        , Cmd.none
        )
    ```

### 3. Render

Render both engine attributes and event listeners on the animated node.

??? example "View Source Code"

    ```elm
    view : Model -> Html Msg
    view model =
        div []
            [ button [ onClick TriggerFadeIn ] [ text "Fade In" ]
            , div
                (Transition.attributes "card" model.animState
                    ++ Transition.events GotAnimMsg
                )
                [ text "Animated card" ]
            ]
    ```

### 4. Trigger with `animate`

Call `animate` to apply the animation config to the current `AnimState`.

??? example "View Source Code"

    ```elm
    TriggerFadeIn ->
        ( { model | animState = Transition.animate model.animState fadeIn }
        , Cmd.none
        )
    ```

### 5. React

Use `update` for incoming transition events.

??? example "View Source Code"

    ```elm
    type Msg
        = TriggerFadeIn
        | GotAnimMsg Transition.AnimMsg


    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( animState, event ) =
                        Transition.update animMsg model.animState
                in
                handleAnimEvent event { model | animState = animState }

            _ ->
                (model, Cmd.none)


    handleAnimEvent : Transition.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimEvent event model =
        case event of
            Transition.Ended _ _ "card" ->
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )
    ```

---

## In Detail

### Initialize

Pass a list of property initializers to `init`. Each registers an animation group name and sets the element's starting inline style from the first render.

??? example "View Source Code"

    ```elm
    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Transition.init [ Opacity.init "card" 0 ] }
        , Cmd.none
        )
    ```

### Trigger

Call `animate` to apply an animation to the current `AnimState`. The browser transitions from its current computed style to the values provided.

Starting values in the builder config are ignored — the browser always starts from the element's current computed style.

### Mid-Flight Interruptions

Because the browser starts from current computed style, interrupting an animation mid-flight automatically transitions smoothly from wherever the element is — just provide a new end value.

### OnLoad Animations

If a transition must run immediately on page load, use `Process.sleep 0` before triggering. Without the delay, the browser has no prior state and the property jumps instantly to the end value.

??? example "View Source Code"

    ```elm
    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Transition.init [ Opacity.init "card" 0 ] }
        , Process.sleep 0 |> Task.perform (\_ -> TriggerFadeIn)
        )
    ```

### Events

`update` returns a single `AnimEvent` per call. Each Transition event carries three values: the element that fired the event (`CurrentTargetId`), the element that owns the listener (`TargetId`), and the animation group name. In most cases only the group name is needed.

??? example "View Source Code"

    ```elm
    handleAnimEvent : Transition.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimEvent event model =
        case event of
            Transition.Ended _ _ "card" ->
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )
    ```

| Event | Fires when... |
| ----- | ------------- |
| `Run` | Transition is queued to run (before any delay) |
| `Started` | Transition begins playing |
| `Ended` | Transition completes |
| `Cancelled` | Transition is cancelled before completing |

### Update

Use `update` to process incoming transition messages. It returns the updated `AnimState` and the corresponding `AnimEvent`.

??? example "View Source Code"

    ```elm
    GotAnimMsg animMsg ->
        let
            ( animState, event ) =
                Transition.update animMsg model.animState
        in
        handleAnimEvent event { model | animState = animState }
    ```

### View

Apply `attributes` to the animated element to set its transition rules and inline styles.

??? example "View Source Code"

    ```elm
    div (Transition.attributes "card" model.animState) [ text "Card" ]
    ```

### Event Listeners

Apply `events` alongside `attributes` to attach the DOM transition event listeners that drive `update`.

??? example "View Source Code"

    ```elm
    div
        (Transition.attributes "card" model.animState
            ++ Transition.events GotAnimMsg
        )
        [ text "Card" ]
    ```

Use `eventsStopPropagation` to prevent events from bubbling to parent elements.

### Timing

Set `duration`, `speed`, and `delay` in the animation builder.

- `duration` — animation length in milliseconds.
- `speed` — alternative to `duration`; set a rate in property units per second and the engine calculates duration from the distance to the end value.
- `delay` — wait before the transition begins, in milliseconds.

??? example "View Source Code"

    ```elm
    fadeIn =
        Opacity.for "card"
            >> Opacity.to 1
            >> Opacity.duration 300
            >> Opacity.delay 50
            >> Opacity.build
    ```

### Easing

Easings are converted to CSS `cubic-bezier` values for the browser to render natively.

Most standard easings (sine, quad, cubic, quart, quint, expo) convert accurately. However, complex curves like **bounce** and **elastic** are approximated and won't match their mathematical definitions exactly.

For accurate complex easing curves, use the [Keyframe](keyframes.md), [Sub](sub.md), or [WAAPI](waapi.md) engine instead.

### Controls

`stop` jumps the animation to its end state. `reset` jumps to the start state. Neither returns a `Cmd`.

??? example "View Source Code"

    ```elm
    Stop ->
        ( { model | animState = Transition.stop "card" model.animState }, Cmd.none )

    Reset ->
        ( { model | animState = Transition.reset "card" model.animState }, Cmd.none )
    ```

### Discrete Properties

The Transition engine uses `discreteEntry` and `discreteExit` — the same API as all other engines.

For this engine, calling either function enables the browser's native `transition-behavior: allow-discrete` CSS feature.

For entry animations, include `startingStyleNode` in your view. This generates `@starting-style` CSS rules so the browser knows the interpolable property values to animate from when an element first appears. Without it, entry transitions are skipped.

??? example "View Source Code"

    ```elm
    fadeIn : AnimBuilder mode -> AnimBuilder mode
    fadeIn =
        Transition.discreteEntry "display" "block"
            >> Opacity.for "box"
            >> Opacity.to 1
            >> Opacity.build

    fadeOut : AnimBuilder mode -> AnimBuilder mode
    fadeOut =
        Transition.discreteExit "display" "block" "none"
            >> Opacity.for "box"
            >> Opacity.to 0
            >> Opacity.build

    view : Model -> Html Msg
    view model =
        div []
            [ Transition.startingStyleNode model.animState
            , div
                (Transition.attributes "box" model.animState
                    ++ Transition.events GotAnimMsg
                    ++ [ style "display" "none" ]
                )
                [ text "Hello!" ]
            ]
    ```

!!! info "Browser Support"
    `transition-behavior: allow-discrete` requires modern browsers (Chrome 117+, Firefox 129+, Safari 18+). In older browsers, discrete property transitions won't animate — the property will snap immediately.

📖 See [Discrete Properties](../concepts/discrete-properties.md) for the full API, live examples, and source code.

### State Queries

Query animation state at any time without waiting for events.

??? example "View Source Code"

    ```elm
    Transition.anyRunning model.animState            -- Maybe Bool
    Transition.isRunning "card" model.animState      -- Maybe Bool
    Transition.allComplete model.animState           -- Maybe Bool
    Transition.isComplete "card" model.animState     -- Maybe Bool
    Transition.isCancelled "card" model.animState    -- Maybe Bool
    ```

`Nothing` is returned when no animation exists for the given group.

### Property Queries

CSS transitions track only end values — the start is always the browser's current computed style.

??? example "View Source Code"

    ```elm
    Transition.getOpacityEnd "card" model.animState                          -- Maybe Float
    Transition.getTranslateEnd "card" model.animState                        -- Maybe { x, y, z }
    Transition.getRotateEnd "card" model.animState                           -- Maybe { x, y, z }
    Transition.getScaleEnd "card" model.animState                            -- Maybe { x, y, z }
    Transition.getSizeEnd "card" model.animState                             -- Maybe { width, height }
    Transition.getSkewEnd "card" model.animState                             -- Maybe { x, y }
    Transition.getPropertyEnd "card" "font-size" model.animState             -- Maybe Float
    Transition.getColorPropertyEnd "card" "background-color" model.animState -- Maybe Color
    ```

For start values and mid-flight current values, use the [Keyframe](keyframes.md), [Sub](sub.md), or [WAAPI](waapi.md) engine.

`Nothing` is returned when no animation exists for the given group.

## When to Choose This Engine

Choose Transition when you want minimal setup and smooth state-tracked A to B animations.

- Best for: UI interactions, hovers, toggles, and small component transitions.
- Avoid when: you need custom transform ordering, pause/resume/restart, or mid-flight value queries.
- Prefer: [Keyframe](keyframes.md) for native looping controls, [Sub](sub.md) for full Elm control, or [WAAPI](waapi.md) for browser-native rich controls.

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks animations and their states |
| `AnimBuilder mode` | Carries all animation configurations |
| `AnimMsg` | Internal engine messages |
| `AnimEvent` | Events received during a transition's lifecycle |
| `AnimGroupName` | `String` type alias for the animation group name |
| `CurrentTargetId` | `String` type alias for the element that fired the event |
| `TargetId` | `String` type alias for the element that owns the listener |

### Initialize

| Function | Type | Description |
| -------- | ---- | ----------- |
| `init` | `List (AnimBuilder mode -> AnimBuilder mode) -> AnimState` | Create initial animation state |

### Trigger

| Function | Type | Description |
| -------- | ---- | ----------- |
| `animate` | `AnimState -> (AnimBuilder mode -> AnimBuilder mode) -> AnimState` | Apply an animation to the current state |

### Events

| Event | Description |
| ----- | ----------- |
| `Run CurrentTargetId TargetId AnimGroupName` | Transition is queued to run |
| `Started CurrentTargetId TargetId AnimGroupName` | Transition begins playing |
| `Ended CurrentTargetId TargetId AnimGroupName` | Transition completes |
| `Cancelled CurrentTargetId TargetId AnimGroupName` | Transition is cancelled |

### Update

| Function | Type | Description |
| -------- | ---- | ----------- |
| `update` | `AnimMsg -> AnimState -> (AnimState, AnimEvent)` | Process transition messages |

### View

| Function | Type | Description |
| -------- | ---- | ----------- |
| `attributes` | `AnimGroupName -> AnimState -> List (Html.Attribute msg)` | Get transition attributes for an element |

### Event Listeners

| Function | Type | Description |
| -------- | ---- | ----------- |
| `events` | `(AnimMsg -> msg) -> List (Html.Attribute msg)` | Attach all transition event listeners |
| `eventsStopPropagation` | `(AnimMsg -> msg) -> List (Html.Attribute msg)` | Attach all listeners, stops propagation |

### Timing

| Function | Type | Description |
| -------- | ---- | ----------- |
| `duration` | `Int -> AnimBuilder mode -> AnimBuilder mode` | Set duration (ms) |
| `speed` | `Float -> AnimBuilder mode -> AnimBuilder mode` | Set speed (property units/sec) |
| `delay` | `Int -> AnimBuilder mode -> AnimBuilder mode` | Set delay before transition starts (ms) |

### Easing

| Function | Type | Description |
| -------- | ---- | ----------- |
| `easing` | `Easing -> AnimBuilder mode -> AnimBuilder mode` | Set easing function |

### Controls

| Function | Type | Description |
| -------- | ---- | ----------- |
| `stop` | `AnimGroupName -> AnimState -> AnimState` | Jump to end state and stop |
| `reset` | `AnimGroupName -> AnimState -> AnimState` | Jump to start state and stop |

### Discrete Properties

| Function | Type | Description |
| -------- | ---- | ----------- |
| `discreteEntry` | `String -> String -> AnimBuilder mode -> AnimBuilder mode` | Set a discrete CSS property value for entry animations |
| `discreteExit` | `String -> String -> String -> AnimBuilder mode -> AnimBuilder mode` | Set a discrete CSS property value for exit animations |
| `startingStyleNode` | `AnimState -> Html msg` | Generate `@starting-style` rules for all groups |
| `startingStyleNodeFor` | `AnimGroupName -> AnimState -> Html msg` | Generate `@starting-style` rules for a specific group |

### State Queries

| Function | Type | Description |
| -------- | ---- | ----------- |
| `anyRunning` | `AnimState -> Maybe Bool` | Check if any animation is running |
| `isRunning` | `AnimGroupName -> AnimState -> Maybe Bool` | Check if a specific group is animating |
| `allComplete` | `AnimState -> Maybe Bool` | Check if all animations are complete |
| `isComplete` | `AnimGroupName -> AnimState -> Maybe Bool` | Check if a specific group's animation is complete |
| `isCancelled` | `AnimGroupName -> AnimState -> Maybe Bool` | Check if a specific group's animation was cancelled |

### Property Queries

CSS transitions track only end values.

| Function | Type | Description |
| -------- | ---- | ----------- |
| `getOpacityEnd` | `AnimGroupName -> AnimState -> Maybe Float` | Get end opacity |
| `getTranslateEnd` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get end translate |
| `getRotateEnd` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get end rotate |
| `getScaleEnd` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get end scale |
| `getSizeEnd` | `AnimGroupName -> AnimState -> Maybe { width, height }` | Get end size |
| `getSkewEnd` | `AnimGroupName -> AnimState -> Maybe { x, y }` | Get end skew |
| `getPropertyEnd` | `AnimGroupName -> String -> AnimState -> Maybe Float` | Get end value for a custom numeric property |
| `getColorPropertyEnd` | `AnimGroupName -> String -> AnimState -> Maybe Color` | Get end value for a custom color property |

`Nothing` is returned when no animation exists for the given group.

For complete API details, see the [Anim.Engine.Transition](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-Transition) documentation.

## Next Steps

The Keyframe Engine which provides a few different features to what you get with transitions.

[Keyframe Engine →](keyframes.md){ .md-button .md-button--primary }
