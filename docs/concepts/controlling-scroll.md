# Controlling Scroll Animations

The Scroll Engine provides full programmatic control over running scroll animations when using stateful subscription-based scrolling. You can `stop`, `reset`, `restart`, `pause` and `resume` scroll animations at any time.

!!! note "Stateful Scrolling Only"
    Control functions are only available when using the [`Scroll.Sub`](../engines/scroll.md) module for stateful subscription-based scrolling. Fire-and-forget [`Scroll.Cmd`](../engines/scroll.md) and task-based [`Scroll.Task`](../engines/scroll.md) scrolling cannot be controlled after they begin.

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

<iframe src="../../examples/src/Engines/Scroll/ControllingScrolls/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

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

Create different effects by controlling the transform order.

[Transform Ordering →](transform-order.md){ .md-button .md-button--primary }


