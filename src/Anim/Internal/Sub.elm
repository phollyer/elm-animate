module Anim.Internal.Sub exposing
    ( AnimBuilder
    , AnimState
    , AnimationMsg(..)
    , allComplete
    , animate
    , anyRunning
    , builder
    , delay
    , duration
    , easing
    , getBackgroundColor
    , getBackgroundColorRange
    , getOpacity
    , getOpacityRange
    , getPosition
    , getPositionRange
    , getRotate
    , getRotateRange
    , getScale
    , getScaleRange
    , getSize
    , getSizeRange
    , htmlAttributes
    , init
    , isAnimationRunning
    , isComplete
    , speed
    , subscriptions
    , update
    )

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



-- BUILD


type alias ElementId =
    String


type Animation
    = PositionAnimation Position
    | RotateAnimation Rotate
    | ScaleAnimation Scale
    | BackgroundColorAnimation Color
    | OpacityAnimation Opacity
    | SizeAnimation Size


type alias PropertyAnimation =
    { propertyType : String
    , animationSteps : List Animation
    , currentStepIndex : Int
    , delayFrames : Int
    , currentDelayFrame : Int
    , isComplete : Bool
    , totalDurationMs : Float
    , elapsedMs : Float
    }


type alias ElementAnimation =
    { properties : List PropertyAnimation
    , isComplete : Bool
    }


type AnimState
    = AnimState
        { elementAnimations : Dict ElementId ElementAnimation
        , isRunning : Bool
        , builder : AnimBuilder
        }


init : AnimState
init =
    AnimState
        { elementAnimations = Dict.empty
        , isRunning = False
        , builder = Builder.init
        }


type alias AnimBuilder =
    Builder.AnimBuilder


builder : AnimState -> AnimBuilder
builder ((AnimState state) as animationState) =
    Dict.foldl (setInitialValues animationState) state.builder state.elementAnimations


animate : AnimBuilder -> AnimState
animate builder_ =
    let
        processedData =
            Builder.processAnimationData builder_

        -- Extract current values from any existing animations in the builder
        currentValues =
            extractCurrentValuesFromBuilder builder_

        startValues =
            { position = Maybe.withDefault { x = 0, y = 0, z = 0 } currentValues.position
            , rotate = Maybe.withDefault { x = 0, y = 0, z = 0 } currentValues.rotate
            , scale = Maybe.withDefault { x = 1.0, y = 1.0, z = 1.0 } currentValues.scale
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



-- UPDATE


type AnimationMsg
    = AnimationFrame Float -- delta time in milliseconds


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



-- SUBSCRIPTIONS


subscriptions : AnimState -> Sub AnimationMsg
subscriptions (AnimState state) =
    if state.isRunning then
        Browser.Events.onAnimationFrameDelta AnimationFrame

    else
        Sub.none



-- VIEW


htmlAttributes : String -> AnimState -> List (Html.Attribute msg)
htmlAttributes elementId (AnimState state) =
    case Dict.get elementId state.elementAnimations of
        Nothing ->
            []

        Just elementAnimation ->
            let
                transformParts =
                    List.filterMap getTransformPart elementAnimation.properties

                sizeStyles =
                    List.concatMap getSizeStyleAttributes elementAnimation.properties

                nonTransformStyles =
                    List.filterMap getNonTransformStyleAttribute elementAnimation.properties

                transformStyle =
                    if List.isEmpty transformParts then
                        []

                    else
                        [ Html.Attributes.style "transform" (String.join " " transformParts) ]
            in
            transformStyle ++ sizeStyles ++ nonTransformStyles



-- Querying


allComplete : AnimState -> Maybe Bool
allComplete (AnimState state) =
    if Dict.isEmpty state.elementAnimations then
        Nothing

    else
        state.elementAnimations
            |> Dict.values
            |> List.all .isComplete
            |> Just


anyRunning : AnimState -> Bool
anyRunning (AnimState state) =
    case Dict.values state.elementAnimations of
        [] ->
            False

        values ->
            List.any (\el -> not el.isComplete) values


isAnimationRunning : String -> AnimState -> Bool
isAnimationRunning elementId (AnimState state) =
    case Dict.get elementId state.elementAnimations of
        Just elementAnimation ->
            not elementAnimation.isComplete && List.any (not << .isComplete) elementAnimation.properties

        Nothing ->
            False


isComplete : String -> AnimState -> Maybe Bool
isComplete elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.map .isComplete


getPropertyRange : (Builder.ProcessedPropertyConfig -> Maybe a) -> String -> AnimState -> Maybe a
getPropertyRange matcher elementId (AnimState state) =
    Builder.processAnimationData state.builder
        |> .elements
        |> Dict.get elementId
        |> Maybe.andThen (.properties >> List.filterMap matcher >> List.head)


getPropertyValue : String -> (Animation -> Maybe a) -> String -> AnimState -> Maybe a
getPropertyValue propertyType extractor elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.properties >> List.filterMap (matchProperty propertyType extractor) >> List.head)


