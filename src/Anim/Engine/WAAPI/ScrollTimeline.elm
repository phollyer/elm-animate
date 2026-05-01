module Anim.Engine.WAAPI.ScrollTimeline exposing
    ( AnimBuilder
    , Container(..)
    , scroll
    , attributes
    , horizontal
    , iterations, alternate
    , easing
    )

{-| Scroll-driven animations that tie progress to a container's scroll position.

Unlike time-based animations, these run automatically as the user scrolls — no
`AnimState`, `update`, or `subscriptions` required.

Requires the `elm-animate-waapi` JavaScript companion library.

For specific Engine guides, setup instructions, and examples, see the
[WAAPI Engine Documentation](https://phollyer.github.io/elm-animate/engines/animation/waapi/).

For Engine comparisons, shared features, examples and code, see the
[Engine Overview](https://phollyer.github.io/elm-animate/engines/animation/overview/) section in the docs.


# Types

@docs AnimBuilder


# Trigger

@docs Container

@docs scroll


# View

@docs attributes


# Axis

@docs horizontal


# Playback

@docs iterations, alternate


# Easing

@docs easing

-}

import Anim.Engine.Keyframe exposing (AnimGroupName)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.WAAPI as WAAPI
import Anim.Internal.Engine.WAAPI.Timeline as Timeline
import Easing exposing (Easing)
import Html
import Html.Attributes
import Json.Encode as Encode



-- ============================================================
-- MODEL
-- ============================================================


{-| Animation builder type for configuring scroll-driven animations.
-}
type alias AnimBuilder =
    Builder.AnimBuilder Timeline.ForScroll


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

    ScrollTimeline.scroll waapiCommand (Container "scroller") <|
        Opacity.for "hero-card"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
scroll : (Encode.Value -> Cmd msg) -> Container -> (AnimBuilder -> AnimBuilder) -> Cmd msg
scroll sendToPort container =
    Timeline.scroll sendToPort <|
        containerToString container


containerToString : Container -> String
containerToString container =
    case container of
        Document ->
            "document"

        Container elementId ->
            elementId



-- ============================================================
-- VIEW
-- ============================================================


{-| Attach the animation group identifier to an element.

    div (ScrollTimeline.attributes "hero-card") [ ... ]

-}
attributes : AnimGroupName -> List (Html.Attribute msg)
attributes animGroupName =
    [ Html.Attributes.attribute "data-anim-target" animGroupName ]



-- ============================================================
-- AXIS
-- ============================================================


{-| Use horizontal scroll as the timeline source.

Vertical scroll is the default, so this is only needed when the scroll
container moves left and right.

    -- Animate based on horizontal scroll position in a carousel
    ScrollTimeline.scroll waapiCommand (Container "carousel") <|
        ScrollTimeline.horizontal
            >> Opacity.for "slide"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
horizontal : AnimBuilder -> AnimBuilder
horizontal =
    Timeline.setScrollAxis "inline"



-- ============================================================
-- PLAYBACK
-- ============================================================


{-| Set how many times the animation should repeat.
-}
iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    WAAPI.iterations


{-| Alternate direction on each iteration (ping-pong).
-}
alternate : AnimBuilder -> AnimBuilder
alternate =
    WAAPI.alternate



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function.
-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    WAAPI.easing
