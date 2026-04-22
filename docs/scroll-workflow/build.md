# Build

## The Builder Pattern

Scroll animations use the same fluent builder pattern as the animation engines. The builder is defined as a function that transforms an `AnimBuilder`, making scrolls composable and easy to read at a glance.

## Basic Structure

Every scroll follows this pattern:

??? example "View Source Code"

    ```elm
    scrollToSection : AnimBuilder -> AnimBuilder
    scrollToSection =
        ScrollTo.forContainer "container-id"   -- Scrollable element (required)
            >> ScrollTo.toElement "target-id"  -- Target element (required)
            >> ScrollTo.speed 300              -- px/s, or ScrollTo.duration 500 (ms)
            >> ScrollTo.easing QuintOut        -- Easing function
            >> ScrollTo.build                  -- Finalize (required)
    ```

    `forContainer` and `build` are required. All other configuration is optional, but without a target the scroll has nowhere to go.

## Targeting Elements

### By Element ID

The most common case - scroll the container until the target element is visible:

??? example "View Source Code"

    ```elm
    scrollToCard : String -> AnimBuilder -> AnimBuilder
    scrollToCard cardId =
        ScrollTo.forContainer "cards-container"
            >> ScrollTo.toElement cardId
            >> ScrollTo.build
    ```

### By Coordinates

Scroll to an exact pixel position within the container:

??? example "View Source Code"

    ```elm
    scrollToTop : AnimBuilder -> AnimBuilder
    scrollToTop =
        ScrollTo.forContainer "main-content"
            >> ScrollTo.toXY 0 0
            >> ScrollTo.build

    scrollToPosition : Float -> Float -> AnimBuilder -> AnimBuilder
    scrollToPosition x y =
        ScrollTo.forContainer "main-content"
            >> ScrollTo.toXY x y
            >> ScrollTo.build
    ```

## Controlling the Axis

By default, `toElement` scrolls on both axes. Use `onXAxis` or `onYAxis` to restrict scrolling to a single axis:

??? example "View Source Code"

    ```elm
    -- Horizontal gallery - only scroll X
    scrollGallery : String -> AnimBuilder -> AnimBuilder
    scrollGallery itemId =
        ScrollTo.forContainer "gallery"
            >> ScrollTo.toElement itemId
            >> ScrollTo.onXAxis
            >> ScrollTo.build

    -- Vertical list - only scroll Y
    scrollList : String -> AnimBuilder -> AnimBuilder
    scrollList itemId =
        ScrollTo.forContainer "list"
            >> ScrollTo.toElement itemId
            >> ScrollTo.onYAxis
            >> ScrollTo.build
    ```

## Offsets

Use `withOffsetXY` to adjust the final scroll position - useful when sticky headers or sidebars would otherwise obscure the target:

??? example "View Source Code"

    ```elm
    -- 64px sticky header, 48px sticky sidebar
    scrollWithOffset : String -> AnimBuilder -> AnimBuilder
    scrollWithOffset targetId =
        ScrollTo.forContainer "content"
            >> ScrollTo.toElement targetId
            >> ScrollTo.withOffsetXY 48 64
            >> ScrollTo.build
    ```

## Timing

Scroll duration can be set either as a fixed duration or as a speed - speed is usually the better choice because it gives consistent motion regardless of scroll distance:

??? example "View Source Code"

    ```elm
    -- Fixed duration (ms) - short scrolls feel fast, long scrolls feel slow
    ScrollTo.duration 500

    -- Speed (px/s) - consistent feel at any distance
    ScrollTo.speed 300
    ```

📖 See [Timing](../getting-started/timing.md) and [Easing](../getting-started/easing.md) for more detail.

## Composing Scrolls

The `AnimBuilder -> AnimBuilder` type composes with `>>` just like animation builders. Extract shared configuration into helpers:

??? example "View Source Code"

    ```elm
    withStandardTiming : AnimBuilder -> AnimBuilder
    withStandardTiming =
        ScrollTo.speed 300
            >> ScrollTo.easing QuintOut

    scrollToSection : String -> AnimBuilder -> AnimBuilder
    scrollToSection sectionId =
        ScrollTo.forContainer "page"
            >> ScrollTo.toElement sectionId
            >> withStandardTiming
            >> ScrollTo.build
    ```

## Next Steps

Now that you've defined your scroll, you need to trigger it.

[Trigger →](trigger.md){ .md-button .md-button--primary }
