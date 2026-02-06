# Controlling CSS Keyframe Animations

The CSS Engine provides full programmatic control over keyframe animations.
You can `stop`, `reset`, `restart`, `pause` and `resume` animations at any time.

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
    --8<-- "docs/examples/src/Engines/CSS/Controls/KeyframeAnimations/Main.elm"
    ```

[:material-play-circle: Run this example](../../../examples/src/Engines/CSS/Controls/KeyframeAnimations/index.html){ .md-button target="_blank" }

## Using Control Functions

All control functions follow the same pattern - they take an element ID and the current `AnimState`, returning the updated state.

### Stop

Immediately jumps to the animation's end state and stops playback:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/CSS/Controls/KeyframeAnimations/Main.elm:stop"
    ```


### Reset

Immediately jumps back to the animation's start state and stops:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/CSS/Controls/KeyframeAnimations/Main.elm:reset"
    ```

### Restart

Resets to the start state, then immediately begins playing the animation again:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/CSS/Controls/KeyframeAnimations/Main.elm:restart"
    ```

### Pause

Pauses the animation in it's current state:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/CSS/Controls/KeyframeAnimations/Main.elm:pause"
    ```


### Resume

Resumes a paused animation:

??? example "View Source Code"

    ```elm
    --8<-- docs/examples/src/Engines/CSS/Controls/KeyframeAnimations/Main.md:resume
    ```

## Best Practices

!!! tip "Handle events for UI feedback"
    Use animation events to update UI elements like status indicators, enable/disable buttons, or trigger subsequent animations.

## Next Steps

Controlling Sub Engine Animations.

[Controlling Sub Engine Animations →](../sub.md){ .md-button .md-button--primary }


