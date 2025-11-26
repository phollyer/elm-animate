module Anim.Internal.Sub exposing
    ( TargetId
    , init, builder, animate, AnimationState, AnimationMsg(..)
    , subscriptions, update
    , getPosition, getCurrentStyles, isAnimationRunning
    , htmlAttributes
    , getDuration
    )

{-| Subscription-based animation system for Anim.

This module converts AnimBuilder configurations to frame-based animations using
onAnimationFrameDelta subscriptions for smooth, controlled animations.


# Animation Execution

@docs TargetId

@docs init, builder, animate, AnimationState, AnimationMsg


# Animation Management

@docs subscriptions, update


# Animation Data

@docs getPosition, getCurrentStyles, isAnimationRunning


# CSS Generation

@docs htmlAttributes

-}

import Anim exposing (AnimBuilder)
import Anim.Internal.Builder as Builder
import Anim.Internal.Properties.Color as Color exposing (Color)
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Properties.Position as Position exposing (Position)
import Anim.Internal.Properties.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Properties.Scale as Scale exposing (Scale)
import Anim.Internal.Timing.Easing as Easing exposing (Easing(..))
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Events
import Dict exposing (Dict)
import Html
import Html.Attributes
import Internal.AnimationCore as AnimationCore



-- CONSTANTS


{-| Frame duration in milliseconds for 60 FPS animations.
-}
frameDurationMs : Int
frameDurationMs =
    16


{-| Convert duration in milliseconds to number of animation frames.
-}
durationToFrames : Int -> Int
durationToFrames durationMs =
    if durationMs == 0 then
        1

    else
        Basics.max 1 (round (toFloat durationMs / toFloat frameDurationMs))


