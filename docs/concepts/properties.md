# Properties

Elm Animate supports various CSS properties for animation (more are being added all the time).
Each property module provides a consistent builder API.

## GPU Accelerated Properties

These properties are GPU-accelerated for smooth performance.

### Opacity

Fade elements in and out.

```elm
import Anim.Property.Opacity as Opacity

fadeAnimation builder =
    builder
        |> Opacity.for "box"
        |> Opacity.from 0
        |> Opacity.to 1
        |> Opacity.build
```

### Rotate

Rotate elements around axes.

```elm
import Anim.Property.Rotate as Rotate

rotateAnimation builder =
    builder
        |> Rotate.for "box"
        |> Rotate.from 0
        |> Rotate.to 180
        |> Rotate.build
```

### Scale

Scale elements uniformly or per-axis.

```elm
import Anim.Property.Scale as Scale

scaleAnimation builder =
    builder
        |> Scale.for "box"
        |> Scale.from 1
        |> Scale.to 1.5
        |> Scale.build
```

### Translate

Move elements in 2D or 3D space.

```elm
import Anim.Property.Translate as Translate

translateAnimation builder =
    builder
        |> Translate.for "box"
        |> Translate.fromXY 0 0
        |> Translate.toXY 100 200
        |> Translate.build
```

!!! tip "3D Animations"
    Rotate, Scale, and Translate all support 3D transforms. See the [3D Animations](3d.md) page for details.


## Non GPU Accelerated Properties

These properties trigger browser repaints or reflows, which can impact performance. Use sparingly for complex animations.

### Background Color

Animate background colors.

!!! warning "Not GPU accelerated"
    Background color changes trigger browser repaints, which can impact performance for complex animations.

```elm
import Anim.Property.BackgroundColor as BackgroundColor
import Anim.Color exposing (hex, rgb)

colorAnimation builder =
    builder
        |> BackgroundColor.for "box"
        |> BackgroundColor.from (hex "#ff0000")
        |> BackgroundColor.to (rgb 0 0 255)
        |> BackgroundColor.build
```

### Font Color

Animate text colors.

!!! warning "Not GPU accelerated"
    Font color changes trigger browser repaints, which can impact performance for complex animations.

```elm
import Anim.Property.FontColor as FontColor

textColorAnimation builder =
    builder
        |> FontColor.for "text"
        |> FontColor.from (hex "#000000")
        |> FontColor.to (hex "#ffffff")
        |> FontColor.build
```


## Size Properties

### Size

Animate width and height.

!!! warning "Triggers reflow and repaint"
    Size changes cause the browser to recalculate layout for the entire page, which is the most expensive animation operation. Consider using `Scale` transforms instead for better performance.

```elm
import Anim.Property.Size as Size

sizeAnimation builder =
    builder
        |> Size.for "box"
        |> Size.fromWH 100 100
        |> Size.toWH 200 150
        |> Size.build
```

## Common Options

All properties support these timing options:

```elm
myAnimation builder =
    builder
        |> Property.for "element-id"
        |> Property.from startValue
        |> Property.to endValue
        |> Property.duration 500        -- Milliseconds
        |> Property.speed 200           -- Pixels per second (alternative to duration)
        |> Property.delay 100           -- Start delay in ms
        |> Property.easing QuintOut     -- Easing function
        |> Property.build
```

!!! warning "Duration vs Speed"
    Use either `duration` or `speed`, not both. Speed calculates duration based on distance traveled.
