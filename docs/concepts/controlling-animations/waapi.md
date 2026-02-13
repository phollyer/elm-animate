# Controlling WAAPI Animations

The WAAPI Engine provides full programmatic control over running animations through the Web Animations API. You can `stop`, `reset`, `restart`, `pause` and `resume` animations at any time.

## Available Controls

| Function | Behavior |
| ---------- | ---------- |
| `stop` | Jump instantly to the animation's **end state** and stop |
| `pause` | Freeze the animation at its current position |
| `resume` | Continue a paused animation from where it was frozen |
| `reset` | Jump instantly to the animation's **start state** and stop |
| `restart` | Reset to start state, then begin playing the animation again |

## Live Example

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/WaapiEngine/Main.elm"
    ```

[:material-play-circle: Run this example](../../examples/src/Concepts/ControllingAnimations//WaapiEngine/index.html){ .md-button target="_blank" }

## Using Control Functions

All control functions follow the same pattern - they take an element ID and the current `AnimState`, returning an updated state and a command.

### Stop

Immediately jumps to the animation's end state and stops playback:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/WaapiEngine/Main.elm:stop"
    ```

### Reset

Immediately jumps back to the animation's start state and stops:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/WaapiEngine/Main.elm:reset"
    ```

### Restart

Resets to the start state, then immediately begins playing the animation again:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/WaapiEngine/Main.elm:restart"
    ```


### Pause

Freezes the animation at its current position. The animation can be resumed later:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/WaapiEngine/Main.elm:pause"
    ```

### Resume

Continues a paused animation from exactly where it was frozen:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/WaapiEngine/Main.elm:resume"
    ```

## Next Steps

Controlling Scroll Animations.

[Controlling Scroll Animations →](scroll.md){ .md-button .md-button--primary }
