# Start Here

## Choosing a Scroll Engine

Elm Animate provides three scroll engines with one shared builder API.

- `Cmd` - fire-and-forget scrolls with the smallest setup
- `Task` - composable scrolls with typed success/failure results
- `Sub` - state-tracked scrolls with events, controls, and live queries

All three use the same `Scroll.Builder` pipeline, so you can switch engines without rewriting scroll definitions.

## Coding Style

The library codebase, and all the examples, use function composition wherever possible.

??? note "New to function composition (`>>`)?"

    If you are more used to Elm's pipeline operator (`|>`), here's how they compare:

    ```elm
    -- Using pipelines (|>)
    scrollToElement targetId animBuilder =
        animBuilder
            |> Scroll.forContainer "scroll-container"
            |> Scroll.toElement targetId
            |> Scroll.speed 250
            |> Scroll.easing BounceOut
            |> Scroll.build

    -- Using function composition (>>)
    scrollToElement targetId =
        Scroll.forContainer "scroll-container"
            >> Scroll.toElement targetId
            >> Scroll.speed 250
            >> Scroll.easing BounceOut
            >> Scroll.build
    ```

    Both produce identical results. The composed version is used throughout this documentation because scroll configurations are naturally reusable functions - they can be stored, passed around, and combined without an explicit argument.

## Examples

Here are a few examples to get started with.

### 1. Vertical Scrolling

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:desc"

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:examples"

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:code"

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:breaking-it-down"

---

### 2. Horizontal Scrolling

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:desc"

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:examples"

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:code"

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:breaking-it-down"

---

### 3. Spreadsheet Navigation

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:desc"

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:examples"

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:code"

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:breaking-it-down"

## Next Steps

Now that you can create a simple scroll, continue with the scroll workflow.

[Scroll Workflow ->](workflow/build.md){ .md-button .md-button--primary }
