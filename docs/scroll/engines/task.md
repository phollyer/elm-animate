# Scroll Task Engine

This page is a practical guide to using the Task engine from setup through advanced usage.
Read [Scroll Engines Overview](overview.md) when you want side-by-side comparisons and tradeoffs.

The Scroll Task Engine provides composable scrolling with typed error handling. Use it when you need to chain scroll operations, handle failures, or compose scrolls with other `Task`s.


## Example

??? example "View Example"
    <iframe src="../../../examples/src/Scroll/Task/FirstScroll/index.html" style="width: 100%; height: 450px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Task/FirstScroll/Main.elm"
    ```

📖 See [Your First Scrolls](../start-here.md) for a step-by-step breakdown.


## Quick Walkthrough

Get up and running in minutes.

### 1. Build

Define the scroll as a builder function:

??? example "View Source Code"

    ```elm
    import Scroll.Engine.Task as ScrollTask exposing (ScrollBuilder, ScrollOk, ScrollError)
    import Scroll.Builder as Scroll
    import Motion.Easing as Easing exposing (Easing(..))
    import Task

    scrollToElement : ScrollBuilder -> ScrollBuilder
    scrollToElement =
        Scroll.forContainer "scroll-container"
            >> Scroll.toElement "target-section"
            >> Scroll.easing BounceOut
            >> Scroll.speed 400
            >> Scroll.build
    ```

### 2. Trigger

Call `scroll` to get a `Task`, then convert it to a `Cmd` with `Task.attempt`:

??? example "View Source Code"

    ```elm
    type Msg
        = ScrollTo String
        | ScrollResult (Result ScrollError (List ScrollOk))

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollTo elementId ->
                ( model
                , scrollToElement elementId
                    |> ScrollTask.scroll
                    |> Task.attempt ScrollResult
                )
    ```

Task scrolls are tied to how quickly the browser processes each update, so actual timing is affected by refresh rate and machine speed. If you need accurate timing use the [Sub](sub.md) Engine.

### 3. Handle the Result

The `Result` gives you typed success or failure:

??? example "View Source Code"

    ```elm
    type Msg
        = ScrollTo String
        | ScrollResult (Result ScrollError (List ScrollOk))

    ScrollResult result ->
        case result of
            Ok _ ->
                ( { model | status = "Arrived" }
                , Cmd.none
                )

            Err (ScrollError _) ->
                ( { model | status = "Scroll failed" }
                , Cmd.none
                )
    ```

---

## In Detail

### Multiple Concurrent Scrolls

Create separate builders and batch their `Cmd`s:

??? example "View Source Code"

    ```elm
    ( model
    , Cmd.batch
        [ ScrollTask.scroll scrollSidebar
            |> Task.attempt SidebarResult
        , ScrollTask.scroll scrollMain
            |> Task.attempt MainResult
        ]
    )
    ```

Each batched task resolves independently. Use this pattern when you want separate messages and separate success or failure handling per scroll rather than one combined result.

### Multiple Sequential Scrolls

Multiple scroll targets in the same builder execute one after another. If any scroll fails, subsequent scrolls are not attempted:

??? example "View Source Code"

    ```elm
    scrollSequence : ScrollBuilder -> ScrollBuilder
    scrollSequence =
        Scroll.forDocument
            >> Scroll.toElement "section-1"
            >> Scroll.build
            >> Scroll.forDocument
            >> Scroll.toElement "section-2"
            >> Scroll.build
    ```

Successful runs return `List ScrollOk` in the same order as the builder pipeline.

### Task Composition

Compose Scrolls with other Tasks.

??? example "View Source Code"

    ```elm
    -- Combine with a data fetch
    fetchData "article-123"
        |> Task.andThen
            (ScrollTask.scroll << scrollToSection << .anchorId)
        |> Task.attempt GotResult
    ```

### Triggering While a Scroll Is Running

If the same `scroll` call fires repeatedly, say from repeated button clicks, each scroll will run independently - and they will all compete for control of the container. This can lead to scrolls finishing short of their target.

To prevent this, either guard the triggering with your own internal state, or use the [Scroll Sub Engine](sub.md), which replaces the running scroll on each call.

### Result Handling

#### Success - ScrollOk

`ScrollOk` represents one completed scroll and is a type alias with two fields:

| Field | Type | Description |
| ----- | ---- | ----------- |
| `container` | `Container` | The container that was scrolled |
| `targetElementId` | `Maybe String` | ID of the target element, if scrolled to an element |

#### Failure - ScrollError

`ScrollError` repesents a scroll failure - for example, when an element ID does not exist in the DOM:

| Field | Type | Description |
| ----- | ---- | ----------- |
| `container` | `Container` | The container that was being scrolled |
| `targetElementId` | `Maybe String` | ID of the target element, if one was specified |
| `domError` | `Dom.Error` | The underlying [Dom.Error](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Dom#Error) |

`scroll` is fail-fast: the first failing target ends the task immediately and later targets in the same builder are not attempted.

### Continue Through Failures

Use `scrollEach` when you need a result for every scroll target, even if some fail:

??? example "View Source Code"

    ```elm
    type Msg
        = ScrollAttempts (List (Result ScrollError ScrollOk))

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollToSequence ->
                ( model
                , scrollSequence
                    |> ScrollTask.scrollEach
                    |> Task.perform ScrollAttempts
                )
    ```

`scrollEach` always completes and returns one `Result` per target, in pipeline order.


### API Quick Reference

#### Types

| Type | Description |
| ---- | ----------- |
| `ScrollBuilder` | Carries scroll configuration in the builder pipeline |
| `Container` | Scroll surface (`Document` or `Container "element-id"`) |
| `ScrollError` | Error payload with `container`, `targetElementId`, and `domError` |
| `ScrollOk` | Success payload with `container` and `targetElementId` |

#### Trigger

| Function | Type | Description |
| -------- | ---- | ----------- |
| `scroll` | `(ScrollBuilder -> ScrollBuilder) -> Task ScrollError (List ScrollOk)` | Fail-fast scroll task |
| `scrollEach` | `(ScrollBuilder -> ScrollBuilder) -> Task Never (List (Result ScrollError ScrollOk))` | Continue-through-failure scroll task |

#### Timing

| Function | Type | Description |
| -------- | ---- | ----------- |
| `delay` | `Int -> ScrollBuilder -> ScrollBuilder` | Set default delay (ms) |
| `duration` | `Int -> ScrollBuilder -> ScrollBuilder` | Set default duration (ms) |
| `speed` | `Float -> ScrollBuilder -> ScrollBuilder` | Set default speed (px/sec) |

#### Easing

| Function | Type | Description |
| -------- | ---- | ----------- |
| `easing` | `Easing -> ScrollBuilder -> ScrollBuilder` | Set default easing |

For complete API details, see the [Scroll.Engine.Task](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Scroll-Engine-Task) documentation.


### Next Steps

Need state tracking, events, or mid-scroll control?

[Sub Engine →](sub.md){ .md-button .md-button--primary }
