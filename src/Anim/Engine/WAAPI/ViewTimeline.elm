module Anim.Engine.WAAPI.ViewTimeline exposing
    ( TimelineBuilder, AnimGroupName
    , animate
    , AnimEvent(..)
    , AnimMsg, update
    , subscriptions
    , attributes
    , horizontal
    , Unit(..), Range(..), rangeStart, rangeEnd
    , iterations, alternate
    , easing
    , discreteEntry, discreteExit
    , transformOrder
    )

{-| View-driven animations that tie progress to an element's position within the viewport.

Animations run automatically as the element scrolls into and out of view — no `AnimState`
required. `update` and `subscriptions` are optional, and only needed if you want to react
to lifecycle events.

The Engine uses the [ViewTimeline](https://developer.mozilla.org/en-US/docs/Web/API/ViewTimeline)
interface to the Web Animations API (WAAPI) and so requires the `elm-animate-waapi` JavaScript
companion library.

For specific Engine guides, setup instructions, and examples, see the
[ViewTimeline Engine Documentation](https://phollyer.github.io/elm-animate/animation/engines/view-timeline/).

For Engine comparisons, shared features, examples and code, see the
[Engine Overview](https://phollyer.github.io/elm-animate/animation/engines/overview/) section in the docs.


# Types

@docs TimelineBuilder, AnimGroupName


# Trigger

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

📖 See [Subscriptions](https://phollyer.github.io/elm-animate/animation/engines/view-timeline/#subscriptions) in the docs.


# View

@docs attributes

📖 See [Render](https://phollyer.github.io/elm-animate/animation/workflow/render/) in the docs.


# Axis

@docs horizontal


# Range

@docs Unit, Range, rangeStart, rangeEnd


# Playback

@docs iterations, alternate


# Easing

@docs easing

📖 See [Easing](https://phollyer.github.io/elm-animate/animation/concepts/easing/) in the docs.


# Discrete Properties

@docs discreteEntry, discreteExit


# Transform Order

@docs transformOrder

-}

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Engine.ViewTimeline as Internal
import Easing exposing (Easing)
import Html
import Json.Decode as Decode
import Json.Encode as Encode



-- ============================================================
-- TYPES
-- ============================================================


{-| Animation builder type for configuring view-driven animations.

Use this in type annotations for animation helpers specific to the
ViewTimeline Engine. For helper functions that should work across all
engines, use `AnimBuilder mode` from `Anim.Builder` instead.

-}
type alias TimelineBuilder =
    Internal.TimelineBuilder


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Fire-and-forget view-driven animation using the browser's `ViewTimeline`.

    port waapiCommand : Encode.Value -> Cmd msg

    ViewTimeline.animate waapiCommand <|
        Opacity.for "hero-card"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
animate : (Encode.Value -> Cmd msg) -> (TimelineBuilder -> TimelineBuilder) -> Cmd msg
animate =
    Internal.animate



-- ============================================================
-- EVENTS
-- ============================================================


{-| Lifecycle events emitted by the ViewTimeline engine.

  - `Ended String` — the element scrolled past the end of the animation range
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


{-| Internal message type. Add this to your `Msg` to receive view-driven lifecycle events.

    type Msg
        = GotViewMsg ViewTimeline.AnimMsg
        | ...

-}
type alias AnimMsg =
    Internal.AnimMsg


{-| Decode an `AnimMsg` into a `Maybe AnimEvent`.

Messages that do not match ViewTimeline lifecycle events return `Nothing`.

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotViewMsg animMsg ->
                case ViewTimeline.update animMsg of
                    Just (ViewTimeline.Ended animGroup) ->
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


{-| Subscribe to view-driven lifecycle events from JavaScript.

Wire this up alongside your `waapiEvent` port. Unlike the WAAPI engine,
no `AnimState` is needed — subscriptions are always active.

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        ViewTimeline.subscriptions GotViewMsg waapiEvent

-}
subscriptions : (AnimMsg -> msg) -> ((Decode.Value -> msg) -> Sub msg) -> Sub msg
subscriptions =
    Internal.subscriptions



-- ============================================================
-- VIEW
-- ============================================================


{-| Attach the animation group identifier to an element.

    div (ViewTimeline.attributes "hero-card") [ ... ]

-}
attributes : AnimGroupName -> List (Html.Attribute msg)
attributes =
    Internal.attributes



-- ============================================================
-- AXIS
-- ============================================================


{-| Use horizontal viewport tracking for the timeline.

Vertical scroll is the default, so this is only needed when the
container scrolls horizontally.

    -- Animate an element entering from the side in a horizontal layout
    ViewTimeline.animate waapiCommand <|
        ViewTimeline.horizontal
            >> Opacity.for "slide"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
horizontal : TimelineBuilder -> TimelineBuilder
horizontal =
    Internal.horizontal



-- ============================================================
-- RANGE
-- ============================================================


{-| The unit for a `Range` offset value.

  - `Perc` — percentage of the named range (`Cover 20 Perc` → `cover 20%`)
  - `Px` — fixed pixel offset (`Cover 100 Px` → `cover 100px`)

-}
type Unit
    = Perc
    | Px


{-| A position along the view timeline, used to configure `rangeStart` and `rangeEnd`.

Each constructor takes a numeric value and a `Unit`:

    rangeStart (Entry 0 Perc) -- entry 0%

    rangeEnd (Exit 100 Px) -- exit 100px

See the [Range section](https://phollyer.github.io/elm-animate/animation/engines/view-timeline/#range)
in the docs for a full breakdown of each constructor.

-}
type Range
    = Cover Float Unit
    | Contain Float Unit
    | Entry Float Unit
    | EntryCrossing Float Unit
    | Exit Float Unit
    | ExitCrossing Float Unit
    | Scroll Float Unit


{-| Set when the animation starts relative to the element's position in the viewport.

Optional — defaults to `Cover 0 Perc` when not called.

    -- Start animating as the element enters the viewport
    ViewTimeline.rangeStart (Entry 0 Perc)

    -- Start animating once the element is fully visible
    ViewTimeline.rangeStart (Entry 100 Perc)

-}
rangeStart : Range -> TimelineBuilder -> TimelineBuilder
rangeStart range =
    Internal.rangeStart (rangeToString range)


{-| Set when the animation ends relative to the element's position in the viewport.

Optional — defaults to `Cover 100 Perc` when not called.

    -- End animating as the element begins to leave the viewport
    ViewTimeline.rangeEnd (Exit 0 Perc)

    -- End animating once the element has fully left the viewport
    ViewTimeline.rangeEnd (Exit 100 Perc)

-}
rangeEnd : Range -> TimelineBuilder -> TimelineBuilder
rangeEnd range =
    Internal.rangeEnd (rangeToString range)


rangeToString : Range -> String
rangeToString range =
    case range of
        Cover n u ->
            "cover " ++ String.fromFloat n ++ unitToString u

        Contain n u ->
            "contain " ++ String.fromFloat n ++ unitToString u

        Entry n u ->
            "entry " ++ String.fromFloat n ++ unitToString u

        EntryCrossing n u ->
            "entry-crossing " ++ String.fromFloat n ++ unitToString u

        Exit n u ->
            "exit " ++ String.fromFloat n ++ unitToString u

        ExitCrossing n u ->
            "exit-crossing " ++ String.fromFloat n ++ unitToString u

        Scroll n u ->
            "scroll " ++ String.fromFloat n ++ unitToString u


unitToString : Unit -> String
unitToString unit =
    case unit of
        Perc ->
            "%"

        Px ->
            "px"



-- ============================================================
-- PLAYBACK
-- ============================================================


{-| Set how many times the animation should repeat.
-}
iterations : Int -> TimelineBuilder -> TimelineBuilder
iterations =
    Internal.iterations


{-| Alternate direction on each iteration (ping-pong).

If `iterations` has not been set, this defaults to `2` so that the
alternate direction has a second iteration to play.

-}
alternate : TimelineBuilder -> TimelineBuilder
alternate =
    Internal.alternate



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function.
-}
easing : Easing -> TimelineBuilder -> TimelineBuilder
easing =
    Internal.easing



-- ============================================================
-- TRANSFORM ORDER
-- ============================================================


{-| Override the order in which transform functions are applied.

By default, transforms are applied in the order: translate → rotate → skew → scale.
Use this when you need a different order for specific visual effects.

    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    ViewTimeline.animate waapiCommand <|
        ViewTimeline.transformOrder [ Scale, Rotate, Translate ]
            >> Translate.for "box"
            >> Translate.fromXY 0 0
            >> Translate.toXY 100 0
            >> Translate.build

-}
transformOrder : List TransformProperty -> TimelineBuilder -> TimelineBuilder
transformOrder =
    Internal.transformOrder



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


{-| Set a discrete CSS property to hold during the animation.

Used for non-interpolatable properties like `display` or `visibility` that need
to be set to a specific value while the animation is active.

    ViewTimeline.animate waapiCommand <|
        ViewTimeline.discreteEntry "display" "block"
            >> ViewTimeline.discreteEntry "visibility" "visible"
            >> Opacity.for "box"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
discreteEntry : String -> String -> TimelineBuilder -> TimelineBuilder
discreteEntry =
    Internal.discreteEntry


{-| Flip a discrete CSS property when the animation completes.

  - `from` — the value to hold during the animation

  - `to` — the value to apply when the animation finishes

    ViewTimeline.animate waapiCommand <|
    ViewTimeline.discreteExit "display" "block" "none"

    > > Opacity.for "box"
    > > Opacity.from 1
    > > Opacity.to 0
    > > Opacity.build

-}
discreteExit : String -> String -> String -> TimelineBuilder -> TimelineBuilder
discreteExit =
    Internal.discreteExit
