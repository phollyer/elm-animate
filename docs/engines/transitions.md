# CSS Transitions Engine

The CSS Transitions Engine uses native browser CSS transitions for simple A→B property animations. The browser handles all rendering, providing excellent performance with minimal setup.


## Basic Usage

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Transitions/BasicUsage/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/Transitions/BasicUsage/index.html){ .md-button target="_blank" }

### How CSS Transitions Work

CSS transitions animate when the browser detects a **_property change_** between renders. This makes them stable and predictable — they won't re-trigger unexpectedly during browser repaints or reflows.

However, for page entry animations (like in the example), where we want the animation to run straight away without any user interaction, we must simulate the **_property change_**. We use `Process.sleep 50` for this: the element renders in its `Idle` state first, then 50ms later the `state` is changed, which in-turn creates the **_property change_** and the animation runs. For most circumstances, user-triggered interactions naturally provide the state change to trigger a transition.

If you prefer animations that run immediately on render without this pattern, use the [Keyframes Engine](keyframes.md) instead - it gives you I-O-A's*...


## Running Animations

### Fire-and-Forget

For one-shot animations where you don't need to track state, use `fireAndForget`:

??? example "View Source Code"

    ```elm
    view : Model -> Html Msg
    view model =
        let
            animState =
                Transitions.fireAndForget <|
                    case model.state of
                        ShowText ->
                            fadeIn

                        HideText ->
                            fadeOut
        in 
        div
            (Transitions.attributes "text" animState)
            [ text "I fade in!" ]
    ```

Fire-and-forget is useful when you don't need chaining, state queries, or stop/reset controls.


### State-Tracked

When you need to query animation state, use stop/reset controls,
or chain animations that continue from the previous end state, use `animate`.

??? example "View Source Code"

    ```elm
    GotShowText ->
        ( { model| animState = Transitions.animate model.animState fadeIn }
        , Cmd.none
        )

    GotHideText ->
        ( { model | animState = Transitions.animate model.animState fadeOut }
        , Cmd.none
        )

    view : Model -> Html Msg
    view model =
        div
            (Transitions.attributes "text" model.animState)
            [ text "I fade in!" ]
    ```

The `animate` function takes your current `AnimState` and an animation pipeline, returning a new `AnimState` with the animation configured.

## Initialization

Create an `AnimState` for state-tracked animations using `init`:

??? example "Empty State"

    ```elm
    type alias Model =
        { animState : Transitions.AnimState }

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Transitions.init [] }
        , Cmd.none
        )
    ```

You can also initialize with starting property values:

??? example "With Initial Values"

    ```elm
    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState =
                Transitions.init
                    [ Opacity.init "my-element" 0
                    , Translate.initXY "my-element" 100 50
                    ]
          }
        , Cmd.none
        )
    ```

    These property values will be used in your view to set the initial state of your element(s).

## Event Handling

CSS transitions generate events throughout their lifecycle. Use these events to chain animations, update state, or trigger follow-up actions.

1. Create a `Msg` type variant for your transition events.

    ??? example "View Source Code"

        ```elm
        type Msg
            = GotTransitionEvent Transitions.AnimEvent
            | ...
        ```

2. Use `Transitions.events` in your view to generate events.

    ??? example "View Source Code"

        ```elm
        view model =
            div
                (Transitions.attributes "box" model.animState
                    ++ Transitions.events "box" GotTransitionEvent
                )
                [...]
        ```

3. Use `Transitions.handleEvent` in your `update` function. This will keep the internal state in sync with the animation lifecycle.

    ??? example "View Source Code"

        ```elm
        update : Msg -> Model -> (Model, Cmd Msg)
        update msg model =
            case msg of
                GotTransitionEvent event ->
                    ( { model | animState = Transitions.handleEvent event model.animState }
                    , Cmd.none 
                    )
        ```

4. Handle any events you are interested in.

    ??? example "View Source Code"

        ```elm
        update : Msg -> Model -> (Model, Cmd Msg)
        update msg model =
            case msg of
                GotTransitionEvent event ->
                    let
                        newModel =
                            { model | animState = Transitions.handleEvent event model.animState }
                    in
                    case event of
                        Transitions.Run "box" ->
                            (newModel, Cmd.none)

                        Transitions.Started "box" ->
                            (newModel, Cmd.none)

                        Transitions.Ended "box" ->
                            (newModel, Cmd.none)

                        Transitions.Cancelled "box" ->
                            (newModel, Cmd.none)

                        _ ->
                            ( newModel, Cmd.none )
        ```

