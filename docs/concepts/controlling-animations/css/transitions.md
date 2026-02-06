# Controlling CSS Transitions

The CSS Engine provides minimal programmatic control over CSS transitions. _This is a limitation of CSS itself, not the engine_.

You can `stop` and `reset` animations but for `pause`, `resume` and `restart` functionality, use [Keyframe Animations](keyframes.md), or switch to either the [Sub](../sub.md) Engine or the [WAAPI](../waapi.md) Engine.

## Available Controls

| Function | Behavior |
| ---------- | ---------- |
| `stop` | Jump instantly to the animation's **end state** and stop |
| `reset` | Jump instantly to the animation's **start state** and stop |

## Live Example

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/CSS/Controls/Transitions/Main.elm"
    ```

[:material-play-circle: Run this example](../../../examples/src/Engines/CSS/Controls/Transitions/index.html){ .md-button target="_blank" }

## Using Control Functions

All control functions follow the same pattern - they take an element ID and the current `AnimState`, returning the updated state.

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

## Best Practices

!!! warning "Reset before re-animating"
    CSS transitions can only run once, . Therefore, if you wish to **replay/repeat** an animation after completion, you must call `reset` to return to the start state before calling `animate` again.

!!! warning "Avoid DOM changes during animation start"
    CSS transitions are sensitive to DOM reflows. If other DOM elements are added or removed in the same render cycle as starting an animation, the browser may skip the transition entirely. Keep DOM structure stable when triggering animations.

## Next Steps

Controlling CSS Keyframe Animations.

[Controlling Keyframe Animations →](keyframes.md){ .md-button .md-button--primary }

