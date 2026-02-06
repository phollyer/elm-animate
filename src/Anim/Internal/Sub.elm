module Anim.Internal.Sub exposing
    ( AnimBuilder
    , AnimEvent(..)
    , AnimMsg
    , AnimState
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
    , getRotate
    , getRotateRange
    , getScale
    , getScaleRange
    , getSize
    , getSizeRange
    , getTranslate
    , getTranslateRange
    , htmlAttributes
    , init
    , isAnimationRunning
    , isComplete
    , pauseElement
    , resetElement
    , restartElement
    , resumeElement
    , speed
    , stopElement
    , subscriptions
    , update
    )

import Anim.Extra.Easing exposing (Easing(..))
import Anim.Internal.AnimationCore as AnimationCore
import Anim.Internal.Builder as Builder
import Anim.Internal.Builders.Property as PropertyBuilder
import Anim.Internal.Easing as Easing
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Color as Color exposing (Color(..))
import Anim.Internal.Properties.FontColor as FontColor
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Properties.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Properties.Scale as Scale exposing (Scale)
import Anim.Internal.Properties.Size as Size exposing (Size)
import Anim.Internal.Properties.Translate as Translate exposing (Translate)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Events
import Dict exposing (Dict)
import Html
import Html.Attributes



-- BUILD


type alias ElementId =
    String


type Animation
    = TranslateAnimation Translate
    | RotateAnimation Rotate
    | ScaleAnimation Scale
    | BackgroundColorAnimation Color
    | FontColorAnimation Color
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
    , isPaused : Bool
    }


type AnimState
    = AnimState
        { elementAnimations : Dict ElementId ElementAnimation
        , isRunning : Bool
        , builder : AnimBuilder
        , pendingEvents : List AnimEvent
        }


{-| Initialize animation state with optional property initializers.

Pass an empty list for empty state, or property initializers to set initial values.

-}
init : List (AnimBuilder -> AnimBuilder) -> AnimState
init propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { elementAnimations = Dict.empty
                , isRunning = False
                , builder = Builder.init
                , pendingEvents = []
                }

        _ ->
            let
                -- Apply all property initializers to a fresh builder
                configuredBuilder =
                    List.foldl (\initializer b -> initializer b)
                        Builder.init
                        propertyInitializers

                processedData =
                    Builder.processAnimationData configuredBuilder

                -- Use default start values since we're just initializing
                startValues =
                    { translate = Translate.default |> Translate.toRecord
                    , rotate = Rotate.default |> Rotate.toRecord
                    , scale = Scale.default |> Scale.toRecord
                    , backgroundColor = BackgroundColor.default
                    , fontColor = FontColor.default
                    , opacity = 1.0
                    , size = Size.default |> Size.toRecord
                    }

                -- Create element states with all animations marked as complete (no running animations)
                elementStates =
                    Dict.map (createElementAnimState startValues) processedData.elements
                        |> Dict.map
                            (\_ elem ->
                                { elem
                                    | isComplete = True
                                    , properties =
                                        List.map (\p -> { p | isComplete = True }) elem.properties
                                }
                            )
            in
            AnimState
                { elementAnimations = elementStates
                , isRunning = False
                , builder =
                    configuredBuilder
                        |> Builder.markDirty
                        |> Builder.clearCurrentElement
                , pendingEvents = []
                }


type alias AnimBuilder =
    Builder.AnimBuilder


builder : AnimState -> AnimBuilder
builder ((AnimState state) as animState) =
    Dict.foldl (setInitialValues animState) state.builder state.elementAnimations


animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate (AnimState state) transform =
    let
        builder_ =
            AnimState state
                |> builder
                |> transform

        processedData =
            Builder.processAnimationData builder_

        -- Extract current values from any existing animations in the builder
        currentValues =
            extractCurrentValuesFromBuilder builder_

        startValues =
            { translate = Maybe.withDefault (Translate.default |> Translate.toRecord) currentValues.translate
            , rotate = Maybe.withDefault (Rotate.default |> Rotate.toRecord) currentValues.rotate
            , scale = Maybe.withDefault (Scale.default |> Scale.toRecord) currentValues.scale
            , backgroundColor = Maybe.withDefault BackgroundColor.default currentValues.color
            , fontColor = Maybe.withDefault FontColor.default currentValues.fontColor
            , opacity = Maybe.withDefault 1.0 currentValues.opacity
            , size = Maybe.withDefault (Size.default |> Size.toRecord) currentValues.size
            }

        elementStates =
            Dict.map (createElementAnimState startValues) processedData.elements

        -- Queue Started events for all animated elements
        startedEvents =
            Dict.keys elementStates
                |> List.map Started
    in
    AnimState
        { elementAnimations = elementStates
        , isRunning = not (Dict.isEmpty elementStates)
        , builder =
            builder_
                |> Builder.markDirty
                |> Builder.clearCurrentElement
        , pendingEvents = state.pendingEvents ++ startedEvents
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


type AnimMsg
    = AnimationFrame Float


{-| Animation lifecycle events.
-}
type AnimEvent
    = Started String
    | Completed String
    | Canceled String
    | Paused String
    | Resumed String
    | Restarted String



-- delta time in milliseconds


update : AnimMsg -> AnimState -> ( AnimState, List AnimEvent )
update msg (AnimState state) =
    case msg of
        AnimationFrame deltaMs ->
            let
                updatedElements =
                    Dict.map (updateElementAnimation deltaMs) state.elementAnimations

                stillRunning =
                    Dict.values updatedElements |> List.any (not << .isComplete)

                -- Detect newly completed elements
                completedEvents =
                    detectCompletedElements state.elementAnimations updatedElements

                -- Combine pending events with any new completion events
                allEvents =
                    state.pendingEvents ++ completedEvents

                newState =
                    AnimState
                        { elementAnimations = updatedElements
                        , isRunning = stillRunning
                        , builder = state.builder
                        , pendingEvents = []
                        }
            in
            ( newState, allEvents )


{-| Detect all elements that just completed (were running, now complete).
-}
detectCompletedElements : Dict String ElementAnimation -> Dict String ElementAnimation -> List AnimEvent
detectCompletedElements oldElements newElements =
    Dict.toList newElements
        |> List.filterMap
            (\( elementId, newElem ) ->
                Dict.get elementId oldElements
                    |> Maybe.andThen
                        (\oldElem ->
                            if not oldElem.isComplete && newElem.isComplete then
                                Just (Completed elementId)

                            else
                                Nothing
                        )
            )



-- SUBSCRIPTIONS


subscriptions : (AnimMsg -> msg) -> AnimState -> Sub msg
subscriptions toMsg (AnimState state) =
    if state.isRunning then
        Browser.Events.onAnimationFrameDelta AnimationFrame
            |> Sub.map toMsg

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

                -- Build transform string in fixed order: translate, rotate, scale
                transformString =
                    String.trim
                        (transformParts.translate
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
        TranslateAnimation pos ->
            Builder.ProcessedTranslateConfig
                { start = Just pos
                , end = pos
                , duration = 0
                , speed = 0
                , distance = 0
                , timing = Duration 0
                , easing = Linear
                , delay = 0
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
                }

        FontColorAnimation fontColor ->
            Builder.ProcessedFontColorConfig
                { start = Just fontColor
                , end = fontColor
                , duration = 0
                , speed = 0
                , distance = 0
                , timing = Duration 0
                , easing = Linear
                , delay = 0
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


getTranslate : String -> AnimState -> Maybe Translate
getTranslate =
    getPropertyValue "translate"
        (\anim ->
            case anim of
                TranslateAnimation pos ->
                    Just pos

                _ ->
                    Nothing
        )


getTranslateRange : String -> AnimState -> Maybe { start : Maybe Translate, end : Translate }
getTranslateRange =
    getPropertyRange
        (\prop ->
            case prop of
                Builder.ProcessedTranslateConfig config ->
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
setInitialValues animState elementId _ builderAcc =
    let
        funcList =
            [ mapCurrentValue getTranslate initTranslate
            , mapCurrentValue getSize initSize
            , mapCurrentValue getScale initScale
            , mapCurrentValue getRotate initRotate
            , mapCurrentValue getBackgroundColor initBackgroundColor
            , mapCurrentValue getOpacity initOpacity
            ]
    in
    List.foldl
        (\func acc -> func elementId animState acc)
        (Builder.for elementId builderAcc)
        funcList


mapCurrentValue : (String -> AnimState -> maybeProp) -> (AnimBuilder -> maybeProp -> AnimBuilder) -> String -> AnimState -> AnimBuilder -> AnimBuilder
mapCurrentValue getter setter elementId animState animBuilder =
    getter elementId animState
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
                        , isDirty = False
                        }
            in
            PropertyBuilder.upsert opacityConfig animBuilder

        Nothing ->
            animBuilder


initTranslate : AnimBuilder -> Maybe Translate -> AnimBuilder
initTranslate animBuilder maybePos =
    case maybePos of
        Just pos ->
            let
                translateConfig =
                    Builder.TranslateConfig
                        { start = Just pos
                        , end = pos
                        , duration = 0
                        , speed = 0
                        , distance = 0
                        , timing = Nothing
                        , easing = Nothing
                        , delay = Nothing
                        , isDirty = False
                        }
            in
            PropertyBuilder.upsert translateConfig animBuilder

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


createFontColorSteps : Color -> Color -> Int -> (Float -> Float) -> List Animation
createFontColorSteps start target frames easingFunction =
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
    List.map FontColorAnimation steps


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


createTranslateSteps : Translate.Translate -> Translate.Translate -> Int -> (Float -> Float) -> List Animation
createTranslateSteps startPos endPos frames easingFunction =
    let
        ( startX, startY ) =
            Translate.toTuple startPos

        ( endX, endY ) =
            Translate.toTuple endPos

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
    List.map (TranslateAnimation << Translate.fromTuple) steps


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
    { translate : Maybe { x : Float, y : Float, z : Float }
    , rotate : Maybe { x : Float, y : Float, z : Float }
    , scale : Maybe { x : Float, y : Float, z : Float }
    , color : Maybe Color
    , fontColor : Maybe Color
    , opacity : Maybe Float
    , size : Maybe { width : Float, height : Float }
    }


propertyValuesEmpty : PropertyValues
propertyValuesEmpty =
    { translate = Nothing
    , rotate = Nothing
    , scale = Nothing
    , color = Nothing
    , fontColor = Nothing
    , opacity = Nothing
    , size = Nothing
    }


type alias UnwrappedPropertyValues =
    { translate : { x : Float, y : Float, z : Float }
    , rotate : { x : Float, y : Float, z : Float }
    , scale : { x : Float, y : Float, z : Float }
    , backgroundColor : Color
    , fontColor : Color
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

        Builder.ProcessedFontColorConfig config ->
            if config.duration == 0 then
                { acc | fontColor = Just config.end }

            else
                acc

        Builder.ProcessedOpacityConfig config ->
            if config.duration == 0 then
                { acc | opacity = Just <| Opacity.toFloat config.end }

            else
                acc

        Builder.ProcessedTranslateConfig config ->
            if config.duration == 0 then
                { acc | translate = Just <| Translate.toRecord config.end }

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
    , isPaused = False
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
                    Easing.toFunction (toFloat duration_) easing_

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
        Builder.ProcessedTranslateConfig config ->
            let
                actualStart =
                    Maybe.withDefault (Translate.fromRecord startValues.translate) config.start
            in
            Just <|
                buildPropertyAnimation
                    "translate"
                    actualStart
                    config.end
                    config.duration
                    config.delay
                    config.easing
                    createTranslateSteps
                    TranslateAnimation

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
                    Maybe.withDefault startValues.backgroundColor config.start
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

        Builder.ProcessedFontColorConfig config ->
            let
                actualStart =
                    Maybe.withDefault startValues.fontColor config.start
            in
            Just <|
                buildPropertyAnimation
                    "fontColor"
                    actualStart
                    config.end
                    config.duration
                    config.delay
                    config.easing
                    createFontColorSteps
                    FontColorAnimation

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
    if elementState.isPaused then
        elementState

    else
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
            Just (Html.Attributes.style "background-color" (Color.toCssString colorValue))

        OpacityAnimation opacity ->
            Just (Html.Attributes.style "opacity" (String.fromFloat (Opacity.toFloat opacity)))

        _ ->
            Nothing


getLastStep : List Animation -> Animation
getLastStep steps =
    List.reverse steps
        |> List.head
        |> Maybe.withDefault (TranslateAnimation (Translate.fromTuple ( 0, 0 )))



-- ANIMATION CONTROL


{-| Stop animation by jumping to its end state.
-}
stopElement : String -> AnimState -> AnimState
stopElement elementId (AnimState state) =
    case Dict.get elementId state.elementAnimations of
        Nothing ->
            AnimState state

        Just elementAnim ->
            let
                wasRunning =
                    not elementAnim.isComplete && not elementAnim.isPaused

                updatedProperties =
                    List.map
                        (\prop ->
                            let
                                lastFrameIndex =
                                    max 0 (List.length prop.animationSteps - 1)
                            in
                            { prop
                                | elapsedMs = prop.totalDurationMs
                                , currentStepIndex = lastFrameIndex
                                , isComplete = True
                            }
                        )
                        elementAnim.properties

                updatedAnim =
                    { elementAnim | properties = updatedProperties, isComplete = True, isPaused = False }

                updatedDict =
                    Dict.insert elementId updatedAnim state.elementAnimations

                newPendingEvents =
                    if wasRunning then
                        state.pendingEvents ++ [ Canceled elementId ]

                    else
                        state.pendingEvents
            in
            AnimState { state | elementAnimations = updatedDict, pendingEvents = newPendingEvents }


{-| Reset animation by jumping to its start state.
-}
resetElement : String -> AnimState -> AnimState
resetElement elementId (AnimState state) =
    case Dict.get elementId state.elementAnimations of
        Nothing ->
            AnimState state

        Just elementAnim ->
            let
                wasRunning =
                    not elementAnim.isComplete && not elementAnim.isPaused

                updatedProperties =
                    List.map
                        (\prop ->
                            { prop
                                | elapsedMs = 0
                                , currentStepIndex = 0
                                , currentDelayFrame = 0
                                , isComplete = False
                            }
                        )
                        elementAnim.properties

                updatedAnim =
                    { elementAnim | properties = updatedProperties, isComplete = False, isPaused = False }

                updatedDict =
                    Dict.insert elementId updatedAnim state.elementAnimations

                newPendingEvents =
                    if wasRunning then
                        state.pendingEvents ++ [ Canceled elementId ]

                    else
                        state.pendingEvents
            in
            AnimState { state | elementAnimations = updatedDict, isRunning = False, pendingEvents = newPendingEvents }


{-| Restart animation from the beginning.
-}
restartElement : String -> AnimState -> AnimState
restartElement elementId (AnimState state) =
    case Dict.get elementId state.elementAnimations of
        Nothing ->
            AnimState state

        Just elementAnim ->
            let
                updatedProperties =
                    List.map
                        (\prop ->
                            { prop
                                | elapsedMs = 0
                                , currentStepIndex = 0
                                , currentDelayFrame = 0
                                , isComplete = False
                            }
                        )
                        elementAnim.properties

                updatedAnim =
                    { elementAnim | properties = updatedProperties, isComplete = False, isPaused = False }

                updatedDict =
                    Dict.insert elementId updatedAnim state.elementAnimations
            in
            AnimState { state | elementAnimations = updatedDict, isRunning = True, pendingEvents = state.pendingEvents ++ [ Restarted elementId ] }


{-| Pause animation for a specific element.
-}
pauseElement : String -> AnimState -> AnimState
pauseElement elementId (AnimState state) =
    case Dict.get elementId state.elementAnimations of
        Nothing ->
            AnimState state

        Just elementAnim ->
            let
                wasRunning =
                    not elementAnim.isComplete && not elementAnim.isPaused

                updatedAnimations =
                    Dict.update elementId
                        (Maybe.map (\ea -> { ea | isPaused = True }))
                        state.elementAnimations

                newPendingEvents =
                    if wasRunning then
                        state.pendingEvents ++ [ Paused elementId ]

                    else
                        state.pendingEvents
            in
            AnimState { state | elementAnimations = updatedAnimations, pendingEvents = newPendingEvents }


{-| Resume animation for a specific element.
-}
resumeElement : String -> AnimState -> AnimState
resumeElement elementId (AnimState state) =
    case Dict.get elementId state.elementAnimations of
        Nothing ->
            AnimState state

        Just elementAnim ->
            let
                wasPaused =
                    elementAnim.isPaused && not elementAnim.isComplete

                updatedAnimations =
                    Dict.update elementId
                        (Maybe.map (\ea -> { ea | isPaused = False }))
                        state.elementAnimations

                newPendingEvents =
                    if wasPaused then
                        state.pendingEvents ++ [ Resumed elementId ]

                    else
                        state.pendingEvents
            in
            AnimState { state | elementAnimations = updatedAnimations, isRunning = True, pendingEvents = newPendingEvents }
