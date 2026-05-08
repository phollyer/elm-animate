# Scroll Timing

Control how long scroll animations take with either fixed durations or distance-based speeds.

## Duration vs Speed

Elm Motion offers two approaches to timing:

| Approach | Behavior | Best For |
| -------- | -------- | -------- |
| `duration` | Fixed time regardless of distance | Predictable, consistent scroll times |
| `speed` | Time varies based on distance | Most scrolling — distance varies naturally |

Since scroll distances vary based on where the user is on the page and where the target is, **speed** is usually the better choice.

!!! tip "Speed feels more natural for scrolling"
    With `speed`, a short scroll (100px) feels snappy while a long scroll (2000px) takes appropriately longer. With `duration`, a short scroll crawls while a long scroll races — neither feels right.

## Duration

Set a fixed scroll time in milliseconds:

??? example "View Source Code"

    ```elm
    Scroll.forDocument
        >> Scroll.toElement "section-id"
        >> Scroll.duration 600  -- Always 600ms regardless of distance
        >> Scroll.build
    ```

Duration can work well when all your scroll targets are at similar distances, or when you want a consistent, predictable feel regardless of position.

## Speed

Set a scroll rate in pixels per second:

??? example "View Source Code"

    ```elm
    Scroll.forDocument
        >> Scroll.toElement "section-id"
        >> Scroll.speed 800  -- 800 pixels per second
        >> Scroll.build
    ```

Scrolling 200px at 800px/s takes 250ms. Scrolling 2400px takes 3000ms.

## Global vs Per-Scroll Timing

Set timing once as a default for all scroll targets in a pipeline, or override it on individual targets:

??? example "View Source Code"

    ```elm
    -- Global default applied to all scroll targets in the pipeline
    Sub.scroll ScrollMsg model.scrollState <|
        Sub.speed 800
            >> Sub.easing QuintOut
            >> Scroll.forDocument
            >> Scroll.toElement "section-1"
            >> Scroll.build
            >> Scroll.forDocument
            >> Scroll.toElement "section-2"
            >> Scroll.build

    -- Per-scroll override on a specific target
    Scroll.forDocument
        >> Scroll.toElement "hero"
        >> Scroll.duration 400  -- overrides the global 800px/s
        >> Scroll.build
    ```

## Timing Accuracy

!!! warning "Cmd and Task timing is approximate"
    The Cmd and Task engines pre-calculate animation frames and execute them sequentially. Because they lack access to the browser's vsync signal, the actual scroll duration can vary by machine speed and display refresh rate.

    If accurate timing matters, use the **[Sub Engine](../engines/sub.md)** — it uses `onAnimationFrameDelta` to produce frame-rate independent animations that match the specified duration precisely.

## Important Notes

!!! warning "Choose one"
    Use either `duration` or `speed`, not both. If both are set, the last one wins.

!!! warning "Default behavior"
    If no `duration` or `speed` is set, a duration of 0ms is used and the page instantly jumps to the target.


## Next Steps

Learn how easing changes the feel of scrolling.

[Easing →](easing.md){ .md-button .md-button--primary }
