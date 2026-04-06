module Anim.Internal.Engine.Animation.Sub exposing
    ( AnimBuilder
    , AnimEvent(..)
    , AnimMsg
    , AnimState
    , allComplete
    , animate
    , anyRunning
    , delay
    , duration
    , easing
    , getBackgroundColor
    , getBackgroundColorRange
    , getBuilder
    , getOpacity
    , getOpacityRange
    , getProgress
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
    , pause
    , reset
    , restart
    , resume
    , speed
    , stop
    , subscriptions
    , update
    )

import Anim.Extra.Easing exposing (Easing(..))
import Anim.Internal.Builder as Builder exposing (Iterations)
import Anim.Internal.Builder.BackgroundColor as BackgroundColor
import Anim.Internal.Builder.FontColor as FontColor
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Extra.Easing as Easing
import Anim.Internal.Property.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Anim.Internal.Property.Size as Size exposing (Size)
import Anim.Internal.Property.Translate as Translate exposing (Translate)
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
    , startValue : Animation
    , endValue : Animation
    , easingFunction : Float -> Float
    , delayMs : Float
    , isComplete : Bool
    , totalDurationMs : Float
    , elapsedMs : Float
    }


type alias ElementAnimation =
    { properties : List PropertyAnimation
    , isComplete : Bool
    , isPaused : Bool
    , transformOrder : List Builder.TransformOrder
    , iterationCount : Iterations
    , currentIteration : Int
    }


defaultTransformOrder : List Builder.TransformOrder
defaultTransformOrder =
    [ Builder.Translate, Builder.Rotate, Builder.Scale ]


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
                , builder = Builder.init []
                , pendingEvents = []
                }

        _ ->
            let
                -- Apply all property initializers to a fresh builder
                builder =
                    Builder.init propertyInitializers

                processedData =
                    Builder.process builder

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
                    Dict.map (createElementAnimState processedData.iterationCount defaultTransformOrder startValues) processedData.groups
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
                    builder
                        |> Builder.mergeEndStates
                        |> Builder.clearAnimData
                , pendingEvents = []
                }


type alias AnimBuilder =
    Builder.AnimBuilder


getBuilder : AnimState -> AnimBuilder
getBuilder ((AnimState state) as animState) =
    Dict.foldl (setInitialValues animState) state.builder state.elementAnimations


animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate (AnimState state) transform =
    let
        -- Skip setInitialValues (the builder function) to avoid adding ALL
        -- existing elements to the builder. Instead, rely on injectCurrentStates
        -- to provide baselines so property builders can resolve start values.
        -- This way, only elements targeted by the transform appear in processedData.
        builder_ =
            state.builder
                |> Builder.injectCurrentStates (extractCurrentStates state.elementAnimations)
                |> transform

        processedData =
            Builder.process builder_

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
            Dict.map (createElementAnimState processedData.iterationCount (Maybe.withDefault defaultTransformOrder processedData.globalTransformOrder) startValues) processedData.groups

        -- For targeted elements, preserve existing properties not covered
        -- by the new animation (e.g. Size set in init, when only Scale is animated).
        elementStatesWithPreserved =
            Dict.map
                (\elementId newElem ->
                    case Dict.get elementId state.elementAnimations of
                        Nothing ->
                            newElem

                        Just existingElem ->
                            let
                                newPropertyTypes =
                                    List.map .propertyType newElem.properties

                                preservedProperties =
                                    List.filter
                                        (\p -> not (List.member p.propertyType newPropertyTypes))
                                        existingElem.properties
                            in
                            { newElem | properties = newElem.properties ++ preservedProperties }
                )
                elementStates

        startedEvents =
            Dict.keys elementStatesWithPreserved
                |> List.map Started

        -- Merge: targeted elements get new animation, others keep running
        mergedAnimations =
            Dict.union elementStatesWithPreserved state.elementAnimations

        stillRunning =
            Dict.values mergedAnimations |> List.any (not << .isComplete)
    in
    AnimState
        { elementAnimations = mergedAnimations
        , isRunning = stillRunning
        , builder =
            builder_
                |> Builder.mergeEndStates
                |> Builder.clearAnimData
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
    | Ended String
    | Cancelled String Float
    | Paused String Float
    | Resumed String
    | Restarted String
    | Iteration String Int
    | Progress String Float



-- delta time in milliseconds


update : AnimMsg -> AnimState -> ( AnimState, List AnimEvent )
update msg (AnimState state) =
    case msg of
        AnimationFrame deltaMs ->
            let
                -- Update each element and collect events
                ( updatedElementsList, elementEvents ) =
                    Dict.toList state.elementAnimations
                        |> List.map
                            (\( elementId, elem ) ->
                                let
                                    ( newElem, events ) =
                                        updateElementWithEvents deltaMs elementId elem
                                in
                                ( ( elementId, newElem ), events )
                            )
                        |> List.unzip

                updatedElements =
                    Dict.fromList updatedElementsList

                allElementEvents =
                    List.concat elementEvents

                stillRunning =
                    Dict.values updatedElements |> List.any (not << .isComplete)

                -- Combine pending events with element events
                allEvents =
                    state.pendingEvents ++ allElementEvents

                newState =
                    AnimState
                        { elementAnimations = updatedElements
                        , isRunning = stillRunning
                        , builder = state.builder
                        , pendingEvents = []
                        }
            in
            ( newState, allEvents )


{-| Update an element and return any events (Iteration or Ended).
-}
updateElementWithEvents : Float -> String -> ElementAnimation -> ( ElementAnimation, List AnimEvent )
updateElementWithEvents deltaMs elementId elementState =
    if elementState.isPaused then
        ( elementState, [] )

    else
        let
            updatedProperties =
                List.map (updatePropertyAnimation deltaMs) elementState.properties

            allPropertiesComplete =
                List.all .isComplete updatedProperties
        in
        if allPropertiesComplete && not elementState.isComplete then
            -- Properties just finished - check if we need to iterate
            case elementState.iterationCount of
                Builder.Infinite ->
                    -- Reset for next iteration
                    let
                        nextIteration =
                            elementState.currentIteration + 1

                        resetProperties =
                            List.map resetPropertyAnimation updatedProperties
                    in
                    ( { elementState
                        | properties = resetProperties
                        , currentIteration = nextIteration
                        , isComplete = False
                      }
                    , [ Iteration elementId nextIteration ]
                    )

                Builder.Times totalIterations ->
                    if elementState.currentIteration < totalIterations then
                        -- More iterations to go
                        let
                            nextIteration =
                                elementState.currentIteration + 1

                            resetProperties =
                                List.map resetPropertyAnimation updatedProperties
                        in
                        ( { elementState
                            | properties = resetProperties
                            , currentIteration = nextIteration
                            , isComplete = False
                          }
                        , [ Iteration elementId nextIteration ]
                        )

                    else
                        -- All iterations done
                        ( { elementState
                            | properties = updatedProperties
                            , isComplete = True
                          }
                        , [ Ended elementId ]
                        )

                Builder.Once ->
                    -- Single iteration, just complete
                    ( { elementState
                        | properties = updatedProperties
                        , isComplete = True
                      }
                    , [ Ended elementId ]
                    )

        else
            -- Not all properties complete yet (or already complete)
            ( { elementState
                | properties = updatedProperties
              }
            , if elementState.isComplete then
                []

              else
                [ Progress elementId (elementProgress updatedProperties) ]
            )


{-| Reset a property animation to its initial state for a new iteration.
-}
resetPropertyAnimation : PropertyAnimation -> PropertyAnimation
resetPropertyAnimation prop =
    { prop
        | elapsedMs = 0
        , isComplete = False
    }


{-| Calculate overall element progress as the max progress across all properties.
Each property's progress accounts for its own delay and duration independently.
-}
elementProgress : List PropertyAnimation -> Float
elementProgress properties =
    properties
        |> List.map propertyProgress
        |> List.maximum
        |> Maybe.withDefault 0


propertyProgress : PropertyAnimation -> Float
propertyProgress prop =
    if prop.isComplete || prop.totalDurationMs <= 0 then
        1.0

    else
        let
            animationElapsedMs =
                max 0 (prop.elapsedMs - prop.delayMs)
        in
        if animationElapsedMs <= 0 then
            0.0

        else
            min 1.0 (animationElapsedMs / prop.totalDurationMs)



-- SUBSCRIPTIONS


subscriptions : (AnimMsg -> msg) -> AnimState -> Sub msg
subscriptions toMsg (AnimState state) =
    if state.isRunning then
        Browser.Events.onAnimationFrameDelta AnimationFrame
            |> Sub.map toMsg

    else
        Sub.none



-- KEY RESOLUTION


{-| Get an element animation by key. Direct Dict lookup.
-}
getAnimation : String -> Dict String ElementAnimation -> Maybe ElementAnimation
getAnimation =
    Dict.get



-- VIEW


htmlAttributes : String -> AnimState -> List (Html.Attribute msg)
htmlAttributes animGroup (AnimState state) =
    case getAnimation animGroup state.elementAnimations of
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

                -- Build transform string using stored transform order
                transformString =
                    elementAnimation.transformOrder
                        |> List.map (transformOrderToPart transformParts)
                        |> List.filter (not << String.isEmpty)
                        |> String.join " "

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


transformOrderToPart : Builder.TransformParts -> Builder.TransformOrder -> String
transformOrderToPart parts order =
    case order of
        Builder.Translate ->
            parts.translate

        Builder.Rotate ->
            parts.rotate

        Builder.Scale ->
            parts.scale


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


anyRunning : AnimState -> Maybe Bool
anyRunning (AnimState state) =
    case Dict.values state.elementAnimations of
        [] ->
            Nothing

        values ->
            List.any (\el -> not el.isComplete) values
                |> Just


isAnimationRunning : String -> AnimState -> Maybe Bool
isAnimationRunning rawKey (AnimState state) =
    getAnimation rawKey state.elementAnimations
        |> Maybe.map
            (\elementAnimation ->
                not elementAnimation.isComplete && List.any (not << .isComplete) elementAnimation.properties
            )


isComplete : String -> AnimState -> Maybe Bool
isComplete rawKey (AnimState state) =
    getAnimation rawKey state.elementAnimations
        |> Maybe.map .isComplete


getProgress : String -> AnimState -> Maybe Float
getProgress rawKey (AnimState state) =
    getAnimation rawKey state.elementAnimations
        |> Maybe.map (\elem -> elementProgress elem.properties)


getPropertyRange : (Builder.ProcessedPropertyConfig -> Maybe a) -> String -> AnimState -> Maybe a
getPropertyRange matcher animGroup (AnimState state) =
    let
        elements =
            Builder.process state.builder
                |> .groups
    in
    Dict.get animGroup elements
        |> Maybe.andThen (.properties >> List.filterMap matcher >> List.head)


getPropertyValue : String -> (Animation -> Maybe a) -> String -> AnimState -> Maybe a
getPropertyValue propertyType extractor rawKey (AnimState state) =
    getAnimation rawKey state.elementAnimations
        |> Maybe.andThen (.properties >> List.filterMap (matchProperty propertyType extractor) >> List.head)


matchProperty : String -> (Animation -> Maybe a) -> PropertyAnimation -> Maybe a
matchProperty propertyType extractor propertyState =
    if propertyState.propertyType == propertyType then
        getCurrentValue propertyState |> extractor

    else
        Nothing


getCurrentValue : PropertyAnimation -> Animation
getCurrentValue propertyState =
    let
        animationElapsedMs =
            max 0 (propertyState.elapsedMs - propertyState.delayMs)

        progress =
            if propertyState.isComplete || propertyState.totalDurationMs <= 0 then
                1.0

            else if animationElapsedMs <= 0 then
                0.0

            else
                min 1.0 (animationElapsedMs / propertyState.totalDurationMs)

        easedProgress =
            propertyState.easingFunction progress
    in
    interpolateAnimation easedProgress propertyState.startValue propertyState.endValue


interpolateAnimation : Float -> Animation -> Animation -> Animation
interpolateAnimation t startAnim endAnim =
    case ( startAnim, endAnim ) of
        ( TranslateAnimation startVal, TranslateAnimation endVal ) ->
            TranslateAnimation (interpolateTranslate t startVal endVal)

        ( RotateAnimation startVal, RotateAnimation endVal ) ->
            RotateAnimation (interpolateRotate t startVal endVal)

        ( ScaleAnimation startVal, ScaleAnimation endVal ) ->
            ScaleAnimation (interpolateScale t startVal endVal)

        ( BackgroundColorAnimation startVal, BackgroundColorAnimation endVal ) ->
            BackgroundColorAnimation (Color.interpolate t startVal endVal)

        ( FontColorAnimation startVal, FontColorAnimation endVal ) ->
            FontColorAnimation (Color.interpolate t startVal endVal)

        ( OpacityAnimation startVal, OpacityAnimation endVal ) ->
            OpacityAnimation (interpolateOpacity t startVal endVal)

        ( SizeAnimation startVal, SizeAnimation endVal ) ->
            SizeAnimation (interpolateSize t startVal endVal)

        _ ->
            endAnim


interpolateFloat : Float -> Float -> Float -> Float
interpolateFloat t start end =
    start + (end - start) * t


interpolateTranslate : Float -> Translate -> Translate -> Translate
interpolateTranslate t start end =
    let
        ( sx, sy, sz ) =
            Translate.toTriple start

        ( ex, ey, ez ) =
            Translate.toTriple end
    in
    Translate.fromTriple ( interpolateFloat t sx ex, interpolateFloat t sy ey, interpolateFloat t sz ez )


interpolateRotate : Float -> Rotate -> Rotate -> Rotate
interpolateRotate t start end =
    let
        ( sx, sy, sz ) =
            Rotate.toTriple start

        ( ex, ey, ez ) =
            Rotate.toTriple end
    in
    Rotate.fromTriple ( interpolateFloat t sx ex, interpolateFloat t sy ey, interpolateFloat t sz ez )


interpolateScale : Float -> Scale -> Scale -> Scale
interpolateScale t start end =
    let
        ( sx, sy, sz ) =
            Scale.toTriple start

        ( ex, ey, ez ) =
            Scale.toTriple end
    in
    Scale.fromTriple ( interpolateFloat t sx ex, interpolateFloat t sy ey, interpolateFloat t sz ez )


interpolateOpacity : Float -> Opacity -> Opacity -> Opacity
interpolateOpacity t start end =
    interpolateFloat t (Opacity.toFloat start) (Opacity.toFloat end)
        |> Opacity.fromFloat


interpolateSize : Float -> Size -> Size -> Size
interpolateSize t start end =
    let
        ( sw, sh ) =
            Size.toTuple start

        ( ew, eh ) =
            Size.toTuple end
    in
    Size.fromTuple ( interpolateFloat t sw ew, interpolateFloat t sh eh )


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


extractCurrentStates : Dict ElementId ElementAnimation -> Dict ElementId { currentStates : Builder.PropertyEndStates }
extractCurrentStates elementAnimations =
    Dict.map (\_ elemAnim -> { currentStates = extractElementCurrentStates elemAnim }) elementAnimations


extractElementCurrentStates : ElementAnimation -> Builder.PropertyEndStates
extractElementCurrentStates elemAnim =
    List.foldl extractPropertyCurrentState
        { translate = Nothing
        , rotate = Nothing
        , scale = Nothing
        , backgroundColor = Nothing
        , fontColor = Nothing
        , opacity = Nothing
        , size = Nothing
        }
        elemAnim.properties


extractPropertyCurrentState : PropertyAnimation -> Builder.PropertyEndStates -> Builder.PropertyEndStates
extractPropertyCurrentState propAnim states =
    case getCurrentValue propAnim of
        TranslateAnimation val ->
            { states | translate = Just val }

        RotateAnimation val ->
            { states | rotate = Just val }

        ScaleAnimation val ->
            { states | scale = Just val }

        BackgroundColorAnimation val ->
            { states | backgroundColor = Just val }

        FontColorAnimation val ->
            { states | fontColor = Just val }

        OpacityAnimation val ->
            { states | opacity = Just val }

        SizeAnimation val ->
            { states | size = Just val }


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
                        , distance = 0
                        , timing = Nothing
                        , easing = Nothing
                        , delay = Nothing
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
                        , distance = 0
                        , timing = Nothing
                        , easing = Nothing
                        , delay = Nothing
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
                        , distance = 0
                        , timing = Nothing
                        , easing = Nothing
                        , delay = Nothing
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
                        , distance = 0
                        , timing = Nothing
                        , easing = Nothing
                        , delay = Nothing
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
                        , distance = 0
                        , timing = Nothing
                        , easing = Nothing
                        , delay = Nothing
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
                        , distance = 0
                        , timing = Nothing
                        , easing = Nothing
                        , delay = Nothing
                        }
            in
            PropertyBuilder.upsert sizeConfig animBuilder

        Nothing ->
            animBuilder



