# CSS Keyframe Engine

This page is a complete guide to using the Keyframe engine end to end.
Read [Engines Overview](overview.md) when you want side-by-side comparisons and tradeoffs.

This Engine uses native browser CSS `@keyframes` animations. The browser handles all rendering, providing excellent performance.

## Example

On-load animation that fades in text as soon as the page loads.

??? example "View Example"

    --8<-- "docs/animation/first-animations/hello-text/keyframe.md:example"

??? example "View Source Code"

    --8<-- "docs/animation/first-animations/hello-text/keyframe.md:code"

The walkthrough below is a standalone minimal reference flow — it is not the implementation of the example above.

## End-to-End Walkthrough

This minimal flow covers the full lifecycle: initialize state, trigger animation, process engine messages, and render keyframes.

### 1. Model and Messages

??? example "View Source Code"

    ```elm
    type alias Model =
        { animState : Keyframe.AnimState }


    type Msg
        = TriggerFadeIn
        | GotAnimMsg Keyframe.AnimMsg
    ```

### 2. Initialize

??? example "View Source Code"

    ```elm
    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Keyframe.init [ Opacity.init "card" 0 ] }
        , Cmd.none
        )
    ```

### 3. Define the Animation

??? example "View Source Code"

    ```elm
    fadeIn : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
    fadeIn =
        Opacity.for "card"
            >> Opacity.to 1
            >> Opacity.duration 350
            >> Opacity.build
    ```

### 4. Trigger with `animate`

Call `animate` to apply the animation config to the current `AnimState`.

??? example "View Source Code"

    ```elm
    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            TriggerFadeIn ->
                ( { model | animState = Keyframe.animate model.animState fadeIn }
                , Cmd.none
                )

            _ ->
                ( model, Cmd.none )
    ```

### 5. Subscriptions and `update`

Subscribe to keyframe engine messages, then process them with `update`.

??? example "View Source Code"

    ```elm
    subscriptions : Model -> Sub Msg
    subscriptions model =
        Keyframe.subscriptions GotAnimMsg model.animState


    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( animState, event ) =
                        Keyframe.update animMsg model.animState
                in
                ( { model | animState = animState }, Cmd.none )

            _ ->
                ( model, Cmd.none )
    ```

### 6. View

Render both the generated `@keyframes` style node and the element attributes.

??? example "View Source Code"

    ```elm
    view : Model -> Html Msg
    view model =
        div []
            [ Keyframe.styleNode model.animState
            , div (Keyframe.attributes "card" model.animState) [ text "Animated card" ]
            ]
    ```


## Keyframe Style Node

Keyframe animations require a `<style>` node to define the `@keyframes` rules. Include this in your view:

??? example "View Source Code"

    ```elm
    view : Model -> Html Msg
    view model =
        div []
            [ Keyframe.styleNode model.animState
            , div
                (Keyframe.attributes "boxAnim" model.animState)
                [ ... ]
            ]
    ```

    Or for a specific animation group:

    ```elm
    Keyframe.styleNodeFor "boxAnim" model.animState
    ```

!!! tip "Positioning the `style` node"
    Keyframe animations restart whenever the browser re-renders their `<style>` node.

    Place `styleNode` in a stable part of your DOM — ideally near the root, outside any conditionally-rendered elements or frequently-updating regions.

## Events

Keyframe animations don't natively fire DOM events for `Paused`, `Resumed` or `Restarted`. These are synthetic events that the Engine generates when their corresponding control functions are called.

In order to achieve this, the `restart`, `pause` and `resume` control functions return a tuple of `(AnimState, Cmd msg)`. The `Cmd msg` must be passed to the Elm runtime in order for their events to be generated.

This pattern lets you centralise all animation-related logic in a single `handleEvent` function, rather than scattering it across call sites.

??? example "View Source Code"

    ```elm
    update : Msg -> Model -> (Model, Cmd Msg)
    update msg model =
        case msg of
            Restart ->
                let
                    (animState, eventCmd) =
                        Keyframe.restart "boxAnim" model.animState
                in
                ( { model | animState = animState }
                , eventCmd
                )

            Resume ->
                let
                    (animState, eventCmd) =
                        Keyframe.resume "boxAnim" model.animState
                in
                ( { model | animState = animState }
                , eventCmd
                )

            Pause ->
                let
                    (animState, eventCmd) =
                        Keyframe.pause "boxAnim" model.animState
                in
                ( { model | animState = animState }
                , eventCmd
                )

            GotAnimMsg animMsg ->
                let 
                    (animState, event) = 
                        Keyframe.update animMsg model.animState
                in 
                ( handleEvent event { model | animState = animState }
                , Cmd.none
                )
            ...

    handleEvent : AnimEvent -> Model -> Model
    handleEvent event model =
        case event of 
            Restarted _ _ _ ->
                ...

            Paused _ _ _ ->
                ...

            Resumed _ _ _ ->
                ...

            Started _ _ _ ->
                ...

            Ended _ _ _ ->

                ...
            Cancelled _ _ _ ->
                ...

            Iteration _ _ _ ->
                ...
    ```

## Interrupting Animations

CSS Keyframe rules don't support mid-flight redirection. Triggering a keyframe animation on an element while a keyframe animation is running replaces the current animation — the element jumps to the end of the current animation and starts the new animation from there rather than smoothly transitioning from its current position.

