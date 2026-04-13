# Font Color

Animate the text color of elements.

**Module:** `Anim.Property.FontColor`

**GPU Accelerated:** ❌ No — triggers browser repaints.

## Basic Usage

??? example "Show Source Code"

    ```elm
    import Anim.Property.FontColor as FontColor
    import Anim.Extra.Color exposing (hex)

    textHighlight : AnimBuilder -> AnimBuilder
    textHighlight =
        FontColor.for "animGroup"
            >> FontColor.to (hex "#0066cc")
            >> FontColor.duration 300
            >> FontColor.build
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
| `init` | `AnimGroupName -> Color -> AnimBuilder -> AnimBuilder` | Set the initial font color |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `AnimGroupName -> AnimBuilder -> Builder` | Start building |
| `build` | `Builder -> AnimBuilder` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `from` | `Color -> Builder -> Builder` | Starting text color |

### End Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `to` | `Color -> Builder -> Builder` | Ending text color |

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

The Size property.

[Size →](size.md){ .md-button .md-button--primary }

Play with and learn from the examples.

[Examples →](../examples.md){ .md-button .md-button--primary }

