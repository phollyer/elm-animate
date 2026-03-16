# Mid-Flight Interruptions

When an animation is already running and you trigger another animation on the same element, the behaviour depends on the properties being animated and the Engine being used.

1. **Same property** — the new animation targets a property that's already animating (e.g., translate → translate)
2. **Different properties** — the new animation targets a property that isn't currently animating (e.g., translate is running, you trigger scale)

## 1. Same Property

**Desired Behaviour**: freeze current position and move to new target position

**Example**: ball is at (100, 100) mid-flight moving right, click 'Move Up', ball stops at (100, 100), and then translates up vertically to (100, 0).

In the examples below, click on another direction before the ball stops moving to see the behaviour of the engine.

--8<-- "docs/concepts/interruptions/examples.md:translate-examples"

## 2. Different Properties

**Desired Behaviour**: freeze current position and move to new target position, rotation and color continue.

**Example**: ball is at (100, 100) mid-flight moving right, click 'Move Up', ball stops at (100, 100), and then translates up vertically to (100, 0), rotation and color continue to their targets uninterrupted.


--8<-- "docs/concepts/interruptions/examples.md:multi-property-examples"

---

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
