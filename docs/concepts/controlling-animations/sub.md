# Controlling Sub Animations

The Sub Engine provides full programmatic control over running animations. You can `stop`,  `reset`, `restart`, `pause` and `resume`, animations at any time.

## Available Controls

| Function | Behavior |
| ---------- | ---------- |
| `stop` | Jump instantly to the animation's **end state** and stop |
| `reset` | Jump instantly to the animation's **start state** and stop |
| `restart` | Reset to start state, then begin playing the animation again |
| `pause` | Freeze the animation at its current position |
| `resume` | Continue a paused animation from where it was frozen |

## Live Example

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/SubEngine/Main.elm"
    ```

[:material-play-circle: Run this example](../../examples/src/Concepts/ControllingAnimations/SubEngine/index.html){ .md-button target="_blank" }

## Using Control Functions

All control functions follow the same pattern - they take an element ID and the current `AnimState`, returning an updated state and a command.

### Stop

Immediately jumps to the animation's end state and stops playback:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/SubEngine/Main.elm:stop"
    ```

### Reset

Immediately jumps back to the animation's start state and stops:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/SubEngine/Main.elm:reset"
    ```

### Restart

Resets to the start state, then immediately begins playing the animation again:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/SubEngine/Main.elm:restart"
    ```



### Pause

Freezes the animation at its current position. The animation can be resumed later:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/SubEngine/Main.elm:pause"
    ```

### Resume

Continues a paused animation from exactly where it was frozen:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/SubEngine/Main.elm:resume"
    ```

## Next Steps

Controlling WAAPI Animations.

[Controlling WAAPI Animations →](waapi.md){ .md-button .md-button--primary }

