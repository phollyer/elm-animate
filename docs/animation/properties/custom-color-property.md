# Custom Color Property

Animate any color CSS property. This is an escape hatch for color CSS properties not covered by the first-class property modules.

**Module:** `Anim.Property.CustomColor`

**GPU Accelerated:** No

## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Extra.Color as Color
    import Anim.Property.CustomColor as PropertyColor

    borderColorAnimation : AnimBuilder -> AnimBuilder
    borderColorAnimation =
        PropertyColor.for "animGroup" PropertyColor.BorderColor
            >> PropertyColor.to (Color.rgb 255 0 0)
            >> PropertyColor.duration 500
            >> PropertyColor.build
    ```

See the [Properties Overview](overview.md) page for the shared usage patterns.

!!! tip "When to use `Anim.Property.CustomColor`"
    Use this module when Elm Animate doesn't provide a first-class module for the color CSS property you need to animate. For numeric properties with units, use [`Anim.Property.Custom`](custom-property.md) instead.

## API

### Types

| Type | Description |
| -------- | ----------- |
| `Builder` | Alias for the Internal builder used to configure the animation |
| `AnimGroupName` | Alias for the animation group name |
| `ColorProperty` | Typed property names (`BackgroundColor`, `AccentColor`, `TextColor`, `BorderColor`, `BorderTopColor`, `BorderRightColor`, `BorderBottomColor`, `BorderLeftColor`, `BorderBlockColor`, `BorderBlockStartColor`, `BorderBlockEndColor`, `BorderInlineColor`, `BorderInlineStartColor`, `BorderInlineEndColor`, `OutlineColor`, `TextDecorationColor`, `TextEmphasisColor`, `CaretColor`, `Fill`, `Stroke`, `StopColor`, `FloodColor`, `LightingColor`, `ColumnRuleColor`, `CustomColorProperty String`) |

### Initialization

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `init` | `AnimGroupName -> ColorProperty -> Color -> AnimBuilder -> AnimBuilder` | Set the initial color — takes group name, typed color property, and color |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `AnimGroupName -> ColorProperty -> AnimBuilder -> Builder` | Start building — takes group name and typed color property |
| `build` | `Builder -> AnimBuilder` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `from` | `Color -> Builder -> Builder` | Starting color |

### End Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `to` | `Color -> Builder -> Builder` | Ending color |

### Timing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `delay` | `Int -> Builder -> Builder` | The delay in ms before the animation starts |
| `duration` | `Int -> Builder -> Builder` | The duration in ms that the animation lasts for |
| `speed` | `Float -> Builder -> Builder` | The rate of change per second |

### Easing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `easing` | `Easing -> Builder -> Builder` | Add natural motion |


## Example

--8<-- "docs/animation/properties/custom-color-property/border-color.md:examples"

--8<-- "docs/animation/properties/custom-color-property/border-color.md:code"


## Next Steps

Learn about animating with Discrete Properties.

[Discrete Properties →](../concepts/discrete-properties.md){ .md-button .md-button--primary }
