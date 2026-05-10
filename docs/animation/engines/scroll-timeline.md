# ScrollTimeline Engine

This page is a practical guide to using the ScrollTimeline engine from setup through common real-world usage.
Read [Engines Overview](overview.md) when you want side-by-side comparisons and tradeoffs.

The ScrollTimeline Engine is a lightweight engine that uses the Browsers native `ScrollTimeline` API.
It ties animation progress to the scroll position of a scrollable element. As the user scrolls, the
animation progresses — no `AnimState` required. `update` and `subscriptions` are optional, and only
needed if you want to react to lifecycle events.

## Example

Scroll the page, and the progress bar will animate in response.

--8<-- "docs/animation/engines/waapi/timeline-animations.md:scroll-timeline-example"

---

## Quick Walkthrough

Get up and running in minutes.

### 1. Build

??? example "View Source Code"

    ```elm
    import Anim.Property.Opacity as Opacity


    scrollAnimation : ScrollTimeline.AnimBuilder mode -> ScrollTimeline.AnimBuilder mode
    scrollAnimation =
        Opacity.for "progress"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build
    ```

### 2. Render

Render attributes on the element being animated. See [View](#view) for full details.

??? example "View Source Code"

    ```elm
    view : Html Msg
    view =
        div (ScrollTimeline.attributes "progress") [ text "Progress" ]
    ```

### 3. Trigger with `animate`

Call `animate` to send a fire-and-forget scroll-driven animation command. See [Trigger](#trigger) for JavaScript companion install instructions and choosing the scroll container.

??? example "View Source Code"

    ```elm
    port module Main exposing (main)

    import Anim.Engine.ScrollTimeline as ScrollTimeline
    import Json.Encode


    port motionCmd : Json.Encode.Value -> Cmd msg


    startScrollAnimation : Cmd Msg
    startScrollAnimation =
        ScrollTimeline.animate motionCmd ScrollTimeline.Document scrollAnimation
    ```

### 4. Optional React

Subscribe only when you need lifecycle events in Elm. See [Subscriptions](#subscriptions) and [Update](#update) for full event handling.

??? example "View Source Code"

    ```elm
    import Json.Decode


    port motionMsg : (Json.Decode.Value -> msg) -> Sub msg


    type Msg
        = GotScrollMsg ScrollTimeline.AnimMsg


    subscriptions : Model -> Sub Msg
    subscriptions _ =
        ScrollTimeline.subscriptions GotScrollMsg motionMsg


    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotScrollMsg animMsg ->
                case ScrollTimeline.update animMsg of
                    Just (ScrollTimeline.Ended _) ->
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
    `ScrollTimeline` is part of the [CSS Scroll-Driven Animations](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_scroll-driven_animations) spec. Check [caniuse.com](https://caniuse.com/css-scroll-driven-animations) for current browser support.
    The `@phollyer/elm-motion` companion automatically loads the [`scroll-timeline-polyfill`](https://github.com/flackr/scroll-timeline) when the native API is not available.

Fire-and-forget. Returns a `Cmd msg` with no state to store.

??? example "View Source Code"

    ```elm
    port module Main exposing (main)

    import Json.Encode

    port motionCmd : Json.Encode.Value -> Cmd msg

    ScrollTimeline.animate motionCmd (Container "carousel") scrollAnimation
    ```

### Events

Subscribing to events is optional. If you only need the visual animation, no subscription or `update` is required.

The incoming port is only needed if you want lifecycle events:

??? example "View Source Code"

    ```elm
    handleAnimEvent : Maybe ScrollTimeline.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimEvent maybeEvent model =
        case maybeEvent of
            Just (ScrollTimeline.Ended "hero-card") ->
                ( model, Cmd.none )

            Just (ScrollTimeline.Iteration "hero-card" count) ->
                ( model, Cmd.none )

            Just (ScrollTimeline.AnimError err) ->
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )
    ```

### Update

If subscribing to events, handle animation messages in your update function. `update` returns `Maybe AnimEvent`.

??? example "View Source Code"

    ```elm
    GotScrollMsg animMsg ->
        case ScrollTimeline.update animMsg of
            Just (ScrollTimeline.Ended animGroup) ->
                handleAnimationEnd animGroup model

            Just (ScrollTimeline.Iteration animGroup count) ->
                handleIteration animGroup count model

            _ ->
                ( model, Cmd.none )
    ```

### Subscriptions

Pass the message constructor and the incoming events port to receive lifecycle events.

??? example "View Source Code"

    ```elm
    port motionMsg : (Json.Decode.Value -> msg) -> Sub msg

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        ScrollTimeline.subscriptions GotScrollMsg motionMsg
    ```

### View

Apply `attributes` to the animated element to attach the required animation group identifier.

??? example "View Source Code"

    ```elm
    div
        (ScrollTimeline.attributes "hero-card")
        [ text "I animate as the user scrolls" ]
    ```

### Axis

Vertical scroll is the default. Call `horizontal` in the animation pipeline when the container scrolls left and right.

??? example "View Source Code"

    ```elm
    ScrollTimeline.animate motionCmd (Container "carousel") <|
        ScrollTimeline.horizontal
            >> Opacity.for "slide"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build
    ```

### Playback

`iterations` and `alternate` work the same as in other engines, with one difference: `alternate` only has an effect when `iterations > 1`. If `iterations` is not set or is less than two when `alternate` is called, `iterations` defaults to two.

📖 See [Playback](overview.md) in the Engines Overview for details.

### Easing

📖 See [Easing](../concepts/easing.md) for available easing functions.

### Discrete Properties

The ScrollTimeline engine manages discrete properties as inline styles. `discreteEntry` values are applied from the first animation frame, and `discreteExit` values flip on the last frame. No additional view setup is needed.

📖 See [Discrete Properties](../concepts/discrete-properties.md) for the full API, live examples, and source code.

### Transform Order

Use `transformOrder` to set the order in which transform properties are applied.

??? example "View Source Code"

    ```elm
    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    ScrollTimeline.animate motionCmd (Container "carousel") <|
        ScrollTimeline.transformOrder [ Scale, Rotate, Translate ]
            >> Translate.for "slide"
            >> ...
    ```

📖 See [Transform Order](../concepts/transform-order.md) for full details.

### When to Choose This Engine

Choose ScrollTimeline when progress should be directly tied to scroll position.

- Best for: progress bars, scroll-driven reveals, and container-linked choreography.
- Avoid when: you need pause/resume/stop/reset controls or AnimState queries.
- Prefer: [WAAPI](waapi.md) when you need full control APIs, or [View Timeline](view-timeline.md) when the trigger is viewport visibility.


### API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimBuilder mode` | Carries all animation configuration |
| `AnimMsg` | Internal engine messages |
| `AnimEvent` | Events returned by `update` |
| `AnimGroupName` | `String` type alias for the animation group name |
| `Container` | Scroll source — `Document` or `Container "id"` |
| `TransformProperty` | Custom transform ordering |

### Trigger

| Function | Type | Description |
| -------- | ---- | ----------- |
| `animate` | `(Value -> Cmd msg) -> Container -> (AnimBuilder mode -> AnimBuilder mode) -> Cmd msg` | Fire-and-forget scroll-driven animation |

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
| `horizontal` | `AnimBuilder mode -> AnimBuilder mode` | Use horizontal scroll as the timeline source |

### Playback

| Function | Type | Description |
| -------- | ---- | ----------- |
| `iterations` | `Int -> AnimBuilder mode -> AnimBuilder mode` | Set number of iterations |
| `alternate` | `AnimBuilder mode -> AnimBuilder mode` | Reverse direction on each iteration |

### Easing

| Function | Type | Description |
| -------- | ---- | ----------- |
| `easing` | `Easing -> AnimBuilder mode -> AnimBuilder mode` | Set the easing function |

### Discrete Properties

| Function | Type | Description |
| -------- | ---- | ----------- |
| `discreteEntry` | `String -> String -> AnimBuilder mode -> AnimBuilder mode` | Set a CSS property value when the animation starts |
| `discreteExit` | `String -> String -> String -> AnimBuilder mode -> AnimBuilder mode` | Set a CSS property value during and after the animation |

### Transform Order

| Function | Type | Description |
| -------- | ---- | ----------- |
| `transformOrder` | `List TransformProperty -> AnimBuilder mode -> AnimBuilder mode` | Set custom transform order |

For complete API details, see the [Anim.Engine.ScrollTimeline](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-ScrollTimeline) documentation.

### Next Steps

Explore the ViewTimeline Engine:

[View Timeline Engine](view-timeline.md){ .md-button .md-button--primary }


Or review migration paths and tradeoffs.

[Migration Guide →](migration-guide.md){ .md-button .md-button--primary }
