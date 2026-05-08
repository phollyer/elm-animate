module Anim.Extra.View3D exposing
    ( perspective
    , PerspectiveOrigin(..), perspectiveOrigin
    , BackfaceVisibility(..), backfaceVisibility
    , TransformStyle(..), transformStyle
    , opacityHack
    )

{-| Create 3D animations.

📖 See the [3D Animations Documentation](https://phollyer.github.io/elm-animate/animation/concepts/3d-animations/) in the docs for more info.


# Perspective

@docs perspective


# Perspective Origin

@docs PerspectiveOrigin, perspectiveOrigin


# Backface Visibility

@docs BackfaceVisibility, backfaceVisibility


# Transform Style

@docs TransformStyle, transformStyle


# Workarounds

@docs opacityHack

-}

import Html
import Html.Attributes exposing (style)



-- ============================================================
-- PERSPECTIVE
-- ============================================================


{-| Set the perspective depth on a container element.

Perspective controls the intensity of the 3D effect. Smaller values create
more dramatic effects, larger values are more subtle. A good starting point is around 800-1200px.

Perspective applies to **direct children** of the element. For deeper nesting,
see [transformStyle](#transformStyle).

-}
perspective : Float -> Html.Attribute msg
perspective value =
    style "perspective" (String.fromFloat value ++ "px")



-- ============================================================
-- PERSPECTIVE ORIGIN
-- ============================================================


{-| The origin point for perspective calculations.

  - `Center` — Center of the element (browser default).
  - `TopLeft`, `TopCenter`, `TopRight`, `LeftMiddle`, `RightMiddle`, `BottomLeft`, `BottomCenter`, `BottomRight` — Named positions.
  - `Percent Float Float` — Custom position as percentages from left and top.
  - `Px Float Float` — Custom position in pixels from left and top.

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


{-| Set the `perspective-origin` CSS property on a container element.

Controls where the viewer is looking from. Default is `Center`.

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



-- ============================================================
-- BACKFACE VISIBILITY
-- ============================================================


{-| Whether the back face of an element is visible when rotated.

  - `Visible` — Back face is shown (browser default).
  - `Hidden` — Back face is invisible.

-}
type BackfaceVisibility
    = Visible
    | Hidden


{-| Set the `backface-visibility` CSS property on an element.

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



-- ============================================================
-- TRANSFORM STYLE
-- ============================================================


{-| Whether children are flattened onto the parent's plane or rendered in 3D space.

  - `Flat` — Children are flattened (browser default).
  - `Preserve3D` — Children keep their own 3D positions.

-}
type TransformStyle
    = Flat
    | Preserve3D


{-| Set the `transform-style` CSS property on an element.

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



-- ============================================================
-- OPACITY HACK
-- ============================================================


{-| Workaround for Chrome GPU compositing issues on macOS.

Some complex 3D animations may cause rendering artifacts in Chrome on macOS
(colored rectangles appearing over the page). Apply this attribute to the
**direct parent** of the animated element to 'fix' the issue.

    div
        [ View3D.opacityHack
        , View3D.perspective 1000
        ]
        [ animated3DElement ]

This sets `opacity: 0.99`, which forces a new compositing layer without
visible effect. From what I could discover, when the new compositing layer
is created, it bypasses the GPU compositing issues.

You can safely include this on all 3D containers.

**Note**: This is a hack, not a perfect solution - YMMV - suggestions welcome.

-}
opacityHack : Html.Attribute msg
opacityHack =
    style "opacity" "0.99"
