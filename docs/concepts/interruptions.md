# Mid-Flight Interruptions

When an animation is already running and you trigger a new one, the behavior depends on the engine you're using.

## Engines That Support Interruption

**Transitions**, **Sub**, and **WAAPI** handle mid-flight interruptions smoothly — but through different mechanisms.

### Transitions: Independent Per-Property Interruption

Transitions use individual CSS `translate` and `scale` properties, while rotation uses the composite `transform` property. Each has its own independent transition rule, so interruptions work correctly even when only **some** properties change — unchanged properties continue toward their original target undisturbed, while changed properties redirect from their current computed value.

See [Transitions Engine — Interrupting Animations](../engines/transitions.md#interrupting-animations) for details.

!!! note "The `from` value doesn't affect interruption"
    Even if you specify a `from` value, Transitions will always start from the browser's current computed value.

### Sub and WAAPI: `animate`

When you trigger a new animation, the engine reads the current value and uses it as the starting point.

If you provide a `from` value, that will be used as the starting point instead of the tracked current value.

### Example: Toggle Animation

A common pattern is toggling between two states. The animation redirects smoothly regardless of when the user triggers it:

??? example "View Source Code"

    === "Transitions"
        ```elm
        update msg model =
            case msg of
                GotToggle ->
                    let
                        newAnimState =
                            Transitions.animate model.animState <|
                                if model.isOpen then
                                    closePanel
                                else
                                    openPanel
                    in
                    ( { model 
                        | isOpen = not model.isOpen
                        , animState = newAnimState
                      }
                    , Cmd.none
                    )
        ```

    === "Sub"
        ```elm
        update msg model =
            case msg of
                GotToggle ->
                    let
                        newAnimState =
                            Sub.animate model.animState <|
                                if model.isOpen then
                                    closePanel
                                else
                                    openPanel
                    in
                    ( { model 
                        | isOpen = not model.isOpen
                        , animState = newAnimState
                      }
                    , Cmd.none
                    )
        ```

    === "WAAPI"
        ```elm
        update msg model =
            case msg of
                GotToggle ->
                    let
                        (newAnimState, cmd) =
                            WAAPI.animate model.animState <|
                                if model.isOpen then
                                    closePanel
                                else
                                    openPanel
                    in
                    ( { model 
                        | isOpen = not model.isOpen
                        , animState = newAnimState
                      }
                    , cmd
                    )
        ```

If the user toggles rapidly, the animation smoothly redirects from wherever it currently is.

## Engine That Doesn't Support Interruption

**Keyframes** don't support mid-flight redirection. Calling `animate` while a keyframe animation is running replaces the current animation — the element jumps to the start of the new animation rather than smoothly transitioning from its current position.

This is a fundamental limitation of CSS `@keyframes`:

- **No playhead access** — CSS provides no API to query where an animation currently is (e.g., "50% through the fade")
- **No progress events** — There's no event that reports intermediate values
- **Hardcoded keyframes** — The `@keyframes` rule defines fixed values; the browser can't start from an arbitrary midpoint

Even though Elm tracks the animation state, there is no way to know the current, mid-flight animated value. The browser runs the animation independently — which is exactly what makes Keyframes so performant — but it means the in-progress state isn't accessible.

If you need interruptible animations, use **Transitions**, **Sub**, or **WAAPI** instead.

## Why This Matters

Mid-flight interruption is critical for responsive interfaces. Without it:

- Toggle buttons feel sluggish (must wait for animation to complete)
- Hover effects can't respond to rapid mouse movement
- Drag interactions feel disconnected from user input

With proper interruption support, animations feel directly connected to user actions.

## Engine Support Summary

| Engine | Mid-Flight Interruption |
| ------ | ----------------------- |
| Transitions | ✅ Smooth — independent per-property transitions (see [details](../engines/transitions.md#interrupting-animations)) |
| Keyframes | ❌ Jumps to new animation start |
| Sub | ✅ Smooth with `animate` only |
| WAAPI | ✅ Smooth with `animate` only |


## Next Steps

Now that you can interrupt animations mid-flight, learn all about their lifecycle events, and how to react to them.

[Events →](events.md){ .md-button .md-button--primary }
