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

## Property Functions

Each property module provides functions tailored to its dimensions:

| Dimensions | Property | Available Functions |
| ---------- | -------- | ------------------- |
| Single value | Opacity | `init`, `to` |
| Two values | Size (W×H) | `init`, `initW`, `initH`, `to`, `toW`, `toH` |
| Three values | Translate (X,Y,Z) | `init`, `initX`, `initXY`, `to`, `toX`, `toXY`, etc. |

Each property also uses sensible defaults for any values that have not been set:

| Property | Default | Examples |
| -------- | :-----: | -------- |
| Size | 0 | `initW 100` -> (width = 100, height = 0) |
| Translate | 0 | `toXY 20 30` -> move to (x = 20, y = 30), leave `z` where it is, or 0 if not set |


See each property's documentation for the full function list.

## Next Steps

Control animation timing with duration and speed.

[Timing →](timing.md){ .md-button .md-button--primary }


