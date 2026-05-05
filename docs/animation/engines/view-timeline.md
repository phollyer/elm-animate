# View Timeline Engine

This page focuses on what makes this Engine different, read [Engines Overview](overview.md) for features that are shared across all Engines.

The ViewTimeline Engine is a lightweight engine that uses the Browsers native `ViewTimeline` API.
It ties animation progress to the view position of an element inside a scrollable container. As
the user scrolls the element into, then out of, view, the animation progresses — no `AnimState`, `update`, or `subscriptions` required.

## Example

Scroll the page, and the different sections will fade in and slide
up as they are scrolled into view.

--8<-- "docs/animation/engines/waapi/timeline-animations.md:view-timeline-example"

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


## Subscriptions

Optionally subscribe to lifecycle events (start, end, cancel, iteration) from view-driven animations.

The incoming port must be wired up alongside the outgoing `waapiCommand` port:

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

Pass the message to `ViewTimeline.update` to get an `AnimEvent` to pattern match on.


## Trigger

Fire-and-forget, returns a `Cmd msg` with no state to store.

??? example "View Source Code"

    ```elm
    ViewTimeline.animate waapiCommand scrollAnimation
    ```

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

    ```em 
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

For complete API details, see the [Anim.Engine.WAAPI.ViewTimeline](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-WAAPI-ViewTimeline) documentation.
