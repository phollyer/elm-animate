# Custom Color Property

Animate any color CSS property. This is an escape hatch for color CSS properties not covered by the first-class property modules.

**Module:** `Anim.PropertyColor`

**GPU Accelerated:** No

## Basic Usage

??? example "Show Source Code"

    ```elm
    import Anim.Extra.Color as Color
    import Anim.PropertyColor as PropertyColor

    borderColorAnimation : AnimBuilder -> AnimBuilder
    borderColorAnimation =
        PropertyColor.for "animGroup" "border-color"
            >> PropertyColor.to (Color.rgb 255 0 0)
            >> PropertyColor.duration 500
            >> PropertyColor.build
    ```

See the [Properties Overview](overview.md) page for the shared usage patterns.

!!! tip "When to use `Anim.PropertyColor`"
    Use this module when Elm Animate doesn't provide a first-class module for the color CSS property you need to animate. For numeric properties with units, use [`Anim.Property`](custom-property.md) instead.

## API

### Types

| Type | Description |
| -------- | ----------- |
| `Builder` | Alias for the Internal builder used to configure the animation |
| `AnimGroupName` | Alias for the animation group name |

### Initialization

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `init` | `AnimGroupName -> String -> Color -> AnimBuilder -> AnimBuilder` | Set the initial color — takes group name, CSS property name, and color |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `AnimGroupName -> String -> AnimBuilder -> Builder` | Start building — takes group name and CSS property name |
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

--8<-- "docs/properties/custom-color-property/border-color.md:examples"

--8<-- "docs/properties/custom-color-property/border-color.md:code"


## Next Steps

Check out the Properties Overview.

[Properties Overview →](overview.md){ .md-button .md-button--primary }

Play with and learn from the examples.

[Examples →](../examples.md){ .md-button .md-button--primary }
