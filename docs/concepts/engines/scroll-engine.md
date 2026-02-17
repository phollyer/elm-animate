# Scroll Engine

The Scroll Engine uses frame-by-frame interpolation to smoothly scroll to elements or positions with full easing control.

## Features

- **Document or container scrolling** — Scroll the entire page or within a scrollable container element
- **Element or position targets** — Scroll to a specific element by ID, or to exact X/Y coordinates
- **Axis control** — Scroll on the X axis, Y axis, or both simultaneously
- **Configurable offsets** — Add pixel offsets (e.g., account for fixed headers)
- **Full easing support** — Apply any easing function for natural-feeling motion

## Document Scrolling

Scroll the entire page to bring an element into view:

??? example "Show Source Code"

    ```elm
    import Anim.Engine.Scroll as Scroll

    scrollCmd =
        Scroll.toCmd ScrollComplete <|
            Scroll.forDocument
                >> Scroll.toElement "target-section"
                >> Scroll.duration 800
                >> Scroll.easing CubicOut
                >> Scroll.build
    ```

## Container Scrolling

Scroll within a specific scrollable container:

??? example "Show Source Code"

    ```elm
    scrollCmd =
        Scroll.toCmd ScrollComplete <|
            Scroll.forContainer "scroll-container"
                >> Scroll.toElement "item-42"
                >> Scroll.duration 500
                >> Scroll.easing CubicOut
                >> Scroll.build
    ```

## Next Steps

Now that you've learned a bit about each of the engines, we'll take a look at how to control them.

[Controlling Animations →](../controlling-animations.md){ .md-button .md-button--primary }

