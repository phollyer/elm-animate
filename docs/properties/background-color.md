# Background Color

Animate the background color of elements.

**Module:** `Anim.Property.BackgroundColor`

**GPU Accelerated:** ❌ No — triggers browser repaints.

## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Property.BackgroundColor as BackgroundColor
    import Anim.Extra.Color exposing (hex)

    highlightAnimation : AnimBuilder -> AnimBuilder
    highlightAnimation =
        BackgroundColor.for "animGroup"
            >> BackgroundColor.to (hex "#ffff00")
            >> BackgroundColor.duration 300
            >> BackgroundColor.build
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
| `init` | `AnimGroupName -> Color -> AnimBuilder -> AnimBuilder` | Set the initial background color |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `AnimGroupName -> AnimBuilder -> Builder` | Start building |
| `build` | `Builder -> AnimBuilder` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `from` | `Color -> Builder -> Builder` | Starting background color |

### End Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `to` | `Color -> Builder -> Builder` | Ending background color |

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

## Next Steps

The FontColor property.

[FontColor →](font-color.md){ .md-button .md-button--primary }

