# Controlling Scroll Animations

The Scroll Engine provides full programmatic control over running scroll animations when using stateful subscription-based scrolling. You can `stop`, `reset`, `restart`, `pause` and `resume` scroll animations at any time.

!!! note "Stateful Scrolling Only"
    Control functions are only available when using stateful subscription-based scrolling via `animate`. Fire-and-forget `toCmd` and task-based `toTask` scrolling cannot be controlled after they begin.

## Available Controls

| Function | Behavior |
| ---------- | ---------- |
| `stop` | Jump instantly to the scroll **target position** and complete |
| `pause` | Freeze the scroll at its current position |
| `resume` | Continue a paused scroll from where it was frozen |
| `reset` | Jump instantly to the **start position** and stop |
| `restart` | Reset to start position, then begin scrolling again |

## Live Example

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Concepts/ControllingAnimations/ScrollEngine/Main.elm"
    ```

[:material-play-circle: Run this example](../../examples/src/Concepts/ControllingAnimations/ScrollEngine/index.html){ .md-button target="_blank" }

## Document vs Container

Each control function has two variants:

- **Document functions** (`stop`, `pause`, etc.) - Control document body scrolling
- **Container functions** (`stopContainer`, `pauseContainer`, etc.) - Control scrolling within specific containers

```elm
-- Stop document scrolling
let
    ( newState, cmd ) = Scroll.stop GotScrollMsg model.scrollAnimations
in
( { model | scrollAnimations = newState }, cmd )

-- Stop a specific container's scrolling
let
    ( newState, cmd ) = Scroll.stopContainer GotScrollMsg "my-scrollable-div" model.scrollAnimations
in
( { model | scrollAnimations = newState }, cmd )
```

## Using Control Functions

Control functions follow two patterns:

- **Pause/Resume** - Take the current `AnimState` and return an updated state
- **Stop/Reset/Restart** - Require a message wrapper and return `(AnimState, Cmd msg)` to issue immediate scroll commands

### Stop

Immediately jumps to the target scroll position and completes the animation:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/Controls/Main.elm:stop"
    ```

### Pause

Freezes the scroll at its current position. The scroll can be resumed later:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/Controls/Main.elm:pause"
    ```

### Resume

Continues a paused scroll from exactly where it was frozen:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/Controls/Main.elm:resume"
    ```

### Reset

Immediately jumps back to the starting scroll position and stops:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/Controls/Main.elm:reset"
    ```

### Restart

Resets to the start position, then immediately begins scrolling again:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/Controls/Main.elm:restart"
    ```

## Container-Specific Controls

For scrollable containers, use the container variants with the element ID:

```elm
-- Pause scrolling in a specific container
Scroll.pauseContainer "article-content" model.scrollAnimations

-- Resume scrolling in that container
Scroll.resumeContainer "article-content" model.scrollAnimations

-- Stop scrolling in a sidebar
let
    ( newState, cmd ) = Scroll.stopContainer GotScrollMsg "sidebar-nav" model.scrollAnimations
in
( { model | scrollAnimations = newState }, cmd )
```

## Next Steps

Now you know how to control the Engines, lets look at animating properties.

[Animating Properties →](../properties.md){ .md-button .md-button--primary }


