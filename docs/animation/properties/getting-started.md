# Properties

Elm Animate supports various CSS properties that can be animated.


## GPU Accelerated Properties

These properties are composited on the GPU for smooth 60fps performance with minimal battery impact.

| Property | Description | Module |
| ---------- | ------------- | -------- |
| [Opacity](../properties/opacity.md) | Fade elements in and out | `Anim.Property.Opacity` |
| [Rotate](../properties/rotate.md) | Rotate elements around X, Y, Z axes | `Anim.Property.Rotate` |
| [Scale](../properties/scale.md) | Scale elements on X, Y, Z axes | `Anim.Property.Scale` |
| [Translate](../properties/translate.md) | Move elements on X, Y, Z axes | `Anim.Property.Translate` |

!!! tip "3D Animations"
    Rotate, Scale, and Translate all support 3D transforms. See the [3D Animations](../concepts/3d.md) page for details.

## Non GPU Accelerated Properties

These properties trigger browser repaints and/or reflows. Use them when needed, but be mindful of performance with many simultaneous animations.

!!! warning "Size animations"
    Size changes also trigger browser reflows in addition to repaints. The scope depends on layout context — fixed-size containers can limit reflow to their subtree. Consider using `Scale` transforms when you don't need actual layout changes.

| Property | Description | Module | Impact |
| ---------- | ------------- | -------- | -------- |
| [Background Color](../properties/background-color.md) | Animate element backgrounds | `Anim.Property.BackgroundColor` | Repaint |
| [Font Color](../properties/font-color.md) | Animate text colors | `Anim.Property.FontColor` | Repaint |
| [Size](../properties/size.md) | Animate width and height | `Anim.Property.Size` | Reflow + Repaint |

## Custom Properties

For CSS properties not covered by the modules above, Elm Animate provides two escape hatches:

| Module | Description | Value Type |
| ------ | ----------- | ---------- |
| [`Anim.Property.Custom`](../properties/custom-property.md) | Animate any numeric CSS property with a unit | `Float` |
| [`Anim.Property.CustomColor`](../properties/custom-color-property.md) | Animate any color CSS property | `Color` |

??? example "View Source Code"

    ```elm
    import Anim.Property.Custom as Property
    import Anim.Property.CustomColor as PropertyColor
    import Anim.Extra.Color as Color

    borderRadiusAnimation : AnimBuilder -> AnimBuilder
    borderRadiusAnimation =
        Property.for "box" "border-radius" "px"
            >> Property.to 24
            >> Property.build

    borderColorAnimation : AnimBuilder -> AnimBuilder
    borderColorAnimation =
        PropertyColor.for "box" PropertyColor.BorderColor
            >> PropertyColor.to (Color.rgb 255 0 0)
            >> PropertyColor.build
    ```

## Property Functions

Each property module provides functions tailored to its dimensions:

| Dimensions | Property | Functions Include |
| ---------- | -------- | ------------------- |
| Single value | Opacity | `init`, `to` |
| Two values | Size (W×H) | `init`, `initW`, `initH`, `to`, `toW`, `toH` |
| Three values | Translate (X,Y,Z) | `init`, `initX`, `initXY`, `initYZ`, `initXYZ`, `to`, `toX`, `toXY`, etc. |

See each property's documentation for the full function list.

## Property Defaults

Each property also uses sensible defaults for any values that have not been set:

| Property | Default |
| -------- | :-----: |
| Opacity | 1 |
| FontColor | opaque black |
| BackgroundColor | transparent white |

See each property's documentation for more info.

## Next Steps

Now that you understand the basics of properties, continue to the full properties reference.

[Properties Overview →](../properties/overview.md){ .md-button .md-button--primary }


