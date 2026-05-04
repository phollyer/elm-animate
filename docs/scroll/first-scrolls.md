# Your First Scrolls

All the examples demonstrate the same scroll for each of the Engines.

??? note "New to function composition (`>>`)?"

    The examples use `>>` (function composition) to chain functions together. If you're more used to Elm's pipeline operator (`|>`), here's how they compare:

    ```elm
    -- Using pipelines (|>)
    scrollToElement targetId animBuilder =
        animBuilder
            |> ScrollTo.forContainer "scroll-container"
            |> ScrollTo.toElement targetId
            |> ScrollTo.speed 250
            |> ScrollTo.easing BounceOut
            |> ScrollTo.build

    -- Using function composition (>>)
    scrollToElement targetId =
        ScrollTo.forContainer "scroll-container"
            >> ScrollTo.toElement targetId
            >> ScrollTo.speed 250
            >> ScrollTo.easing BounceOut
            >> ScrollTo.build
    ```

    Both produce identical results. The composed version is used throughout this documentation because scroll configurations are naturally reusable functions - they can be stored, passed around, and combined without an explicit argument.


## 1. Vertical Scrolling

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:desc"

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:examples"

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:code"

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:breaking-it-down"

---

## 2. Horizontal Scrolling

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:desc"

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:examples"

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:code"

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:breaking-it-down"

---

## 3. Spreadsheet Navigation

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:desc"

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:examples"

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:code"

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:breaking-it-down"

## Next Steps

Now that you can create a scroll animation, continue with the scroll workflow.

[Scroll Workflow →](../scroll/workflow/build.md){ .md-button .md-button--primary }