-- Step Creators
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
    Builder.process
        >> .groups
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


createElementAnimState : Builder.Iterations -> List Builder.TransformOrder -> UnwrappedPropertyValues -> String -> Builder.ProcessedAnimGroupConfig -> ElementAnimation
createElementAnimState iterationCount order startValues _ elementConfig =
    let
        properties =
            List.filterMap (createPropertyAnimState startValues) elementConfig.properties
    in
    { properties = properties
    , isComplete = False
    , isPaused = False
    , transformOrder = order
    , iterationCount = iterationCount
    , currentIteration = 1
    }


createPropertyAnimState : UnwrappedPropertyValues -> Builder.ProcessedPropertyConfig -> Maybe PropertyAnimation
createPropertyAnimState startValues property =
    let
        buildPropertyAnimation : String -> Animation -> Animation -> Int -> Int -> Easing -> PropertyAnimation
        buildPropertyAnimation propertyType start end duration_ delay_ easing_ =
            { propertyType = propertyType
            , startValue = start
            , endValue = end
            , easingFunction = Easing.toFunction (toFloat duration_) easing_
            , delayMs = toFloat delay_
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
                    (TranslateAnimation actualStart)
                    (TranslateAnimation config.end)
                    config.duration
                    config.delay
                    config.easing

        Builder.ProcessedRotateConfig config ->
            let
                actualStart =
                    Maybe.withDefault (Rotate.fromRecord startValues.rotate) config.start
            in
            Just <|
                buildPropertyAnimation
                    "rotate"
                    (RotateAnimation actualStart)
                    (RotateAnimation config.end)
                    config.duration
                    config.delay
                    config.easing

        Builder.ProcessedScaleConfig config ->
            let
                actualStart =
                    Maybe.withDefault (Scale.fromRecord startValues.scale) config.start
            in
            Just <|
                buildPropertyAnimation
                    "scale"
                    (ScaleAnimation actualStart)
                    (ScaleAnimation config.end)
                    config.duration
                    config.delay
                    config.easing

        Builder.ProcessedBackgroundColorConfig config ->
            let
                actualStart =
                    Maybe.withDefault startValues.backgroundColor config.start
            in
            Just <|
                buildPropertyAnimation
                    "backgroundColor"
                    (BackgroundColorAnimation actualStart)
                    (BackgroundColorAnimation config.end)
                    config.duration
                    config.delay
                    config.easing

        Builder.ProcessedFontColorConfig config ->
            let
                actualStart =
                    Maybe.withDefault startValues.fontColor config.start
            in
            Just <|
                buildPropertyAnimation
                    "fontColor"
                    (FontColorAnimation actualStart)
                    (FontColorAnimation config.end)
                    config.duration
                    config.delay
                    config.easing

        Builder.ProcessedOpacityConfig config ->
            let
                actualStart =
                    Maybe.withDefault (Opacity.fromFloat startValues.opacity) config.start
            in
            Just <|
                buildPropertyAnimation
                    "opacity"
                    (OpacityAnimation actualStart)
                    (OpacityAnimation config.end)
                    config.duration
                    config.delay
                    config.easing

        Builder.ProcessedSizeConfig config ->
            let
                actualStart =
                    Maybe.withDefault (Size.fromTuple ( startValues.size.width, startValues.size.height )) config.start
            in
            Just <|
                buildPropertyAnimation
                    "size"
                    (SizeAnimation actualStart)
                    (SizeAnimation config.end)
                    config.duration
                    config.delay
                    config.easing


updatePropertyAnimation : Float -> PropertyAnimation -> PropertyAnimation
updatePropertyAnimation deltaMs propertyState =
    if propertyState.isComplete then
        propertyState

    else
        let
            newElapsedMs =
                propertyState.elapsedMs + deltaMs

            animationElapsedMs =
                max 0 (newElapsedMs - propertyState.delayMs)

            isComplete_ =
                animationElapsedMs >= propertyState.totalDurationMs
        in
        { propertyState
            | elapsedMs = newElapsedMs
            , isComplete = isComplete_
        }



-- View Helpers
-- View Helpers


getSizeStyleAttributes : PropertyAnimation -> List (Html.Attribute msg)
getSizeStyleAttributes propertyState =
    let
        currentValue =
            getCurrentValue propertyState
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
            getCurrentValue propertyState
    in
    case currentValue of
        BackgroundColorAnimation colorValue ->
            Just (Html.Attributes.style "background-color" (Color.toCssString colorValue))

        OpacityAnimation opacity ->
            Just (Html.Attributes.style "opacity" (String.fromFloat (Opacity.toFloat opacity)))

        _ ->
            Nothing



-- ANIMATION CONTROL


{-| Stop animation by jumping to its end state.
-}
stop : String -> AnimState -> AnimState
stop animGroup (AnimState state) =
    case Dict.get animGroup state.elementAnimations of
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
                                | elapsedMs = prop.totalDurationMs + prop.delayMs
                                , isComplete = True
                            }
                        )
                        elementAnim.properties

                updatedAnim =
                    { elementAnim | properties = updatedProperties, isComplete = True, isPaused = False }

                updatedDict =
                    Dict.insert animGroup updatedAnim state.elementAnimations

                newPendingEvents =
                    if wasRunning then
                        state.pendingEvents ++ [ Cancelled animGroup (elementProgress elementAnim.properties) ]

                    else
                        state.pendingEvents
            in
            AnimState { state | elementAnimations = updatedDict, pendingEvents = newPendingEvents }