!!! info "When events fire"

    | Event | Fires when... |
    | ----- | ------------- |
    | `Run` | The transition is created (before any delay) |
    | `Started` | The transition begins (after any delay) |
    | `Ended` | The transition completes |
    | `Cancelled` | The browser aborts the transition — e.g., the element is removed from the DOM, set to `display: none`, or the transition is interrupted by a new property change |

!!! info "Event Bubbling"
    CSS transition events bubble up the DOM tree. If a child element's transition ends, the event fires on the child then bubbles to its parent. When using nested elements with transitions, conditionally attach event listeners based on which element's events you care about to avoid spurious events triggering unintended actions.

## Default Settings

Set (optional) defaults for all properties:

- Timing: use `speed` or `duration`
- Easing
- Delay

These settings will be used for all property animations in the pipeline.

??? example "View Source Code"

    ```elm

    animState =
        Transitions.animate model.animState <|
            Transitions.duration 500
                >> Transitions.easing QuintOut
                >> Transitions.delay 100
                >> myAnimation
            
    ```

Individual properties can override them:

??? example "View Source Code"

    ```elm
    myAnimation : Transitions.AnimBuilder -> Transitions.AnimBuilder
    myAnimation =
        Opacity.for "box"
            >> Opacity.duration 1000  
            >> Opacity.easing SineOut 
            >> Opacity.delay 0
            >> Opacity.build
    ```

## Discrete Transitions

By default, CSS transitions only work with properties that can have intermediate values (like `opacity: 0.5`).
Discrete properties like `display`, `visibility`, and `content-visibility` have no in-between states — they snap instantly from one value to the next.

To enable smooth transitions with discrete properties, use `allowDiscrete`:

```elm
Transitions.animate model.animState <|
    (Transitions.allowDiscrete >> fadeIn >> slideIn)
```

### Entry vs Exit Animations

Discrete transitions behave differently depending on direction:

=== "Entry Animations (Showing)"

    **Entry animations need additional setup** via `@starting-style`.
    
    When an element first appears (or goes from `display: none` to visible), the browser
    needs to know what values to animate FROM. Without this, it skips the transition entirely.
    
    Include `startingStyleNode` in your view:
    
    ```elm
    view model =
        div []
            [ Transitions.startingStyleNode model.animState  
            , div
                (Transitions.attributes "my-element" model.animState)
                [ text "I'll animate when I appear" ]
            ]
    ```


=== "Exit Animations (Hiding)"

    **Exit animations work automatically** with just `allowDiscrete`.
    
    When transitioning TO `display: none`, the browser keeps the element visible during
    the transition, then hides it at the end.
    
    ```elm
    -- This just works™
    Transitions.animate model.animState <|
        Transitions.allowDiscrete >> fadeOut
    ```

### Why Entry Animations Need Extra Setup

When the browser encounters a new element being added to the DOM (or one changing from `display: none`), it has no "before" state to transition from. The `@starting-style` CSS rule tells the browser: "when this element enters, pretend it started with these values."

The engine generates this automatically from your animation's start values:

```css
/* Generated by startingStyleNode */
@starting-style {
  #my-element {
    opacity: 0;
    transform: translate3d(-20px, 0px, 0px);
  }
}
```

!!! tip "When to use startingStyleNode"
    - **Use it** when elements are added to the DOM
    - **Skip it** for elements always in the DOM that just animate their properties

