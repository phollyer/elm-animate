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

All control functions take an animation group name and the current `AnimState`, returning the updated state.

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

!!! warning "Not available for Transitions"
    CSS Transitions don't support restart. Use `reset` followed by `animate` instead.

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

## Pause

Freezes the animation at its current position. The animation can be resumed later.

!!! warning "Not available for Transitions"
    CSS Transitions don't support pausing. Consider using a different engine if you need pause/resume.

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

## Resume

Continues a paused animation from exactly where it was frozen.

!!! warning "Not available for Transitions"
    CSS Transitions don't support resuming. Consider using a different engine if you need pause/resume.

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


## Replaying The Same Animation

### CSS Transitions Limitations

CSS transitions trigger on property changes - the browser must see a property change to start a transition - therefore, repeatedly calling `animate` with the same animation configuration **will not** replay the transition because there is no state change.

To 'fix' this, call `reset` first, then in the next `update` loop call `animate`. This allows Elm to render the `reset` state before the `animate` state, and gives the Browser the state change it needs.

In Elm, if you call `reset` and `animate` in the same `update` loop, only the final `animate` state is rendered, so the browser never sees the `reset` state.

Use a small delay to ensure separate renders:

??? example "View Source Code"

    ```elm
    type Msg
        = ReplayAnimation
        | StartAnimation

    update msg model =
        case msg of
            ReplayAnimation ->
                ( { model | animState = Transitions.reset "boxAnim" model.animState }
                , Process.sleep 50 |> Task.perform (always StartAnimation)
                )

            StartAnimation ->
                ( { model | animState = Transitions.animate model.animState fadeIn }
                , Cmd.none
                )
    ```
    
    The 50ms delay ensures that Elm renders the `reset` state before the `animate` state. This provides the state change that the Browser requires in order to run the transition. 

## Live Examples

Try the control functions in action:

- [:material-play-circle: Transitions Engine](../examples/src/Concepts/ControllingAnimations/TransitionsEngine/index.html){ target="_blank" }
- [:material-play-circle: Keyframes Engine](../examples/src/Concepts/ControllingAnimations/KeyframesEngine/index.html){ target="_blank" }
- [:material-play-circle: Sub Engine](../examples/src/Concepts/ControllingAnimations/SubEngine/index.html){ target="_blank" }
- [:material-play-circle: WAAPI Engine](../examples/src/Concepts/ControllingAnimations/WaapiEngine/index.html){ target="_blank" }

## Next Steps

Now that you understand how to control animations, let's learn how to interrupt them mid-flight.

[Interrupting Animations →](interruptions.md){ .md-button .md-button--primary }

Or

Learn about controlling scrolls.

[Controlling Scrolls →](controlling-scroll.md){ .md-button .md-button--primary }

