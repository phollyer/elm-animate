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

import Anim.Easing exposing (Easing(..))
import Anim.Internal.AnimationCore as AnimationCore
import Anim.Internal.Builder as Builder
import Anim.Internal.Builders.Property as PropertyBuilder
import Anim.Internal.Easing as Easing
import Anim.Internal.Properties.BackgroundColor as Color exposing (Color)
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Properties.Position as Position exposing (Position)
import Anim.Internal.Properties.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Properties.Scale as Scale exposing (Scale)
import Anim.Internal.Properties.Size as Size exposing (Size)
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
        , builder =
            builder_
                |> Builder.markDirty
                |> Builder.clearCurrentElement
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
                -- Get current animated values for each property
                currentProperties =
                    List.map getCurrentPropertyValue elementAnimation.properties

                -- Extract transforms in correct order using Builder's shared function
                transformParts =
                    Builder.extractTransformsFromProcessed currentProperties

                -- Build transform string in fixed order: position, rotate, scale
                transformString =
                    String.trim
                        (transformParts.position
                            ++ " "
                            ++ transformParts.rotate
                            ++ " "
                            ++ transformParts.scale
                        )

                sizeStyles =
                    List.concatMap getSizeStyleAttributes elementAnimation.properties

                nonTransformStyles =
                    List.filterMap getNonTransformStyleAttribute elementAnimation.properties

                transformStyle =
                    if String.isEmpty transformString then
                        []

                    else
                        [ Html.Attributes.style "transform" transformString ]
            in
            transformStyle ++ sizeStyles ++ nonTransformStyles


{-| Get the current property value as a ProcessedPropertyConfig.
This is used to extract current animated values for transform ordering.
-}
getCurrentPropertyValue : PropertyAnimation -> Builder.ProcessedPropertyConfig
getCurrentPropertyValue propertyState =
    let
        currentValue =
            getCurrentValue propertyState
    in
    case currentValue of
        PositionAnimation pos ->
            Builder.ProcessedPositionConfig
                { start = Just pos
                , end = pos
                , duration = 0
                , speed = 0
                , distance = 0
                , timing = Duration 0
                , easing = Linear
                , delay = 0
                , perspective = Nothing
                }

        RotateAnimation rotate ->
            Builder.ProcessedRotateConfig
                { start = Just rotate
                , end = rotate
                , duration = 0
                , speed = 0
                , distance = 0
                , timing = Duration 0
                , easing = Linear
                , delay = 0
                , perspective = Nothing
                }

        ScaleAnimation scale ->
            Builder.ProcessedScaleConfig
                { start = Just scale
                , end = scale
                , duration = 0
                , speed = 0
                , distance = 0
                , timing = Duration 0
                , easing = Linear
                , delay = 0
                , perspective = Nothing
                }

        BackgroundColorAnimation color ->
            Builder.ProcessedBackgroundColorConfig
                { start = Just color
                , end = color
                , duration = 0
                , speed = 0
                , distance = 0
                , timing = Duration 0
                , easing = Linear
                , delay = 0
                , perspective = Nothing
                }

        OpacityAnimation opacity ->
            Builder.ProcessedOpacityConfig
                { start = Just opacity
                , end = opacity
                , duration = 0
                , speed = 0
                , distance = 0
                , timing = Duration 0
                , easing = Linear
                , delay = 0
                , perspective = Nothing
                }

        SizeAnimation size ->
            Builder.ProcessedSizeConfig
                { start = Just size
                , end = size
                , duration = 0
                , speed = 0
                , distance = 0
                , timing = Duration 0
                , easing = Linear
                , delay = 0
                , perspective = Nothing
                }



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
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