matchProperty : String -> (Animation -> Maybe a) -> PropertyAnimation -> Maybe a
matchProperty propertyType extractor propertyState =
    if propertyState.propertyType == propertyType then
        getCurrentValue propertyState |> extractor

    else
        Nothing


getCurrentValue : PropertyAnimation -> Animation
getCurrentValue propertyState =
    List.drop propertyState.currentStepIndex propertyState.animationSteps
        |> List.head
        |> Maybe.withDefault (getLastStep propertyState.animationSteps)


getBackgroundColor : String -> AnimState -> Maybe Color
getBackgroundColor =
    getPropertyValue "backgroundColor"
        (\anim ->
            case anim of
                BackgroundColorAnimation color ->
                    Just color

                _ ->
                    Nothing
        )


getBackgroundColorRange : String -> AnimState -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange =
    getPropertyRange
        (\prop ->
            case prop of
                Builder.ProcessedBackgroundColorConfig config ->
                    Just { start = config.startAt, end = config.endAt }

                _ ->
                    Nothing
        )


getOpacityRange : String -> AnimState -> Maybe { start : Maybe Opacity, end : Opacity }
getOpacityRange =
    getPropertyRange
        (\prop ->
            case prop of
                Builder.ProcessedOpacityConfig config ->
                    Just { start = config.startAt, end = config.endAt }

                _ ->
                    Nothing
        )


getOpacity : String -> AnimState -> Maybe Opacity
getOpacity =
    getPropertyValue "opacity"
        (\anim ->
            case anim of
                OpacityAnimation opacity ->
                    Just opacity

                _ ->
                    Nothing
        )


getPosition : String -> AnimState -> Maybe Position
getPosition =
    getPropertyValue "position"
        (\anim ->
            case anim of
                PositionAnimation pos ->
                    Just pos

                _ ->
                    Nothing
        )


getPositionRange : String -> AnimState -> Maybe { start : Maybe Position, end : Position }
getPositionRange =
    getPropertyRange
        (\prop ->
            case prop of
                Builder.ProcessedPositionConfig config ->
                    Just { start = config.startAt, end = config.endAt }

                _ ->
                    Nothing
        )


getRotate : String -> AnimState -> Maybe Rotate
getRotate =
    getPropertyValue "rotate"
        (\anim ->
            case anim of
                RotateAnimation rotate ->
                    Just rotate

                _ ->
                    Nothing
        )


getRotateRange : String -> AnimState -> Maybe { start : Maybe Rotate, end : Rotate }
getRotateRange =
    getPropertyRange
        (\prop ->
            case prop of
                Builder.ProcessedRotateConfig config ->
                    Just { start = config.startAt, end = config.endAt }

                _ ->
                    Nothing
        )


getScale : String -> AnimState -> Maybe Scale
getScale =
    getPropertyValue "scale"
        (\anim ->
            case anim of
                ScaleAnimation scale ->
                    Just scale

                _ ->
                    Nothing
        )


getScaleRange : String -> AnimState -> Maybe { start : Maybe Scale, end : Scale }
getScaleRange =
    getPropertyRange
        (\prop ->
            case prop of
                Builder.ProcessedScaleConfig config ->
                    Just { start = config.startAt, end = config.endAt }

                _ ->
                    Nothing
        )


getSize : String -> AnimState -> Maybe Size
getSize =
    getPropertyValue "size"
        (\anim ->
            case anim of
                SizeAnimation size ->
                    Just size

                _ ->
                    Nothing
        )


getSizeRange : String -> AnimState -> Maybe { start : Maybe Size, end : Size }
getSizeRange =
    getPropertyRange
        (\prop ->
            case prop of
                Builder.ProcessedSizeConfig config ->
                    Just { start = config.startAt, end = config.endAt }

                _ ->
                    Nothing
        )



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



