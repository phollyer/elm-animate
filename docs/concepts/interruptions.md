# Mid-Flight Interruptions

When an animation is already running and you trigger a new one, the behavior depends on the engine you're using.

## Engines That Support Interruption

**Transitions**, **Sub**, and **WAAPI** handle mid-flight interruptions smoothly — but through different mechanisms.

### Transitions: Always Smooth

Transitions redirect smoothly regardless of trigger type (`animate` or `fireAndForget`). The browser's CSS engine handles the interpolation — it always animates from the current computed value to the new target. No Elm-side tracking required.

### Sub and WAAPI: Requires `animate`

For **Sub** and **WAAPI**, smooth redirection requires using `animate` so the engine can track the current position. When you trigger a new animation:

1. The engine reads the current animated value from state
2. Uses that as the starting point for the new animation
3. Begins animating toward the new target

With `fireAndForget`, the state resets — so mid-flight triggers will jump to the start value.

```elm
-- User clicks while fade-in is at 50% opacity
-- Engine starts from 0.5 and animates to new target
update msg model =
    case msg of
        GotClickWhileAnimating ->
            ( { model 
                | animState = Transitions.animate model.animState fadeOut 
              }
            , Cmd.none
            )
```

### Example: Toggle Animation

A common pattern is toggling between two states. The animation redirects smoothly regardless of when the user triggers it:

```elm
update msg model =
    case msg of
        GotToggle ->
            let
                animation =
                    if model.isOpen then
                        closePanel
                    else
                        openPanel
            in
            ( { model 
                | isOpen = not model.isOpen
                , animState = Transitions.animate model.animState animation
              }
            , Cmd.none
            )
```

If the user toggles rapidly, the animation smoothly reverses direction from wherever it currently is.

## Engine That Doesn't Support Interruption

**Keyframes** don't support mid-flight redirection. Calling `animate` while a keyframe animation is running replaces the current animation — the element jumps to the start of the new animation rather than smoothly transitioning from its current position.

This is a fundamental limitation of CSS `@keyframes`:

- **No playhead access** — CSS provides no API to query where an animation currently is (e.g., "50% through the fade")
- **No progress events** — Unlike `transitionend`, there's no event that reports intermediate values
- **Hardcoded keyframes** — The `@keyframes` rule defines fixed values; the browser can't start from an arbitrary midpoint

Even with state-tracked animations using `animate`, Elm has no way to know the current animated value. The browser runs the animation independently — which is exactly what makes Keyframes so performant — but it means the in-progress state isn't accessible.

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
| Transitions | ✅ Always smooth (browser handles it) |
| Keyframes | ❌ Jumps to new animation start |
| Sub | ✅ Smooth with `animate` only |
| WAAPI | ✅ Smooth with `animate` only |


## Next Steps

Learn about animating in 3D!!

[3D Animations →](3d.md){ .md-button .md-button--primary }
