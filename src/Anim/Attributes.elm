module Anim.Attributes exposing
    ( position, positionXY, positionXYZ
    , rotate, rotateZ, rotateXYZ
    , scale, scaleXY, scaleXYZ
    , transform
    )

{-| HTML attribute helpers for setting initial transform values.

Use these to set starting positions, rotations, and scales on elements before animating them.
When animations run via WAAPI, they read these computed values as starting points automatically.


# Position

@docs position, positionXY, positionXYZ


# Rotate

@docs rotate, rotateZ, rotateXYZ


# Scale

@docs scale, scaleXY, scaleXYZ


# Combined Transform

For elements with multiple transform properties, use the combined helper to ensure correct ordering.

@docs transform

-}

import Html
import Html.Attributes exposing (style)


{-| Set an element's X position using CSS transform.

    div [ id "ball", position 100 ] [ text "🏀" ]

-}
position : Float -> Html.Attribute msg
position x =
    style "transform" ("translateX(" ++ String.fromFloat x ++ "px)")


{-| Set an element's X and Y position using CSS transform.

    div [ id "ball", positionXY 100 50 ] [ text "🏀" ]

-}
positionXY : Float -> Float -> Html.Attribute msg
positionXY x y =
    style "transform"
        ("translate(" ++ String.fromFloat x ++ "px, " ++ String.fromFloat y ++ "px)")


{-| Set an element's X, Y, and Z position using CSS transform.

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


{-| Set an element's Z-axis rotation (most common 2D rotation).

    div [ id "arrow", rotate 45 ] [ text "→" ]

Angle is in degrees.

-}
rotate : Float -> Html.Attribute msg
rotate degrees =
    style "transform" ("rotate(" ++ String.fromFloat degrees ++ "deg)")


{-| Alias for `rotate` - explicitly Z-axis rotation.

    div [ id "arrow", rotateZ 45 ] [ text "→" ]

-}
rotateZ : Float -> Html.Attribute msg
rotateZ =
    rotate


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


{-| Set uniform scale on an element.

    div [ id "box", scale 1.5 ] [ text "📦" ]

-}
scale : Float -> Html.Attribute msg
scale s =
    style "transform" ("scale(" ++ String.fromFloat s ++ ")")


{-| Set non-uniform scale on X and Y axes.

    div [ id "box", scaleXY 2 0.5 ] [ text "📦" ]

-}
scaleXY : Float -> Float -> Html.Attribute msg
scaleXY x y =
    style "transform"
        ("scale(" ++ String.fromFloat x ++ ", " ++ String.fromFloat y ++ ")")


{-| Set scale on all three axes.

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
    div [ rotate 45 ] []

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