-- Builder Helpers


setInitialValues : AnimState -> String -> ElementAnimation -> AnimBuilder -> AnimBuilder
setInitialValues animationState elementId _ builderAcc =
    let
        funcList =
            [ mapCurrentValue getPosition initPosition
            , mapCurrentValue getSize initSize
            , mapCurrentValue getScale initScale
            , mapCurrentValue getRotate initRotate
            , mapCurrentValue getBackgroundColor initBackgroundColor
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


initBackgroundColor : AnimBuilder -> Maybe Color -> AnimBuilder
initBackgroundColor animBuilder maybeColor =
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



-- Step Creators


createBackgroundColorSteps : Color.Color -> Color.Color -> Int -> (Float -> Float) -> List Animation
createBackgroundColorSteps start target frames easingFunction =
    let
        progressValues =
            case AnimationCore.animationStepsWithFrames frames easingFunction 0.0 1.0 of
                [] ->
                    List.repeat frames 1.0

                vals ->
                    vals

        steps =
            List.map (Color.interpolate start target) progressValues
    in
    List.map BackgroundColorAnimation steps


createOpacitySteps : Opacity.Opacity -> Opacity.Opacity -> Int -> (Float -> Float) -> List Animation
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
    List.map (OpacityAnimation << Opacity.fromFloat) steps


createPositionSteps : Position.Position -> Position.Position -> Int -> (Float -> Float) -> List Animation
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
    List.map (PositionAnimation << Position.fromTuple) steps


createRotateSteps : Rotate.Rotate -> Rotate.Rotate -> Int -> (Float -> Float) -> List Animation
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
    List.map (RotateAnimation << Rotate.fromFloat) steps


createScaleSteps : Scale.Scale -> Scale.Scale -> Int -> (Float -> Float) -> List Animation
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
    List.map (ScaleAnimation << Scale.fromTuple) steps


createSizeSteps : Size.Size -> Size.Size -> Int -> (Float -> Float) -> List Animation
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

        steps =
            List.map2 Tuple.pair stepsWidth stepsHeight
    in
    List.map (SizeAnimation << Size.fromTuple) steps



-- Extract Current Values


type alias PropertyValues =
    { position : Maybe { x : Float, y : Float, z : Float }
    , rotate : Maybe { x : Float, y : Float, z : Float }
    , scale : Maybe { x : Float, y : Float, z : Float }
    , color : Maybe Color
    , opacity : Maybe Float
    , size : Maybe { width : Float, height : Float }
    }


propertyValuesEmpty : PropertyValues
propertyValuesEmpty =
    { position = Nothing
    , rotate = Nothing
    , scale = Nothing
    , color = Nothing
    , opacity = Nothing
    , size = Nothing
    }


type alias UnwrappedPropertyValues =
    { position : { x : Float, y : Float, z : Float }
    , rotate : { x : Float, y : Float, z : Float }
    , scale : { x : Float, y : Float, z : Float }
    , color : Color
    , opacity : Float
    , size : { width : Float, height : Float }
    }


extractCurrentValuesFromBuilder : AnimBuilder -> PropertyValues
extractCurrentValuesFromBuilder =
    Builder.processAnimationData
        >> .elements
        >> Dict.values
        >> List.concatMap .properties
        >> List.foldl extractFromProperty propertyValuesEmpty


extractFromProperty : Builder.ProcessedPropertyConfig -> PropertyValues -> PropertyValues
extractFromProperty property acc =
    case property of
        Builder.ProcessedBackgroundColorConfig config ->
            if config.duration == 0 then
                { acc | color = Just config.endAt }

            else
                acc

        Builder.ProcessedOpacityConfig config ->
            if config.duration == 0 then
                { acc | opacity = Just <| Opacity.toFloat config.endAt }

            else
                acc

        Builder.ProcessedPositionConfig config ->
            if config.duration == 0 then
                { acc | position = Just <| Position.toRecord config.endAt }

            else
                acc

        Builder.ProcessedRotateConfig config ->
            if config.duration == 0 then
                { acc | rotate = Just <| Rotate.toRecord config.endAt }

            else
                acc

        Builder.ProcessedScaleConfig config ->
            if config.duration == 0 then
                { acc | scale = Just <| Scale.toRecord config.endAt }

            else
                acc

        Builder.ProcessedSizeConfig config ->
            if config.duration == 0 then
                { acc | size = Just <| Size.toRecord config.endAt }

            else
                acc



-- Create Element Animation State


createElementAnimState : UnwrappedPropertyValues -> String -> Builder.ProcessedElementConfig -> ElementAnimation
createElementAnimState startValues _ elementConfig =
    let
        properties =
            List.filterMap (createPropertyAnimState startValues) elementConfig.properties
    in
    { properties = properties
    , isComplete = False
    }


createPropertyAnimState : UnwrappedPropertyValues -> Builder.ProcessedPropertyConfig -> Maybe PropertyAnimation
createPropertyAnimState startValues property =
    case property of
        Builder.ProcessedPositionConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just start ->
                            start

                        Nothing ->
                            Position.fromRecord startValues.position

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
                        [ PositionAnimation config.endAt ]

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
                            Rotate.fromRecord startValues.rotate

                frames =
                    durationToFrames config.duration

                easeFunction =
                    Easing.toFunction config.easing

                steps =
                    if config.duration == 0 then
                        -- Zero duration: immediately jump to end value
                        [ RotateAnimation config.endAt ]

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
                            Scale.fromRecord startValues.scale

                frames =
                    durationToFrames config.duration

                easeFunction =
                    Easing.toFunction config.easing

                steps =
                    if config.duration == 0 then
                        -- Zero duration: immediately jump to end value
                        [ ScaleAnimation config.endAt ]

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
                        [ BackgroundColorAnimation config.endAt ]

                    else
                        createBackgroundColorSteps actualStart config.endAt frames easeFunction
            in
            Just
                { propertyType = "backgroundColor"
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
                        [ OpacityAnimation config.endAt ]

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
                        [ SizeAnimation config.endAt ]

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



-- Update Element Animation


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


updatePropertyAnimation : Float -> PropertyAnimation -> PropertyAnimation
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

            isComplete_ =
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
            , isComplete = isComplete_
        }



-- View Helpers


getTransformPart : PropertyAnimation -> Maybe String
getTransformPart propertyState =
    let
        currentValue =
            List.drop propertyState.currentStepIndex propertyState.animationSteps
                |> List.head
                |> Maybe.withDefault (getLastStep propertyState.animationSteps)
    in
    case currentValue of
        PositionAnimation pos ->
            let
                ( x, y, z ) =
                    Position.toTriple pos
            in
            Just ("translate3d(" ++ String.fromFloat x ++ "px, " ++ String.fromFloat y ++ "px, " ++ String.fromFloat z ++ "px)")

        RotateAnimation rotate ->
            Just (Rotate.to3DCssString rotate)

        ScaleAnimation scale ->
            let
                ( x, y ) =
                    Scale.toTuple scale
            in
            Just ("scale(" ++ String.fromFloat x ++ ", " ++ String.fromFloat y ++ ")")

        _ ->
            Nothing


getSizeStyleAttributes : PropertyAnimation -> List (Html.Attribute msg)
getSizeStyleAttributes propertyState =
    let
        currentValue =
            List.drop propertyState.currentStepIndex propertyState.animationSteps
                |> List.head
                |> Maybe.withDefault (getLastStep propertyState.animationSteps)
    in
    case currentValue of
        SizeAnimation size ->
            let
                ( width, height ) =
                    Size.toTuple size
            in
            [ Html.Attributes.style "width" (String.fromFloat width ++ "px")
            , Html.Attributes.style "height" (String.fromFloat height ++ "px")
            ]

        _ ->
            []


getNonTransformStyleAttribute : PropertyAnimation -> Maybe (Html.Attribute msg)
getNonTransformStyleAttribute propertyState =
    let
        currentValue =
            List.drop propertyState.currentStepIndex propertyState.animationSteps
                |> List.head
                |> Maybe.withDefault (getLastStep propertyState.animationSteps)
    in
    case currentValue of
        BackgroundColorAnimation colorValue ->
            Just (Html.Attributes.style "background-color" (Color.toString colorValue))

        OpacityAnimation opacity ->
            Just (Html.Attributes.style "opacity" (String.fromFloat (Opacity.toFloat opacity)))

        _ ->
            Nothing


getLastStep : List Animation -> Animation
getLastStep steps =
    List.reverse steps
        |> List.head
        |> Maybe.withDefault (PositionAnimation (Position.fromTuple ( 0, 0 )))