{-| Reset animation by jumping to its start state.
-}
reset : String -> AnimState -> AnimState
reset animGroup (AnimState state) =
    case Dict.get animGroup state.elementAnimations of
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
                                , isComplete = False
                            }
                        )
                        elementAnim.properties

                updatedAnim =
                    { elementAnim | properties = updatedProperties, isComplete = False, isPaused = False }

                updatedDict =
                    Dict.insert animGroup updatedAnim state.elementAnimations

                newPendingEvents =
                    if wasRunning then
                        state.pendingEvents ++ [ Cancelled animGroup (elementProgress elementAnim.properties) ]

                    else
                        state.pendingEvents
            in
            AnimState { state | elementAnimations = updatedDict, isRunning = False, pendingEvents = newPendingEvents }


{-| Restart animation from the beginning.
-}
restart : String -> AnimState -> AnimState
restart animGroup (AnimState state) =
    case Dict.get animGroup state.elementAnimations of
        Nothing ->
            AnimState state

        Just elementAnim ->
            let
                updatedProperties =
                    List.map
                        (\prop ->
                            { prop
                                | elapsedMs = 0
                                , isComplete = False
                            }
                        )
                        elementAnim.properties

                updatedAnim =
                    { elementAnim | properties = updatedProperties, isComplete = False, isPaused = False }

                updatedDict =
                    Dict.insert animGroup updatedAnim state.elementAnimations
            in
            AnimState { state | elementAnimations = updatedDict, isRunning = True, pendingEvents = state.pendingEvents ++ [ Restarted animGroup ] }


