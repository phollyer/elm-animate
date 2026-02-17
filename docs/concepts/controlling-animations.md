# Controlling Animations

All animation engines provide control functions to manipulate running animations. The available controls vary by engine.

## Control Functions

| Function | Transitions | Keyframes | Sub | WAAPI |
| -------- | :---------: | :-------: | :-: | :---: |
| `stop` | ✓ | ✓ | ✓ | ✓ |
| `reset` | ✓ | ✓ | ✓ | ✓ |
| `restart` | | ✓ | ✓ | ✓ |
| `pause` | | ✓ | ✓ | ✓ |
| `resume` | | ✓ | ✓ | ✓ |

All control functions take an animation group name and the current `AnimState`, returning the updated state.

## Stop

Immediately jumps to the animation's **end state** and stops playback.

=== "Transitions"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/TransitionsEngine/Main.elm:stop"
    ```

=== "Keyframes"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/KeyframesEngine/Main.elm:stop"
    ```

=== "Sub"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/SubEngine/Main.elm:stop"
    ```

=== "WAAPI"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/WaapiEngine/Main.elm:stop"
    ```

## Reset

Immediately jumps back to the animation's **start state** and stops.

=== "Transitions"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/TransitionsEngine/Main.elm:reset"
    ```

=== "Keyframes"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/KeyframesEngine/Main.elm:reset"
    ```

=== "Sub"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/SubEngine/Main.elm:reset"
    ```

=== "WAAPI"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/WaapiEngine/Main.elm:reset"
    ```

## Restart

Resets to the start state, then immediately begins playing the animation again.

!!! warning "Not available for Transitions"
    CSS Transitions don't support restart. Use `reset` followed by `animate` instead.

=== "Keyframes"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/KeyframesEngine/Main.elm:restart"
    ```

=== "Sub"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/SubEngine/Main.elm:restart"
    ```

=== "WAAPI"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/WaapiEngine/Main.elm:restart"
    ```

## Pause

Freezes the animation at its current position. The animation can be resumed later.

!!! warning "Not available for Transitions"
    CSS Transitions don't support pausing. Consider using a different engine if you need pause/resume.

=== "Keyframes"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/KeyframesEngine/Main.elm:pause"
    ```

=== "Sub"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/SubEngine/Main.elm:pause"
    ```

=== "WAAPI"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/WaapiEngine/Main.elm:pause"
    ```

## Resume

Continues a paused animation from exactly where it was frozen.

!!! warning "Not available for Transitions"
    CSS Transitions don't support resuming. Consider using a different engine if you need pause/resume.

=== "Keyframes"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/KeyframesEngine/Main.elm:resume"
    ```

=== "Sub"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/SubEngine/Main.elm:resume"
    ```

=== "WAAPI"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/WaapiEngine/Main.elm:resume"
    ```

## Live Examples

Try the control functions in action:

- [:material-play-circle: Transitions Engine](../examples/src/Concepts/ControllingAnimations/TransitionsEngine/index.html){ target="_blank" }
- [:material-play-circle: Keyframes Engine](../examples/src/Concepts/ControllingAnimations/KeyframesEngine/index.html){ target="_blank" }
- [:material-play-circle: Sub Engine](../examples/src/Concepts/ControllingAnimations/SubEngine/index.html){ target="_blank" }
- [:material-play-circle: WAAPI Engine](../examples/src/Concepts/ControllingAnimations/WaapiEngine/index.html){ target="_blank" }

## CSS Transitions Limitations

The Transitions Engine has limited control because of CSS itself, not the engine:

!!! warning "Reset before re-animating"
    CSS transitions can only run once. To replay an animation after completion, call `reset` to return to the start state before calling `animate` again.

!!! warning "Avoid DOM changes during animation start"
    CSS transitions are sensitive to DOM reflows. If other DOM elements are added or removed in the same render cycle as starting an animation, the browser may skip the transition entirely. Keep DOM structure stable when triggering animations.

## Scroll Engine Controls

The Scroll Engine has its own control functions for scroll animations. See [Controlling Scroll Animations](controlling-animations/scroll.md) for details.
