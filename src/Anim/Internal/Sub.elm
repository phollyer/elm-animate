module Anim.Internal.Sub exposing
    ( TargetId
    , init, builder, animate, AnimState, AnimationMsg(..)
    , subscriptions, update
    , getPosition, getPositionXY, getPositionX, getPositionY
    , getCurrentStyles
    , isAnimationRunning
    , htmlAttributes
    , AnimBuilder, allComplete, anyRunning, delay, duration, easing, getBackgroundColorRange, getColor, getDuration, getOpacity, getOpacityRange, getPositionRange, getRotate, getRotateRange, getScale, getScaleRange, getSize, getSizeH, getSizeHW, getSizeRange, getSizeW, isElementComplete, isElementRunning, speed
    )

{-| Subscription-based animation system for Anim.

This module converts AnimBuilder configurations to frame-based animations using
onAnimationFrameDelta subscriptions for smooth, controlled animations.


# Animation Execution

@docs TargetId

@docs init, builder, animate, AnimState, AnimationMsg


# Animation Management

@docs subscriptions, update


# Animation Querying


## Position

@docs getPosition, getPositionXY, getPositionX, getPositionY


## Current Styles

@docs getCurrentStyles


## Animation State

@docs isAnimationRunning


# CSS Generation

@docs htmlAttributes

-}

import Anim.Internal.AnimationCore as AnimationCore
import Anim.Internal.Builder as Builder
import Anim.Internal.Builders.Property as PropertyBuilder
import Anim.Internal.Properties.BackgroundColor as Color exposing (Color)
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Properties.Position as Position exposing (Position)
import Anim.Internal.Properties.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Properties.Scale as Scale exposing (Scale)
import Anim.Internal.Properties.Size as Size exposing (Size)
import Anim.Internal.Timing.Easing as Easing exposing (Easing(..))
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Events
import Dict exposing (Dict)
import Html
import Html.Attributes


type alias AnimBuilder =
    Builder.AnimBuilder



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
type AnimState
    = AnimState
        { elementAnimations : Dict ElementId ElementAnimation
        , isRunning : Bool
        , builder : AnimBuilder
        }


{-| Initialize empty animation builder.
-}
init : AnimState
init =
    AnimState
        { elementAnimations = Dict.empty
        , isRunning = False
        , builder = Builder.init
        }


type alias ElementId =
    String


