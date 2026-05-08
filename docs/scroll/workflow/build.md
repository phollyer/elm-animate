# Build

## The Builder Pattern

Elm Motion uses a fluent builder pattern for defining scrolls.
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
Use `forContainer` when you want to scroll a specific element.

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

## Best Practices

!!! tip "Prefer speed for consistent feel"
    `Scroll.speed` usually gives a more consistent user experience across short and long distances than fixed `duration`.

!!! tip "Extract common patterns"
    If you use the same configurations often, create helper functions.

    ??? example "View Source Code"

        ```elm
        withStandardTiming : AnimBuilder -> AnimBuilder
        withStandardTiming =
            Engine.speed 300
                >> Engine.easing QuintOut

        scrollToSection : String -> AnimBuilder -> AnimBuilder
        scrollToSection sectionId =
            withStandardTiming
                >> Scroll.forContainer "page"
                >> Scroll.toElement sectionId
                >> Scroll.build
        ```

## Next Steps

Now that you've defined your scroll, you need to trigger it.

[Trigger →](trigger.md){ .md-button .md-button--primary }
