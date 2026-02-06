# Properties

Elm Animate supports various CSS properties that can be animated. All properties share the same consistent builder API, making them easy to learn and compose.

!!! note "Why one module per property?"
    Rather than use a single `Property` phantom type that supports all properties, I chose individual property modules despite the increased maintenance load. This provides improved readability and better IDE autocompletion, but more importantly, simpler and more obvious type safety.

## Common API

All properties follow the same builder pattern (Start with `for` -> Configure -> End with `build`):

??? example "View Source Code"

    ```elm
    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        -- Start
        Property.for "element-id"           -- Target element by ID (required)
            -- Configure
            >> Property.from startValue     -- Starting value 
            >> Property.to endValue         -- Ending value
            >> Property.duration 500        -- Duration in milliseconds
            >> Property.easing QuintOut     -- Easing function
            >> Property.delay 100           -- Start delay in ms
            -- End
            >> Property.build               -- Finalize the property (required)
    ```

    The `Configure` steps between `for` and `build` are all optional, some more so than others. After all, it wouldn't be much of an animation if there was no end state (`to`) to animate to.

### Duration vs Speed

You can specify timing with either `duration` (fixed time) or `speed` (distance-based):


??? example "View Source Code"

    ```elm
    -- Fixed 500ms regardless of distance
    |> Translate.duration 500

    -- 200 pixels per second (duration varies with distance)
    |> Translate.speed 200

    ```

!!! note "Units for speed"
    The meaning of 'units' varies by property type. For `Translate` it's 'pixels'. Refer to each individual property for how speed is interpretted.

!!! warning
    Use either `duration` or `speed`, not both. If both are set, the last one wins.

!!! warning
    If no `duration` or `speed` is set, either globally on the engine, or locally on the property, then a duration of 0ms will be used, and the element will instantly jump to it's end state.


## GPU Accelerated Properties

These properties are composited on the GPU for smooth 60fps performance with minimal battery impact.

| Property | Description | Module |
|----------|-------------|--------|
| [Opacity](../properties/opacity.md) | Fade elements in and out | `Anim.Property.Opacity` |
| [Rotate](../properties/rotate.md) | Rotate elements around X, Y, Z axes | `Anim.Property.Rotate` |
| [Scale](../properties/scale.md) | Scale elements on X, Y, Z axes | `Anim.Property.Scale` |
| [Translate](../properties/translate.md) | Move elements on X, Y, Z axes | `Anim.Property.Translate` |

!!! tip "3D Animations"
    Rotate, Scale, and Translate all support 3D transforms. See the [3D Animations](3d.md) page for details.

## Non GPU Accelerated Properties

These properties trigger browser repaints and/or reflows. Use them when needed, but be mindful of performance with many simultaneous animations.

!!! warning "Size animations"
    Size changes also trigger browser reflows. The scope depends on layout context — fixed-size containers can limit reflow to their subtree. Consider using `Scale` transforms when you don't need actual layout changes.

| Property | Description | Module | Impact |
|----------|-------------|--------|--------|
| [Background Color](../properties/background-color.md) | Animate element backgrounds | `Anim.Property.BackgroundColor` | Repaint |
| [Font Color](../properties/font-color.md) | Animate text colors | `Anim.Property.FontColor` | Repaint |
| [Size](../properties/size.md) | Animate width and height | `Anim.Property.Size` | Reflow + Repaint |