type alias ElementAnimation =
    { properties : List PropertyAnimState
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


createSizeSteps : Size.Size -> Size.Size -> Int -> (Float -> Float) -> List AnimationValue
createSizeSteps startSize endSize frames easingFunction =
    let
        ( startWidth, startHeight ) =
            Size.toTuple startSize

        ( endWidth, endHeight ) =
            Size.toTuple endSize

        stepsWidth =
            case AnimationCore.animationStepsWithFrames frames easingFunction startWidth endWidth of
                [] ->
                    List.repeat frames endWidth

                vals ->
                    vals

        stepsHeight =
            case AnimationCore.animationStepsWithFrames frames easingFunction startHeight endHeight of
                [] ->
                    List.repeat frames endHeight

                vals ->
                    vals
    in
    List.map2 (\w h -> SizeAnimationValue (Size.fromTuple ( w, h ))) stepsWidth stepsHeight


type alias PropertyAnimState =
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
    | SizeAnimationValue Size


{-| Messages for animation updates.
-}
type AnimationMsg
    = AnimationFrame Float -- delta time in milliseconds (converted to frame tick)



-- ANIMATION EXECUTION


{-| The ID of the target element to animate.
-}
type alias TargetId =
    String


{-| Turn the AnimState into an AnimBuilder.

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
builder : AnimState -> AnimBuilder
builder ((AnimState state) as animationState) =
    Dict.foldl (setInitialValues animationState) state.builder state.elementAnimations



{- Set the start/end values for properties that are currently being animated.

   This ensures that if an element is mid-animation, and a new animation is started,
   the new animation will start from the current position/color/scale/etc.,
   rather than jumping back to the original start value.
-}


setInitialValues : AnimState -> String -> ElementAnimation -> AnimBuilder -> AnimBuilder
setInitialValues animationState elementId _ builderAcc =
    let
        funcList =
            [ mapCurrentValue getPosition initPosition
            , mapCurrentValue getSize initSize
            , mapCurrentValue getScale initScale
            , mapCurrentValue getRotate initRotate
            , mapCurrentValue getColor initColor
            , mapCurrentValue getOpacity initOpacity
            ]
    in
    List.foldl
        (\func acc -> func elementId animationState acc)
        (Builder.for elementId builderAcc)
        funcList


mapCurrentValue : (String -> AnimState -> maybeProp) -> (AnimBuilder -> maybeProp -> AnimBuilder) -> String -> AnimState -> AnimBuilder -> AnimBuilder
mapCurrentValue getter setter elementId animationState animBuilder =
    getter elementId animationState
        |> setter animBuilder


initPosition : AnimBuilder -> Maybe Position -> AnimBuilder
initPosition animBuilder maybePos =
    case maybePos of
        Just pos ->
            let
                positionConfig =
                    Builder.PositionConfig
                        { startAt = Just pos
                        , endAt = pos
                        , duration = 0
                        , speed = 0
                        , distance = 0
                        , timing = Nothing
                        , easing = Nothing
                        , delay = Nothing
                        , perspective = Nothing
                        , isDirty = False
                        }
            in
            PropertyBuilder.upsert positionConfig animBuilder

        Nothing ->
            animBuilder


initSize : AnimBuilder -> Maybe Size -> AnimBuilder
initSize animBuilder maybeSize =
    case maybeSize of
        Just size ->
            let
                sizeConfig =
                    Builder.SizeConfig
                        { startAt = Just size
                        , endAt = size
                        , duration = 0
                        , speed = 0
                        , distance = 0
                        , timing = Nothing
                        , easing = Nothing
                        , delay = Nothing
                        , perspective = Nothing
                        , isDirty = False
                        }
            in
            PropertyBuilder.upsert sizeConfig animBuilder

        Nothing ->
            animBuilder


initScale : AnimBuilder -> Maybe Scale -> AnimBuilder
initScale animBuilder maybeScale =
    case maybeScale of
        Just scale ->
            let
                scaleConfig =
                    Builder.ScaleConfig
                        { startAt = Just scale
                        , endAt = scale
                        , duration = 0
                        , speed = 0
                        , distance = 0
                        , timing = Nothing
                        , easing = Nothing
                        , delay = Nothing
                        , perspective = Nothing
                        , isDirty = False
                        }
            in
            PropertyBuilder.upsert scaleConfig animBuilder

        Nothing ->
            animBuilder


initRotate : AnimBuilder -> Maybe Rotate -> AnimBuilder
initRotate animBuilder maybeRotate =
    case maybeRotate of
        Just rotate ->
            let
                rotateConfig =
                    Builder.RotateConfig
                        { startAt = Just rotate
                        , endAt = rotate
                        , duration = 0
                        , speed = 0
                        , distance = 0
                        , timing = Nothing
                        , easing = Nothing
                        , delay = Nothing
                        , perspective = Nothing
                        , isDirty = False
                        }
            in
            PropertyBuilder.upsert rotateConfig animBuilder

        Nothing ->
            animBuilder


initColor : AnimBuilder -> Maybe Color -> AnimBuilder
initColor animBuilder maybeColor =
    case maybeColor of
        Just color ->
            let
                colorConfig =
                    Builder.BackgroundColorConfig
                        { startAt = Just color
                        , endAt = color
                        , duration = 0
                        , speed = 0
                        , distance = 0
                        , timing = Nothing
                        , easing = Nothing
                        , delay = Nothing
                        , perspective = Nothing
                        , isDirty = False
                        }
            in
            PropertyBuilder.upsert colorConfig animBuilder

        Nothing ->
            animBuilder


initOpacity : AnimBuilder -> Maybe Opacity -> AnimBuilder
initOpacity animBuilder maybeOpacity =
    case maybeOpacity of
        Just opacity ->
            let
                opacityConfig =
                    Builder.OpacityConfig
                        { startAt = Just opacity
                        , endAt = opacity
                        , duration = 0
                        , speed = 0
                        , distance = 0
                        , timing = Nothing
                        , easing = Nothing
                        , delay = Nothing
                        , perspective = Nothing
                        , isDirty = False
                        }
            in
            PropertyBuilder.upsert opacityConfig animBuilder

        Nothing ->
            animBuilder


{-| Extract current values from dirty properties in the builder.
Dirty properties with duration=0 represent current state.
-}
extractCurrentValuesFromBuilder : AnimBuilder -> { position : Maybe { x : Float, y : Float }, rotate : Maybe Float, scale : Maybe { x : Float, y : Float }, color : Maybe Color, opacity : Maybe Float, size : Maybe { width : Float, height : Float } }
extractCurrentValuesFromBuilder animBuilder =
    let
        processedData =
            Builder.processAnimationData animBuilder

        -- Look through all processed elements for dirty properties (duration=0)
        extractFromElements =
            Dict.values processedData.elements
                |> List.concatMap .properties
                |> List.foldl extractFromProperty { position = Nothing, rotate = Nothing, scale = Nothing, color = Nothing, opacity = Nothing, size = Nothing }
    in
    extractFromElements


extractFromProperty : Builder.ProcessedPropertyConfig -> { position : Maybe { x : Float, y : Float }, rotate : Maybe Float, scale : Maybe { x : Float, y : Float }, color : Maybe Color, opacity : Maybe Float, size : Maybe { width : Float, height : Float } } -> { position : Maybe { x : Float, y : Float }, rotate : Maybe Float, scale : Maybe { x : Float, y : Float }, color : Maybe Color, opacity : Maybe Float, size : Maybe { width : Float, height : Float } }
extractFromProperty property acc =
    case property of
        Builder.ProcessedPositionConfig config ->
            if config.duration == 0 then
                { acc | position = Just { x = Position.x config.endAt, y = Position.y config.endAt } }

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

        Builder.ProcessedBackgroundColorConfig config ->
            if config.duration == 0 then
                { acc | color = Just config.endAt }

            else
                acc

        Builder.ProcessedOpacityConfig config ->
            if config.duration == 0 then
                { acc | opacity = Just (Opacity.toFloat config.endAt) }

            else
                acc

        Builder.ProcessedSizeConfig config ->
            if config.duration == 0 then
                { acc | size = Just (Size.toRecord config.endAt) }

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
animate : AnimBuilder -> AnimState
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
            , size = Maybe.withDefault { width = 0, height = 0 } currentValues.size
            }

        elementStates =
            Dict.map (createElementAnimState startValues) processedData.elements
    in
    AnimState
        { elementAnimations = elementStates
        , isRunning = not (Dict.isEmpty elementStates)
        , builder = Builder.markDirty builder_
        }


createElementAnimState :
    { position : { x : Float, y : Float }
    , rotate : Float
    , scale : { x : Float, y : Float }
    , color : Color
    , opacity : Float
    , size : { width : Float, height : Float }
    }
    -> String
    -> Builder.ProcessedElementConfig
    -> ElementAnimation
createElementAnimState startValues _ elementConfig =
    let
        properties =
            List.filterMap (createPropertyAnimState startValues) elementConfig.properties
    in
    { properties = properties
    , isComplete = False
    }


createPropertyAnimState :
    { position : { x : Float, y : Float }
    , rotate : Float
    , scale : { x : Float, y : Float }
    , color : Color
    , opacity : Float
    , size : { width : Float, height : Float }
    }
    -> Builder.ProcessedPropertyConfig
    -> Maybe PropertyAnimState
createPropertyAnimState startValues property =
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

        Builder.ProcessedBackgroundColorConfig config ->
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

        Builder.ProcessedSizeConfig config ->
            let
                startSize =
                    Size.fromTuple ( startValues.size.width, startValues.size.height )

                actualStart =
                    case config.startAt of
                        Just start ->
                            start

                        Nothing ->
                            startSize

                -- Default size
                frames =
                    durationToFrames config.duration

                easeFunction =
                    Easing.toFunction config.easing

                steps =
                    if config.duration == 0 then
                        -- Zero duration: immediately jump to end value
                        [ SizeAnimationValue config.endAt ]

                    else
                        createSizeSteps actualStart config.endAt frames easeFunction
            in
            Just
                { propertyType = "size"
                , animationSteps = steps
                , currentStepIndex = 0
                , delayFrames = delayToFrames config.delay
                , currentDelayFrame = 0
                , isComplete = False
                , totalDurationMs = toFloat config.duration
                , elapsedMs = 0.0
                }


duration : Int -> AnimBuilder -> AnimBuilder
duration =
    Builder.duration


speed : Float -> AnimBuilder -> AnimBuilder
speed value =
    Builder.speed value


easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Builder.easing


delay : Int -> AnimBuilder -> AnimBuilder
delay =
    Builder.delay



-- SUBSCRIPTIONS


{-| Subscribe to animation frames when animations are running.
-}
subscriptions : AnimState -> Sub AnimationMsg
subscriptions (AnimState state) =
    if state.isRunning then
        Browser.Events.onAnimationFrameDelta AnimationFrame

    else
        Sub.none



-- UPDATE


{-| Update animation state with frame delta time.
-}
update : AnimationMsg -> AnimState -> AnimState
update msg (AnimState state) =
    case msg of
        AnimationFrame deltaMs ->
            let
                updatedElements =
                    Dict.map (updateElementAnimation deltaMs) state.elementAnimations

                stillRunning =
                    Dict.values updatedElements |> List.any (not << .isComplete)
            in
            AnimState
                { elementAnimations = updatedElements
                , isRunning = stillRunning
                , builder = state.builder
                }


updateElementAnimation : Float -> String -> ElementAnimation -> ElementAnimation
updateElementAnimation deltaMs _ elementState =
    let
        updatedProperties =
            List.map (updatePropertyAnimation deltaMs) elementState.properties

        allPropertiesComplete =
            List.all .isComplete updatedProperties
    in
    { elementState
        | properties = updatedProperties
        , isComplete = allPropertiesComplete
    }


updatePropertyAnimation : Float -> PropertyAnimState -> PropertyAnimState
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
getPosition : String -> AnimState -> Maybe Position
getPosition elementId (AnimState state) =
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


{-| Get current X and Y position of an element being animated.
-}
getPositionXY : String -> AnimState -> Maybe ( Float, Float )
getPositionXY elementId animationState =
    getPosition elementId animationState
        |> Maybe.map Position.toTuple


{-| Get current X position of an element being animated.
-}
getPositionX : String -> AnimState -> Maybe Float
getPositionX elementId animationState =
    getPosition elementId animationState
        |> Maybe.map (Position.toRecord >> .x)


{-| Get current Y position of an element being animated.
-}
getPositionY : String -> AnimState -> Maybe Float
getPositionY elementId animationState =
    getPosition elementId animationState
        |> Maybe.map (Position.toRecord >> .y)



-- SIZE


{-| Get current size of an element being animated.
-}
getSize : String -> AnimState -> Maybe Size
getSize elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen
            (\elementState ->
                -- Search through all properties for a Size property
                elementState.properties
                    |> List.filterMap
                        (\propertyState ->
                            if propertyState.propertyType == "size" then
                                let
                                    currentValue =
                                        List.drop propertyState.currentStepIndex propertyState.animationSteps
                                            |> List.head
                                            |> Maybe.withDefault (getLastStep propertyState.animationSteps)
                                in
                                case currentValue of
                                    SizeAnimationValue size ->
                                        Just size

                                    _ ->
                                        Nothing

                            else
                                Nothing
                        )
                    |> List.head
            )


{-| Get current scale of an element being animated.
-}
getScale : String -> AnimState -> Maybe Scale
getScale elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen
            (\elementState ->
                elementState.properties
                    |> List.filterMap
                        (\propertyState ->
                            if propertyState.propertyType == "scale" then
                                let
                                    currentValue =
                                        List.drop propertyState.currentStepIndex propertyState.animationSteps
                                            |> List.head
                                            |> Maybe.withDefault (getLastStep propertyState.animationSteps)
                                in
                                case currentValue of
                                    ScaleAnimationValue scale ->
                                        Just scale

                                    _ ->
                                        Nothing

                            else
                                Nothing
                        )
                    |> List.head
            )


{-| Get current rotation of an element being animated.
-}
getRotate : String -> AnimState -> Maybe Rotate
getRotate elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen
            (\elementState ->
                elementState.properties
                    |> List.filterMap
                        (\propertyState ->
                            if propertyState.propertyType == "rotate" then
                                let
                                    currentValue =
                                        List.drop propertyState.currentStepIndex propertyState.animationSteps
                                            |> List.head
                                            |> Maybe.withDefault (getLastStep propertyState.animationSteps)
                                in
                                case currentValue of
                                    RotateAnimationValue rotate ->
                                        Just rotate

                                    _ ->
                                        Nothing

                            else
                                Nothing
                        )
                    |> List.head
            )


{-| Get current color of an element being animated.
-}
getColor : String -> AnimState -> Maybe Color
getColor elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen
            (\elementState ->
                elementState.properties
                    |> List.filterMap
                        (\propertyState ->
                            if propertyState.propertyType == "color" then
                                let
                                    currentValue =
                                        List.drop propertyState.currentStepIndex propertyState.animationSteps
                                            |> List.head
                                            |> Maybe.withDefault (getLastStep propertyState.animationSteps)
                                in
                                case currentValue of
                                    ColorAnimationValue color ->
                                        Just color

                                    _ ->
                                        Nothing

                            else
                                Nothing
                        )
                    |> List.head
            )


{-| Get current opacity of an element being animated.
-}
getOpacity : String -> AnimState -> Maybe Opacity
getOpacity elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen
            (\elementState ->
                elementState.properties
                    |> List.filterMap
                        (\propertyState ->
                            if propertyState.propertyType == "opacity" then
                                let
                                    currentValue =
                                        List.drop propertyState.currentStepIndex propertyState.animationSteps
                                            |> List.head
                                            |> Maybe.withDefault (getLastStep propertyState.animationSteps)
                                in
                                case currentValue of
                                    OpacityAnimationValue opacity ->
                                        Just opacity

                                    _ ->
                                        Nothing

                            else
                                Nothing
                        )
                    |> List.head
            )


{-| Get current width and height of an element being animated.
-}
getSizeHW : String -> AnimState -> Maybe ( Float, Float )
getSizeHW elementId animationState =
    getSize elementId animationState
        |> Maybe.map Size.toTuple


{-| Get current height of an element being animated.
-}
getSizeH : String -> AnimState -> Maybe Float
getSizeH elementId animationState =
    getSize elementId animationState
        |> Maybe.map (Size.toTuple >> Tuple.second)


{-| Get current width of an element being animated.
-}
getSizeW : String -> AnimState -> Maybe Float
getSizeW elementId animationState =
    getSize elementId animationState
        |> Maybe.map (Size.toTuple >> Tuple.first)


{-| Get duration of the first animation found for an element.
Returns Nothing if the element has no animations.
-}
getDuration : String -> AnimState -> Maybe Int
getDuration elementId (AnimState state) =
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
isAnimationRunning : String -> AnimState -> Bool
isAnimationRunning elementId (AnimState state) =
    case Dict.get elementId state.elementAnimations of
        Just elementAnimation ->
            not elementAnimation.isComplete && List.any (not << .isComplete) elementAnimation.properties

        Nothing ->
            False


{-| Check if any animations are currently running.
-}
anyRunning : AnimState -> Bool
anyRunning (AnimState state) =
    case Dict.values state.elementAnimations of
        [] ->
            False

        values ->
            List.any (\el -> not el.isComplete) values


{-| Check if a specific element has any animations currently running.
-}
isElementRunning : String -> AnimState -> Bool
isElementRunning =
    isAnimationRunning


{-| Check if all animations are complete.
-}
allComplete : AnimState -> Maybe Bool
allComplete (AnimState state) =
    if Dict.isEmpty state.elementAnimations then
        Nothing

    else
        state.elementAnimations
            |> Dict.values
            |> List.all .isComplete
            |> Just


{-| Check if a specific element's animations have completed.
-}
isElementComplete : String -> AnimState -> Maybe Bool
isElementComplete elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.map .isComplete



-- RANGE QUERYING (Start/End values)


{-| Get both start and end positions for an element's animation.
Returns Nothing if the element has no position animation.
-}
getPositionRange : String -> AnimState -> Maybe { start : Maybe Position, end : Position }
getPositionRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedPositionConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end scales for an element's animation.
Returns Nothing if the element has no scale animation.
-}
getScaleRange : String -> AnimState -> Maybe { start : Maybe Scale, end : Scale }
getScaleRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedScaleConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end rotations for an element's animation.
Returns Nothing if the element has no rotate animation.
-}
getRotateRange : String -> AnimState -> Maybe { start : Maybe Rotate, end : Rotate }
getRotateRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedRotateConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end opacity values for an element's animation.
Returns Nothing if the element has no opacity animation.
-}
getOpacityRange : String -> AnimState -> Maybe { start : Maybe Opacity, end : Opacity }
getOpacityRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedOpacityConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end background colors for an element's animation.
Returns Nothing if the element has no background color animation.
-}
getBackgroundColorRange : String -> AnimState -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedBackgroundColorConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end sizes for an element's animation.
Returns Nothing if the element has no size animation.
-}
getSizeRange : String -> AnimState -> Maybe { start : Maybe Size, end : Size }
getSizeRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedSizeConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )



-- CURRENT STYLES


{-| Get current animation values as CSS-compatible styles.
-}
getCurrentStyles : String -> AnimState -> List ( String, String )
getCurrentStyles elementId (AnimState state) =
    case Dict.get elementId state.elementAnimations of
        Nothing ->
            []

        Just elementState ->
            combinePropertyStyles elementState.properties


combinePropertyStyles : List PropertyAnimState -> List ( String, String )
combinePropertyStyles properties =
    let
        transformParts =
            List.filterMap getTransformPart properties

        sizeStyles =
            List.concatMap getSizeStyles properties

        nonTransformStyles =
            List.filterMap getNonTransformStyle properties

        transformStyle =
            if List.isEmpty transformParts then
                []

            else
                [ ( "transform", String.join " " transformParts ) ]
    in
    transformStyle ++ sizeStyles ++ nonTransformStyles


getTransformPart : PropertyAnimState -> Maybe String
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
                ( x, y, z ) =
                    Position.toTriple pos
            in
            Just ("translate3d(" ++ String.fromFloat x ++ "px, " ++ String.fromFloat y ++ "px, " ++ String.fromFloat z ++ "px)")

        RotateAnimationValue rotate ->
            Just (Rotate.to3DCssString rotate)

        ScaleAnimationValue scale ->
            let
                ( x, y ) =
                    Scale.toTuple scale
            in
            Just ("scale(" ++ String.fromFloat x ++ ", " ++ String.fromFloat y ++ ")")

        _ ->
            Nothing


