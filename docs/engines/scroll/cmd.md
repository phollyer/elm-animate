# Scroll Cmd Engine

This page focuses on what makes this engine different, read [Scroll Engines Overview](overview.md) for features that are shared across all Scroll engines.

The Scroll Cmd Engine provides fire-and-forget scrolling. Call `animate` and the scroll happens — no state management needed.


## Live Example

<iframe src="../../../examples/src/Engines/Scroll/FirstScrollCmd/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Full Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/FirstScrollCmd/Main.elm"
    ```

📖 See [Your First Scrolls](../../getting-started/first-scrolls.md) for a step-by-step breakdown.


## Usage

### 1. Build

Define the scroll as a builder function:

```elm
import Anim.Engine.Scroll.Cmd as Scroll exposing (AnimBuilder)
import Anim.Engine.Scroll.Builder as ScrollTo
import Anim.Extra.Easing exposing (Easing(..))

scrollToElement : String -> AnimBuilder -> AnimBuilder
scrollToElement targetId =
    ScrollTo.forContainer "scroll-container"
        >> ScrollTo.toElement targetId
        >> ScrollTo.easing BounceOut
        >> ScrollTo.build
```

### 2. Trigger

Call `animate` from your `update` function. It takes a completion message and the builder function, and returns a `Cmd`:

```elm
type Msg
    = ScrollTo String
    | ScrollComplete

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScrollTo targetId ->
            ( model
            , Scroll.animate ScrollComplete <| scrollToElement targetId
            )

        ScrollComplete ->
            -- Scroll finished (or failed silently)
            ( model, Cmd.none )
```

No model state, subscriptions, or view attributes needed — `animate` returns a self-contained `Cmd`.

### Triggering While a Scroll Is Running

!!! warning "Retriggering causes short scrolls"
    Each call to `animate` pre-calculates its frame steps from the DOM scroll position at the moment the Cmd runs. If a new `animate` call fires while a previous scroll is still in flight, the second scroll measures from a mid-animation position and will stop short of its target.

    If you need to cancel and restart a scroll safely — for example when a user clicks a button repeatedly — use the [Scroll Sub Engine](sub.md), which replaces the running animation on each call.

### Multiple Concurrent Scrolls

Configure multiple scroll targets in the same builder pipeline. Each fires the completion message independently as it finishes:

```elm
scrollMultiple : AnimBuilder -> AnimBuilder
scrollMultiple =
    ScrollTo.forContainer "sidebar"
        >> ScrollTo.toElement "nav-item"
        >> ScrollTo.build
        >> ScrollTo.forContainer "main-content"
        >> ScrollTo.toElement "section-3"
        >> ScrollTo.build
```


## Under The Hood

??? info "How Cmd Execution Works"

    **Single scroll target:**

    1. DOM queries retrieve current scroll position and target element position
    2. Distance is calculated from current to target position
    3. Animation steps are pre-calculated based on distance, timing and easing
    4. Animation steps are sequenced into a `Task` chain
    5. `Task` chain is converted to a `Cmd` via `Task.attempt`
    6. Elm runtime receives the `Cmd` and executes each step in the `Task` chain in sequence
    7. Completion message fires with target identifier - errors are silently ignored

    **Multiple scroll targets:**

    - Each scroll is independently converted to a `Cmd` (following steps 1-5 above)
    - All `Cmd`s are `Cmd.batch`ed into a single `Cmd`
    - Elm runtime receives the single `Cmd` and executes all scrolls concurrently
    - Browser's rendering engine handles all simultaneous scroll animations in parallel
    - Each scroll fires the completion message independently as it finishes - errors are silently ignored

    **Completion behavior:**

    - The completion message fires when the scroll animation finishes (success or failure)
    - With multiple targets, the message fires once per target as each scroll completes
    - The `String` parameter identifies the target: element ID for element targets, or a description like "document:top" for position targets


## API Quick Reference

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `animate` | `msg -> (AnimBuilder -> AnimBuilder) -> Cmd msg` | Fire-and-forget scroll |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (px/sec) |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

For complete API details, see the [Anim.Engine.Scroll.Cmd](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-Scroll-Cmd) documentation.


## Next Steps

Need error handling or task composition?

[Scroll Task Engine →](task.md){ .md-button .md-button--primary }

Need state tracking, events, or mid-scroll control?

[Scroll Sub Engine →](sub.md){ .md-button .md-button--primary }