??? info "Further Reading"
    - [MDN: transition-behavior](https://developer.mozilla.org/en-US/docs/Web/CSS/transition-behavior)
    - [MDN: @starting-style](https://developer.mozilla.org/en-US/docs/Web/CSS/@starting-style)
    - [Chrome for Developers: Entry and exit animations](https://developer.chrome.com/blog/entry-exit-animations)

## 3D Transforms

Fully supports 3D animations. See [3D Animations](../concepts/3d.md) for more information.

## Controlling Animations

For details on `stop` and `reset` controls, see [Controlling Animations](../concepts/controlling-animations.md).

## Querying Animation State

Check whether animations are running or complete:

??? example "View Source Code"

    ```elm
    view model =
        div []
            [ if Transitions.anyRunning model.animState then
                text "Animating..."
              else
                text "Complete"
            ]
    ```

You can also query specific elements:

??? example "View Source Code"

    ```elm
    view model =
        let
            boxStatus =
                if Transitions.isRunning "box" model.animState then
                    "Box is animating"
                else
                    case Transitions.isComplete "box" model.animState of
                        Just True ->
                            "Box animation complete"

                        Just False ->
                            "Box animation not started"

                        Nothing ->
                            "No animation for box"
        in
        div [] [ text boxStatus ]
    ```

## Querying Property Values

Query the start, end, or current values of animated properties:

??? example "View Source Code"

    ```elm
    view model =
        let
            positionText =
                case Transitions.getCurrentTranslate "box" model.animState of
                    Just { x, y, z } ->
                        "Position: " ++ String.fromFloat x ++ ", " ++ String.fromFloat y

                    Nothing ->
                        "No translate animation"
        in
        div [] [ text positionText ]
    ```

Available getters:

| Property | Start | End | Current |
| -------- | ----- | --- | ------- |
| Translate | `getStartTranslate` | `getEndTranslate` | `getCurrentTranslate` |
| Scale | `getStartScale` | `getEndScale` | `getCurrentScale` |
| Rotate | `getStartRotate` | `getEndRotate` | `getCurrentRotate` |
| Opacity | `getStartOpacity` | `getEndOpacity` | `getCurrentOpacity` |
| Size | `getStartSize` | `getEndSize` | `getCurrentSize` |
| Background Color | `getStartBackgroundColor` | `getEndBackgroundColor` | `getCurrentBackgroundColor` |

!!! note "Mid-flight values"
    CSS transitions don't expose actual mid-flight values. The "current" getters return the start value before the animation runs and the end value once it starts. For true mid-flight interpolation, use the [Sub Engine](sub.md) or [WAAPI Engine](waapi.md).

## Transform Ordering

The default transform order is: **Translate → Rotate → Scale**. This works well for most animations.

For custom ordering, use `animateOrder` or `fireAndForgetOrder`:

??? example "Custom Transform Order"

    ```elm
    -- Scale → Rotate → Translate
    Transitions.animateOrder [ Scale, Rotate, Translate ] model.animState <|
        scaleUp 
            >> rotateLeft
            >> moveRight
    ```

Transform order affects how combined transforms render. For example, rotating then translating moves along the rotated axis, while translating then rotating moves along the original axis.

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animations configurations |
| `AnimEvent` | Events received during a transitions lifecycle |
| `TransformOrder` | Custom transform ordering |

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `List (AnimBuilder -> AnimBuilder) -> AnimState` | Create initial animation state |
| `animate` | `AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Create a state-tracked animation |
| `fireAndForget` | `(AnimBuilder -> AnimBuilder) -> AnimState` | Fire-and-forget animation (no state tracking) |
| `animateOrder` | `List TransformOrder -> AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Animate with custom transform order |
| `fireAndForgetOrder` | `List TransformOrder -> (AnimBuilder -> AnimBuilder) -> AnimState` | Fire-and-forget with custom transform order |

### View Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `attributes` | `String -> AnimState -> List (Html.Attribute msg)` | Get the transition attributes for an element |
| `events` | `String -> (AnimEvent -> msg) -> List (Attribute msg)` | Attach transition event listeners |

### Event Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `handleEvent` | `AnimEvent -> AnimState -> AnimState` | Update AnimState after a transition event |

### Default Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (property units/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing function |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

### Control Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `stop` | `String -> AnimState -> AnimState` | Jump to end state and stop |
| `reset` | `String -> AnimState -> AnimState` | Jump to start state and stop |

### State Query Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `anyRunning` | `AnimState -> Bool` | Check if any animations are running |
| `isRunning` | `String -> AnimState -> Bool` | Check if a specific element is animating |
| `allComplete` | `AnimState -> Maybe Bool` | Check if all animations are complete |
| `isComplete` | `String -> AnimState -> Maybe Bool` | Check if a specific element's animation is complete |

### Property Query Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `getStartTranslate` | `String -> AnimState -> Maybe { x, y, z }` | Get start translate value |
| `getEndTranslate` | `String -> AnimState -> Maybe { x, y, z }` | Get end translate value |
| `getCurrentTranslate` | `String -> AnimState -> Maybe { x, y, z }` | Get current translate value |
| `getStart*` | (similar for Scale, Rotate, Opacity, Size, BackgroundColor) | Get start value |
| `getEnd*` | (similar for Scale, Rotate, Opacity, Size, BackgroundColor) | Get end value |
| `getCurrent*` | (similar for Scale, Rotate, Opacity, Size, BackgroundColor) | Get current value |

### Discrete Transition Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `allowDiscrete` | `AnimBuilder -> AnimBuilder` | Enable `transition-behavior: allow-discrete` |
| `startingStyleNode` | `AnimState -> Html msg` | Generate `@starting-style` for discrete entry animations |
| `startingStyleNodeFor` | `String -> AnimState -> Html msg` | Generate `@starting-style` for a specific element |

For complete API details, see the [Anim.Engine.CSS.Transitions](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-CSS-Transitions) documentation.

## Next Steps

The Keyframes Engine which provides a few more features than you get with transitions.

[Keyframes Engine →](keyframes.md){ .md-button .md-button--primary }

---

\* Guess the film... 😉
