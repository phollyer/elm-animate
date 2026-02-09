# CSS Transitions Engine

The CSS Transitions Engine uses native browser CSS transitions for simple A→B property animations. The browser handles all rendering, providing excellent performance with minimal setup.


## Basic Usage

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Transitions/BasicUsage/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/Transitions/BasicUsage/index.html){ .md-button target="_blank" }

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
                        Transitions.animate model.animState moveToNewPosition
                in
                ( { model | animState = newAnimState }, Cmd.none )
    ```

## Event Handling

CSS transitions generate events throughout their lifecycle. Use these events to chain animations, update state, or trigger follow-up actions.

1. Create a `Msg` type variant for your transition events.

    ??? example "View Source Code"

        ```elm
        type Msg
            = GotTransitionEvent Transitions.Event
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
        update msg model =
            case msg of
                GotTransitionEvent event ->
                    let
                        newModel =
                            { model | animState = Transitions.handleEvent event model.animState}
                    in
                    case event of
                        Transitions.Ended "box" ->
                            -- Animation complete
                            (newModel, Cmd.none)

                        Transitions.Started "box" ->
                            -- Animation started
                            (newModel, Cmd.none)

                        _ ->
                            ( newModel, Cmd.none )
        ```

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

=== "Exit Animations (Hiding)"

    **Exit animations work automatically** with just `allowDiscrete`.
    
    When transitioning TO `display: none`, the browser keeps the element visible during
    the transition, then hides it at the end.
    
    ```elm
    -- This just works™
    Transitions.animate model.animState <|
        Transitions.allowDiscrete >> fadeOut
    ```

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

## 3D Transforms

Fully supports 3D animations. See [3D Animations](../concepts/3d.md) for more information.

## Controlling Animations

For details on `stop` and `reset` controls, see [Controlling CSS Transitions](../concepts/controlling-animations/transitions.md).

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animations configurations |
| `Event` | Events received during a transitions lifecycle |
| `TransformOrder` | Custom transform ordering |

### Core Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `List (AnimBuilder -> AnimBuilder) -> AnimState` | Create initial animation state |
| `animate` | `AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Generate final animation state |
| `fireAndForget` | `(AnimBuilder -> AnimBuilder) -> AnimState` | Fire-and-forget animation |

### View Functions

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `attributes` | `String -> AnimState -> List (Html.Attribute msg)` | Get the transition attributes for an element |
| `events` | `String -> (Event -> msg) -> List (Attribute msg)` | Attach transition event listeners |

### Event Functions

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `handleEvent` | `Event -> AnimState -> AnimState` | Update AnimState after a transition event |

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
