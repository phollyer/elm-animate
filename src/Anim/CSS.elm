module Anim.CSS exposing
    ( builder
    , animate, AnimationState, init
    , getElementPosition
    , getElementStyles
    , htmlAttributes
    , onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel
    -- New automatic position function
    )

{-| CSS-based animation system for Anim with property state tracking.

This module converts AnimBuilder configurations to CSS transition and transform styles
for native browser performance and hardware acceleration. It also tracks current property
values to enable exact distance calculations for speed-based animations.


# Builder Functions

@docs builder


# Animation Execution

@docs animate, AnimationState, init


# State Tracking

@docs getElementPosition


# Utility Functions

@docs getElementStyles


# Element Integration

@docs htmlAttributes


# Event Handling

@docs onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel

-}

import Anim exposing (AnimBuilder)
import Anim.Internal.Builder as Builder
import Anim.Internal.Properties.Color as Color
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Position as Position
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Timing.Delay as Delay
import Anim.Internal.Timing.Easing as Easing
import Anim.Internal.Timing.TimeSpec as TimeSpec
import Dict exposing (Dict)
import Html
import Html.Attributes
import Html.Events
import Json.Decode


{-| Result of CSS animation generation with property state tracking.
-}
type AnimationState
    = AnimationState
        { elementAnimations : Dict ElementId ElementAnimation
        , builder : AnimBuilder -- Store original builder for automatic state queries
        }


type alias ElementId =
    String


{-| CSS animation data for a single element.
-}
type alias ElementAnimation =
    { elementId : ElementId
    , styles : List ( String, String )
    , keyframes : Maybe String
    }


{-| Generate CSS animations from AnimBuilder.

    Anim.init "my-element"
        |> Anim.Properties.Position.to { x = 100, y = 200 }
        |> Anim.Properties.Scale.to { x = 1.5, y = 1.5 }
        |> Anim.CSS.animate

Returns CSS styles that can be applied via Html.Attributes.style or similar.

-}
animate : AnimBuilder -> AnimationState
animate builder_ =
    let
        elementsDict =
            Builder.elements builder_

        elementAnimations =
            elementsDict
                |> Dict.map generateElementAnimation
    in
    AnimationState
        { elementAnimations = elementAnimations
        , builder = builder_ -- Store builder for automatic queries
        }


{-| Initialize empty animation state.
-}
init : AnimationState
init =
    AnimationState
        { elementAnimations = Dict.empty
        , builder = Anim.init
        }


{-| Get the underlying AnimBuilder from AnimationState.

Use this to start new animations based on the current state.

-}
builder : AnimationState -> AnimBuilder
builder (AnimationState state) =
    state.builder


{-| Get the current position of an element.

For elements that are currently animating, it returns the target position.
For elements not currently animating, it returns the last known position or (0,0).

    -- No need to track positions manually!
    currentPos =
        CSS.getElementPosition "box" animationState

-}
getElementPosition : ElementId -> AnimationState -> { x : Float, y : Float }
getElementPosition elementId (AnimationState state) =
    let
        elementsDict =
            Builder.elements state.builder
    in
    Dict.get elementId elementsDict
        |> Maybe.map getTargetPositionFromConfig
        |> Maybe.withDefault { x = 0.0, y = 0.0 }


{-| Helper function to extract target position from element configuration.
-}
getTargetPositionFromConfig : Builder.ElementConfig -> { x : Float, y : Float }
getTargetPositionFromConfig elementConfig =
    elementConfig.properties
        |> List.foldl extractPositionFromProperty { x = 0, y = 0 }


{-| Helper function to extract position from a property configuration.
-}
extractPositionFromProperty : Builder.PropertyConfig -> { x : Float, y : Float } -> { x : Float, y : Float }
extractPositionFromProperty property currentPos =
    case property of
        Builder.PositionConfig config ->
            Position.toRecord config.endAt

        _ ->
            currentPos



-- CSS GENERATION


generateElementAnimation : String -> Builder.ElementConfig -> ElementAnimation
generateElementAnimation elementId elementConfig =
    let
        transforms =
            generateTransforms elementConfig.properties

        transitions =
            generateTransitions elementConfig.properties

        colors =
            generateColorStyles elementConfig.properties

        allStyles =
            [ ( "transform", transforms )
            , ( "transition", transitions )
            ]
                ++ colors
                |> List.filter (\( _, value ) -> not (String.isEmpty value))
    in
    { elementId = elementId
    , styles = allStyles
    , keyframes = Nothing -- For future complex animations
    }


