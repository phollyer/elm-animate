# Scroll Task Engine

This page focuses on what makes this engine different, read [Scroll Engines Overview](overview.md) for features that are shared across all Scroll engines.

The Scroll Task Engine provides composable scrolling with typed error handling. Use it when you need to chain scroll operations, handle failures, or compose scrolls with other `Task`s.


## Live Example

<iframe src="../../../examples/src/Engines/Scroll/FirstScrollTask/index.html" style="width: 100%; height: 550px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Full Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/FirstScrollTask/Main.elm"
    ```

📖 See [Your First Scrolls](../../getting-started/first-scrolls.md) for a step-by-step breakdown.


## Usage

### 1. Build

Define the scroll as a builder function:

```elm
import Anim.Engine.Scroll.Task as Scroll exposing (AnimBuilder)
import Anim.Engine.Scroll.Builder as ScrollTo
import Anim.Extra.Easing exposing (Easing(..))
import Task

scrollToElement : AnimBuilder -> AnimBuilder
scrollToElement =
    ScrollTo.forContainer "scroll-container"
        >> ScrollTo.toElement "target-section"
        >> ScrollTo.easing BounceOut
        >> ScrollTo.build
```

### 2. Trigger

Call `animate` to get a `Task`, then convert it to a `Cmd` with `Task.attempt`:

```elm
type Msg
    = ScrollTo
    | ScrollResult (Result Scroll.ScrollError Scroll.ScrollOk)

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScrollTo ->
            ( model
            , Scroll.animate scrollToElement
                |> Task.attempt ScrollResult
            )
```

### 3. Handle the Result

The `Result` gives you typed success or failure:

```elm
        ScrollResult result ->
            case result of
                Ok scrollOk ->
                    -- scrollOk.containerId : String
                    -- scrollOk.targetElementId : Maybe String
                    ( { model | status = "Arrived" }
                    , Cmd.none
                    )

                Err (Scroll.ScrollError error) ->
                    -- error.containerId : String
                    -- error.targetElementId : Maybe String
                    -- error.domError : Dom.Error
                    ( { model | status = "Scroll failed" }
                    , Cmd.none
                    )
```

### ScrollOk

`ScrollOk` is delivered when the scroll completes successfully:

| Field | Type | Description |
| ----- | ---- | ----------- |
| `containerId` | `String` | ID of the element that was scrolled |
| `targetElementId` | `Maybe String` | ID of the target element, if scrolled to an element |

### ScrollError

`ScrollError` is delivered when the scroll fails - for example, when an element ID does not exist in the DOM:

| Field | Type | Description |
| ----- | ---- | ----------- |
| `containerId` | `String` | ID of the container that was being scrolled |
| `targetElementId` | `Maybe String` | ID of the target element, if one was specified |
| `domError` | `Dom.Error` | The underlying [Dom.Error](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Dom#Error) |


## Error Handling

`ScrollError` carries structured information about what went wrong:

```elm
type ScrollError
    = ScrollError
        { containerId : String
        , targetElementId : Maybe String
        , domError : Dom.Error
        }
```

Errors typically occur when a target element doesn't exist in the DOM. The `domError` field gives the underlying `Browser.Dom.Error` for diagnostics.


## Task Composition

If you already know the final target, use a single scroll:

```elm
Scroll.animate (scrollToSection "first-paragraph")
    |> Task.attempt GotScrollResult
```

Chain scroll Tasks only when you truly have a multi-step flow, such as nested scrollable containers or when the second target is only known after another Task completes:

```elm
-- Nested containers: scroll outer container first, then inner container
Scroll.animate (scrollOuterToSection "chapter-2")
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

```elm
scrollSequence : AnimBuilder -> AnimBuilder
scrollSequence =
    ScrollTo.forDocument
        >> ScrollTo.toElement "section-1"
        >> ScrollTo.build
        >> ScrollTo.forDocument
        >> ScrollTo.toElement "section-2"
        >> ScrollTo.build
```

### Triggering While a Scroll Is Running

!!! warning "Retriggering causes short scrolls"
    Each call to `animate` pre-calculates its frame steps from the DOM scroll position at the moment the Task runs. If a new `animate` call fires while a previous scroll is still in flight, the second scroll measures from a mid-animation position and will stop short of its target.

    If you need to cancel and restart a scroll safely — for example when a user clicks a button repeatedly — use the [Scroll Sub Engine](sub.md), which replaces the running animation on each call.

### Concurrent Scrolls with Individual Error Handling

Create separate builders and batch their `Cmd`s:

```elm
( model
, Cmd.batch
    [ Scroll.animate scrollSidebar |> Task.attempt SidebarResult
    , Scroll.animate scrollMain |> Task.attempt MainResult
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
    - Returns `ScrollOk` only if all scrolls succeed, with details of the last completed scroll

    **Multiple concurrent scroll targets:**

    - Each scroll is independently converted to a `Task` (following steps 1-5 above)
    - Each `Task` is independently converted to a `Cmd` via `Task.attempt`
    - All `Cmd`s are `Cmd.batch`ed into a single `Cmd`
    - Elm runtime receives the single `Cmd` and executes all scrolls concurrently
    - Browser's rendering engine handles all simultaneous scroll animations in parallel
    - Each scroll returns its own `ScrollOk` or `ScrollError` independently

    **Error handling:**

    - Returns `ScrollOk` on success with details about the completed scroll
    - Returns `ScrollError` on failure with details about what failed
    - Errors typically occur when target elements don't exist in the DOM
    - Can be composed with other tasks using `Task.andThen`, `Task.map`, etc.


## API Quick Reference

| Function / Type | Type | Description |
| ---------- | ------ | ------------- |
| `animate` | `(AnimBuilder -> AnimBuilder) -> Task ScrollError ScrollOk` | Composable scroll with error handling |
| `ScrollError` | type | Error with containerId, targetElementId, domError |
| `ScrollOk` | type alias | Success with containerId and targetElementId |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (px/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

For complete API details, see the [Anim.Engine.Scroll.Task](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Scroll-Task) documentation.


## Next Steps

Need state tracking, events, or mid-scroll control?

[Scroll Sub Engine →](sub.md){ .md-button .md-button--primary }