getSizeStyles : PropertyAnimState -> List ( String, String )
getSizeStyles propertyState =
    let
        currentValue =
            List.drop propertyState.currentStepIndex propertyState.animationSteps
                |> List.head
                |> Maybe.withDefault (getLastStep propertyState.animationSteps)
    in
    case currentValue of
        SizeAnimationValue size ->
            let
                ( width, height ) =
                    Size.toTuple size
            in
            [ ( "width", String.fromFloat width ++ "px" )
            , ( "height", String.fromFloat height ++ "px" )
            ]

        -- Handle the case where we have a Size property but got a wrong fallback
        _ ->
            if propertyState.propertyType == "size" then
                -- Force some default size CSS if this is a size property
                [ ( "width", "150px" )
                , ( "height", "150px" )
                ]

            else
                []


getNonTransformStyle : PropertyAnimState -> Maybe ( String, String )
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


htmlAttributes : String -> AnimState -> List (Html.Attribute msg)
htmlAttributes elementId animationResult =
    getElementStyles elementId animationResult
        |> List.map (\( prop, value ) -> Html.Attributes.style prop value)


getElementStyles : String -> AnimState -> List ( String, String )
getElementStyles elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.map .properties
        |> Maybe.map combinePropertyStyles
        |> Maybe.withDefault []