generateTransforms : List Builder.PropertyConfig -> String
generateTransforms properties =
    let
        transformParts =
            List.filterMap transformFromProperty properties
    in
    String.join " " transformParts


transformFromProperty : Builder.PropertyConfig -> Maybe String
transformFromProperty property =
    case property of
        Builder.PositionConfig config ->
            Just ("translate(" ++ Position.toCssString config.endAt ++ ")")

        Builder.RotateConfig config ->
            Just ("rotate(" ++ Rotate.toCssString config.endAt ++ ")")

        Builder.ScaleConfig config ->
            Just ("scale(" ++ Scale.toCssString config.endAt ++ ")")

        Builder.ColorConfig _ ->
            -- Color doesn't use transform
            Nothing

        Builder.OpacityConfig _ ->
            -- Opacity doesn't use transform
            Nothing



-- CSS TRANSITIONS


generateTransitions : List Builder.PropertyConfig -> String
generateTransitions properties =
    let
        -- Group properties by CSS property type
        transformProperties =
            List.filter isTransformProperty properties

        nonTransformTransitions =
            List.filterMap transitionFromNonTransformProperty properties

        -- Generate single consolidated transform transition
        transformTransition =
            case consolidateTransformTiming transformProperties of
                Just transition ->
                    [ transition ]

                Nothing ->
                    []

        allTransitions =
            transformTransition ++ nonTransformTransitions
    in
    String.join ", " allTransitions


isTransformProperty : Builder.PropertyConfig -> Bool
isTransformProperty property =
    case property of
        Builder.PositionConfig _ ->
            True

        Builder.RotateConfig _ ->
            True

        Builder.ScaleConfig _ ->
            True

        _ ->
            False


transitionFromNonTransformProperty : Builder.PropertyConfig -> Maybe String
transitionFromNonTransformProperty property =
    case property of
        Builder.ColorConfig config ->
            let
                distance =
                    calculatePropertyDistance (Builder.ColorConfig config)
            in
            Just ("background-color " ++ TimeSpec.toCssString distance config.timing ++ " " ++ Easing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)

        Builder.OpacityConfig config ->
            let
                distance =
                    calculatePropertyDistance (Builder.OpacityConfig config)
            in
            Just ("opacity " ++ TimeSpec.toCssString distance config.timing ++ " " ++ Easing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)

        _ ->
            Nothing


consolidateTransformTiming : List Builder.PropertyConfig -> Maybe String
consolidateTransformTiming transformProps =
    case transformProps of
        [] ->
            Nothing

        _ ->
            let
                -- Strategy: Use the longest duration, latest easing, earliest delay
                longestDistance =
                    findLongestDistance transformProps

                longestDuration =
                    findLongestDuration transformProps

                latestEasing =
                    findLatestEasing transformProps

                earliestDelay =
                    findEarliestDelay transformProps
            in
            Just ("transform " ++ TimeSpec.toCssString longestDistance longestDuration ++ " " ++ Easing.toCSS (Just latestEasing) ++ " " ++ Delay.toCssString earliestDelay)


findLongestDistance : List Builder.PropertyConfig -> Float
findLongestDistance properties =
    let
        distances =
            List.filterMap extractDistance properties
    in
    case distances of
        [] ->
            0.0

        _ ->
            distances
                |> List.maximum
                |> Maybe.withDefault 0.0


extractDistance : Builder.PropertyConfig -> Maybe Float
extractDistance property =
    case property of
        Builder.PositionConfig config ->
            Just config.distance

        Builder.RotateConfig config ->
            Just config.distance

        Builder.ScaleConfig config ->
            Just config.distance

        _ ->
            Nothing


calculatePropertyDistance : Builder.PropertyConfig -> Float
calculatePropertyDistance property =
    case property of
        Builder.PositionConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Position.fromTuple ( 0, 0 )
            in
            Position.distance startAt config.endAt

        Builder.RotateConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Rotate.fromFloat 0
            in
            Rotate.distance startAt config.endAt

        Builder.ScaleConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Scale.fromTuple ( 1, 1 )
            in
            Scale.distance startAt config.endAt

        Builder.ColorConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Color.rgb255 0 0 0
            in
            Color.distance startAt config.endAt

        Builder.OpacityConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Opacity.fromFloat 1.0
            in
            Opacity.distance startAt config.endAt


