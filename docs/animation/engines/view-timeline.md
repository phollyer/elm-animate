# View Timeline Engine

This page is a practical guide to using the ViewTimeline engine from setup through production patterns.
Read [Engines Overview](overview.md) when you want side-by-side comparisons and tradeoffs.

The ViewTimeline Engine is a lightweight engine that uses the Browsers native `ViewTimeline` API.
It ties animation progress to the view position of an element inside a scrollable container. As
the user scrolls the element into, then out of, view, the animation progresses — no `AnimState`
required. `update` and `subscriptions` are optional, and only needed if you want to react to
lifecycle events.

## Example

Scroll the page, and the different sections will fade in and slide
up as they are scrolled into view.

--8<-- "docs/animation/engines/waapi/timeline-animations.md:view-timeline-example"

The walkthrough below is a standalone minimal reference flow — it is not the implementation of the example above.

## End-to-End Walkthrough

This minimal flow covers the full lifecycle: define a view-driven animation, trigger it, render attributes, and optionally react to events.

### 1. Setup and Messages

Define the ports and a `Msg` variant for lifecycle events. See [Setup](#setup) for JavaScript companion install instructions.

??? example "View Source Code"

    ```elm
    port waapiCommand : Json.Encode.Value -> Cmd msg
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg


    type Msg
        = GotViewMsg ViewTimeline.AnimMsg
    ```

### 2. Define the Animation

Set `rangeStart` and `rangeEnd` to control when the animation begins and ends. See [Range](#range) for all available `Range` constructors.

??? example "View Source Code"

    ```elm
    reveal : ViewTimeline.AnimBuilder -> ViewTimeline.AnimBuilder
    reveal =
        ViewTimeline.rangeStart (ViewTimeline.Entry 0 ViewTimeline.Perc)
            >> ViewTimeline.rangeEnd (ViewTimeline.Entry 100 ViewTimeline.Perc)
            >> Opacity.for "section"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build
    ```

### 3. Trigger with `animate`

Call `animate` to send a fire-and-forget view-driven animation command. See [Trigger](#trigger) for full details.

??? example "View Source Code"

    ```elm
    startReveal : Cmd Msg
    startReveal =
        ViewTimeline.animate waapiCommand reveal
    ```

### 4. View

Render attributes on the element being tracked by the view timeline. See [View](#view) for full details.

??? example "View Source Code"

    ```elm
    view : Html Msg
    view =
        section (ViewTimeline.attributes "section") [ text "Reveal me" ]
    ```

### 5. Optional Subscriptions and `update`

Subscribe only when you need lifecycle events in Elm. See [Subscriptions](#subscriptions) and [Update](#update) for full event handling.

??? example "View Source Code"

    ```elm
    subscriptions : Model -> Sub Msg
    subscriptions _ =
        ViewTimeline.subscriptions GotViewMsg waapiEvent


    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotViewMsg animMsg ->
                case ViewTimeline.update animMsg of
                    Just (ViewTimeline.Ended _) ->
                        ( model, Cmd.none )

                    _ ->
                        ( model, Cmd.none )
    ```


## Setup

Uses the same JavaScript companion as the WAAPI Engine. See [WAAPI JavaScript](../../installation.md#waapi-javascript) for CDN and NPM install instructions.

Only the outgoing port is needed:

??? example "View Source Code"

    ```elm
    port module Main exposing (main)

    import Json.Encode


    -- Outgoing port (Elm → JS): sends animation commands
    port waapiCommand : Json.Encode.Value -> Cmd msg
    ```

!!! info "Browser support"
    `ViewTimeline` is part of the [CSS Scroll-Driven Animations](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_scroll-driven_animations) spec. Check [caniuse.com](https://caniuse.com/css-scroll-driven-animations) for current browser support.
    For older browsers, the `elm-animate-waapi` JavaScript companion automatically loads the [`scroll-timeline-polyfill`](https://github.com/flackr/scroll-timeline) when the native API is not available.


## Trigger

Fire-and-forget, returns a `Cmd msg` with no state to store.

??? example "View Source Code"

    ```elm
    ViewTimeline.animate waapiCommand scrollAnimation
    ```


## Subscriptions

Optionally subscribe to lifecycle events.

The function takes your `Msg` type and the incoming events port function.

??? example "View Source Code"

    ```elm
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    type Msg
        = GotViewMsg ViewTimeline.AnimMsg
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        ViewTimeline.subscriptions GotViewMsg waapiEvent
    ```

Pass the message to `update` to get a `Maybe AnimEvent` to pattern match on.


## Update

Optionally handle animation events in your update function. The `update` function returns
`Maybe AnimEvent` — `Nothing` if the message was not intended for this animation.

??? example "View Source Code"

    ```elm
    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotViewMsg animMsg ->
                case ViewTimeline.update animMsg of
                    Just (ViewTimeline.Ended animGroup) ->
                        handleAnimationEnd animGroup model

                    Just (ViewTimeline.Iteration animGroup count) ->
                        handleIteration animGroup count model

                    _ ->
                        ( model, Cmd.none )

            ...
    ```

📖 See [Event Reference](https://phollyer.github.io/elm-animate/animation/workflow/react/#event-reference) in the docs for all available events.

## View

Use `attributes` with the AnimGroupName to set the required attributes on
the element being animated:

??? example "View Source Code"

    ```elm
    div 
        (ViewTimeline.attributes "hero-card") 
        [ text "I animate as the user scrolls" ]
    ```


## Range

Setting the range determines when the animation will start and end in relation to it's position in the viewport.

The Engine has two functions for this; `rangeStart` and `rangeEnd`.

Use the `Range` type to construct start and end values.

??? example "Show Source Code"

    ```elm 
    -- Built-in Library types
    type Unit 
        = Px
        | Perc
        
    type Range
        = Cover Float Unit
        | Contain Float Unit
        | Entry Float Unit
        | EntryCrossing Float Unit
        | Exit Float Unit
        | ExitCrossing Float Unit
        | Scroll Float Unit

    -- Example usage
    ViewTimeline.animate waapiCommand <|
        ViewTimeline.rangeStart (Entry 0 Perc)
            >> ViewTimeline.rangeEnd (Entry 100 Perc)
            >> ...
    ```

| Constructor | 0 is when… | 100% / max is when… |
| ----------- | ----------- | -------------------- |
| `Cover` | Element's leading edge first enters the viewport | Element's trailing edge leaves the viewport |
| `Contain` | Element is fully contained in the viewport | Element is no longer fully contained in the viewport |
| `Entry` | Element's leading edge first enters the viewport | Element has fully entered the viewport |
| `EntryCrossing` | Element's leading edge first enters the viewport | Element has fully entered the viewport |
| `Exit` | Element's leading edge starts to leave the viewport | Element has fully left the viewport |
| `ExitCrossing` | Element's leading edge starts to leave the viewport | Element has fully left the viewport |
| `Scroll` | Scroll container is at its very start | Scroll container is at its very end |

Both `rangeStart` and `rangeEnd` are optional — omitting them defaults to starting when the element's leading edge crosses the entry boundry, and ending when the element's trailing edge crosses the exit boundary - this is equivalent to `rangeStart (Cover 0 Perc)` and `rangeEnd (Cover 100 Perc)`.

It may appear from the table that both `Entry*` variants exhibit the same behaviour and so do both `Exit*` variants.
However, there are nuanced differencies in behaviour depending on whether the element being animated is larger or smaller than the viewport it sits in. The easiest way to understand these is visually with this [tool](https://scroll-driven-animations.style/tools/view-timeline/ranges).



## Horizontal Axis

Vertical tracking is the default. Call `horizontal` in the pipeline when the element is inside a container that scrolls left and right:

??? example "View Source Code"

    ```elm
    ViewTimeline.animate waapiCommand <|
        ViewTimeline.horizontal
            >> Opacity.for "slide"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build
    ```


## Playback

`iterations` and `alternate` work the same as in other engines, with one difference: for view-driven animations, `alternate` only has an effect when `iterations > 1`. Calling `alternate` without first calling `iterations` will automatically set iterations to `2`.

📖 See [Playback](overview.md) in the Engines Overview for details.


## Easing

📖 See [Easing](../concepts/easing.md) for available easing functions.


## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimBuilder` | Carries all animation configuration for a view-driven animation |
| `Range` | A position along the view timeline — use the constructors to create values |
| `Unit` | The unit for a range offset — `Perc` or `Px` |

### Trigger

| Function | Type | Description |
| -------- | ---- | ----------- |
| `animate` | `(Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg` | Fire-and-forget view-driven animation |

### View

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `attributes` | `String -> List (Html.Attribute msg)` | Attach the animation group identifier to an element |

### Range

| Function | Type | Description |
| -------- | ---- | ----------- |
| `rangeStart` | `Range -> AnimBuilder -> AnimBuilder` | Set when the animation begins |
| `rangeEnd` | `Range -> AnimBuilder -> AnimBuilder` | Set when the animation ends |
| `Cover` | `Float -> Unit -> Range` | Full element coverage — start or end |
| `Contain` | `Float -> Unit -> Range` | Full element containment — start or end |
| `Entry` | `Float -> Unit -> Range` | Element entering the viewport |
| `EntryCrossing` | `Float -> Unit -> Range` | Leading edge crossing |
| `Exit` | `Float -> Unit -> Range` | Element leaving the viewport |
| `ExitCrossing` | `Float -> Unit -> Range` | Trailing edge crossing |
| `Scroll` | `Float -> Unit -> Range` | Full scroll container range — start or end |
| `Perc` | `Unit` | Percentage unit |
| `Px` | `Unit` | Pixel unit |

### Axis

| Function | Type | Description |
| -------- | ---- | ----------- |
| `horizontal` | `AnimBuilder -> AnimBuilder` | Use horizontal viewport tracking |

### Playback

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `iterations` | `Int -> AnimBuilder -> AnimBuilder` | Set number of iterations |
| `alternate` | `AnimBuilder -> AnimBuilder` | Reverse direction on each iteration |

### Easing

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set the easing function |

## When to Choose This Engine

Choose ViewTimeline when playback should follow how an element moves through the viewport.

- Best for: section reveals, scroll storytelling, and enter/exit viewport choreography.
- Avoid when: you need pause/resume/stop/reset controls or AnimState queries.
- Prefer: [Scroll Timeline](scroll-timeline.md) when progress should follow container scroll position rather than element visibility.

For complete API details, see the [Anim.Engine.WAAPI.ViewTimeline](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-WAAPI-ViewTimeline) documentation.

## Next Steps

Compare timeline engines and migration paths:

- [Scroll Timeline Engine](scroll-timeline.md)
- [WAAPI Engine](waapi.md)
- [Migration Guide](migration-guide.md)

[Migration Guide ->](migration-guide.md){ .md-button .md-button--primary }