{-| Pause animation for a specific element.
-}
pause : String -> AnimState -> AnimState
pause animGroup (AnimState state) =
    case Dict.get animGroup state.elementAnimations of
        Nothing ->
            AnimState state

        Just elementAnim ->
            let
                wasRunning =
                    not elementAnim.isComplete && not elementAnim.isPaused

                updatedAnimations =
                    Dict.update animGroup
                        (Maybe.map (\ea -> { ea | isPaused = True }))
                        state.elementAnimations

                newPendingEvents =
                    if wasRunning then
                        state.pendingEvents ++ [ Paused animGroup (elementProgress elementAnim.properties) ]

                    else
                        state.pendingEvents
            in
            AnimState { state | elementAnimations = updatedAnimations, pendingEvents = newPendingEvents }


{-| Resume animation for a specific element.
-}
resume : String -> AnimState -> AnimState
resume animGroup (AnimState state) =
    case Dict.get animGroup state.elementAnimations of
        Nothing ->
            AnimState state

        Just elementAnim ->
            let
                wasPaused =
                    elementAnim.isPaused && not elementAnim.isComplete

                updatedAnimations =
                    Dict.update animGroup
                        (Maybe.map (\ea -> { ea | isPaused = False }))
                        state.elementAnimations

                newPendingEvents =
                    if wasPaused then
                        state.pendingEvents ++ [ Resumed animGroup ]

                    else
                        state.pendingEvents
            in
            AnimState { state | elementAnimations = updatedAnimations, isRunning = True, pendingEvents = newPendingEvents }