findLongestDuration : List Builder.PropertyConfig -> Maybe TimeSpec.TimeSpec
findLongestDuration properties =
    let
        propertyDistances =
            List.filterMap
                (\prop ->
                    extractTiming prop
                        |> Maybe.map (\timeSpec -> ( timeSpec, calculatePropertyDistance prop ))
                )
                properties
    in
    case propertyDistances of
        [] ->
            Nothing

        ( firstTimeSpec, _ ) :: rest ->
            rest
                |> List.foldl
                    (\( timeSpec, dist ) acc ->
                        chooseLongerDuration (\ts -> toFloat (TimeSpec.duration dist ts)) timeSpec acc
                    )
                    firstTimeSpec
                |> Just


chooseLongerDuration : (TimeSpec.TimeSpec -> Float) -> TimeSpec.TimeSpec -> TimeSpec.TimeSpec -> TimeSpec.TimeSpec
chooseLongerDuration calcDuration a b =
    let
        durationA =
            calcDuration a

        durationB =
            calcDuration b
    in
    if durationA >= durationB then
        a

    else
        b



-- Slower speed = longer duration


findLatestEasing : List Builder.PropertyConfig -> Easing.Easing
findLatestEasing properties =
    properties
        |> List.filterMap extractEasing
        |> List.reverse
        -- Get the last one added
        |> List.head
        |> Maybe.withDefault Easing.Linear


findEarliestDelay : List Builder.PropertyConfig -> Maybe Int
findEarliestDelay properties =
    let
        delays =
            List.filterMap extractDelay properties
    in
    case delays of
        [] ->
            Nothing

        _ ->
            delays
                |> List.foldl chooseSmallerDelay 999999
                -- Start with large delay
                |> Just


chooseSmallerDelay : Int -> Int -> Int
chooseSmallerDelay a b =
    if a <= b then
        a

    else
        b


extractTiming : Builder.PropertyConfig -> Maybe TimeSpec.TimeSpec
extractTiming property =
    case property of
        Builder.PositionConfig config ->
            config.timing

        Builder.RotateConfig config ->
            config.timing

        Builder.ScaleConfig config ->
            config.timing

        _ ->
            Nothing


extractEasing : Builder.PropertyConfig -> Maybe Easing.Easing
extractEasing property =
    case property of
        Builder.PositionConfig config ->
            config.easing

        Builder.RotateConfig config ->
            config.easing

        Builder.ScaleConfig config ->
            config.easing

        _ ->
            Nothing


extractDelay : Builder.PropertyConfig -> Maybe Int
extractDelay property =
    case property of
        Builder.PositionConfig config ->
            config.delay

        Builder.RotateConfig config ->
            config.delay

        Builder.ScaleConfig config ->
            config.delay

        _ ->
            Nothing


generateColorStyles : List Builder.PropertyConfig -> List ( String, String )
generateColorStyles properties =
    List.filterMap colorStyleFromProperty properties


colorStyleFromProperty : Builder.PropertyConfig -> Maybe ( String, String )
colorStyleFromProperty property =
    case property of
        Builder.ColorConfig config ->
            Just ( "background-color", Color.toString config.endAt )

        Builder.OpacityConfig config ->
            Just ( "opacity", Opacity.toString config.endAt )

        _ ->
            Nothing



-- UTILITY FUNCTIONS FOR CONSUMERS


{-| Extract styles for a specific element from AnimationResult.

    case Anim.CSS.animate builder of
        AnimationResult animations ->
            animations
                |> List.filter (\anim -> anim.elementId == "my-element")
                |> List.head
                |> Maybe.map .styles
                |> Maybe.withDefault []

-}
getElementStyles : ElementId -> AnimationState -> List ( String, String )
getElementStyles elementId (AnimationState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.map .styles
        |> Maybe.withDefault []


{-| Get all HTML attributes needed for CSS animations on an element.

This is a convenience function that combines CSS styles, transition properties,
and event handling into a single list of Html.Attribute values.

Example:

    div
        ([ Html.Attributes.id "my-element"
         , Html.Attributes.class "box"
         ]
            ++ CSS.htmlAttributes "my-element" animationResult AnimationComplete
        )
        [ text "Animating element" ]

For Elm UI, wrap each attribute with htmlAttribute:

    el
        ([ htmlAttribute (Html.Attributes.id "my-element") ]
            ++ List.map htmlAttribute (CSS.htmlAttributes "my-element" animationResult AnimationComplete)
        )
        (text "Animating element")

-}
htmlAttributes : String -> AnimationState -> List (Html.Attribute msg)
htmlAttributes elementId animationResult =
    getElementStyles elementId animationResult
        |> List.map (\( prop, value ) -> Html.Attributes.style prop value)



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
