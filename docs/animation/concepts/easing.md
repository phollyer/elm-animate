# Animation Easing

Easing controls how property values accelerate and decelerate during animation.

## Animation Example

??? example "View Source Code"

    ```elm
    Translate.for "cardAnim"
        >> Translate.toX 320
        >> Translate.duration 450
        >> Translate.easing QuintOut
        >> Translate.build
    ```

!!! tip "Default pick"
    For most UI animations, start with `QuintOut` or `CubicOut`.

--8<-- "docs/getting-started/shared/easing-reference.md"

## Choosing an Easing for Animation

| Use Case | Recommended Easing | Why |
| -------- | ------------------ | --- |
| Entering elements | `QuintOut` / `CubicOut` | Arrives fast, settles smoothly |
| Exiting elements | `QuintIn` / `CubicIn` | Leaves with acceleration |
| State-to-state transitions | `QuintInOut` / `CubicInOut` | Balanced easing at both ends |
| Playful motion moments | `BackOut` / `ElasticOut` / `BounceOut` | Adds character and energy |

!!! tip "For entrances"
    Use `Out` variants — elements should arrive and settle smoothly.

!!! tip "For exits"
    Use `In` variants — elements should accelerate away.

!!! tip "For state changes"
    Use `InOut` variants — smooth transitions between states.

## Next Steps

Continue to transform composition.

[Transform Order →](../concepts/transform-order.md){ .md-button .md-button--primary }