getOpacityRange : String -> AnimState -> Maybe { start : Maybe Opacity, end : Opacity }
getOpacityRange =
    getPropertyRange
        (\prop ->
            case prop of
                Builder.ProcessedOpacityConfig config ->
                    Just { start = config.start, end = config.end }

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
                    Just { start = config.start, end = config.end }

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
                    Just { start = config.start, end = config.end }

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
                    Just { start = config.start, end = config.end }

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
                    Just { start = config.start, end = config.end }

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
                        { start = Just color
                        , end = color
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
                        { start = Just opacity
                        , end = opacity
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
                        { start = Just pos
                        , end = pos
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
                        { start = Just rotate
                        , end = rotate
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
                        { start = Just scale
                        , end = scale
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
                        { start = Just size
                        , end = size
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
                { acc | color = Just config.end }

            else
                acc

        Builder.ProcessedOpacityConfig config ->
            if config.duration == 0 then
                { acc | opacity = Just <| Opacity.toFloat config.end }

            else
                acc

        Builder.ProcessedPositionConfig config ->
            if config.duration == 0 then
                { acc | position = Just <| Position.toRecord config.end }

            else
                acc

        Builder.ProcessedRotateConfig config ->
            if config.duration == 0 then
                { acc | rotate = Just <| Rotate.toRecord config.end }

            else
                acc

        Builder.ProcessedScaleConfig config ->
            if config.duration == 0 then
                { acc | scale = Just <| Scale.toRecord config.end }

            else
                acc

        Builder.ProcessedSizeConfig config ->
            if config.duration == 0 then
                { acc | size = Just <| Size.toRecord config.end }

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
    let
        buildPropertyAnimation :
            String
            -> a
            -> a
            -> Int
            -> Int
            -> Easing
            -> (a -> a -> Int -> (Float -> Float) -> List Animation)
            -> (a -> Animation)
            -> PropertyAnimation
        buildPropertyAnimation propertyType actualStart end duration_ delay_ easing_ stepCreator wrapper =
            let
                frames =
                    if duration_ == 0 then
                        1

                    else
                        durationToFrames duration_

                easeFunction =
                    Easing.toFunction easing_

                steps =
                    if duration_ == 0 then
                        [ wrapper end ]

                    else
                        stepCreator actualStart end frames easeFunction
            in
            { propertyType = propertyType
            , animationSteps = steps
            , currentStepIndex = 0
            , delayFrames = delayToFrames delay_
            , currentDelayFrame = 0
            , isComplete = False
            , totalDurationMs = toFloat duration_
            , elapsedMs = 0.0
            }
    in
    case property of
        Builder.ProcessedPositionConfig config ->
            let
                actualStart =
                    Maybe.withDefault (Position.fromRecord startValues.position) config.start
            in
            Just <|
                buildPropertyAnimation
                    "position"
                    actualStart
                    config.end
                    config.duration
                    config.delay
                    config.easing
                    createPositionSteps
                    PositionAnimation

        Builder.ProcessedRotateConfig config ->
            let
                actualStart =
                    Maybe.withDefault (Rotate.fromRecord startValues.rotate) config.start
            in
            Just <|
                buildPropertyAnimation
                    "rotate"
                    actualStart
                    config.end
                    config.duration
                    config.delay
                    config.easing
                    createRotateSteps
                    RotateAnimation

        Builder.ProcessedScaleConfig config ->
            let
                actualStart =
                    Maybe.withDefault (Scale.fromRecord startValues.scale) config.start
            in
            Just <|
                buildPropertyAnimation
                    "scale"
                    actualStart
                    config.end
                    config.duration
                    config.delay
                    config.easing
                    createScaleSteps
                    ScaleAnimation

        Builder.ProcessedBackgroundColorConfig config ->
            let
                actualStart =
                    Maybe.withDefault startValues.color config.start
            in
            Just <|
                buildPropertyAnimation
                    "backgroundColor"
                    actualStart
                    config.end
                    config.duration
                    config.delay
                    config.easing
                    createBackgroundColorSteps
                    BackgroundColorAnimation

        Builder.ProcessedOpacityConfig config ->
            let
                actualStart =
                    Maybe.withDefault (Opacity.fromFloat startValues.opacity) config.start
            in
            Just <|
                buildPropertyAnimation
                    "opacity"
                    actualStart
                    config.end
                    config.duration
                    config.delay
                    config.easing
                    createOpacitySteps
                    OpacityAnimation

        Builder.ProcessedSizeConfig config ->
            let
                actualStart =
                    Maybe.withDefault (Size.fromTuple ( startValues.size.width, startValues.size.height )) config.start
            in
            Just <|
                buildPropertyAnimation
                    "size"
                    actualStart
                    config.end
                    config.duration
                    config.delay
                    config.easing
                    createSizeSteps
                    SizeAnimation



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
-- View Helpers


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