{-| Convert delay in milliseconds to number of delay frames.
-}
delayToFrames : Int -> Int
delayToFrames delayMs =
    max 0 (delayMs // frameDurationMs)


{-| Calculate duration from animation step count.
-}
framesToDuration : Int -> Int
framesToDuration stepCount =
    if stepCount <= 1 then
        0

    else
        stepCount * frameDurationMs



-- ANIMATION STATE


{-| State for managing subscription-based animations.
-}
type AnimationState
    = AnimationState
        { elementAnimations : Dict ElementId ElementAnimation
        , isRunning : Bool
        , builder : AnimBuilder
        }


{-| Initialize empty animation builder.
-}
init : AnimationState
init =
    AnimationState
        { elementAnimations = Dict.empty
        , isRunning = False
        , builder = Anim.init
        }


type alias ElementId =
    String


type alias ElementAnimation =
    { properties : List PropertyAnimationState
    , isComplete : Bool
    }



-- Helper functions to create animation steps using AnimationCore


createPositionSteps : Position.Position -> Position.Position -> Int -> (Float -> Float) -> List AnimationValue
createPositionSteps startPos endPos frames easingFunction =
    let
        ( startX, startY ) =
            Position.toTuple startPos

        ( endX, endY ) =
            Position.toTuple endPos

        stepsX =
            case AnimationCore.animationStepsWithFrames frames easingFunction startX endX of
                [] ->
                    List.repeat frames endX

                vals ->
                    vals

        stepsY =
            case AnimationCore.animationStepsWithFrames frames easingFunction startY endY of
                [] ->
                    List.repeat frames endY

                vals ->
                    vals

        steps =
            List.map2 Tuple.pair stepsX stepsY
    in
    List.map (\( x, y ) -> PositionAnimationValue (Position.fromTuple ( x, y ))) steps


createRotateSteps : Rotate.Rotate -> Rotate.Rotate -> Int -> (Float -> Float) -> List AnimationValue
createRotateSteps start target frames easingFunction =
    let
        startFloat =
            Rotate.toFloat start

        targetFloat =
            Rotate.toFloat target

        steps =
            case AnimationCore.animationStepsWithFrames frames easingFunction startFloat targetFloat of
                [] ->
                    List.repeat frames targetFloat

                vals ->
                    vals
    in
    List.map (\value -> RotateAnimationValue (Rotate.fromFloat value)) steps


createScaleSteps : Scale.Scale -> Scale.Scale -> Int -> (Float -> Float) -> List AnimationValue
createScaleSteps start end frames easingFunction =
    let
        ( startX, startY ) =
            Scale.toTuple start

        ( targetX, targetY ) =
            Scale.toTuple end

        stepsX =
            case AnimationCore.animationStepsWithFrames frames easingFunction startX targetX of
                [] ->
                    List.repeat frames targetX

                vals ->
                    vals

        stepsY =
            case AnimationCore.animationStepsWithFrames frames easingFunction startY targetY of
                [] ->
                    List.repeat frames targetY

                vals ->
                    vals

        steps =
            List.map2 Tuple.pair stepsX stepsY
    in
    List.map (\( x, y ) -> ScaleAnimationValue (Scale.fromTuple ( x, y ))) steps


createOpacitySteps : Opacity.Opacity -> Opacity.Opacity -> Int -> (Float -> Float) -> List AnimationValue
createOpacitySteps start target frames easingFunction =
    let
        startFloat =
            Opacity.toFloat start

        targetFloat =
            Opacity.toFloat target

        steps =
            case AnimationCore.animationStepsWithFrames frames easingFunction startFloat targetFloat of
                [] ->
                    List.repeat frames targetFloat

                vals ->
                    vals
    in
    List.map (\value -> OpacityAnimationValue (Opacity.fromFloat value)) steps


createColorSteps : Color.Color -> Color.Color -> Int -> (Float -> Float) -> List AnimationValue
createColorSteps start target frames easingFunction =
    let
        progressValues =
            case AnimationCore.animationStepsWithFrames frames easingFunction 0.0 1.0 of
                [] ->
                    List.repeat frames 1.0

                vals ->
                    vals

        steps =
            List.map (\progress -> Color.interpolate start target progress) progressValues
    in
    List.map ColorAnimationValue steps


type alias PropertyAnimationState =
    { propertyType : String
    , animationSteps : List AnimationValue
    , currentStepIndex : Int
    , delayFrames : Int
    , currentDelayFrame : Int
    , isComplete : Bool
    , totalDurationMs : Float
    , elapsedMs : Float
    }


type AnimationValue
    = PositionAnimationValue Position
    | RotateAnimationValue Rotate
    | ScaleAnimationValue Scale
    | ColorAnimationValue Color
    | OpacityAnimationValue Opacity


{-| Messages for animation updates.
-}
type AnimationMsg
    = AnimationFrame Float -- delta time in milliseconds (converted to frame tick)



-- ANIMATION EXECUTION


{-| The ID of the target element to animate.
-}
type alias TargetId =
    String


{-| Turn the AnimationState into an AnimBuilder.

Use this to start new animations based on current state.

    -- Start a new animation based on current state
    newBuilder =
        model.animations
            |> Sub.builder
            |> Position.for "element"
            |> Position.to { x = 100, y = 200 }
            |> Position.build
            |> Sub.animate

-}
builder : AnimationState -> AnimBuilder
builder (AnimationState state) =
    -- Return the stored builder which contains current state
    state.builder


{-| Extract current values from dirty properties in the builder.
Dirty properties with duration=0 represent current state.
-}
extractCurrentValuesFromBuilder : AnimBuilder -> { position : Maybe { x : Float, y : Float }, rotate : Maybe Float, scale : Maybe { x : Float, y : Float }, color : Maybe Color, opacity : Maybe Float }
extractCurrentValuesFromBuilder animBuilder =
    let
        processedData =
            Builder.processAnimationData animBuilder

        -- Look through all processed elements for dirty properties (duration=0)
        extractFromElements =
            Dict.values processedData.elements
                |> List.concatMap .properties
                |> List.foldl extractFromProperty { position = Nothing, rotate = Nothing, scale = Nothing, color = Nothing, opacity = Nothing }
    in
    extractFromElements


extractFromProperty : Builder.ProcessedPropertyConfig -> { position : Maybe { x : Float, y : Float }, rotate : Maybe Float, scale : Maybe { x : Float, y : Float }, color : Maybe Color, opacity : Maybe Float } -> { position : Maybe { x : Float, y : Float }, rotate : Maybe Float, scale : Maybe { x : Float, y : Float }, color : Maybe Color, opacity : Maybe Float }
extractFromProperty property acc =
    case property of
        Builder.ProcessedPositionConfig config ->
            if config.duration == 0 then
                { acc | position = Just (Position.toRecord config.endAt) }

            else
                acc

        Builder.ProcessedRotateConfig config ->
            if config.duration == 0 then
                { acc | rotate = Just (Rotate.toFloat config.endAt) }

            else
                acc

        Builder.ProcessedScaleConfig config ->
            if config.duration == 0 then
                let
                    ( x, y ) =
                        Scale.toTuple config.endAt
                in
                { acc | scale = Just { x = x, y = y } }

            else
                acc

        Builder.ProcessedColorConfig config ->
            if config.duration == 0 then
                { acc | color = Just config.endAt }

            else
                acc

        Builder.ProcessedOpacityConfig config ->
            if config.duration == 0 then
                { acc | opacity = Just (Opacity.toFloat config.endAt) }

            else
                acc


{-| Create animation state from AnimBuilder.

    let
        animationState =
            Anim.init "my-element"
                |> Position.to { x = 100, y = 200 }
                |> Scale.to { x = 1.5, y = 1.5 }
                |> Sub.animate
    in
    -- Use with subscriptions and update

-}
animate : AnimBuilder -> AnimationState
animate builder_ =
    let
        processedData =
            Builder.processAnimationData builder_

        -- Extract current values from any existing animations in the builder
        currentValues =
            extractCurrentValuesFromBuilder builder_

        startValues =
            { position = Maybe.withDefault { x = 0, y = 0 } currentValues.position
            , rotate = Maybe.withDefault 0 currentValues.rotate
            , scale = Maybe.withDefault { x = 1.0, y = 1.0 } currentValues.scale
            , color = Maybe.withDefault (Color.rgba255 255 255 255 1.0) currentValues.color
            , opacity = Maybe.withDefault 1.0 currentValues.opacity
            }

        elementStates =
            Dict.map (createElementAnimationState startValues) processedData.elements
    in
    AnimationState
        { elementAnimations = elementStates
        , isRunning = not (Dict.isEmpty elementStates)
        , builder = Builder.markDirty builder_
        }


createElementAnimationState :
    { position : { x : Float, y : Float }
    , rotate : Float
    , scale : { x : Float, y : Float }
    , color : Color
    , opacity : Float
    }
    -> String
    -> Builder.ProcessedElementConfig
    -> ElementAnimation
createElementAnimationState startValues _ elementConfig =
    { properties = List.filterMap (createPropertyAnimationState startValues) elementConfig.properties
    , isComplete = False
    }


createPropertyAnimationState :
    { position : { x : Float, y : Float }
    , rotate : Float
    , scale : { x : Float, y : Float }
    , color : Color
    , opacity : Float
    }
    -> Builder.ProcessedPropertyConfig
    -> Maybe PropertyAnimationState
createPropertyAnimationState startValues property =
    case property of
        Builder.ProcessedPositionConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just start ->
                            start

                        Nothing ->
                            Position.fromTuple ( startValues.position.x, startValues.position.y )

                frames =
                    if config.duration == 0 then
                        1

                    else
                        durationToFrames config.duration

                easeFunction =
                    Easing.toFunction config.easing

                steps =
                    if config.duration == 0 then
                        -- Zero duration: immediately jump to end value
                        [ PositionAnimationValue config.endAt ]

                    else
                        createPositionSteps startAt config.endAt frames easeFunction
            in
            Just
                { propertyType = "position"
                , animationSteps = steps
                , currentStepIndex = 0
                , delayFrames = delayToFrames config.delay
                , currentDelayFrame = 0
                , isComplete = False
                , totalDurationMs = toFloat config.duration
                , elapsedMs = 0.0
                }

        Builder.ProcessedRotateConfig config ->
            let
                actualStart =
                    case config.startAt of
                        Just start ->
                            start

                        Nothing ->
                            Rotate.fromFloat startValues.rotate

                frames =
                    durationToFrames config.duration

                easeFunction =
                    Easing.toFunction config.easing

                steps =
                    if config.duration == 0 then
                        -- Zero duration: immediately jump to end value
                        [ RotateAnimationValue config.endAt ]

                    else
                        createRotateSteps actualStart config.endAt frames easeFunction
            in
            Just
                { propertyType = "rotate"
                , animationSteps = steps
                , currentStepIndex = 0
                , delayFrames = delayToFrames config.delay
                , currentDelayFrame = 0
                , isComplete = False
                , totalDurationMs = toFloat config.duration
                , elapsedMs = 0.0
                }

        Builder.ProcessedScaleConfig config ->
            let
                actualStart =
                    case config.startAt of
                        Just start ->
                            start

                        Nothing ->
                            Scale.fromTuple ( startValues.scale.x, startValues.scale.y )

                frames =
                    durationToFrames config.duration

                easeFunction =
                    Easing.toFunction config.easing

                steps =
                    if config.duration == 0 then
                        -- Zero duration: immediately jump to end value
                        [ ScaleAnimationValue config.endAt ]

                    else
                        createScaleSteps actualStart config.endAt frames easeFunction
            in
            Just
                { propertyType = "scale"
                , animationSteps = steps
                , currentStepIndex = 0
                , delayFrames = delayToFrames config.delay
                , currentDelayFrame = 0
                , isComplete = False
                , totalDurationMs = toFloat config.duration
                , elapsedMs = 0.0
                }

        Builder.ProcessedColorConfig config ->
            let
                startColor =
                    startValues.color

                actualStart =
                    case config.startAt of
                        Just start ->
                            start

                        Nothing ->
                            startColor

                frames =
                    if config.duration == 0 then
                        1

                    else
                        durationToFrames config.duration

                easeFunction =
                    Easing.toFunction config.easing

                steps =
                    if config.duration == 0 then
                        -- Zero duration: immediately jump to end value
                        [ ColorAnimationValue config.endAt ]

                    else
                        createColorSteps actualStart config.endAt frames easeFunction
            in
            Just
                { propertyType = "color"
                , animationSteps = steps
                , currentStepIndex = 0
                , delayFrames = delayToFrames config.delay
                , currentDelayFrame = 0
                , isComplete = False
                , totalDurationMs = toFloat config.duration
                , elapsedMs = 0.0
                }

        Builder.ProcessedOpacityConfig config ->
            let
                startOpacity =
                    Opacity.fromFloat startValues.opacity

                actualStart =
                    case config.startAt of
                        Just start ->
                            start

                        Nothing ->
                            startOpacity

                frames =
                    durationToFrames config.duration

                easeFunction =
                    Easing.toFunction config.easing

                steps =
                    if config.duration == 0 then
                        -- Zero duration: immediately jump to end value
                        [ OpacityAnimationValue config.endAt ]

                    else
                        createOpacitySteps actualStart config.endAt frames easeFunction
            in
            Just
                { propertyType = "opacity"
                , animationSteps = steps
                , currentStepIndex = 0
                , delayFrames = delayToFrames config.delay
                , currentDelayFrame = 0
                , isComplete = False
                , totalDurationMs = toFloat config.duration
                , elapsedMs = 0.0
                }



-- SUBSCRIPTIONS


{-| Subscribe to animation frames when animations are running.
-}
subscriptions : AnimationState -> Sub AnimationMsg
subscriptions (AnimationState state) =
    if state.isRunning then
        Browser.Events.onAnimationFrameDelta AnimationFrame

    else
        Sub.none



-- UPDATE


{-| Update animation state with frame delta time.
-}
update : AnimationMsg -> AnimationState -> AnimationState
update msg (AnimationState state) =
    case msg |> Debug.log "==> update" of
        AnimationFrame deltaMs ->
            let
                updatedElements =
                    Dict.map (updateElementAnimation deltaMs) state.elementAnimations

                stillRunning =
                    Dict.values updatedElements |> List.any (not << .isComplete)
            in
            AnimationState
                { elementAnimations = updatedElements
                , isRunning = stillRunning
                , builder = state.builder
                }


updateElementAnimation : Float -> String -> ElementAnimation -> ElementAnimation
updateElementAnimation deltaMs _ elementState =
    let
        updatedProperties =
            List.map (updatePropertyAnimation deltaMs) elementState.properties

        allComplete =
            List.all .isComplete updatedProperties
    in
    { elementState
        | properties = updatedProperties
        , isComplete = allComplete
    }


updatePropertyAnimation : Float -> PropertyAnimationState -> PropertyAnimationState
updatePropertyAnimation deltaMs propertyState =
    if propertyState.isComplete then
        propertyState

    else
        let
            newElapsedMs =
                propertyState.elapsedMs + deltaMs

            delayMs =
                toFloat propertyState.delayFrames * toFloat frameDurationMs

            isInDelayPeriod =
                newElapsedMs < delayMs

            animationElapsedMs =
                max 0 (newElapsedMs - delayMs)

            isComplete =
                animationElapsedMs >= propertyState.totalDurationMs

            -- Calculate correct frame index based on elapsed time, not frame stepping
            correctFrameIndex =
                if isInDelayPeriod || propertyState.totalDurationMs <= 0 then
                    0

                else
                    let
                        progress =
                            min 1.0 (animationElapsedMs / propertyState.totalDurationMs)

                        maxIndex =
                            List.length propertyState.animationSteps - 1
                    in
                    min maxIndex (round (progress * toFloat maxIndex))
        in
        { propertyState
            | elapsedMs = newElapsedMs
            , currentStepIndex = correctFrameIndex
            , isComplete = isComplete
        }



-- POSITION


{-| Get current position of an element being animated.
-}
getPosition : String -> AnimationState -> Maybe Position
getPosition elementId (AnimationState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen
            (\elementState ->
                List.head elementState.properties
                    |> Maybe.andThen
                        (\propertyState ->
                            let
                                currentValue =
                                    List.drop propertyState.currentStepIndex propertyState.animationSteps
                                        |> List.head
                                        |> Maybe.withDefault (getLastStep propertyState.animationSteps)
                            in
                            case currentValue of
                                PositionAnimationValue pos ->
                                    Just pos

                                _ ->
                                    Nothing
                        )
            )


{-| Get duration of the first animation found for an element.
Returns Nothing if the element has no animations.
-}
getDuration : String -> AnimationState -> Maybe Int
getDuration elementId (AnimationState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen
            (\elementAnimation ->
                elementAnimation.properties
                    |> List.filterMap
                        (\prop ->
                            -- Calculate duration from animation steps
                            let
                                stepCount =
                                    List.length prop.animationSteps
                            in
                            Just (framesToDuration stepCount)
                        )
                    |> List.head
            )


{-| Check if an animation is currently running for the given element.
Returns True if the element has active animations, False otherwise.
-}
isAnimationRunning : String -> AnimationState -> Bool
isAnimationRunning elementId (AnimationState state) =
    case Dict.get elementId state.elementAnimations of
        Just elementAnimation ->
            not elementAnimation.isComplete && List.any (not << .isComplete) elementAnimation.properties

        Nothing ->
            False



-- CURRENT STYLES


{-| Get current animation values as CSS-compatible styles.
-}
getCurrentStyles : String -> AnimationState -> List ( String, String )
getCurrentStyles elementId (AnimationState state) =
    case Dict.get elementId state.elementAnimations of
        Nothing ->
            []

        Just elementState ->
            combinePropertyStyles elementState.properties


combinePropertyStyles : List PropertyAnimationState -> List ( String, String )
combinePropertyStyles properties =
    let
        transformParts =
            List.filterMap getTransformPart properties

        nonTransformStyles =
            List.filterMap getNonTransformStyle properties

        transformStyle =
            if List.isEmpty transformParts then
                []

            else
                [ ( "transform", String.join " " transformParts ) ]
    in
    transformStyle ++ nonTransformStyles


getTransformPart : PropertyAnimationState -> Maybe String
getTransformPart propertyState =
    let
        currentValue =
            List.drop propertyState.currentStepIndex propertyState.animationSteps
                |> List.head
                |> Maybe.withDefault (getLastStep propertyState.animationSteps)
    in
    case currentValue of
        PositionAnimationValue pos ->
            let
                ( x, y ) =
                    Position.toTuple pos
            in
            Just ("translate(" ++ String.fromFloat x ++ "px, " ++ String.fromFloat y ++ "px)")

        RotateAnimationValue rotate ->
            let
                degrees =
                    Rotate.toFloat rotate
            in
            Just ("rotate(" ++ String.fromFloat degrees ++ "deg)")

        ScaleAnimationValue scale ->
            let
                ( x, y ) =
                    Scale.toTuple scale
            in
            Just ("scale(" ++ String.fromFloat x ++ ", " ++ String.fromFloat y ++ ")")

        _ ->
            Nothing


getNonTransformStyle : PropertyAnimationState -> Maybe ( String, String )
getNonTransformStyle propertyState =
    let
        currentValue =
            List.drop propertyState.currentStepIndex propertyState.animationSteps
                |> List.head
                |> Maybe.withDefault (getLastStep propertyState.animationSteps)
    in
    case currentValue of
        ColorAnimationValue colorValue ->
            Just ( "background-color", Color.toString colorValue )

        OpacityAnimationValue opacity ->
            let
                opacityValue =
                    Opacity.toFloat opacity
            in
            Just ( "opacity", String.fromFloat opacityValue )

        _ ->
            Nothing


getLastStep : List AnimationValue -> AnimationValue
getLastStep steps =
    List.reverse steps
        |> List.head
        |> Maybe.withDefault (PositionAnimationValue (Position.fromTuple ( 0, 0 )))



-- HELPER FUNCTIONS


htmlAttributes : String -> AnimationState -> List (Html.Attribute msg)
htmlAttributes elementId animationResult =
    getElementStyles elementId animationResult
        |> List.map (\( prop, value ) -> Html.Attributes.style prop value)


getElementStyles : String -> AnimationState -> List ( String, String )
getElementStyles elementId (AnimationState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.map .properties
        |> Maybe.map combinePropertyStyles
        |> Maybe.withDefault []
