module Anim.Attributes exposing
    ( position, positionX, positionY, positionZ, positionXY, positionXZ, positionYZ, positionXYZ
    , rotate, rotateX, rotateY, rotateZ, rotateXY, rotateXZ, rotateYZ, rotateXYZ
    , scale, scaleX, scaleY, scaleZ, scaleXY, scaleXZ, scaleYZ, scaleXYZ
    , transform
    )

{-| HTML attribute helpers for setting initial transform values.

Use these to set starting positions, rotations, and scales on elements before animating them.
When animations run via WAAPI, the starting values can come from a number of places:

  - If a `from` value is specificed in the animation, it will take precedence
  - If a start value is set using [WAAPI.initProperties](../Engine/WAAPI#initProperties), that value will be used
  - If no `from` value is specified, and no start value is set, these attributes set the initial values
  - If none of the above are set, then sensible defaults are used

Using these attribute helpers allows you to define the initial state of elements in your view.
Whether you set start values in the animation builder or via these attributes is purely a matter of preference.


# Position

@docs position, positionX, positionY, positionZ, positionXY, positionXZ, positionYZ, positionXYZ


# Rotate

@docs rotate, rotateX, rotateY, rotateZ, rotateXY, rotateXZ, rotateYZ, rotateXYZ


# Scale

@docs scale, scaleX, scaleY, scaleZ, scaleXY, scaleXZ, scaleYZ, scaleXYZ


# Combined Transform

For elements with multiple transform properties, use the combined helper to ensure correct ordering.

@docs transform

-}

import Html
import Html.Attributes exposing (style)



-- POSITION


{-| Set an element's position using CSS transform with a record.

    div [ id "ball", position { x = 100, y = 50, z = 0 } ] [ text "🏀" ]

-}
position : { x : Float, y : Float, z : Float } -> Html.Attribute msg
position { x, y, z } =
    style "transform"
        ("translate3d("
            ++ String.fromFloat x
            ++ "px, "
            ++ String.fromFloat y
            ++ "px, "
            ++ String.fromFloat z
            ++ "px)"
        )


{-| Set an element's X position.

    div [ id "ball", positionX 100 ] [ text "🏀" ]

-}
positionX : Float -> Html.Attribute msg
positionX x =
    style "transform" ("translateX(" ++ String.fromFloat x ++ "px)")


{-| Set an element's Y position.

    div [ id "ball", positionY 50 ] [ text "🏀" ]

-}
positionY : Float -> Html.Attribute msg
positionY y =
    style "transform" ("translateY(" ++ String.fromFloat y ++ "px)")


{-| Set an element's Z position.

    div [ id "ball", positionZ 10 ] [ text "🏀" ]

-}
positionZ : Float -> Html.Attribute msg
positionZ z =
    style "transform" ("translateZ(" ++ String.fromFloat z ++ "px)")


{-| Set an element's X and Y position.

    div [ id "ball", positionXY 100 50 ] [ text "🏀" ]

-}
positionXY : Float -> Float -> Html.Attribute msg
positionXY x y =
    style "transform"
        ("translate(" ++ String.fromFloat x ++ "px, " ++ String.fromFloat y ++ "px)")


{-| Set an element's X and Z position.

    div [ id "ball", positionXZ 100 10 ] [ text "🏀" ]

-}
positionXZ : Float -> Float -> Html.Attribute msg
positionXZ x z =
    style "transform"
        ("translateX(" ++ String.fromFloat x ++ "px) translateZ(" ++ String.fromFloat z ++ "px)")


{-| Set an element's Y and Z position.

    div [ id "ball", positionYZ 50 10 ] [ text "🏀" ]

-}
positionYZ : Float -> Float -> Html.Attribute msg
positionYZ y z =
    style "transform"
        ("translateY(" ++ String.fromFloat y ++ "px) translateZ(" ++ String.fromFloat z ++ "px)")


{-| Set an element's X, Y, and Z position.

    div [ id "ball", positionXYZ 100 50 0 ] [ text "🏀" ]

-}
positionXYZ : Float -> Float -> Float -> Html.Attribute msg
positionXYZ x y z =
    style "transform"
        ("translate3d("
            ++ String.fromFloat x
            ++ "px, "
            ++ String.fromFloat y
            ++ "px, "
            ++ String.fromFloat z
            ++ "px)"
        )



-- ROTATE


{-| Set an element's rotation using CSS transform with a record.

    div [ id "cube", rotate { x = 30, y = 45, z = 0 } ] [ text "📦" ]

Angles are in degrees.

-}
rotate : { x : Float, y : Float, z : Float } -> Html.Attribute msg
rotate { x, y, z } =
    style "transform"
        ("rotateX("
            ++ String.fromFloat x
            ++ "deg) rotateY("
            ++ String.fromFloat y
            ++ "deg) rotateZ("
            ++ String.fromFloat z
            ++ "deg)"
        )


{-| Set an element's X-axis rotation.

    div [ id "cube", rotateX 30 ] [ text "📦" ]

Angle is in degrees.

-}
rotateX : Float -> Html.Attribute msg
rotateX x =
    style "transform" ("rotateX(" ++ String.fromFloat x ++ "deg)")


{-| Set an element's Y-axis rotation.

    div [ id "cube", rotateY 45 ] [ text "📦" ]

Angle is in degrees.

-}
rotateY : Float -> Html.Attribute msg
rotateY y =
    style "transform" ("rotateY(" ++ String.fromFloat y ++ "deg)")


{-| Set an element's Z-axis rotation (most common 2D rotation).

    div [ id "arrow", rotateZ 45 ] [ text "→" ]

Angle is in degrees.

-}
rotateZ : Float -> Html.Attribute msg
rotateZ z =
    style "transform" ("rotateZ(" ++ String.fromFloat z ++ "deg)")


{-| Set an element's X and Y rotation.

    div [ id "cube", rotateXY 30 45 ] [ text "📦" ]

Angles are in degrees.

-}
rotateXY : Float -> Float -> Html.Attribute msg
rotateXY x y =
    style "transform"
        ("rotateX(" ++ String.fromFloat x ++ "deg) rotateY(" ++ String.fromFloat y ++ "deg)")


{-| Set an element's X and Z rotation.

    div [ id "cube", rotateXZ 30 45 ] [ text "📦" ]

Angles are in degrees.

-}
rotateXZ : Float -> Float -> Html.Attribute msg
rotateXZ x z =
    style "transform"
        ("rotateX(" ++ String.fromFloat x ++ "deg) rotateZ(" ++ String.fromFloat z ++ "deg)")


{-| Set an element's Y and Z rotation.

    div [ id "cube", rotateYZ 45 30 ] [ text "📦" ]

Angles are in degrees.

-}
rotateYZ : Float -> Float -> Html.Attribute msg
rotateYZ y z =
    style "transform"
        ("rotateY(" ++ String.fromFloat y ++ "deg) rotateZ(" ++ String.fromFloat z ++ "deg)")


{-| Set an element's rotation on all three axes.

    div [ id "cube", rotateXYZ 30 45 0 ] [ text "📦" ]

Angles are in degrees.

-}
rotateXYZ : Float -> Float -> Float -> Html.Attribute msg
rotateXYZ x y z =
    style "transform"
        ("rotateX("
            ++ String.fromFloat x
            ++ "deg) rotateY("
            ++ String.fromFloat y
            ++ "deg) rotateZ("
            ++ String.fromFloat z
            ++ "deg)"
        )



-- SCALE


{-| Set an element's scale using CSS transform with a record.

    div [ id "box", scale { x = 1.5, y = 1.5, z = 1 } ] [ text "📦" ]

-}
scale : { x : Float, y : Float, z : Float } -> Html.Attribute msg
scale { x, y, z } =
    style "transform"
        ("scale3d("
            ++ String.fromFloat x
            ++ ", "
            ++ String.fromFloat y
            ++ ", "
            ++ String.fromFloat z
            ++ ")"
        )


{-| Set an element's X-axis scale.

    div [ id "box", scaleX 2 ] [ text "📦" ]

-}
scaleX : Float -> Html.Attribute msg
scaleX x =
    style "transform" ("scaleX(" ++ String.fromFloat x ++ ")")


{-| Set an element's Y-axis scale.

    div [ id "box", scaleY 0.5 ] [ text "📦" ]

-}
scaleY : Float -> Html.Attribute msg
scaleY y =
    style "transform" ("scaleY(" ++ String.fromFloat y ++ ")")


{-| Set an element's Z-axis scale.

    div [ id "box", scaleZ 2 ] [ text "📦" ]

-}
scaleZ : Float -> Html.Attribute msg
scaleZ z =
    style "transform" ("scaleZ(" ++ String.fromFloat z ++ ")")


{-| Set an element's X and Y scale.

    div [ id "box", scaleXY 2 0.5 ] [ text "📦" ]

-}
scaleXY : Float -> Float -> Html.Attribute msg
scaleXY x y =
    style "transform"
        ("scale(" ++ String.fromFloat x ++ ", " ++ String.fromFloat y ++ ")")


{-| Set an element's X and Z scale.

    div [ id "box", scaleXZ 2 1.5 ] [ text "📦" ]

-}
scaleXZ : Float -> Float -> Html.Attribute msg
scaleXZ x z =
    style "transform"
        ("scaleX(" ++ String.fromFloat x ++ ") scaleZ(" ++ String.fromFloat z ++ ")")


{-| Set an element's Y and Z scale.

    div [ id "box", scaleYZ 0.5 1.5 ] [ text "📦" ]

-}
scaleYZ : Float -> Float -> Html.Attribute msg
scaleYZ y z =
    style "transform"
        ("scaleY(" ++ String.fromFloat y ++ ") scaleZ(" ++ String.fromFloat z ++ ")")


{-| Set an element's scale on all three axes.

    div [ id "cube", scaleXYZ 1 2 1 ] [ text "📦" ]

-}
scaleXYZ : Float -> Float -> Float -> Html.Attribute msg
scaleXYZ x y z =
    style "transform"
        ("scale3d("
            ++ String.fromFloat x
            ++ ", "
            ++ String.fromFloat y
            ++ ", "
            ++ String.fromFloat z
            ++ ")"
        )



-- COMBINED TRANSFORM


{-| Set a combined transform with position, rotation, and scale.

Use this when you need multiple transform properties on one element.
Transform order matters - this uses the standard order: translate → rotate → scale.

    div
        [ id "animated-element"
        , transform
            { x = 100
            , y = 50
            , z = 0
            , rotateX = 0
            , rotateY = 0
            , rotateZ = 45
            , scaleX = 1.5
            , scaleY = 1.5
            , scaleZ = 1
            }
        ]
        [ text "🎯" ]

**Note:** For simpler cases, use the individual helpers:

    -- Position only
    div [ positionXY 100 50 ] []

    -- Rotation only
    div [ rotateZ 45 ] []

-}
transform :
    { x : Float
    , y : Float
    , z : Float
    , rotateX : Float
    , rotateY : Float
    , rotateZ : Float
    , scaleX : Float
    , scaleY : Float
    , scaleZ : Float
    }
    -> Html.Attribute msg
transform config =
    let
        translatePart =
            "translate3d("
                ++ String.fromFloat config.x
                ++ "px, "
                ++ String.fromFloat config.y
                ++ "px, "
                ++ String.fromFloat config.z
                ++ "px)"

        rotatePart =
            if config.rotateX == 0 && config.rotateY == 0 then
                -- Simple Z rotation (most common)
                if config.rotateZ == 0 then
                    ""

                else
                    " rotateZ(" ++ String.fromFloat config.rotateZ ++ "deg)"

            else
                " rotateX("
                    ++ String.fromFloat config.rotateX
                    ++ "deg) rotateY("
                    ++ String.fromFloat config.rotateY
                    ++ "deg) rotateZ("
                    ++ String.fromFloat config.rotateZ
                    ++ "deg)"

        scalePart =
            if config.scaleX == 1 && config.scaleY == 1 && config.scaleZ == 1 then
                ""

            else
                " scale3d("
                    ++ String.fromFloat config.scaleX
                    ++ ", "
                    ++ String.fromFloat config.scaleY
                    ++ ", "
                    ++ String.fromFloat config.scaleZ
                    ++ ")"
    in
    style "transform" (translatePart ++ rotatePart ++ scalePart)
