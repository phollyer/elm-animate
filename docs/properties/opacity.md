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
        Opacity.for "my-element"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.duration 500
            >> Opacity.build
    ```

## API

See the [Properties Overview](overview.md) for the shared builder pipeline, targeting, timing, and initialization patterns.

### Initialization

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `init` | `String -> Float -> AnimBuilder -> AnimBuilder` | Set the initial opacity value for your element id so that your Engine can set it in your view |

### Values

| Function | Signature | Description |
| ---------- | ------ | ------------- |
| `from` | `Float -> Builder -> Builder` | Starting opacity (0.0 to 1.0) |
| `to` | `Float -> Builder -> Builder` | Ending opacity (0.0 to 1.0) |

## Example

### Pulse Effect

Combine with other properties for a pulse.

??? example "Show Source Code"

    ```elm
    fade : AnimBuilder -> AnimBuilder
    fade =
        Opacity.for "box"
            >> Opacity.from 1
            >> Opacity.to 0.5
            >> Opacity.duration 500
            >> Opacity.easing SineInOut
            >> Opacity.build

    scale : AnimBuilder -> AnimBuilder
    scale =
        Scale.for "box"
            >> Scale.from 1
            >> Scale.to 1.05
            >> Scale.duration 500
            >> Scale.easing SineInOut
            >> Scale.build

    pulse : AnimBuilder -> AnimBuilder
    pulse =
        fade >> scale
    ```

## Tips

!!! tip "Combine with Translate for entrances"
    Fade-in animations feel more polished when combined with subtle movement:

    ```elm
    slide : AnimBuilder -> AnimBuilder
    slide =
        Translate.for "box"
            >> Translate.fromY 20
            >> Translate.toY 0
            >> Translate.build


    fade : AnimBuilder -> AnimBuilder
    fade =
        Opacity.for "box"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

    
    slideAndFade : AnimBuilder -> AnimBuilder
    slideAndFade =
        slide >> fade
    ```
