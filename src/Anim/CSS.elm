module Anim.CSS exposing
    ( Model
    , init
    , animate
    , animateOpacity
    , animatePosition
    , animateToX
    , animateToY
    , animateScale
    , animateRotation
    , animateBackgroundColor
    , getCurrentPosition
    , styleProperties
    , transitionStyles
    , onTransitionStart
    , onTransitionEnd
    , onTransitionRun
    , onTransitionCancel
    )

{-| CSS-based animation system using native browser transitions.


# Model

@docs Model
@docs init


# Animation

@docs animate
@docs animateOpacity
@docs animatePosition
@docs animateToX
@docs animateToY
@docs animateScale
@docs animateRotation
@docs animateBackgroundColor
@docs getCurrentPosition


# CSS Generation

@docs styleProperties
@docs transitionStyles


# Event Handlers

@docs onTransitionStart
@docs onTransitionEnd
@docs onTransitionRun
@docs onTransitionCancel

-}

import Anim exposing (AnimationTarget(..), ColorValue(..), FilterValue(..), Position, RotationValue, ScaleValue, defaultConfig)
import Anim.Internal as Internal
import Dict exposing (Dict)
import Html
import Html.Events
import Json.Decode



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
            -- For transform targets, filter by specific target type, not general type
            if isTransformTarget target then
                target :: List.filter (\t -> getSpecificTargetType t /= getSpecificTargetType target) currentTargets

            else
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


{-| Animate element to a specific X coordinate, preserving current Y position.
-}
animateToX : String -> Float -> Model -> Model
animateToX elementId targetX model =
    let
        currentPosition =
            getCurrentPosition elementId model

        newPosition =
            { currentPosition | x = targetX }
    in
    animatePosition elementId newPosition model


{-| Animate element to a specific Y coordinate, preserving current X position.
-}
animateToY : String -> Float -> Model -> Model
animateToY elementId targetY model =
    let
        currentPosition =
            getCurrentPosition elementId model

        newPosition =
            { currentPosition | y = targetY }
    in
    animatePosition elementId newPosition model


{-| Get the current position of an element from the animation model.
Returns { x = 0, y = 0 } if no position is set.
-}
getCurrentPosition : String -> Model -> Position
getCurrentPosition elementId (Model animations) =
    case Dict.get elementId animations of
        Just targets ->
            targets
                |> List.filterMap extractPosition
                |> List.head
                |> Maybe.withDefault { x = 0, y = 0 }

        Nothing ->
            { x = 0, y = 0 }


{-| Extract position from AnimationTarget if it's a ToPosition target.
-}
extractPosition : AnimationTarget -> Maybe Position
extractPosition target =
    case target of
        ToPosition position ->
            Just position

        _ ->
            Nothing



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
Ensures transforms are applied in the correct order: translate, scale, rotate.
-}
combineTransforms : List AnimationTarget -> String
combineTransforms targets =
    let
        -- Separate transforms by type for proper ordering
        positions =
            targets |> List.filterMap extractTranslate

        scales =
            targets |> List.filterMap extractScale

        rotations =
            targets |> List.filterMap extractRotation

        -- Combine in correct order: translate, scale, rotate
        orderedTransforms =
            (positions |> List.map transformToString)
                ++ (scales |> List.map transformToString)
                ++ (rotations |> List.map transformToString)
    in
    String.join " " orderedTransforms


{-| Extract translate transform from AnimationTarget if it's a ToPosition target.
-}
extractTranslate : AnimationTarget -> Maybe AnimationTarget
extractTranslate target =
    case target of
        ToPosition _ ->
            Just target

        _ ->
            Nothing


{-| Extract scale transform from AnimationTarget if it's a ToScale target.
-}
extractScale : AnimationTarget -> Maybe AnimationTarget
extractScale target =
    case target of
        ToScale _ ->
            Just target

        _ ->
            Nothing


{-| Extract rotation transform from AnimationTarget if it's a ToRotation target.
-}
extractRotation : AnimationTarget -> Maybe AnimationTarget
extractRotation target =
    case target of
        ToRotation _ ->
            Just target

        _ ->
            Nothing


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
            "dimensions"

        ToBorderRadius _ ->
            "border-radius"

        ToFilter _ ->
            "filter"


{-| Get the specific type identifier for an AnimationTarget (distinguishes between transform subtypes).
-}
getSpecificTargetType : AnimationTarget -> String
getSpecificTargetType target =
    case target of
        ToPosition _ ->
            "position"

        ToScale _ ->
            "scale"

        ToRotation _ ->
            "rotation"

        ToOpacity _ ->
            "opacity"

        ToBackgroundColor _ ->
            "background-color"

        ToTextColor _ ->
            "color"

        ToBorderColor _ ->
            "border-color"

        ToDimensions _ ->
            "dimensions"

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



-- CSS TRANSITION EVENT HANDLERS


{-| Event handler for when a CSS transition starts.
-}
onTransitionStart : msg -> Html.Attribute msg
onTransitionStart msg =
    Html.Events.on "transitionstart" (Json.Decode.succeed msg)


{-| Event handler for when a CSS transition ends.
-}
onTransitionEnd : msg -> Html.Attribute msg
onTransitionEnd msg =
    Html.Events.on "transitionend" (Json.Decode.succeed msg)


{-| Event handler for when a CSS transition run begins (even if delayed).
-}
onTransitionRun : msg -> Html.Attribute msg
onTransitionRun msg =
    Html.Events.on "transitionrun" (Json.Decode.succeed msg)


{-| Event handler for when a CSS transition is cancelled.
-}
onTransitionCancel : msg -> Html.Attribute msg
onTransitionCancel msg =
    Html.Events.on "transitioncancel" (Json.Decode.succeed msg)
