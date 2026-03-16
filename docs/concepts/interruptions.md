# Mid-Flight Interruptions

When an animation is already running and you trigger a new animation on the same element, the result depends on the engine and the properties involved.

## Simple Case - Same Property

Triggering an animation on an element with a property that's already in mid-flight.

| Engine | Result | Description |
| ------ | :----: | ----------- |
| Keyframes | ❌ | Jumps to the end state of the current animation, then begins the new one from there |
| Transitions | ✅ | Smoothly transitions from the current value to the new end value |
| Sub | ✅ | Smoothly transitions from the current value to the new end value |
| WAAPI | ✅ | Smoothly transitions from the current value to the new end value |

The following example uses the `Translate` property because the behaviour is more visually apparent, but all properties exhibit the same behaviour.

--8<-- "docs/concepts/interruptions/examples.md:translate-examples"

### Freezing Axes with `freeze*`

The example above demonstrates the default behaviour, but this can be changed with the family of `freeze*` functions.

The `freeze*` functions let you opt in to freezing specific axes at their current mid-flight values. When a frozen axis is encountered during animation, it holds its current position while only the specified axes animate to new targets.

In the examples below, try the same sequence — click "Move Right" then "Move Up". The box now travels straight up from wherever it is, because `freezeX` holds the X axis at its current position.

--8<-- "docs/concepts/interruptions/examples.md:translate-freeze-examples"

The only difference from the examples above is adding a freeze function before the property builder:

```elm
-- Without freeze: X continues toward its previous target
moveUp =
    moveBox (Translate.toY 0)

-- With freeze: X holds at its current position
moveUp =
    moveBox (Sub.freezeX [ Sub.translate ]) (Translate.toY 0)
```

`freeze*` is available on the **Sub** and **WAAPI** engines.

## Different Properties

When you call `animate` with properties that aren't currently animating, the new animation runs alongside existing ones.

In the examples below, the first click animates translate, rotate, and background color together. Clicking again while moving only changes translate — rotate and color continue uninterrupted to their original targets.

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
