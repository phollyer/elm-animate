module Anim.Engine.WAAPI.ScrollTimeline exposing
    ( AnimBuilder, AnimGroupName
    , Container(..)
    , animate
    , AnimEvent(..)
    , AnimMsg, update
    , subscriptions
    , attributes
    , horizontal
    , iterations, alternate
    , easing
    , transformOrder
    , discreteEntry, discreteExit
    )

{-| Scroll-driven animations that tie progress to a container's scroll position.

Animations run automatically as the user scrolls — no `AnimState` required.
`update` and `subscriptions` are optional, and only needed if you want to react
to lifecycle events.

The Engine uses the [ScrollTimeline](https://developer.mozilla.org/en-US/docs/Web/API/ScrollTimeline)
interface to the Web Animations API (WAAPI) and so requires the `elm-animate-waapi` JavaScript
companion library.

For specific Engine guides, setup instructions, and examples, see the
[ScrollTimeline Engine Documentation](https://phollyer.github.io/elm-animate/animation/engines/scroll-timeline/).

For Engine comparisons, shared features, examples and code, see the
[Engine Overview](https://phollyer.github.io/elm-animate/animation/engines/overview/) section in the docs.


# Types

@docs AnimBuilder, AnimGroupName


# Trigger

@docs Container

@docs animate

📖 See [Triggering Animations](https://phollyer.github.io/elm-animate/animation/workflow/trigger/) in the docs.


# Events

@docs AnimEvent

📖 See [Event Reference](https://phollyer.github.io/elm-animate/animation/workflow/react/#event-reference) in the docs.


# Update

@docs AnimMsg, update

📖 See [React](https://phollyer.github.io/elm-animate/animation/workflow/react/) in the docs.


# Subscriptions

@docs subscriptions

📖 See [Subscriptions](https://phollyer.github.io/elm-animate/animation/engines/scroll-timeline/#subscriptions) in the docs.


# View

@docs attributes

📖 See [Render](https://phollyer.github.io/elm-animate/animation/workflow/render/) in the docs.


# Axis

@docs horizontal


# Playback

@docs iterations, alternate


# Easing

@docs easing

📖 See [Easing](https://phollyer.github.io/elm-animate/animation/concepts/easing/) in the docs.


# Transform Order

@docs transformOrder


# Discrete Properties

@docs discreteEntry, discreteExit

-}

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.ScrollTimeline as Internal
import Easing exposing (Easing)
import Html
import Json.Decode as Decode
import Json.Encode as Encode



-- ============================================================
-- TYPES
-- ============================================================


{-| Animation builder type for configuring scroll-driven animations.
-}
type alias AnimBuilder =
    Builder.AnimBuilder Internal.ForScroll


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Identifies the scroll surface handled by the engine.

Use `Document` for the document body, or `Container "element-id"` for a
specific scrollable element.

-}
type Container
    = Document
    | Container String


{-| Fire-and-forget scroll-driven animation using the browser's `ScrollTimeline`.

    port waapiCommand : Encode.Value -> Cmd msg

    ScrollTimeline.animate waapiCommand (Container "scroller") <|
        Opacity.for "hero-card"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
animate : (Encode.Value -> Cmd msg) -> Container -> (AnimBuilder -> AnimBuilder) -> Cmd msg
animate =
    Internal.animate containerToId


containerToId : Container -> String
containerToId container =
    case container of
        Document ->
            "document"

        Container elementId ->
            elementId



-- ============================================================
-- EVENTS
-- ============================================================


{-| Lifecycle events emitted by the ScrollTimeline engine.

  - `Ended String` — the scroll position reached the end of the animation range
  - `Cancelled String` — the animation was cancelled (e.g. element removed)
  - `Iteration String Int` — the animation looped; the `Int` is the cumulative iteration count
  - `AnimError String` — a message arrived but could not be decoded

Returned as a `Maybe` — `Nothing` indicates the message was not intended for this engine.

-}
type AnimEvent
    = Ended AnimGroupName
    | Cancelled AnimGroupName Float
    | Iteration AnimGroupName Int
    | AnimError String



-- ============================================================
-- UPDATE
-- ============================================================


{-| Internal message type. Add this to your `Msg` to receive scroll-driven lifecycle events.

    type Msg
        = GotScrollMsg ScrollTimeline.AnimMsg
        | ...

-}
type alias AnimMsg =
    Internal.AnimMsg


{-| Decode an `AnimMsg` into a `Maybe AnimEvent`.

Messages that do not match ScrollTimeline lifecycle events return `Nothing`.

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotScrollMsg animMsg ->
                case ScrollTimeline.update animMsg of
                    Just (ScrollTimeline.Ended animGroup) ->
                        ...

                    _ ->
                        ( model, Cmd.none )

-}
update : AnimMsg -> Maybe AnimEvent
update =
    Internal.update toAnimEvent


toAnimEvent : Internal.AnimEvent -> AnimEvent
toAnimEvent internalEvent =
    case internalEvent of
        Internal.Ended animGroup ->
            Ended animGroup

        Internal.Cancelled animGroup progress ->
            Cancelled animGroup progress

        Internal.Iteration animGroup iteration ->
            Iteration animGroup iteration

        Internal.AnimError errorMsg ->
            AnimError errorMsg



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


{-| Subscribe to scroll-driven lifecycle events from JavaScript.

Wire this up alongside your `waapiEvent` port. Unlike the WAAPI engine,
no `AnimState` is needed — subscriptions are always active.

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        ScrollTimeline.subscriptions GotScrollMsg waapiEvent

-}
subscriptions : (AnimMsg -> msg) -> ((Decode.Value -> msg) -> Sub msg) -> Sub msg
subscriptions =
    Internal.subscriptions



-- ============================================================
-- VIEW
-- ============================================================


{-| Attach the animation group identifier to an element.

    div (ScrollTimeline.attributes "hero-card") [ ... ]

-}
attributes : AnimGroupName -> List (Html.Attribute msg)
attributes =
    Internal.attributes



-- ============================================================
-- AXIS
-- ============================================================


{-| Use horizontal scroll as the timeline source.

Vertical scroll is the default, so this is only needed when the
container scrolls horizontally.

    -- Animate based on horizontal scroll position in a carousel
    ScrollTimeline.animate waapiCommand (Container "carousel") <|
        ScrollTimeline.horizontal
            >> Opacity.for "slide"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
horizontal : AnimBuilder -> AnimBuilder
horizontal =
    Internal.horizontal



-- ============================================================
-- PLAYBACK
-- ============================================================


{-| Set how many times the animation should repeat.
-}
iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    Internal.iterations


{-| Alternate direction on each iteration (ping-pong).

If `iterations` has not been set, this defaults to `2` so that the
alternate direction has a second iteration to play.

-}
alternate : AnimBuilder -> AnimBuilder
alternate =
    Internal.alternate



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function.
-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Internal.easing



-- ============================================================
-- TRANSFORM ORDER
-- ============================================================


{-| Override the order in which transform functions are applied.

By default, transforms are applied in the order: translate → rotate → skew → scale.
Use this when you need a different order for specific visual effects.

    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    ScrollTimeline.animate waapiCommand (Container "scroller") <|
        ScrollTimeline.transformOrder [ Scale, Rotate, Translate ]
            >> Translate.for "box"
            >> Translate.fromXY 0 0
            >> Translate.toXY 100 0
            >> Translate.build

-}
transformOrder : List TransformProperty -> AnimBuilder -> AnimBuilder
transformOrder =
    Internal.transformOrder



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


{-| Set a discrete CSS property to hold during the animation.

Used for non-interpolatable properties like `display` or `visibility` that need
to be set to a specific value while the animation is active.

    ScrollTimeline.animate waapiCommand (Container "scroller") <|
        ScrollTimeline.discreteEntry "display" "block"
            >> ScrollTimeline.discreteEntry "visibility" "visible"
            >> Opacity.for "box"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
discreteEntry : String -> String -> AnimBuilder -> AnimBuilder
discreteEntry =
    Internal.discreteEntry


{-| Flip a discrete CSS property when the animation completes.

  - `from` — the value to hold during the animation

  - `to` — the value to apply when the animation finishes

    ScrollTimeline.animate waapiCommand (Container "scroller") <|
    ScrollTimeline.discreteExit "display" "block" "none"
    >> Opacity.for "box"
    >> Opacity.from 1
    >> Opacity.to 0
    >> Opacity.build

-}
discreteExit : String -> String -> String -> AnimBuilder -> AnimBuilder
discreteExit =
    Internal.discreteExit
