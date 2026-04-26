# Font Color

Animate the text color of elements.

**Module:** `Anim.Property.CustomColor`

**GPU Accelerated:** ❌ No — triggers browser repaints.

Font/text color is animated using the `CustomColor` module with the `TextColor` color property.

## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Property.CustomColor as PropertyColor
    import Anim.Extra.Color exposing (hex)

    textHighlight : AnimBuilder -> AnimBuilder
    textHighlight =
        PropertyColor.for "animGroup" PropertyColor.TextColor
            >> PropertyColor.to (hex "#0066cc")
            >> PropertyColor.duration 300
            >> PropertyColor.build
    ```

See the [Properties Overview](overview.md) page for the shared usage patterns and the [Custom Color Property](custom-color-property.md) page for the full API reference.

## Next Steps

The Size property.

[Size →](size.md){ .md-button .md-button--primary }

