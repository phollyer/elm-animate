module Anim.Extra.View3D exposing
    ( PerspectiveOrigin(..), BackfaceVisibility(..), TransformStyle(..)
    , perspective, perspectiveOrigin
    , backfaceVisibility, transformStyle
    , opacityHack
    )

{-| Helper module for 3D CSS properties.

3D animations require specific CSS properties on container and animated elements.
This module provides type-safe helpers for setting these properties.


# Types

@docs PerspectiveOrigin, BackfaceVisibility, TransformStyle


# Container Properties

These go on the **parent** element of the animated element.

@docs perspective, perspectiveOrigin


# Animated Element Properties

These go on the **animated element itself**.

@docs backfaceVisibility, transformStyle


# Workarounds

@docs opacityHack

-}

import Html
import Html.Attributes exposing (style)


{-| The origin point for perspective calculations.

The perspective origin determines where the viewer is looking from.
Default is `Center` (center of the element).

    import Anim.Extra.View3D exposing (PerspectiveOrigin(..))

    -- Keyword positions
    div [ View3D.perspective 1000, View3D.perspectiveOrigin TopLeft ] [ card ]

    -- Percentage-based (x%, y%)
    div [ View3D.perspective 1000, View3D.perspectiveOrigin (Percent 25 75) ] [ card ]

    -- Pixel-based
    div [ View3D.perspective 1000, View3D.perspectiveOrigin (Px 100 50) ] [ card ]

-}
type PerspectiveOrigin
    = Center
    | TopLeft
    | TopCenter
    | TopRight
    | LeftMiddle
    | RightMiddle
    | BottomLeft
    | BottomCenter
    | BottomRight
    | Percent Float Float
    | Px Float Float


{-| Controls whether the back face of an element is visible when rotated.

When flipping elements 180°, you typically want to hide the back face.

    import Anim.Extra.View3D exposing (BackfaceVisibility(..))

    div
        [ id "card"
        , View3D.backfaceVisibility Hidden
        ]
        [ text "Card content" ]

-}
type BackfaceVisibility
    = Visible
    | Hidden


{-| Controls how child elements are rendered in 3D space.

Use `Preserve3D` when you have nested 3D transforms and want children
to maintain their own 3D positions relative to the parent.

    import Anim.Extra.View3D exposing (TransformStyle(..))

    -- For nested 3D elements
    div
        [ View3D.perspective 1000
        , View3D.transformStyle Preserve3D
        ]
        [ child1, child2 ]

-}
type TransformStyle
    = Flat
    | Preserve3D



-- CONTAINER PROPERTIES


{-| Set the perspective depth on a container element.

Perspective controls the intensity of the 3D effect. Smaller values create
more dramatic effects, larger values are more subtle.

| Value | Effect |
| ------------ | ----------------------------- |
| 500-800px | Dramatic, close-up 3D effect |
| 1000-1500px | Natural, balanced perspective |
| 2000px+ | Subtle, distant 3D effect |

    import Anim.Extra.View3D as View3D

    view model =
        div
            [ id "container"
            , View3D.perspective 1000
            ]
            [ animatedCard ]

-}
perspective : Float -> Html.Attribute msg
perspective value =
    style "perspective" (String.fromFloat value ++ "px")


{-| Set the perspective origin on a container element.

This determines the vanishing point for 3D transforms. Use this together
with `perspective` on the same parent element.

    import Anim.Extra.View3D exposing (PerspectiveOrigin(..))

    -- Vanishing point at top-left corner
    div
        [ View3D.perspective 1000
        , View3D.perspectiveOrigin TopLeft
        ]
        [ card ]

    -- Custom vanishing point at 25% from left, 75% from top
    div
        [ View3D.perspective 1000
        , View3D.perspectiveOrigin (Percent 25 75)
        ]
        [ card ]

-}
perspectiveOrigin : PerspectiveOrigin -> Html.Attribute msg
perspectiveOrigin origin =
    style "perspective-origin" (perspectiveOriginToString origin)



-- ANIMATED ELEMENT PROPERTIES


{-| Control whether the back face of an element is visible.

Essential for card flip animations where you don't want to see
the mirrored back of the front face.

    import Anim.Extra.View3D exposing (BackfaceVisibility(..))

    -- Front of card
    div
        [ class "card-front"
        , View3D.backfaceVisibility Hidden
        ]
        [ text "Front" ]

    -- Back of card (rotated 180°)
    div
        [ class "card-back"
        , style "transform" "rotateY(180deg)"
        , View3D.backfaceVisibility Hidden
        ]
        [ text "Back" ]

-}
backfaceVisibility : BackfaceVisibility -> Html.Attribute msg
backfaceVisibility visibility =
    style "backface-visibility" <|
        case visibility of
            Visible ->
                "visible"

            Hidden ->
                "hidden"


{-| Control how children are positioned in 3D space.

Use `Preserve3D` when you have nested 3D transforms and want children
to maintain their 3D context. Use `Flat` (default) to flatten children
onto the parent's plane.

    import Anim.Extra.View3D exposing (TransformStyle(..))

    -- Parent maintains 3D context for children
    div
        [ View3D.perspective 1000
        , View3D.transformStyle Preserve3D
        ]
        [ rotatedChild1
        , rotatedChild2
        ]

-}
transformStyle : TransformStyle -> Html.Attribute msg
transformStyle ts =
    style "transform-style" <|
        case ts of
            Flat ->
                "flat"

            Preserve3D ->
                "preserve-3d"


{-| Workaround for Chrome GPU compositing issues on macOS.

Some complex 3D animations may cause rendering artifacts in Chrome on macOS
(colored rectangles appearing over the page). Apply this attribute to the
**direct parent** of the animated element to fix the issue.

    div
        [ View3D.opacityHack
        , View3D.perspective 1000
        ]
        [ animated3DElement ]

This sets `opacity: 0.99`, which forces a new compositing layer without
visible effect. You can safely include this on all 3D containers.

-}
opacityHack : Html.Attribute msg
opacityHack =
    style "opacity" "0.99"



-- HELPERS


perspectiveOriginToString : PerspectiveOrigin -> String
perspectiveOriginToString origin =
    case origin of
        Center ->
            "center center"

        TopLeft ->
            "left top"

        TopCenter ->
            "center top"

        TopRight ->
            "right top"

        LeftMiddle ->
            "left center"

        RightMiddle ->
            "right center"

        BottomLeft ->
            "left bottom"

        BottomCenter ->
            "center bottom"

        BottomRight ->
            "right bottom"

        Percent x y ->
            String.fromFloat x ++ "% " ++ String.fromFloat y ++ "%"

        Px x y ->
            String.fromFloat x ++ "px " ++ String.fromFloat y ++ "px"
