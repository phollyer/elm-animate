module Anim.CSS exposing
    ( Model
    , init
    , animate
    , getCurrentPosition
    , styleProperties
    , transitionStyles
    , onTransitionStart
    , onTransitionEnd
    , onTransitionRun
    , onTransitionCancel
    )

{-| CSS-based animation system using native browser transitions.

This module provides a way to animate elements using browser-native CSS transitions for optimal performance and battery efficiency. Use the fluent Animation builder API from the core Anim module to create animations, then apply them with this module's functions.

**Basic Usage:**

    import Anim
    import Anim.CSS as CSS


    -- Create animations using the builder pattern
    fadeAnimation =
        Anim.opacity "my-element" 0.5
            |> Anim.opacityDuration 300
            |> Anim.easeInOut

    positionAnimation =
        Anim.position "my-element" { x = 100, y = 200 }
            |> Anim.pixelsPerSecond 200.0
            |> Anim.easeOut

    -- Apply animations
    model1 =
        CSS.animate fadeAnimation model.cssModel

    model2 =
        CSS.animate positionAnimation model1

    -- Generate CSS styles
    transitionStyle =
        CSS.transitionStyles fadeAnimation

    elementStyles =
        CSS.styleProperties "my-element" model2


# Model

@docs Model
@docs init


# Animation

@docs animate
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

import Anim exposing (Animation, AnimationTarget(..), ColorValue(..), FilterValue(..), Position, getAnimationData)
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


{-| Animate an element using the new Animation builder API.

    animation =
        Anim.position "my-element" { x = 100, y = 200 }
            |> Anim.duration 500
            |> Anim.easeOut

    newModel =
        animate animation model

-}
animate : Animation -> Model -> Model
animate animation (Model animations) =
    let
        animationData =
            getAnimationData animation

        elementId =
            animationData.elementId

        target =
            animationData.target

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


{-| Generate CSS transition styles for an animation.

Use this function to generate the CSS transition property for smooth animations:

    animation =
        Anim.opacity "my-element" 0.5
            |> Anim.opacityDuration 500
            |> Anim.easeInOut

    styles =
        transitionStyles animation

-}
transitionStyles : Animation -> String
transitionStyles animation =
    let
        animationData =
            getAnimationData animation

        duration =
            Internal.animationToMilliseconds animation 1.0

        easing =
            Internal.easingToString animationData.easing
    in
    "all " ++ String.fromFloat duration ++ "ms " ++ easing



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
