# Scroll Task Engine

This page focuses on what makes this engine different, read [Scroll Engines Overview](overview.md) for features that are shared across all Scroll engines.

The Scroll Task Engine provides composable scrolling with typed error handling. Use it when you need to chain scroll operations, handle failures, or compose scrolls with other `Task`s.


## Example

??? example "View Example"
    <iframe src="../../../examples/src/Scroll/Task/FirstScroll/index.html" style="width: 100%; height: 550px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Task/FirstScroll/Main.elm"
    ```

📖 See [Your First Scrolls](../first-scrolls.md) for a step-by-step breakdown.


## Usage

### 1. Build

Define the scroll as a builder function:

??? example "View Source Code"

    ```elm
    import Scroll.Engine.Task as Scroll exposing (AnimBuilder)
    import Scroll.Builder as Scroll
    import Easing exposing (Easing(..))
    import Task

    scrollToElement : AnimBuilder -> AnimBuilder
    scrollToElement =
        Scroll.forContainer "scroll-container"
            >> Scroll.toElement "target-section"
            >> Scroll.easing BounceOut
            >> Scroll.build
    ```

### 2. Trigger

Call `animate` to get a `Task`, then convert it to a `Cmd` with `Task.attempt`:

??? example "View Source Code"

    ```elm
    type Msg
        = ScrollTo String
        | ScrollResult (Result Scroll.ScrollError (List Scroll.ScrollOk))

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollTo elementId ->
                ( model
                , scrollToElement elementId
                    |> Scroll.animate 
                    |> Task.attempt ScrollResult
                )
    ```

### 3. Handle the Result

The `Result` gives you typed success or failure:

??? example "View Source Code"

    ```elm
    type Msg
        = ScrollTo String
        | ScrollResult (Result Scroll.ScrollError (List Scroll.ScrollOk))

    ScrollResult result ->
        case result of
            Ok scrollsOk ->
                -- scrollsOk : List Scroll.ScrollOk
                ( { model | status = "Arrived" }
                , Cmd.none
                )

            Err (Scroll.ScrollError error) ->
                -- error.container : Scroll.Container
                -- error.targetElementId : Maybe String
                -- error.domError : Dom.Error
                ( { model | status = "Scroll failed" }
                , Cmd.none
                )
    ```

### ScrollOk

`ScrollOk` represents one completed scroll in the sequence:

| Field | Type | Description |
| ----- | ---- | ----------- |
| `container` | `Container` | The container that was scrolled |
| `targetElementId` | `Maybe String` | ID of the target element, if scrolled to an element |

### ScrollError

`ScrollError` is delivered when the scroll fails - for example, when an element ID does not exist in the DOM:

| Field | Type | Description |
| ----- | ---- | ----------- |
| `container` | `Container` | The container that was being scrolled |
| `targetElementId` | `Maybe String` | ID of the target element, if one was specified |
| `domError` | `Dom.Error` | The underlying [Dom.Error](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Dom#Error) |


## Error Handling

`ScrollError` carries structured information about what went wrong:

??? example "View Source Code"

    ```elm
    type ScrollError
        = ScrollError
            { container : Container
            , targetElementId : Maybe String
            , domError : Dom.Error
            }
    ```

Errors typically occur when a target element doesn't exist in the DOM. The `domError` field gives the underlying `Browser.Dom.Error` for diagnostics.


## Task Composition

If you already know the final target, use a single scroll:

??? example "View Source Code"

    ```elm
    scrollToSection "first-paragraph"
        |> Scroll.animate 
        |> Task.attempt GotScrollResult
    ```

Chain scroll Tasks only when you truly have a multi-step flow, such as nested scrollable containers or when the second target is only known after another Task completes:

??? example "View Source Code"

    ```elm
    -- Nested containers: scroll outer container first, then inner container
    scrollOuterToSection "chapter-2"
        |> Scroll.animate 
        |> Task.andThen (\_ -> Scroll.animate (scrollInnerToParagraph "first-paragraph"))
        |> Task.attempt GotScrollResult

    -- Combine with a data fetch
    fetchData "article-123"
        |> Task.andThen
            (\article ->
                Scroll.animate (scrollToSection article.anchorId)
            )
        |> Task.attempt GotResult
    ```

### Sequential Scrolls

Multiple scroll targets in the same builder execute one after another. If any scroll fails, subsequent scrolls are not attempted:

??? example "View Source Code"

    ```elm
    scrollSequence : AnimBuilder -> AnimBuilder
    scrollSequence =
        Scroll.forDocument
            >> Scroll.toElement "section-1"
            >> Scroll.build
            >> Scroll.forDocument
            >> Scroll.toElement "section-2"
            >> Scroll.build
    ```

### Continue Through Failures

Use `attempt` when you need a result for every scroll target, even if some fail:

??? example "View Source Code"

    ```elm
    type Msg
        = ScrollAttempts (List (Result Scroll.ScrollError Scroll.ScrollOk))

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollToSequence ->
                ( model
                , scrollSequence
                    |> Scroll.attempt
                    |> Task.perform ScrollAttempts
                )
    ```

### Triggering While a Scroll Is Running

!!! warning "Retriggering does not replace the current scroll"
    Each call to `animate` pre-calculates its frame steps from the DOM state at the moment the Task runs. If a new `animate` call fires while a previous scroll is still in flight, the second scroll starts another independent sequence instead of replacing the first one.

    Retriggering the same `toElement` target now calculates the correct absolute destination, but overlapping Task scrolls to different targets can still compete because neither scroll owns shared animation state. If you need to cancel and restart a scroll safely — for example when a user clicks a button repeatedly — use the [Scroll Sub Engine](sub.md), which replaces the running animation on each call.

### Concurrent Scrolls with Individual Error Handling

Create separate builders and batch their `Cmd`s:

??? example "View Source Code"

    ```elm
    ( model
    , Cmd.batch
        [ Scroll.animate scrollSidebar 
            |> Task.attempt SidebarResult
        , Scroll.animate scrollMain 
            |> Task.attempt MainResult
        ]
    )
    ```


## Under The Hood

??? info "How Task Execution Works"

    **Single scroll target:**

    1. DOM queries retrieve current scroll position and target element position
    2. Distance is calculated from current to target position
    3. Animation steps are pre-calculated based on distance, timing and easing
    4. Steps are sequenced into a `Task` chain
    5. `Task` is executed when converted to `Cmd` with `Task.attempt` or composed with other tasks
    6. Returns `ScrollOk` on success or `ScrollError` on failure

    **Multiple sequential scroll targets:**

    - Each scroll is processed sequentially (one after another, in pipeline order)
    - First scroll goes through steps 1-5, then second scroll begins
    - Returns `ScrollError` for the first scroll that fails, subsequent scrolls are not attempted
    - Returns `List ScrollOk` only if all scrolls succeed, in pipeline order

    **Multiple sequential scroll targets (continue through failures):**

    - Each scroll is processed sequentially (one after another, in pipeline order)
    - Failures do not stop the sequence
    - Returns `List (Result ScrollError ScrollOk)` with one entry per target, in pipeline order

    **Multiple concurrent scroll targets:**

    - Each scroll is independently converted to a `Task` (following steps 1-5 above)
    - Each `Task` is independently converted to a `Cmd` via `Task.attempt`
    - All `Cmd`s are `Cmd.batch`ed into a single `Cmd`
    - Elm runtime receives the single `Cmd` and executes all scrolls concurrently
    - Browser's rendering engine handles all simultaneous scroll animations in parallel
    - Each scroll returns its own `ScrollOk` or `ScrollError` independently

    **Error handling:**

    - `animate` returns `List ScrollOk` on success (all succeeded) or `ScrollError` on first failure
    - `attempt` returns `List (Result ScrollError ScrollOk)` and always completes
    - Returns `ScrollError` on failure with details about what failed
    - Errors typically occur when target elements don't exist in the DOM
    - Can be composed with other tasks using `Task.andThen`, `Task.map`, etc.


## API Quick Reference

| Function / Type | Type | Description |
| ---------- | ------ | ------------- |
| `animate` | `(AnimBuilder -> AnimBuilder) -> Task ScrollError (List ScrollOk)` | Composable scroll with fail-fast error handling |
| `attempt` | `(AnimBuilder -> AnimBuilder) -> Task Never (List (Result ScrollError ScrollOk))` | Composable scroll that continues after failures |
| `ScrollError` | type | Error with container, targetElementId, domError |
| `ScrollOk` | type alias | Success with container and targetElementId |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (px/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

For complete API details, see the [Scroll.Engine.Task](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Scroll-Task) documentation.


## Next Steps

Need state tracking, events, or mid-scroll control?

[Sub Engine →](sub.md){ .md-button .md-button--primary }
