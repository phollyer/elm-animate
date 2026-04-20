# Custom Property

Animate any numeric CSS property with a unit. This is an escape hatch for CSS properties not covered by the first - class property modules.

**Module:** `Anim.Property`

**GPU Accelerated:** Depends on the CSS property being animated.

## Basic Usage

??? example "Show Source Code"

    ```elm
    import Anim.Property as Property

    borderRadiusAnimation : AnimBuilder -> AnimBuilder
    borderRadiusAnimation =
        Property.for "animGroup" "border-radius" "px"
            >> Property.to 24
            >> Property.duration 500
            >> Property.build
    ```

See the [Properties Overview](overview.md) page for the shared usage patterns.

!!! tip "When to use `Anim.Property`"
    Use this module when Elm Animate doesn't provide a first - class module for the CSS property you need to animate. For color - based properties, use [`Anim.PropertyColor`](custom-color-property.md) instead.

## API

### Types

| Type | Description |
| -------- | ----------- |
| `Builder` | Alias for the Internal builder used to configure the animation |
| `AnimGroupName` | Alias for the animation group name |

### Initialization

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `init` | `AnimGroupName -> String -> String -> Float -> AnimBuilder -> AnimBuilder` | Set the initial value — takes group name, CSS property name, CSS unit, and value |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `AnimGroupName -> String -> String -> AnimBuilder -> Builder` | Start building — takes group name, CSS property name, and CSS unit |
| `build` | `Builder -> AnimBuilder` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `from` | `Float -> Builder -> Builder` | Starting value |

### End Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `to` | `Float -> Builder -> Builder` | Ending value |

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

--8<-- "docs/properties/custom-property/border-radius.md:examples"

--8<-- "docs/properties/custom-property/border-radius.md:code"


## Next Steps

The Custom Color Property.

[Custom Color Property →](custom-color-property.md){ .md-button .md-button--primary }

Play with and learn from the examples.

[Examples →](../examples.md){ .md-button .md-button--primary }
