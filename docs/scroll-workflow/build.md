# Build

## The Builder Pattern

Elm Animate uses a fluent builder pattern for defining scrolls.
This approach provides a consistent, composable API across all engines that reads naturally
and is easy to reason about — you can see at a glance what a scroll does and how it behaves.

## Basic Structure

Every scroll follows this pattern:

??? example "View Source Code"

    ```elm
    scrollToSection : AnimBuilder -> AnimBuilder
    scrollToSection =
        Scroll.forContainer "container-id"   -- Scrollable element, or `Scroll.forDocument`, (required)
            >> Scroll.toElement "target-id"  -- Alternative targeting functions are available
            >> Scroll.speed 300              -- px/s, or `Scroll.duration 500` (ms)
            >> Scroll.easing QuintOut        -- Make the scroll feel natural
            >> Scroll.build                  -- Finalize (required)
    ```

    Either `forContainer` or `forDocument` are required to start the builder chain along with `build` to complete it.
    All other configurations are optional, although without a target the scroll won't have anywhere to go!!

## Container Selection

Use `forDocument` when you want to scroll the page itself (the browser viewport / document).
Use `forContainer` when you want to scroll a specific element with its own overflow.

### `forDocument`

`forDocument` targets the main page scroll position. This is useful for jumping between sections in long pages.

??? example "View Source Code"

    ```elm
    scrollPageToSection : String -> AnimBuilder -> AnimBuilder
    scrollPageToSection sectionId =
        Scroll.forDocument
            >> Scroll.toElement sectionId
            >> Scroll.speed 300
            >> Scroll.build
    ```

### `forContainer`

`forContainer` targets a specific scrollable element by its `id`. This is useful for cards, panels, tables, and any nested scroll region.

??? example "View Source Code"

    ```elm
    scrollPanelToItem : String -> AnimBuilder -> AnimBuilder
    scrollPanelToItem itemId =
        Scroll.forContainer "results-panel"
            >> Scroll.toElement itemId
            >> Scroll.speed 300
            >> Scroll.build
    ```

### Multiple Scrolls

Scroll multiple containers at once:

??? example "View Source Code"

    ```elm
    resetContainers : AnimBuilder -> AnimBuilder
    resetContainers =
        Scroll.forContainer "results-panel"
            >> Scroll.toTop
            >> Scroll.speed 300
            >> Scroll.build
            >> Scroll.forContainer "chat-panel"
            >> Scroll.toBottom
            >> Scroll.speed 300
            >> Scroll.build
    ```


## Targeting Elements

### By Element ID

The most common case - scroll the container until the target element is visible:

??? example "View Source Code"

    ```elm
    scrollToCard : String -> AnimBuilder -> AnimBuilder
    scrollToCard cardId =
        Scroll.forContainer "cards-container"
            >> Scroll.toElement cardId
            >> Scroll.build
    ```

### By Coordinates

Scroll to an exact pixel position within the container:

??? example "View Source Code"

    ```elm
    scrollToTop : AnimBuilder -> AnimBuilder
    scrollToTop =
        Scroll.forContainer "main-content"
            >> Scroll.toXY 0 0
            >> Scroll.build

    scrollToPosition : Float -> Float -> AnimBuilder -> AnimBuilder
    scrollToPosition x y =
        Scroll.forContainer "main-content"
            >> Scroll.toXY x y
            >> Scroll.build
    ```

## Controlling the Axis

By default, `toElement` scrolls on both axes. Use `onXAxis` or `onYAxis` to restrict scrolling to a single axis:

??? example "View Source Code"

    ```elm
    -- Horizontal gallery - only scroll X
    scrollGallery : String -> AnimBuilder -> AnimBuilder
    scrollGallery itemId =
        Scroll.forContainer "gallery"
            >> Scroll.toElement itemId
            >> Scroll.onXAxis
            >> Scroll.build

    -- Vertical list - only scroll Y
    scrollList : String -> AnimBuilder -> AnimBuilder
    scrollList itemId =
        Scroll.forContainer "list"
            >> Scroll.toElement itemId
            >> Scroll.onYAxis
            >> Scroll.build
    ```

## Offsets

Use `withOffsetXY` to adjust the final scroll position - useful when sticky headers or sidebars would otherwise obscure the target:

??? example "View Source Code"

    ```elm
    -- 64px sticky header, 48px sticky sidebar
    scrollWithOffset : String -> AnimBuilder -> AnimBuilder
    scrollWithOffset targetId =
        Scroll.forContainer "content"
            >> Scroll.toElement targetId
            >> Scroll.withOffsetXY 48 64
            >> Scroll.build
    ```

## Timing

Scroll duration can be set either as a fixed duration or as a speed - speed is usually the better choice because it gives consistent motion regardless of scroll distance:

??? example "View Source Code"

    ```elm
    -- Fixed duration (ms) - short scrolls feel fast, long scrolls feel slow
    Scroll.duration 500

    -- Speed (px/s) - consistent feel at any distance
    Scroll.speed 300
    ```

📖 See [Timing](../getting-started/timing.md) and [Easing](../getting-started/easing.md) for more detail.

## Composing Scrolls

The `AnimBuilder -> AnimBuilder` type composes with `>>` just like animation builders. Extract shared configuration into helpers:

??? example "View Source Code"

    ```elm
    withStandardTiming : AnimBuilder -> AnimBuilder
    withStandardTiming =
        Scroll.speed 300
            >> Scroll.easing QuintOut

    scrollToSection : String -> AnimBuilder -> AnimBuilder
    scrollToSection sectionId =
        Scroll.forContainer "page"
            >> Scroll.toElement sectionId
            >> withStandardTiming
            >> Scroll.build
    ```

## Next Steps

Now that you've defined your scroll, you need to trigger it.

[Trigger →](trigger.md){ .md-button .md-button--primary }
