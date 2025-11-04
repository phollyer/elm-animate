module Anim.CSS exposing
    ( Model
    , init
    , animate
    , animateOpacity
    , animatePosition
    , animateScale
    , animateRotation
    , animateBackgroundColor
    , styleProperties
    , transitionStyles
    )

{-| CSS-based animation system using native browser transitions.


# Model

@docs Model
@docs init


# Animation

@docs animate
@docs animateOpacity
@docs animatePosition
@docs animateScale
@docs animateRotation
@docs animateBackgroundColor


# CSS Generation

@docs styleProperties
@docs transitionStyles

-}

import Anim exposing (AnimationTarget(..), ColorValue(..), FilterValue(..), Position, RotationValue, ScaleValue, defaultConfig)
import Anim.Internal as Internal
import Dict exposing (Dict)



-- MODEL


{-| Model for managing CSS-based animations.
-}
type Model
    = Model (Dict String (List AnimationTarget))


{-| Initialize an empty animation model.
-}
init : Model
init =
    Model Dict.empty



-- ANIMATION FUNCTIONS


{-| Animate an element to a specific animation target.
-}
animate : String -> AnimationTarget -> Model -> Model
animate elementId target (Model animations) =
    let
        currentTargets =
            Dict.get elementId animations |> Maybe.withDefault []

        newTargets =
            target :: List.filter (\t -> getTargetType t /= getTargetType target) currentTargets
    in
    Model (Dict.insert elementId newTargets animations)


{-| Animate element opacity.
-}
animateOpacity : String -> Float -> Model -> Model
animateOpacity elementId opacity model =
    animate elementId (ToOpacity opacity) model


{-| Animate element position.
-}
animatePosition : String -> Position -> Model -> Model
animatePosition elementId position model =
    animate elementId (ToPosition position) model


{-| Animate element scale.
-}
animateScale : String -> ScaleValue -> Model -> Model
animateScale elementId scale model =
    animate elementId (ToScale scale) model


{-| Animate element rotation.
-}
animateRotation : String -> RotationValue -> Model -> Model
animateRotation elementId degrees model =
    animate elementId (ToRotation degrees) model


{-| Animate element background color.
-}
animateBackgroundColor : String -> ColorValue -> Model -> Model
animateBackgroundColor elementId color model =
    animate elementId (ToBackgroundColor color) model



-- CSS GENERATION


{-| Generate CSS property declarations for an element's animations.
-}
styleProperties : String -> Model -> List ( String, String )
styleProperties elementId (Model animations) =
    case Dict.get elementId animations of
        Just targets ->
            groupAndCombineTargets targets

        Nothing ->
            []


{-| Generate CSS transition styles.
-}
transitionStyles : String -> Model -> String
transitionStyles _ _ =
    let
        config =
            defaultConfig

        duration =
            Internal.timingToMilliseconds config.timing

        easing =
            Internal.easingToString config.easing
    in
    "all " ++ String.fromFloat (duration 1.0) ++ "ms " ++ easing



-- HELPERS


{-| Group targets by CSS property and combine them.
-}
groupAndCombineTargets : List AnimationTarget -> List ( String, String )
groupAndCombineTargets targets =
    let
        -- Separate transform targets from others
        ( transformTargets, otherTargets ) =
            List.partition isTransformTarget targets

        -- Combine transform targets into single transform property
        transformProperty =
            if List.isEmpty transformTargets then
                []

            else
                [ ( "transform", combineTransforms transformTargets ) ]

        -- Convert other targets to properties
        otherProperties =
            List.map targetToProperty otherTargets
    in
    transformProperty ++ otherProperties


{-| Check if target affects CSS transform property.
-}
isTransformTarget : AnimationTarget -> Bool
isTransformTarget target =
    case target of
        ToPosition _ ->
            True

        ToScale _ ->
            True

        ToRotation _ ->
            True

        _ ->
            False


{-| Combine multiple transform targets into single transform value.
-}
combineTransforms : List AnimationTarget -> String
combineTransforms targets =
    targets
        |> List.map transformToString
        |> String.join " "


{-| Convert transform target to CSS transform function.
-}
transformToString : AnimationTarget -> String
transformToString target =
    case target of
        ToPosition pos ->
            "translate3d(" ++ String.fromFloat pos.x ++ "px, " ++ String.fromFloat pos.y ++ "px, 0)"

        ToScale scale ->
            "scale(" ++ String.fromFloat scale.x ++ ", " ++ String.fromFloat scale.y ++ ")"

        ToRotation degrees ->
            "rotate(" ++ String.fromFloat degrees ++ "deg)"

        _ ->
            ""


{-| Get the type identifier for an AnimationTarget.
-}
getTargetType : AnimationTarget -> String
getTargetType target =
    case target of
        ToPosition _ ->
            "transform"

        ToScale _ ->
            "transform"

        ToRotation _ ->
            "transform"

        ToOpacity _ ->
            "opacity"

        ToBackgroundColor _ ->
            "background-color"

        ToTextColor _ ->
            "color"

        ToBorderColor _ ->
            "border-color"

        ToDimensions _ ->
            "width"

        ToBorderRadius _ ->
            "border-radius"

        ToFilter _ ->
            "filter"


{-| Convert an AnimationTarget to a CSS property.
-}
targetToProperty : AnimationTarget -> ( String, String )
targetToProperty target =
    case target of
        ToOpacity value ->
            ( "opacity", String.fromFloat (clamp 0.0 1.0 value) )

        ToBackgroundColor color ->
            ( "background-color", colorToString color )

        ToTextColor color ->
            ( "color", colorToString color )

        ToBorderColor color ->
            ( "border-color", colorToString color )

        ToDimensions dimensions ->
            ( "width", String.fromFloat dimensions.width ++ "px" )

        ToBorderRadius radius ->
            ( "border-radius", String.fromFloat radius ++ "px" )

        ToFilter filter ->
            ( "filter", filterToString filter )

        _ ->
            ( "", "" )



-- Transform targets handled separately


{-| Convert ColorValue to CSS color string.
-}
colorToString : ColorValue -> String
colorToString color =
    case color of
        Hex hexString ->
            hexString

        Rgb rgb ->
            "rgb(" ++ String.fromInt rgb.r ++ ", " ++ String.fromInt rgb.g ++ ", " ++ String.fromInt rgb.b ++ ")"

        Rgba rgba ->
            "rgba(" ++ String.fromInt rgba.r ++ ", " ++ String.fromInt rgba.g ++ ", " ++ String.fromInt rgba.b ++ ", " ++ String.fromFloat rgba.a ++ ")"

        Hsl hsl ->
            "hsl(" ++ String.fromFloat hsl.h ++ ", " ++ String.fromFloat hsl.s ++ "%, " ++ String.fromFloat hsl.l ++ "%)"

        Hsla hsla ->
            "hsla(" ++ String.fromFloat hsla.h ++ ", " ++ String.fromFloat hsla.s ++ "%, " ++ String.fromFloat hsla.l ++ "%, " ++ String.fromFloat hsla.a ++ ")"


{-| Convert FilterValue to CSS filter string.
-}
filterToString : Anim.FilterValue -> String
filterToString filter =
    case filter of
        Blur radius ->
            "blur(" ++ String.fromFloat radius ++ "px)"

        Brightness value ->
            "brightness(" ++ String.fromFloat value ++ ")"

        Contrast value ->
            "contrast(" ++ String.fromFloat value ++ ")"

        Grayscale value ->
            "grayscale(" ++ String.fromFloat (clamp 0.0 1.0 value) ++ ")"

        Saturate value ->
            "saturate(" ++ String.fromFloat value ++ ")"
