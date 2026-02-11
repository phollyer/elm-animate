# Scroll Engine

Scrolling the Document or a container is effectively an animation - animating scroll position rather than CSS properties. The Scroll Engine uses frame-by-frame interpolation (like the Sub Engine) to smoothly scroll to elements or positions with full easing control.

## Overview

| Engine | Rendering | Control | Use Case |
| -------- | ----------- | --------- | ---------- |
| [Scroll](#scroll-engine) | Browser scroll | Fire-and-forget, Programmatic | Document and container scrolling |

The Scroll Engine provides smooth Document and container scrolling to elements or positions:

- **Document or container scrolling**
- **X, Y, or both axes**
- **Configurable offsets**
- **Full easing support**

??? example "View Source Code"

    ```elm
    import Anim.Engine.Scroll as Scroll

    scrollCmd =
        Scroll.toCmd ScrollComplete <|
            Scroll.toElement "target-section"
                >> Scroll.duration 2000
                >> Scroll.build
    ```

## Next Steps

Now that you've learned a bit about each of the engines, we'll look at the builder pattern used for all animations.

[Builder Pattern →](../builder-pattern.md){ .md-button .md-button--primary }

