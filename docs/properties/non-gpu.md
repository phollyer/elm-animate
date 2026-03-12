# Non-GPU Properties

Properties that are not GPU-accelerated trigger rendering work on the main thread:

- **Repaints**: are relatively cheap
- **Reflows**: are expensive because the browser must recalculate the position and size of elements in the document flow

!!! tip "Prefer `Scale` over `Size` when possible"
    If you only need a visual resize effect and don't need the layout to actually change, use `Scale` instead of `Size`.


## Which Properties Are Not GPU Accelerated?

| Property | CSS Property | Impact |
| -------- | ------------ | ------ |
| [Background Color](background-color.md) | `background-color` | Repaint |
| [Font Color](font-color.md) | `color` | Repaint |
| [Size](size.md) | `width` / `height` | Repaint + Reflow |


## Further Reading

- [Animations and Performance (MDN)](https://developer.mozilla.org/en-US/docs/Web/Performance/Animation_performance_and_frame_rate) — animation performance and frame rate
- [Stick to Compositor-Only Properties (web.dev)](https://web.dev/articles/stick-to-compositor-only-properties-and-manage-layer-count) — why compositor-only properties are fast

## Next Steps

Check out each Non-GPU Accelerated property, starting with BackgroundColor.

[BackgroundColor →](background-color.md){ .md-button .md-button--primary }

Play with and learn from the examples.

[Examples →](../examples.md){ .md-button .md-button--primary }
