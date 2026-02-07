# CSS Transitions Engine

The CSS Transitions Engine uses native browser CSS transitions for simple A→B property animations. The browser handles all rendering, providing excellent performance with minimal setup.

```elm
import Anim.Engine.CSS.Transitions as CSS
```

## When to Use

✅ **For:**

- Fire-and-forget animations
- Hover effects and micro-interactions
- Page transitions and entrances
- Simple A→B property changes
- When you don't need pause/resume control

❌ **Consider [Keyframes](css-keyframes.md) when:**

- You need looping or iterations
- You need pause/resume functionality
- Entry animations without `Process.sleep` delays

## Basic Usage

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/CSS/BasicUsage/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/CSS/BasicUsage/index.html){ .md-button target="_blank" }

!!! note "Why the delay?"
    CSS transitions only trigger when the browser detects a *change* between renders. `Process.sleep 50` is used to ensure the element renders in its initial state first, then the animation is applied 50ms later. This creates the *change* the browser needs.

## User-Triggered Animations

In practice, most animations are triggered by user interactions, which naturally provide the state change:

??? example "View Source Code"

    ```elm
    type Msg
        = AnimateBox


    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            AnimateBox ->
                let
                    newAnimState =
                        CSS.animate (CSS.init []) moveToNewPosition
                in
                ( { model | animState = newAnimState }, Cmd.none )
    ```

## Event Handling

CSS transitions generate events throughout their lifecycle. Use these events to chain animations, update state, or trigger follow-up actions.

Create a `Msg` type variant for your CSS transition events.

??? example "View Source Code"

    ```elm
    type Msg
        = GotTransitionEvent CSS.TransitionEvent
        | ...
    ```

Use `CSS.transitionEvents` in your view to generate events.

??? example "View Source Code"

    ```elm
    view model =
        div
            (CSS.transitionAttributes "box" model.animState
                ++ CSS.transitionEvents "box" GotTransitionEvent
            )
            [...]
    ```

Use `CSS.handleTransitionEvent` in your `update` function. This will keep the internal state in sync with the animation lifecycle.

??? example "View Source Code"

    ```elm
    update msg model =
        case msg of
            GotTransitionEvent event ->
                let
                    newModel =
                        { model | animState = CSS.handleTransitionEvent event model.animState}
                in
                case event of
                    CSS.TransitionEnded "box" ->
                        -- Animation complete
                        (newModel, Cmd.none)

                    CSS.TransitionStarted "box" ->
                        -- Animation started
                        (newModel, Cmd.none)

                    _ ->
                        ( newModel, Cmd.none )
    ```

## Global Settings

Set (optional) defaults for all properties:

- Timing: use `speed` or `duration`
- Easing
- Delay

These settings will be used for all property animations in the pipeline.

??? example "View Source Code"

    ```elm

    animState =
        CSS.animate (CSS.init [])
            (CSS.duration 500
                >> CSS.easing QuintOut
                >> CSS.delay 100
                >> myAnimation
            )
    ```

Individual properties can override them:

??? example "View Source Code"

    ```elm
    myAnimation builder =
        builder
            |> Opacity.for "box"
            |> Opacity.duration 1000  
            |> Opacity.easing SineOut 
            |> Opacity.delay 0
            |> Opacity.build
    ```

## Discrete Transitions

By default, CSS transitions only work with properties that have intermediate values (like `opacity: 0.5`).
Discrete properties like `display`, `visibility`, and `content-visibility` snap instantly between values.

To enable smooth transitions with discrete properties, use `allowDiscreteTransitions`:

```elm
CSS.animate model.animState <|
    (allowDiscreteTransitions >> fadeIn >> slideIn)
```

This adds `transition-behavior: allow-discrete` to your animation.

### Entry vs Exit Animations

Discrete transitions behave differently depending on direction:

=== "Exit Animations (Hiding)"

    **Exit animations work automatically** with just `allowDiscreteTransitions`.
    
    When transitioning TO `display: none`, the browser keeps the element visible during
    the transition, then hides it at the end.
    
    ```elm
    -- This just works™
    CSS.animate model.animState <|
        (allowDiscreteTransitions >> fadeOut)
    ```

=== "Entry Animations (Showing)"

    **Entry animations need additional setup** via `@starting-style`.
    
    When an element first appears (or goes from `display: none` to visible), the browser
    needs to know what values to animate FROM. Without this, it skips the transition entirely.
    
    Include `startingStyleNode` in your view:
    
    ```elm
    view model =
        div []
            [ CSS.startingStyleNode model.animState  -- Required for entry!
            , div
                (CSS.transitionAttributes "my-element" model.animState)
                [ text "I'll animate when I appear" ]
            ]
    ```

!!! note "Browser Support"
    `transition-behavior` and `@starting-style` are supported in Chrome 117+, Firefox 129+, and Safari 17.4+.

## 3D Transforms

Fully supports 3D animations. See [3D Animations](../concepts/3d.md) for more information.

## Controlling Animations

For details on `stop` and `reset` controls, see [Controlling CSS Transitions](../concepts/controlling-animations/css/transitions.md).

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animations configurations |
| `TransitionEvent` | Events received during a transitions lifecycle |
| `TransformOrder` | Custom transform ordering |

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `List (String, String, String) -> AnimState` | Create initial animation state |
| `builder` | `AnimState -> AnimBuilder` | Get builder for defining animations |
| `animate` | `AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Generate final animation state |
| `fireAndForget` | `(AnimBuilder -> AnimBuilder) -> AnimState` | Fire-and-forget animation |

### View Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `transitionAttributes` | `String -> AnimState -> List (Html.Attribute msg)` | Get the transition attributes for an element |
| `transitionEvents` | `String -> (TransitionEvent -> msg) -> List (Attribute msg)` | Attach transition event listeners |
| `startingStyleNode` | `AnimState -> Html msg` | Generate `@starting-style` for entry animations |
| `startingStyleNodeFor` | `String -> AnimState -> Html msg` | Generate `@starting-style` for a specific element |

### Event Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `handleTransitionEvent` | `TransitionEvent -> AnimState -> AnimState` | Update AnimState after a transition event |

### Global Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (property units/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing function |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |
| `allowDiscreteTransitions` | `AnimBuilder -> AnimBuilder` | Enable `transition-behavior: allow-discrete` |

### Control Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `stop` | `String -> AnimState -> AnimState` | Jump to end state and stop |
| `reset` | `String -> AnimState -> AnimState` | Jump to start state and stop |

For complete API details, see the [Anim.Engine.CSS.Transitions](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-CSS-Transitions) documentation.
