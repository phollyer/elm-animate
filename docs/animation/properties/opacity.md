# Opacity

Fade elements in and out by animating their opacity value.

**Module:** `Anim.Property.Opacity`

**GPU Accelerated:** ✅ Usually — typically compositor / GPU accelerated, but browser and scene dependent.

## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Property.Opacity as Opacity

    fadeIn : AnimBuilder mode -> AnimBuilder mode
    fadeIn =
        Opacity.for "animGroup"
            >> Opacity.to 1
            >> Opacity.duration 500
            >> Opacity.build
    ```

See the [Properties Overview](overview.md) page for the shared usage patterns.

## API

### Types

| Type | Description |
| -------- | ----------- |
| `Builder` | Alias for the Internal builder used to configure the animation |
| `AnimGroupName` | Alias for the animation group name |

### Initialization

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `init` | `AnimGroupName -> Float -> AnimBuilder mode -> AnimBuilder mode` | Set the initial opacity value |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `AnimGroupName -> AnimBuilder mode -> Builder mode` | Start building |
| `build` | `Builder mode -> AnimBuilder mode` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `from` | `Float -> Builder -> Builder` | Starting opacity (0.0 to 1.0) |

### End Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `to` | `Float -> Builder -> Builder` | Ending opacity (0.0 to 1.0) |

### Timing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `delay` | `Int -> Builder -> Builder` | The delay in ms before the animation starts |
| `duration` | `Int -> Builder -> Builder` | The duration in ms that the animation lasts for |
| `speed` | `Float -> Builder -> Builder` | The rate of change per second - 0 -> 1 = 1 sec |

### Easing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `easing` | `Easing -> Builder -> Builder` | Add natural motion |


## Next Steps

The Rotate property.

[Rotate →](rotate.md){ .md-button .md-button--primary }

Non-GPU Accelerated Properties.

[Non-GPU →](non-gpu.md){ .md-button .md-button--primary }
