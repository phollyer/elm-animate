# Mid-Flight Interruptions

When an animation is running on an element and you trigger another animation on the same element, the result depends on the engine and the properties involved.

## Engine Summary

| Engine | Same Property | Multiple Properties |
| ------ | ------------- | ------------------- |
| Transitions | ✅ Redirects from current position | ✅ Run side by side |
| Keyframes | ❌ Jumps to new animation start | ❌ Replaces all properties |
| Sub | ✅ Redirects from current position | ✅ Run side by side |
| WAAPI | ✅ Redirects from current position | ✅ Run side by side |

## Same Property

**Scenario**: A property is animating on an element, and you trigger another animation for the same property on the same element.

The following example uses the `Color` property to demonstrate the behaviour. Click a button to change the color; the color change will take 3 seconds, click another color button before the change is complete to redirect to a new color.

--8<-- "docs/concepts/interruptions/examples.md:color-examples"

## Multiple Properties

### Interrupting One of Many

**Scenario**: Multiple properties animating together and you interrupt one of them with another animation.

In the examples below, clicking a button while the box is stationary animates translate, rotate, and background color together. Clicking again while the box is moving only redirects translate — rotate and color continue uninterrupted to their original targets.

--8<-- "docs/concepts/interruptions/examples.md:multi-property-examples"

**Transitions**, **Sub**, and **WAAPI** handle each property independently — rotate and color finish their animations while translate redirects to the new target.

**Keyframes** replaces the entire animation — all properties restart from the beginning. See [Keyframes Engine — Interrupting Animations](../engines/keyframes.md#interrupting-animations) for details.

### Adding Properties Mid-Flight

**Scenario**: One or more properties animating together, and you start animating one or more different properties on the same element.

In the examples below, the first click only animates translate. Clicking again while the box is moving adds rotate and color on top of the running translate animation.

--8<-- "docs/concepts/interruptions/examples.md:adding-properties-examples"

**Transitions**, **Sub**, and **WAAPI** layer the new properties alongside the running translate animation without disturbing it.

**Keyframes** replaces the entire animation — translate restarts along with the newly added properties.

### Properties with Multiple Axes

**Scenario**: Animating one axis, then animating another axis before it completes.

The following example uses the `Translate` property. Try clicking 'Move Right' followed by 'Move Up' before the animation completes. The new axis animation will be added to the current axis animation, and they will both complete together.

--8<-- "docs/concepts/interruptions/examples.md:translate-examples"

### Freezing Axes with `freeze*`

The example above demonstrates the default behaviour, but this can be changed with the family of `freeze*` functions.

The `freeze*` functions let you opt in to freezing specific axes at their current mid-flight values. When a frozen axis is encountered during animation, it holds its current position while only the specified axes animate to new targets.

In the examples below, try the same sequence — click "Move Right" then "Move Up". The box now travels straight up from wherever it is, because `freezeX` holds the X axis at its current position.

--8<-- "docs/concepts/interruptions/examples.md:translate-freeze-examples"

The only difference from the examples above is adding a freeze function before the property builder.

??? example "View Source Code"

    === "Sub"

        Without `freeze*`

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/InterruptingAnimations/Translate/Main.elm:WithoutFreeze"
        ```

        With `freeze*`

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/InterruptingAnimations/TranslateFreeze/Main.elm:WithFreeze"
        ```

    === "WAAPI"

        Without `freeze*`

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/InterruptingAnimations/Translate/Main.elm:WithoutFreeze"
        ```

        With `freeze*`

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/InterruptingAnimations/TranslateFreeze/Main.elm:WithFreeze"
        ```

`freeze*` is available on the **Sub** and **WAAPI** engines.

---

## Why This Matters

Mid-flight interruption is critical for responsive interfaces. Without it:

- Toggle buttons feel sluggish (must wait for animation to complete)
- Hover effects can't respond to rapid mouse movement
- Drag interactions feel disconnected from user input

With proper interruption support, animations feel directly connected to user actions.


## Next Steps

Now that you understand how animations handle interruptions, learn about their lifecycle events and how to react to them.

[Events →](events.md){ .md-button .md-button--primary }
