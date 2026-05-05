# ScrollTimeline Engine

This page focuses on what makes this Engine different, read [Engines Overview](overview.md) for features
that are shared across all Engines.

The ScrollTimeline Engine is a lightweight engine that uses the Browsers native `ScrollTimeline` API.
It ties animation progress to the scroll position of a scrollable element. As the user scrolls, the
animation progresses — no `AnimState` required. `update` and `subscriptions` are optional, and only
needed if you want to react to lifecycle events.

## Example

Scroll the page, and the progress bar will animate in response.

--8<-- "docs/animation/engines/waapi/timeline-animations.md:scroll-timeline-example"

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
    `ScrollTimeline` is part of the [CSS Scroll-Driven Animations](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_scroll-driven_animations) spec. Check [caniuse.com](https://caniuse.com/css-scroll-driven-animations) for current browser support.
    For older browsers, the `elm-animate-waapi` JavaScript companion automatically loads the [`scroll-timeline-polyfill`](https://github.com/flackr/scroll-timeline) when the native API is not available.


## Trigger

Fire-and-forget. Returns a `Cmd msg` with no state to store.

??? example "View Source Code"

    ```elm
    ScrollTimeline.animate waapiCommand (Container "carousel") scrollAnimation
    ```


## Subscriptions

Optionally subscribe to lifecycle events.

The function takes your `Msg` type and the incoming events port function.

??? example "View Source Code"

    ```elm
    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    type Msg
        = GotScrollMsg ScrollTimeline.AnimMsg
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        ScrollTimeline.subscriptions GotScrollMsg waapiEvent
    ```

Pass the message to `update` to get a `Maybe AnimEvent`.


## Update

Optionally handle animation events in your update function. The `update` function returns
`Maybe AnimEvent` — `Nothing` if the message was not intended for this animation.

??? example "View Source Code"

    ```elm
    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotScrollMsg animMsg ->
                case ScrollTimeline.update animMsg of
                    Just (ScrollTimeline.Ended animGroup) ->
                        handleAnimationEnd animGroup model

                    Just (ScrollTimeline.Iteration animGroup count) ->
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
        (ScrollTimeline.attributes "hero-card") 
        [ text "I animate as the user scrolls" ]
    ```


## Horizontal Axis

Vertical scroll is the default. Call `horizontal` in the pipeline when the container scrolls left and right:

??? example "View Source Code"

    ```elm
    ScrollTimeline.animate waapiCommand (Container "carousel") <|
        ScrollTimeline.horizontal
            >> Opacity.for "slide"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build
    ```


## Playback

`iterations` and `alternate` work the same as in other engines, with one difference: for scroll-driven animations, `alternate` only has an effect when `iterations > 1`. Therefore, if `iterations` is not set, or is less than two when `alternate` is called, `iterations` will default to two.

📖 See [Playback](overview.md) in the Engines Overview for details.


## Easing

📖 See [Easing](../concepts/easing.md) for available easing functions.


## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimBuilder` | Carries all animation configuration for a scroll-driven animation |
| `Container` | Identifies the scroll source — `Document` or `Container "id"` |

### Trigger

| Function | Type | Description |
| -------- | ---- | ----------- |
| `animate` | `(Value -> Cmd msg) -> Container -> (AnimBuilder -> AnimBuilder) -> Cmd msg` | Fire-and-forget scroll-driven animation |

### View

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `attributes` | `String -> List (Html.Attribute msg)` | Attach the animation group identifier to an element |

### Axis

| Function | Type | Description |
| -------- | ---- | ----------- |
| `horizontal` | `AnimBuilder -> AnimBuilder` | Use horizontal scroll as the timeline source |

### Playback

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `iterations` | `Int -> AnimBuilder -> AnimBuilder` | Set number of iterations |
| `alternate` | `AnimBuilder -> AnimBuilder` | Reverse direction on each iteration |

### Easing

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set the easing function |

For complete API details, see the [Anim.Engine.WAAPI.ScrollTimeline](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-WAAPI-ScrollTimeline) documentation.

## Next Steps

Explore the ViewTimeline Engine:

[View Timeline Engine](view-timeline.md){ .md-button .md-button--primary }


Or review migration paths and tradeoffs.

[Migration Guide →](migration-guide.md){ .md-button .md-button--primary }