This is a fundamental limitation of CSS `@keyframes`:

- **No playhead access** — CSS provides no API to query where an animation currently is (e.g., "50% through the fade")
- **No progress events** — There's no event that reports intermediate values
- **Hardcoded keyframes** — The `@keyframes` rule defines fixed values; the browser can't start from an arbitrary midpoint

Even though Elm tracks the animation state, there is no way to know the current, mid-flight animated value. The browser runs the animation independently — which is exactly what makes Keyframe so performant — but it means the in-progress state isn't accessible.

This also applies when animating a **different property** — calling `animate` with any new properties cancels all currently running animations on that element, not just the ones being replaced.

If mid-flight interruption is important for your use case, consider using the [Transition](transition.md), [Sub](sub.md), or [WAAPI](waapi.md) engine instead.

## Discrete Properties

The Keyframe engine manages discrete properties as inline styles. `discreteEntry` values are applied from the first animation frame, and `discreteExit` values flip on the last frame. No additional view setup is needed.

📖 See [Discrete Properties](../concepts/discrete-properties.md) for the full API, live examples, and source code.

## When to Choose This Engine

Choose Keyframe when you want browser-native keyframes with state-tracked lifecycle and playback controls.

- Best for: on-load animations, loops, and timelines that benefit from pause/resume/restart.
- Avoid when: you need true mid-flight value access or smooth redirection from current playhead position.
- Prefer: [Sub](sub.md) or [WAAPI](waapi.md) for mid-flight querying and stronger interruption control.

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animations configurations |
| `AnimMsg` | Internal `Msg`s for state tracked animations |
| `AnimEvent` | Events received during a keyframe animation lifecycle |
| `AnimGroup` | `String` type alias representing the animation group name |
| `TransformProperty` | Custom transform ordering |

### Initialize

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `List (AnimBuilder -> AnimBuilder) -> AnimState` | Create initial animation state |

### Trigger

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `animate` | `AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Create a state-tracked animation |

### Update

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `update` | `AnimMsg -> AnimState -> (AnimState, AnimEvent)` | Update AnimState after a keyframe event |

### View

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `attributes` | `AnimGroup -> AnimState -> List (Html.Attribute msg)` | Get the animation attributes for an element |
| `styleNode` | `AnimState -> Html msg` | Generate `@keyframes` rules for all animation groups |
| `styleNodeFor` | `AnimGroup -> AnimState -> Html msg` | Generate `@keyframes` rules for a specific animation group |
| `getElementKeyframes` | `AnimGroup -> AnimState -> String` | Get the raw `@keyframes` CSS for a specific animation group |

### Event Listeners

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `events` | `String -> (AnimEvent -> msg) -> List (Attribute msg)` | Attach all animation event listeners for an animation group |
| `eventsStopPropagation` | `String -> (AnimEvent -> msg) -> List (Attribute msg)` | Attach all listeners, stops propagation |

### Events

| Event | Fires when... |
| ----- | ------------- |
| `Started` | The animation begins playing |
| `Ended` | The animation completes (after all iterations) |
| `Cancelled` | The animation is interrupted before completing |
| `Paused` | `pause` is called |
| `Resumed` | `resume` is called |
| `Restarted` | `restart` is called |
| `Iteration` | Each cycle completes |

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
| ---------- | ---- | ------------- |
| `stop` | `AnimGroup -> AnimState -> AnimState` | Jump to end state and stop |
| `reset` | `AnimGroup -> AnimState -> AnimState` | Jump to start state and stop |
| `restart` | `AnimGroup -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )` | Reset and begin playing again |
| `pause` | `AnimGroup -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )` | Freeze at current position |
| `resume` | `AnimGroup -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )` | Continue from paused position |

### Discrete Properties

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `discreteEntry` | `String -> String -> AnimBuilder -> AnimBuilder` | Set a CSS property value when the animation starts |
| `discreteExit` | `String -> String -> String -> AnimBuilder -> AnimBuilder` | Set a CSS property value during and after the animation |

### State Queries

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `anyRunning` | `AnimState -> Maybe Bool` | Check if any animations are running |
| `isRunning` | `AnimGroup -> AnimState -> Maybe Bool` | Check if a specific element is animating |
| `allComplete` | `AnimState -> Maybe Bool` | Check if all animations are complete |
| `isComplete` | `AnimGroup -> AnimState -> Maybe Bool` | Check if a specific element's animation is complete |

### Property Queries

CSS keyframes do not provide access to mid-flight values, so only start and end values are tracked. For mid-flight values, use either the [Sub](sub.md) or [WAAPI](waapi.md) engine.

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `getTranslateStart` | `AnimGroup -> AnimState -> Maybe { x, y, z }` | Get start translate value |
| `getTranslateEnd` | `AnimGroup -> AnimState -> Maybe { x, y, z }` | Get end translate value |
| `get*Start` | `AnimGroup -> AnimState -> Maybe *` | Get start * value |
| `get*End` | `AnimGroup -> AnimState -> Maybe *` | Get end * value |

If no animation exists `Nothing` is returned.

For complete API details, see the [Anim.Engine.CSS.Keyframe](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-CSS-Keyframe) documentation.

## Next Steps

The Sub Engine which provides a few more features than you get with keyframes.

[Sub Engine →](sub.md){ .md-button .md-button--primary }
