# Controlling Animations

All animation engines provide control functions to manipulate running animations.

## Control Functions

| Function | Transition | Keyframe | Sub | WAAPI |
| -------- | :---------: | :-------: | :-: | :---: |
| `stop` | ✓ | ✓ | ✓ | ✓ |
| `reset` | ✓ | ✓ | ✓ | ✓ |
| `restart` | | ✓ | ✓ | ✓ |
| `pause` | | ✓ | ✓ | ✓ |
| `resume` | | ✓ | ✓ | ✓ |

The Transition Engine has limited control because of CSS itself, not the engine.

---

## Example

--8<-- "docs/animation/concepts/controlling-animations/drop-the-ball.md:page"


---

## Control Functions

All control functions take an animation group name and the current `AnimState`, returning the updated state, and sometimes a `Cmd msg`.

### Stop

Immediately jumps to the animation's **end state** and stops playback.

??? example "View Source Code"

    === "Transition"

        ```elm
        --8<-- "docs/examples/src/Animation/Transition/ControllingAnimations/Main.elm:stop"
        ```

    === "Keyframe"

        ```elm
        --8<-- "docs/examples/src/Animation/Keyframe/ControllingAnimations/Main.elm:stop"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/ControllingAnimations/Main.elm:stop"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Animation/WAAPI/ControllingAnimations/Main.elm:stop"
        ```

### Reset

Immediately jumps back to the animation's **start state** and stops.

??? example "View Source Code"

    === "Transition"

        ```elm
        --8<-- "docs/examples/src/Animation/Transition/ControllingAnimations/Main.elm:reset"
        ```

    === "Keyframe"

        ```elm
        --8<-- "docs/examples/src/Animation/Keyframe/ControllingAnimations/Main.elm:reset"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/ControllingAnimations/Main.elm:reset"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Animation/WAAPI/ControllingAnimations/Main.elm:reset"
        ```

### Restart

Resets to the start state, then immediately begins playing the animation again.

??? example "View Source Code"

    === "Keyframe"

        ```elm
        --8<-- "docs/examples/src/Animation/Keyframe/ControllingAnimations/Main.elm:restart"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/ControllingAnimations/Main.elm:restart"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Animation/WAAPI/ControllingAnimations/Main.elm:restart"
        ```

    CSS Transition don't support restart.


### Pause

Freezes the animation at its current position. The animation can be resumed later.

??? example "View Source Code"

    === "Keyframe"

        ```elm
        --8<-- "docs/examples/src/Animation/Keyframe/ControllingAnimations/Main.elm:pause"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/ControllingAnimations/Main.elm:pause"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Animation/WAAPI/ControllingAnimations/Main.elm:pause"
        ```

    CSS Transition don't support pause.

### Resume

Continues a paused animation from exactly where it was frozen.

??? example "View Source Code"

    === "Keyframe"

        ```elm
        --8<-- "docs/examples/src/Animation/Keyframe/ControllingAnimations/Main.elm:resume"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/ControllingAnimations/Main.elm:resume"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Animation/WAAPI/ControllingAnimations/Main.elm:resume"
        ```

    CSS Transition don't support resume.

---

## Next Steps

Learn about Timing for animations.

[Timing →](../concepts/timing.md){ .md-button .md-button--primary }

