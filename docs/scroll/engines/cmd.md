# Scroll Cmd Engine

This page is a practical guide to using the Cmd engine from setup through common real-world usage.
Read [Scroll Engines Overview](overview.md) when you want side-by-side comparisons and tradeoffs.

The Scroll Cmd Engine provides fire-and-forget scrolling. Call `scroll` and the scroll happens — no state management needed.


## Example

??? example "View Example"
    <iframe src="../../../examples/src/Scroll/Cmd/FirstScroll/index.html" class="example-iframe example-iframe--lg" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Cmd/FirstScroll/Main.elm"
    ```

📖 See [Your First Scrolls](../start-here.md) for a step-by-step breakdown.

---

## Quick Walkthrough

Get up and running in minutes.

### 1. Build

Define the scroll as a builder function:

??? example "View Source Code"

    ```elm
    import Scroll.Engine.Cmd as Cmd exposing (ScrollBuilder)
    import Scroll.Builder as Scroll
    import Motion.Easing as Easing exposing (Easing(..))

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement targetId =
        Scroll.forContainer "scroll-container"
            >> Scroll.toElement targetId
            >> Scroll.easing BounceOut
            >> Scroll.speed 400
            >> Scroll.build
    ```

### 2. Trigger

Call `scroll` from your `update` function. It takes a completion message and the builder function, and returns a `Cmd`:

??? example "View Source Code"

    ```elm
    type Msg
        = ScrollTo String
        | ScrollComplete

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollTo targetId ->
                ( model
                , Cmd.scroll ScrollComplete <|
                    scrollToElement targetId
                )

            ScrollComplete ->
                -- Scroll finished (or failed silently)
                ( model, Cmd.none )
    ```

No model state, subscriptions, or view attributes needed — `scroll` returns a self-contained `Cmd`.

Cmd scrolls are tied to how quickly the browser processes each update, so actual timing is affected by refresh rate and machine speed. If you need accurate timing use the [Sub](sub.md) Engine.

---

## In Detail

### Multiple Concurrent Scrolls

Configure multiple scroll targets in the same builder pipeline. Each fires the completion message independently as it finishes:

??? example "View Source Code"

    ```elm
    scrollMultiple : ScrollBuilder -> ScrollBuilder
    scrollMultiple =
        Scroll.forContainer "sidebar"
            >> Scroll.toElement "nav-item-3"
            >> Scroll.speed 300
            >> Scroll.build
            >> Scroll.forContainer "main-content"
            >> Scroll.toElement "section-3"
            >> Scroll.speed 400
            >> Scroll.build
    ```

With multiple targets, `Cmd.scroll` batches them into a single `Cmd`, but each target still completes independently. The completion message fires once per target, using the message value you supplied when triggering the scroll.

### Triggering While a Scroll Is Running

If the same `scroll` call fires repeatedly, say from repeated button clicks, each scroll will run independently - and they will all compete for control of the container. This can lead to scrolls finishing short of their target.

To prevent this, either guard the triggering with your own internal state, or use the [Scroll Sub Engine](sub.md), which replaces the running scroll on each call.


### API Quick Reference

#### Types

| Type | Description |
| ---- | ----------- |
| `ScrollBuilder` | Carries scroll configuration in the builder pipeline |

#### Trigger

| Function | Type | Description |
| -------- | ---- | ----------- |
| `scroll` | `msg -> (ScrollBuilder -> ScrollBuilder) -> Cmd msg` | Fire-and-forget scroll command |

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

For complete API details, see the [Scroll.Engine.Cmd](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Scroll-Engine-Cmd) documentation.


### Next Steps

Need error handling or task composition?

[Task Engine →](task.md){ .md-button .md-button--primary }

Need state tracking, events, or mid-scroll control?

[Sub Engine →](sub.md){ .md-button .md-button--primary }
