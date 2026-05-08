# View Timeline Engine

This page is a practical guide to using the ViewTimeline engine from setup through common real-world usage.
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

---

## Quick Walkthrough

Get up and running in minutes.

### 1. Build

Set `rangeStart` and `rangeEnd` to control when the animation begins and ends. See [Range](#range) for all available `Range` constructors.

??? example "View Source Code"

    ```elm
    import Anim.Property.Opacity as Opacity


    reveal : ViewTimeline.AnimBuilder -> ViewTimeline.AnimBuilder
    reveal =
        ViewTimeline.rangeStart (ViewTimeline.Entry 0 ViewTimeline.Perc)
            >> ViewTimeline.rangeEnd (ViewTimeline.Entry 100 ViewTimeline.Perc)
            >> Opacity.for "section"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build
    ```

### 2. Render

Render attributes on the element being tracked by the view timeline. See [View](#view) for full details.

??? example "View Source Code"

    ```elm
    view : Html Msg
    view =
        section (ViewTimeline.attributes "section") [ text "Reveal me" ]
    ```

### 3. Trigger with `animate`

Call `animate` to send a fire-and-forget view-driven animation command. See [Trigger](#trigger) for JavaScript companion install instructions and full details.

??? example "View Source Code"

    ```elm
    port module Main exposing (main)

    import Anim.Engine.WAAPI.ViewTimeline as ViewTimeline
    import Json.Encode


    port waapiCommand : Json.Encode.Value -> Cmd msg


    startReveal : Cmd Msg
    startReveal =
        ViewTimeline.animate waapiCommand reveal
    ```

### 4. Optional React

Subscribe only when you need lifecycle events in Elm. See [Subscriptions](#subscriptions) and [Update](#update) for full event handling.

??? example "View Source Code"

    ```elm
    import Json.Decode


    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg


    type Msg
        = GotViewMsg ViewTimeline.AnimMsg


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

---

## In Detail

### Trigger

This engine uses the same JavaScript companion as the WAAPI engine. Only the outgoing port is needed.

📖 See [WAAPI JavaScript](../../installation.md#waapi-javascript) for CDN and NPM install instructions.

!!! info "Browser support"
    `ViewTimeline` is part of the [CSS Scroll-Driven Animations](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_scroll-driven_animations) spec. Check [caniuse.com](https://caniuse.com/css-scroll-driven-animations) for current browser support.
    The `@phollyer/elm-motion` companion automatically loads the [`scroll-timeline-polyfill`](https://github.com/flackr/scroll-timeline) when the native API is not available.

Fire-and-forget, returns a `Cmd msg` with no state to store.

??? example "View Source Code"

    ```elm
    port module Main exposing (main)

    import Json.Encode

    port waapiCommand : Json.Encode.Value -> Cmd msg

    ViewTimeline.animate waapiCommand scrollAnimation
    ```

### Events

Subscribing to events is optional. If you only need the visual animation, no subscription or `update` is required.

The incoming port is only needed if you want lifecycle events:

??? example "View Source Code"

    ```elm
    handleAnimEvent : Maybe ViewTimeline.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimEvent maybeEvent model =
        case maybeEvent of
            Just (ViewTimeline.Ended "hero-card") ->
                ( model, Cmd.none )

            Just (ViewTimeline.Iteration "hero-card" count) ->
                ( model, Cmd.none )

            Just (ViewTimeline.AnimError err) ->
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )
    ```

### Update

If subscribing to events, handle animation messages in your update function. `update` returns `Maybe AnimEvent`.

??? example "View Source Code"

    ```elm
    GotViewMsg animMsg ->
        case ViewTimeline.update animMsg of
            Just (ViewTimeline.Ended animGroup) ->
                handleAnimationEnd animGroup model

            Just (ViewTimeline.Iteration animGroup count) ->
                handleIteration animGroup count model

            _ ->
                ( model, Cmd.none )
    ```

### Subscriptions

Pass the message constructor and the incoming events port to receive lifecycle events.

??? example "View Source Code"

    ```elm
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        ViewTimeline.subscriptions GotViewMsg waapiEvent
    ```

### View

Apply `attributes` to the animated element to attach the required animation group identifier.

??? example "View Source Code"

    ```elm
    div
        (ViewTimeline.attributes "hero-card")
        [ text "I animate as the user scrolls" ]
    ```

### Axis

Vertical tracking is the default. Call `horizontal` in the animation pipeline when the element is inside a container that scrolls left and right.

??? example "View Source Code"

    ```elm
    ViewTimeline.animate waapiCommand <|
        ViewTimeline.horizontal
            >> Opacity.for "slide"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build
    ```

### Range

Setting the range determines when the animation starts and ends relative to the element's position in the viewport.

Use `rangeStart` and `rangeEnd` with `Range` constructor values. Both are optional — omitting them defaults to `Cover 0 Perc` through `Cover 100 Perc`.

??? example "Show Source Code"

    ```elm
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

For nuanced differences between `Entry`/`EntryCrossing` and `Exit`/`ExitCrossing` depending on element size, see this [interactive tool](https://scroll-driven-animations.style/tools/view-timeline/ranges).

### Playback

`iterations` and `alternate` work the same as in other engines, with one difference: `alternate` only has an effect when `iterations > 1`. Calling `alternate` without first calling `iterations` will automatically set iterations to `2`.

📖 See [Playback](overview.md) in the Engines Overview for details.

### Easing

📖 See [Easing](../concepts/easing.md) for available easing functions.

### Discrete Properties

The ViewTimeline engine manages discrete properties as inline styles. `discreteEntry` values are applied from the first animation frame, and `discreteExit` values flip on the last frame. No additional view setup is needed.

📖 See [Discrete Properties](../concepts/discrete-properties.md) for the full API, live examples, and source code.

### Transform Order

Use `transformOrder` to set the order in which transform properties are applied.

??? example "View Source Code"

    ```elm
    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    ViewTimeline.animate waapiCommand <|
        ViewTimeline.transformOrder [ Scale, Rotate, Translate ]
            >> Translate.for "slide"
            >> ...
    ```

📖 See [Transform Order](../concepts/transform-order.md) for full details.


### When to Choose This Engine

Choose ViewTimeline when playback should follow how an element moves through the viewport.

- Best for: section reveals, scroll storytelling, and enter/exit viewport choreography.
- Avoid when: you need pause/resume/stop/reset controls or AnimState queries.
- Prefer: [Scroll Timeline](scroll-timeline.md) when progress should follow container scroll position rather than element visibility.

### API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimBuilder` | Carries all animation configuration |
| `AnimMsg` | Internal engine messages |
| `AnimEvent` | Events returned by `update` |
| `AnimGroupName` | `String` type alias for the animation group name |
| `Range` | A position along the view timeline |
| `Unit` | The unit for a range offset — `Perc` or `Px` |
| `TransformProperty` | Custom transform ordering |

### Trigger

| Function | Type | Description |
| -------- | ---- | ----------- |
| `animate` | `(Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg` | Fire-and-forget view-driven animation |

### Events

| Event | Description |
| ----- | ----------- |
| `Ended AnimGroupName` | Animation completes |
| `Cancelled AnimGroupName Float` | Animation cancelled; `Float` is progress at cancellation |
| `Iteration AnimGroupName Int` | Loop iteration completes; `Int` is iteration count |
| `AnimError String` | JavaScript-layer error |

### Update

| Function | Type | Description |
| -------- | ---- | ----------- |
| `update` | `AnimMsg -> Maybe AnimEvent` | Process messages and return an optional event |

### Subscriptions

| Function | Type | Description |
| -------- | ---- | ----------- |
| `subscriptions` | `(AnimMsg -> msg) -> ((Value -> msg) -> Sub msg) -> Sub msg` | Subscribe to animation events from JavaScript |

### View

| Function | Type | Description |
| -------- | ---- | ----------- |
| `attributes` | `AnimGroupName -> List (Html.Attribute msg)` | Attach the animation group identifier to an element |

### Axis

| Function | Type | Description |
| -------- | ---- | ----------- |
| `horizontal` | `AnimBuilder -> AnimBuilder` | Use horizontal viewport tracking |

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

### Playback

| Function | Type | Description |
| -------- | ---- | ----------- |
| `iterations` | `Int -> AnimBuilder -> AnimBuilder` | Set number of iterations |
| `alternate` | `AnimBuilder -> AnimBuilder` | Reverse direction on each iteration |

### Easing

| Function | Type | Description |
| -------- | ---- | ----------- |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set the easing function |

### Discrete Properties

| Function | Type | Description |
| -------- | ---- | ----------- |
| `discreteEntry` | `String -> String -> AnimBuilder -> AnimBuilder` | Set a CSS property value when the animation starts |
| `discreteExit` | `String -> String -> String -> AnimBuilder -> AnimBuilder` | Set a CSS property value during and after the animation |

### Transform Order

| Function | Type | Description |
| -------- | ---- | ----------- |
| `transformOrder` | `List TransformProperty -> AnimBuilder -> AnimBuilder` | Set custom transform order |

For complete API details, see the [Anim.Engine.WAAPI.ViewTimeline](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-WAAPI-ViewTimeline) documentation.

### Next Steps

Compare timeline engines and migration paths:

- [Scroll Timeline Engine](scroll-timeline.md)
- [WAAPI Engine](waapi.md)
- [Migration Guide](migration-guide.md)

[Migration Guide ->](migration-guide.md){ .md-button .md-button--primary }
