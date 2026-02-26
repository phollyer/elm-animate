# Properties

Elm Animate supports various CSS properties that can be animated. All properties use the same [builder pattern](../animation-workflow/build.md) — start with `for`, configure, end with `build`.


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

## Next Steps

Control animation timing with duration and speed.

[Timing →](timing.md){ .md-button .md-button--primary }


