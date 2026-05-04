# GPU Accelerated Properties

Opacity, Rotate, Scale, Skew, and Translate are typically compositor-accelerated (usually GPU-backed) — the browser often composites them on separate layers, keeping the main thread free for your application logic.

## How It Works

When you animate these properties, the browser often promotes the element to its own compositing layer. Interpolation can then happen independently of the main thread, which means:

- **No layout recalculation** — the element's position in the document flow doesn't change
- **No repaint** — the browser doesn't need to redraw pixels
- **Smooth 60fps** — animation frames are handled by the GPU even if the main thread is busy

!!! info "Reality Check"
 This fast path is not an absolute guarantee. Browser heuristics, device constraints, and scene complexity can affect layer promotion and compositing behavior.

This is why a `Translate` animation can remain silky smooth even during heavy Elm model updates, while a `Size` animation might stutter under the same conditions.


## Which Properties Are GPU Accelerated?

| Property | CSS Property |
| -------- | ------------ |
| [Opacity](opacity.md) | `opacity` |
| [Rotate](rotate.md) | `transform: rotate()` |
| [Scale](scale.md) | `transform: scale()` |
| [Skew](skew.md) | `transform: skew()` |
| [Translate](translate.md) | `transform: translate()` |


📖 - [Animations and Performance (MDN)](https://developer.mozilla.org/en-US/docs/Web/Performance/Animation_performance_and_frame_rate) — animation performance and frame rate

📖 - [Stick to Compositor-Only Properties (web.dev)](https://web.dev/articles/stick-to-compositor-only-properties-and-manage-layer-count) — why compositor-only properties are fast

## Next Steps

Check out each GPU Accelerated property, starting with Opacity.

[Opacity →](opacity.md){ .md-button .md-button--primary }

Non-GPU Accelerated Properties.

[Non-GPU →](non-gpu.md){ .md-button .md-button--primary }
