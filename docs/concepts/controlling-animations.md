# Controlling Animations

All animation engines provide control functions to manipulate running animations. The available controls vary slightly by engine.

## Control Functions

| Function | Transitions | Keyframes | Sub | WAAPI |
| -------- | :---------: | :-------: | :-: | :---: |
| `stop` | ✓ | ✓ | ✓ | ✓ |
| `reset` | ✓ | ✓ | ✓ | ✓ |
| `restart` | | ✓ | ✓ | ✓ |
| `pause` | | ✓ | ✓ | ✓ |
| `resume` | | ✓ | ✓ | ✓ |

The Transitions Engine has limited control because of CSS itself, not the engine.

All control functions take an animation group name and the current `AnimState`, returning the updated state, and sometimes a `Cmd msg`.

## Stop

Immediately jumps to the animation's **end state** and stops playback.

??? example "View Source Code"

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

??? example "View Source Code"

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

??? example "View Source Code"

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

    CSS Transitions don't support restart.


## Pause

Freezes the animation at its current position. The animation can be resumed later.

??? example "View Source Code"

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

    CSS Transitions don't support pause.

## Resume

Continues a paused animation from exactly where it was frozen.

??? example "View Source Code"

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

    CSS Transitions don't support resume.

## Live Examples

Interactive demonstrations of animation control functions (stop, reset, restart, pause, resume) across all engines.

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/ControllingAnimations/Main.elm"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/ControllingAnimations/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/ControllingAnimations/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/ControllingAnimations/Main.elm"
        ```

=== "Transitions"

    <iframe src="../../examples/src/Engines/Transitions/ControllingAnimations/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Keyframes"

    <iframe src="../../examples/src/Engines/Keyframes/ControllingAnimations/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Sub"

    <iframe src="../../examples/src/Engines/Sub/ControllingAnimations/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "WAAPI"

    <iframe src="../../examples/src/Engines/WAAPI/ControllingAnimations/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

## Next Steps

Now that you understand how to control animations, let's learn how to interrupt them mid-flight.

[Interrupting Animations →](interruptions.md){ .md-button .md-button--primary }

Or

Learn about controlling scrolls.

[Controlling Scrolls →](controlling-scroll.md){ .md-button .md-button--primary }

