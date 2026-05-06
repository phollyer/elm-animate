# Controlling Scroll Animations

!!! note "Stateful Scrolling Only"
    Control functions are only available when using the [`Scroll.Sub`](../engines/sub.md) engine for stateful subscription-based scrolling. Fire-and-forget [`Scroll.Cmd`](../engines/cmd.md) and task-based [`Scroll.Task`](../engines/task.md) scrolling cannot be controlled after they begin.

The Sub Engine provides full programmatic control over running scroll animations. You can `stop`, `reset`, `restart`, `pause` and `resume` scroll animations at any time.


## Available Controls

| Document | Container | Behavior |
| -------- | --------- | -------- |
| `stop` | `stopContainer` | Jump instantly to the scroll **target position** and complete |
| `pause` | `pauseContainer` | Freeze the scroll at its current position |
| `resume` | `resumeContainer` | Continue a paused scroll from where it was frozen |
| `reset` | `resetContainer` | Jump instantly to the **start position** and stop |
| `restart` | `restartContainer` | Reset to start position, then begin scrolling again |

--8<-- "docs/scroll/concepts/controlling-scrolls/scroll-to-section.md"

## Using Control Functions

Control functions follow two patterns:

- **Stop/Reset/Restart** - Require a message wrapper and return `(ScrollState, Cmd msg)` to issue immediate scroll commands
- **Pause/Resume** - Take the current `ScrollState` and return an updated state

### Stop

Immediately jumps to the target scroll position and completes the animation:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/Sub/ControllingScrolls/Main.elm:stop"
    ```

### Reset

Immediately jumps back to the starting scroll position and stops:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/Sub/ControllingScrolls/Main.elm:reset"
    ```

### Restart

Resets to the start position, then immediately begins scrolling again:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/Sub/ControllingScrolls/Main.elm:restart"
    ```


### Pause

Freezes the scroll at its current position. The scroll can be resumed later:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/Sub/ControllingScrolls/Main.elm:pause"
    ```

### Resume

Continues a paused scroll from exactly where it was frozen:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/Sub/ControllingScrolls/Main.elm:resume"
    ```

## Next Steps

Learn about Timing for scrolls.

[Timing →](../concepts/timing.md){ .md-button .md-button--primary }

