# Opacity

Fade elements in and out by animating their opacity value.

**Module:** `Anim.Property.Opacity`

**GPU Accelerated:** ✅ Yes — composited on the GPU for smooth performance.

## Basic Usage

??? example "Show Source Code"

    ```elm
    import Anim.Property.Opacity as Opacity

    fadeIn : AnimBuilder -> AnimBuilder
    fadeIn =
        Opacity.for "animGroup"
            >> Opacity.to 1
            >> Opacity.duration 500
            >> Opacity.build
    ```

See the [Properties Overview](overview.md) for the shared patterns.

## API

### Initialization

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `init` | `String -> Float -> AnimBuilder -> AnimBuilder` | Set the initial opacity value for the animation group |

### Values

| Function | Signature | Description |
| ---------- | ------ | ------------- |
| `from` | `Float -> Builder -> Builder` | Starting opacity (0.0 to 1.0) |
| `to` | `Float -> Builder -> Builder` | Ending opacity (0.0 to 1.0) |

## Next Steps

The Rotate property.

[Rotate →](rotate.md){ .md-button .md-button--primary }

Non-GPU Accelerated Properties.

[Non-GPU →](non-gpu.md){ .md-button .md-button--primary }

Play with and learn from the examples.

[Examples →](../examples.md){ .md-button .md-button--primary }

