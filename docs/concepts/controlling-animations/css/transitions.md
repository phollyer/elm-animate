# Controlling CSS Transitions

The CSS Engine provides partial programmatic control over CSS transitions. _This is a limitation of CSS itself, not the engine_.

You can `stop`, `reset`, and `restart` animations at any time. For `pause` and `resume` functionality, use [Keyframe Animations](keyframes.md), or switch to either the [Sub](../sub.md) Engine or the [WAAPI](../waapi.md) Engine.

## Available Controls

| Function | Behavior |
| ---------- | ---------- |
| `stop` | Jump instantly to the animation's **end state** and stop |
| `reset` | Jump instantly to the animation's **start state** and stop |
| `restart` | Reset to start state, then begin playing the animation again |

## Live Example

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/CSS/Controls/Transitions/Main.elm"
    ```

[:material-play-circle: Run this example](../../../examples/src/Engines/CSS/Controls/Transitions/index.html){ .md-button target="_blank" }

## Using Control Functions

All control functions follow the same pattern - they take an element ID and the current `AnimState`, returning an updated state and a command.

### Stop

Immediately jumps to the animation's end state and stops playback:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/CSS/Controls/Transitions/Main.elm:stop"
    ```

### Reset

Immediately jumps back to the animation's start state and stops:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/CSS/Controls/Transitions/Main.elm:reset"
    ```

### Restart

Resets to the start state, then immediately begins playing the animation again:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/CSS/Controls/Transitions/Main.elm:restart"
    ```



## Animation Events

When using control functions, the WAAPI engine fires lifecycle events that you can handle in your update function:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/CSS/Controls/Transitions/Main.elm:handleAnimationEvent"
    ```

### Event Types

| Event | Triggered When |
| ------- | ---------------- |
| `Started` | Animation begins playing |
| `Completed` | Animation reaches its end naturally |
| `Canceled` | Animation is stopped before completion |
| `Restarted` | Animation is restarted |

## Best Practices

!!! tip "Always update AnimState"
    Control functions return a new `AnimState` that reflects the pending operation. Always update your model with this new state to keep Elm and JavaScript synchronized.

!!! tip "Handle events for UI feedback"
    Use animation events to update UI elements like status indicators, enable/disable buttons, or trigger subsequent animations.

!!! tip "Pause vs Stop"
    Use `pause` when you want to temporarily freeze an animation and resume later. Use `stop` when the animation should jump to its final state immediately.
