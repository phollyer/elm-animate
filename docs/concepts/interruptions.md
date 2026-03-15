# Mid-Flight Interruptions

When an animation is already running and you trigger a new one for the same property on the same element, the behaviour depends on the engine you're using.

**Desired Behaviour**: freeze current position and move to new target position

**Example**: ball is at (100, 100) mid-flight moving right, click 'Move Up', ball stops at (100, 100), and then translates up vertically to (100, 0).

In the examples below, click on another direction before the ball stops moving to see the behaviour of the engine.

--8<-- "docs/concepts/interruptions/examples.md:examples"

## Engines That Support Interruption

**Sub**, and **WAAPI** handle mid-flight interruptions smoothly.

**Transitions** will animate smoothly from the current browser computed value, to the new end target. The problem with Transitions, is that there is no way to detect the current mid-flight values in order to freeze then re-direct. So if the ball is moving right, and you click down, the ball will continue moving right, while it moves down to the the new target.

See [Transitions Engine — Interrupting Animations](../engines/transitions.md#interrupting-animations) for details.

!!! note "The `from` value doesn't affect interruption"
    Even if you specify a `from` value, Transitions will always start from the browser's current computed value.

## Engine That Doesn't Support Interruption

**Keyframes** don't support mid-flight redirection. Calling `animate` while a keyframe animation is running replaces the current animation — the element jumps to the start of the new animation rather than smoothly transitioning from its current position.

See [Keyframes Engine — Interrupting Animations](../engines/keyframes.md#interrupting-animations) for details on why this is a fundamental limitation of CSS `@keyframes`.

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
