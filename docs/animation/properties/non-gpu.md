# Non-GPU Properties

Properties that are not GPU-accelerated trigger rendering work on the main thread:

- **Repaints**: are relatively cheap
- **Reflows**: are expensive because the browser must recalculate the position and size of elements in the document flow

!!! tip "Prefer `Scale` over `Size` when possible"
    If you only need a visual resize effect and don't need the layout to actually change, use `Scale` instead of `Size`.


## Which Properties Are Not GPU Accelerated?

| Property | CSS Property | Impact |
| -------- | ------------ | ------ |
| [Size](size.md) | `width` / `height` | Repaint + Reflow |


## Further Reading

- [Animations and Performance (MDN)](https://developer.mozilla.org/en-US/docs/Web/Performance/Animation_performance_and_frame_rate) — animation performance and frame rate
- [Stick to Compositor-Only Properties (web.dev)](https://web.dev/articles/stick-to-compositor-only-properties-and-manage-layer-count) — why compositor-only properties are fast

## Next Steps

Check out the Non-GPU Accelerated properties.

[Size →](size.md){ .md-button .md-button--primary }
