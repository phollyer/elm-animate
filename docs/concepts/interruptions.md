# Mid-Flight Interruptions

When an animation is already running and you trigger a new animation on the same element, the result depends on the engine and the properties involved.

## Same Property

When you call `animate` with a property that's already mid-flight, the engine redirects from the current position to the new target.

In the examples below, click a different direction while the ball is still moving.

--8<-- "docs/concepts/interruptions/examples.md:translate-examples"

**Transitions**, **Sub**, and **WAAPI** all redirect smoothly from the current position to the new target.

**Keyframes** replaces the entire animation — the element jumps to the start of the new animation rather than transitioning from its current position. See [Keyframes Engine — Interrupting Animations](../engines/keyframes.md#interrupting-animations) for details on why this is a fundamental limitation of CSS `@keyframes`.

## Different Properties

When you call `animate` with properties that aren't currently animating, the new animation runs alongside existing ones.

In the examples below, the first click animates translate, rotate, and background color together. Clicking again while moving only changes translate — watch whether rotate and color continue or restart.

--8<-- "docs/concepts/interruptions/examples.md:multi-property-examples"

**Transitions**, **Sub**, and **WAAPI** run animations for different properties side by side. The rotate and color animations continue uninterrupted while translate redirects.

**Keyframes** replaces the entire animation — all properties restart from the beginning. See [Keyframes Engine — Interrupting Animations](../engines/keyframes.md#interrupting-animations) for details.

---

## Why This Matters

Mid-flight interruption is critical for responsive interfaces. Without it:

- Toggle buttons feel sluggish (must wait for animation to complete)
- Hover effects can't respond to rapid mouse movement
- Drag interactions feel disconnected from user input

With proper interruption support, animations feel directly connected to user actions.

## Engine Summary

| Engine | Same Property | Different Property |
| ------ | ------------- | ------------------ |
| Transitions | ✅ Redirects from current position | ✅ Run side by side |
| Keyframes | ❌ Jumps to new animation start | ❌ Replaces all properties |
| Sub | ✅ Redirects from current position | ✅ Run side by side |
| WAAPI | ✅ Redirects from current position | ✅ Run side by side |

## Next Steps

Now that you understand how animations handle interruptions, learn about their lifecycle events and how to react to them.

[Events →](events.md){ .md-button .md-button--primary }
