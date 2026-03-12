# Controlling Scroll Animations

The Scroll Engine provides full programmatic control over running scroll animations when using stateful subscription-based scrolling. You can `stop`, `reset`, `restart`, `pause` and `resume` scroll animations at any time.

!!! note "Stateful Scrolling Only"
    Control functions are only available when using stateful subscription-based scrolling via `animate`. Fire-and-forget `toCmd` and task-based `toTask` scrolling cannot be controlled after they begin.

## Available Controls

| Document | Container | Behavior |
| -------- | --------- | -------- |
| `stop` | `stopContainer` | Jump instantly to the scroll **target position** and complete |
| `pause` | `pauseContainer` | Freeze the scroll at its current position |
| `resume` | `resumeContainer` | Continue a paused scroll from where it was frozen |
| `reset` | `resetContainer` | Jump instantly to the **start position** and stop |
| `restart` | `restartContainer` | Reset to start position, then begin scrolling again |

## Live Example

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/ControllingScrolls/Main.elm"
    ```

[:material-play-circle: Run this example](../examples/src/Engines/Scroll/ControllingScrolls//index.html){ .md-button target="_blank" }

## Using Control Functions

Control functions follow two patterns:

- **Stop/Reset/Restart** - Require a message wrapper and return `(AnimState, Cmd msg)` to issue immediate scroll commands
- **Pause/Resume** - Take the current `AnimState` and return an updated state

### Stop

Immediately jumps to the target scroll position and completes the animation:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/ScrollEngine/Main.elm:stop"
    ```

### Reset

Immediately jumps back to the starting scroll position and stops:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/ScrollEngine/Main.elm:reset"
    ```

### Restart

Resets to the start position, then immediately begins scrolling again:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/ScrollEngine/Main.elm:restart"
    ```


### Pause

Freezes the scroll at its current position. The scroll can be resumed later:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/ScrollEngine/Main.elm:pause"
    ```

### Resume

Continues a paused scroll from exactly where it was frozen:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/ScrollEngine/Main.elm:resume"
    ```

## Next Steps

Now you know how to control scrolling, let's look at the Scroll Engine in more detail.

[Scroll Engine →](../engines/scroll.md){ .md-button .md-button--primary }


