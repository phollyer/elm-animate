# Background Color

Animate the background color of elements.

**Module:** `Anim.Property.CustomColor`

**GPU Accelerated:** ❌ No — triggers browser repaints.

Background color is animated using the `CustomColor` module with the `BackgroundColor` color property.

## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Property.CustomColor as PropertyColor
    import Anim.Extra.Color exposing (hex)

    highlightAnimation : AnimBuilder -> AnimBuilder
    highlightAnimation =
        PropertyColor.for "animGroup" PropertyColor.BackgroundColor
            >> PropertyColor.to (hex "#ffff00")
            >> PropertyColor.duration 300
            >> PropertyColor.build
    ```

See the [Properties Overview](overview.md) page for the shared usage patterns and the [Custom Color Property](custom-color-property.md) page for the full API reference.

## Next Steps

The Font Color property.

[Font Color →](font-color.md){ .md-button .md-button--primary }

