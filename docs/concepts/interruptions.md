# Mid-Flight Interruptions

When an animation is running on an element and you trigger another animation on the same element, the result depends on the engine and the properties involved.

## Engine Summary

| Engine | Same Property | Multiple Properties |
| ------ | ------------- | ------------------- |
| Transitions | ✅ Redirects from current position | ✅ Run side by side |
| Keyframes | ❌ Jumps to new animation start | ❌ Replaces all properties |
| Sub | ✅ Redirects from current position | ✅ Run side by side |
| WAAPI | ✅ Redirects from current position | ✅ Run side by side |

## Single Property

**Scenario**: A property is animating on an element, and you trigger another animation for the same property on the same element.

The following example uses the `BackgroundColor` property to demonstrate the behaviour for each Engine. Click a button to change the background color of the box; the color change will take 3 seconds, click another color button before the change is complete to redirect to a new color.

--8<-- "docs/concepts/interruptions/single-property.md:page"

## Multiple Properties

### Adding Properties Mid-Flight

**Scenario**: One property is animating, and another is added mid-flight.

The following example uses `Translate` and `BackgroundColor` to demonstrate the behaviour. Click either move button, then a color button before the move is complete to see the behaviour of the Engine.

--8<-- "docs/concepts/interruptions/multiple-properties.md:page"

### Properties with Multiple Axes

**Scenario**: Animating one axis, then animating another axis before it completes.

The following example uses the `Translate` property to demonstrate the behaviour. Click 'Move Right' followed by 'Move Up' before the animation completes to see the behaviour of the Engine.

--8<-- "docs/concepts/interruptions/multiple-axes.md:page"

### Freezing Axes with `freeze*`

The example above demonstrates the default behaviour, but this can be changed with the family of `freeze*` functions.

The `freeze*` functions let you opt in to freezing specific axes at their current mid-flight values. When a frozen axis is encountered during animation, it holds its current position while only the specified axes animate to new targets.

In the examples below, try the same sequence — click "Move Right" then "Move Up". The box now travels straight up from wherever it is, because `freezeX` holds the X axis at its current position.

--8<-- "docs/concepts/interruptions/freeze-axis.md:page"

`freeze*` is available on the **Sub** and **WAAPI** engines.

---

## Why This Matters

Mid-flight interruption is critical for responsive interfaces. Without it:

- Toggle buttons feel sluggish (must wait for animation to complete)
- Hover effects can't respond to rapid mouse movement
- Drag interactions feel disconnected from user input

With proper interruption support, animations feel directly connected to user actions.


## Next Steps

Now that you understand how animations handle interruptions, learn how to control them.

[Controlling Animations →](controlling-animations.md){ .md-button .md-button--primary }
