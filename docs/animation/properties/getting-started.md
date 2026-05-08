# Properties

Elm Motion provides built-in support for some of the most common animatable CSS properties, and allows you to animate any numeric or color CSS property through the `Custom` and `CustomColor` modules.


## GPU-Accelerated Properties

These properties are typically compositor-accelerated (usually GPU-backed) for smooth performance with minimal battery impact. This is highly reliable in practice, but not guaranteed in every browser, device, or rendering context.

They also operate outside the normal document flow — animating them does not trigger reflow or repaint, so surrounding elements are unaffected.

| Property | Description | Module |
| ---------- | ------------- | -------- |
| [Opacity](../properties/opacity.md) | Fade elements in and out | `Anim.Property.Opacity` |
| [Rotate](../properties/rotate.md) | Rotate elements around X, Y, Z axes | `Anim.Property.Rotate` |
| [Scale](../properties/scale.md) | Scale elements on X, Y, Z axes | `Anim.Property.Scale` |
| [Skew](../properties/skew.md) | Skew elements along X and Y axes | `Anim.Property.Skew` |
| [Translate](../properties/translate.md) | Move elements on X, Y, Z axes | `Anim.Property.Translate` |

!!! tip "3D Animations"
    Rotate, Scale, and Translate all support 3D transforms. See the [3D Animations](../concepts/3d.md) page for details.

## Non-GPU-Accelerated Properties

These properties trigger browser repaints and/or reflows. Use them when needed, but be mindful of performance with many simultaneous animations. They can also affect the layout of any surrounding elements if the property being animated causes the element's bounding box to change size.

| Property | Description | Module | Impact |
| ---------- | ------------- | -------- | -------- |
| [Size](../properties/size.md) | Animate width and height | `Anim.Property.Size` | Reflow + Repaint |
| [`Custom`](../properties/custom-property.md) | Animate any single numeric CSS property | `Anim.Property.Custom` | Property specific |
| [`CustomColor`](../properties/custom-color-property.md) | Animate any color CSS property | `Anim.Property.CustomColor` | Property specific |

??? example "View Source Code"

    ```elm
    import Anim.Property.Custom as Property exposing (Property(..))
    import Anim.Property.CustomColor as PropertyColor exposing (ColorProperty(..))
    import Anim.Extra.Color as Color

    borderRadiusAnimation : AnimBuilder -> AnimBuilder
    borderRadiusAnimation =
        Property.for "box" (BorderRadius "px")
            >> Property.to 24
            >> Property.build

    borderColorAnimation : AnimBuilder -> AnimBuilder
    borderColorAnimation =
        PropertyColor.for "box" BorderColor
            >> PropertyColor.to (Color.rgb 255 0 0)
            >> PropertyColor.build
    ```

## Property Functions

Each property module provides functions tailored to its dimensions:

| Dimensions | Property | Functions Include |
| ---------- | -------- | ------------------- |
| Single value | Opacity / Custom / CustomColor | `init`, `from`, `to` etc |
| Two values | Size (W×H) | `initHW`, `initH`, `initW`, `toHW`, `toH`, `toW` etc |
| Two values | Skew (X,Y) | `initXY`, `initX`, `initY`, `toXY`, `toX`, `toY` etc |
| Three values | Translate (X,Y,Z) | `initXYZ`, `initXY`, `initX`, `initYZ`, `initY`, `initZ`, `toXYZ`, `toXY`, `toX`, etc. |
| Three values | Rotate (X,Y,Z) | `initXYZ`, `initXY`, `initX`, `initYZ`, `initY`, `initZ`, `toXYZ`, `toXY`, `toX`, etc. |
| Three values | Scale (X, Y, Z) | `initXYZ`, `initXY`, `initX`, `initYZ`, `initY`, `initZ`, `toXYZ`, `toXY`, `toX`, etc. |

See each property's documentation for the full function list.

## Property Defaults

Each property also uses sensible defaults for any values that have not been set:

See each property's documentation for more info.

## Next Steps

Now that you understand the basics of properties, continue to the full properties reference.

[Properties Overview →](../properties/overview.md){ .md-button .md-button--primary }


