# Mid-Flight Interruptions

When an animation is already running and you trigger another animation on the same element, the behaviour depends on the properties being animated and the Engine being used.

1. **Same property** — the new animation targets a property that's already animating (e.g., translate → translate)
2. **Different properties** — the new animation targets a property that isn't currently animating (e.g., translate is running, you trigger scale)

## 1. Same Property

**Desired Behaviour**: freeze current position and move to new target position

**Example**: ball is at (100, 100) mid-flight moving right, click 'Move Up', ball stops at (100, 100), and then translates up vertically to (100, 0).

In the examples below, click on another direction before the ball stops moving to see the behaviour of the engine.

--8<-- "docs/concepts/interruptions/examples.md:translate-examples"

## Engines That Support Interruption

**Sub**, and **WAAPI** handle mid-flight interruptions smoothly.

**Transitions** will animate smoothly from the current browser computed value, to the new end target. The problem with Transitions, is that there is no way to detect the current mid-flight values in order to freeze then re-direct. So if the ball is moving right, and you click down, the ball will continue moving right, while it moves down to the the new target.

See [Transitions Engine — Interrupting Animations](../engines/transitions.md#interrupting-animations) for details.

!!! note "The `from` value doesn't affect interruption"
    Even if you specify a `from` value, Transitions will always start from the browser's current computed value.

## Engine That Doesn't Support Interruption

**Keyframes** don't support mid-flight redirection. Calling `animate` while a keyframe animation is running replaces the current animation — the element jumps to the start of the new animation rather than smoothly transitioning from its current position.

See [Keyframes Engine — Interrupting Animations](../engines/keyframes.md#interrupting-animations) for details on why this is a fundamental limitation of CSS `@keyframes`.

## 2. Different Properties

When the box is stationary, clicking a direction animates translate, rotate, and background color together. When it's already moving, only translate redirects — rotate and color continue to their targets independently.

--8<-- "docs/concepts/interruptions/examples.md:multi-property-examples"

**Transitions**, **Sub**, and **WAAPI** all run different-property animations side by side. If translate is mid-flight and you trigger only translate, the rotate and color animations continue uninterrupted.

**Keyframes** does not — calling `animate` with any properties replaces the entire animation. The rotate and color jump back to their starting values and restart alongside the new translate.

## Why This Matters

Mid-flight interruption is critical for responsive interfaces. Without it:

- Toggle buttons feel sluggish (must wait for animation to complete)
- Hover effects can't respond to rapid mouse movement
- Drag interactions feel disconnected from user input

With proper interruption support, animations feel directly connected to user actions.

## Engine Support Summary

| Engine | Same Property | Different Property |
| ------ | ------------- | ------------------ |
| Transitions | ✅ Smooth from current computed value (see [details](../engines/transitions.md#interrupting-animations)) | ✅ Run side by side |
| Keyframes | ❌ Jumps to new animation start | ❌ Cancels running animation |
| Sub | ✅ Freeze + redirect | ✅ Run side by side |
| WAAPI | ✅ Freeze + redirect | ✅ Run side by side |


## Next Steps

Now that you can interrupt animations mid-flight, learn all about their lifecycle events, and how to react to them.

[Events →](events.md){ .md-button .md-button--primary }
