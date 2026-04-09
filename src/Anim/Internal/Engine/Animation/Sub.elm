module Anim.Internal.Engine.Animation.Sub exposing
    ( AnimBuilder
    , AnimEvent(..)
    , AnimMsg
    , AnimState
    , ControlEvent(..)
    , TickEvent(..)
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
import Anim.Extra.TransformOrder as TransformOrder exposing (TransformOrder)
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.BackgroundColor as BackgroundColor
import Anim.Internal.Builder.FontColor as FontColor
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Engine.Animation.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Animation.Sub.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Animation.Sub.Animation exposing (Animation(..), PropertyAnimation)
import Anim.Internal.Engine.Animation.Sub.Animations as Animations
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Extra.Easing as Easing
import Anim.Internal.Property.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Anim.Internal.Property.Size as Size exposing (Size)
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Events
import Html
import Html.Attributes



-- BUILD


type AnimState
    = AnimState
        { builder : AnimBuilder
        , isRunning : Bool
        , pendingControlEvents : List ControlEvent
        }
        (AnimGroups AnimGroup)


{-| Initialize animation state with optional property initializers.

Pass an empty list for empty state, or property initializers to set initial values.

-}
init : List (AnimBuilder -> AnimBuilder) -> AnimState
init propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { builder = Builder.init []
                , isRunning = False
                , pendingControlEvents = []
                }
                AnimGroups.init

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
                    AnimGroups.map (createElementAnimState processedData.iterationCount TransformOrder.default startValues) processedData.groups
                        |> AnimGroups.map
                            (\_ animGroup ->
                                let
                                    properties =
                                        AnimGroup.getAnimations animGroup
                                            |> Animations.map (\_ -> setAnimatedPropertyComplete True)
                                in
                                animGroup
                                    |> AnimGroup.setIsComplete True
                                    |> AnimGroup.setAnimations properties
                            )
            in
            AnimState
                { builder =
                    builder
                        |> Builder.mergeEndStates
                        |> Builder.clearAnimData
                , isRunning = False
                , pendingControlEvents = []
                }
                elementStates


type alias AnimBuilder =
    Builder.AnimBuilder


type alias AnimGroupName =
    String


getBuilder : AnimState -> AnimBuilder
getBuilder ((AnimState state animGroups) as animState) =
    AnimGroups.foldl (setInitialValues animState) state.builder animGroups


animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate (AnimState state animGroups) transform =
    let
        builder_ =
            state.builder
                |> Builder.injectCurrentStates (extractCurrentStates animGroups)
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
            AnimGroups.map (createElementAnimState processedData.iterationCount (Maybe.withDefault TransformOrder.default processedData.globalTransformOrder) startValues) processedData.groups

        -- For targeted elements, preserve existing properties not covered
        -- by the new animation (e.g. Size set in init, when only Scale is animated).
        elementStatesWithPreserved =
            AnimGroups.map
                (\animGroupName newAnimGroup ->
                    case AnimGroups.get animGroupName animGroups of
                        Nothing ->
                            newAnimGroup

                        Just animGroup ->
                            newAnimGroup
                                |> AnimGroup.addAnimation (AnimGroup.getAnimations animGroup)
                )
                elementStates

        startedEvents =
            AnimGroups.names elementStatesWithPreserved
                |> List.map Started

        -- Merge: targeted elements get new animation, others keep running
        mergedAnimations =
            AnimGroups.union elementStatesWithPreserved animGroups

        stillRunning =
            AnimGroups.values mergedAnimations |> List.any (not << .isComplete)
    in
    AnimState
        { isRunning = stillRunning
        , builder =
            builder_
                |> Builder.mergeEndStates
                |> Builder.clearAnimData
        , pendingControlEvents = state.pendingControlEvents ++ startedEvents
        }
        mergedAnimations


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
    = Tick TickEvent
    | Control ControlEvent


{-| Events generated naturally by animation frame ticks.
-}
type TickEvent
    = Progress String Float
    | Ended String
    | Iteration String Int


{-| Events generated by control function calls (animate, stop, pause, etc.).
-}
type ControlEvent
    = Started String
    | Cancelled String Float
    | Paused String Float
    | Resumed String
    | Restarted String



-- delta time in milliseconds


update : AnimMsg -> AnimState -> ( AnimState, List AnimEvent )
update msg (AnimState state animGroups) =
    case msg of
        AnimationFrame deltaMs ->
            let
                -- Update each element and collect events
                ( updatedElementsList, elementEvents ) =
                    AnimGroups.toList animGroups
                        |> List.map
                            (\( animGroupName, elem ) ->
                                let
                                    ( newElem, events ) =
                                        updateElementWithEvents deltaMs animGroupName elem
                                in
                                ( ( animGroupName, newElem ), events )
                            )
                        |> List.unzip

                updatedElements =
                    AnimGroups.fromList updatedElementsList

                allElementEvents =
                    List.concat elementEvents

                stillRunning =
                    AnimGroups.values updatedElements |> List.any (not << .isComplete)

                -- Combine control events with tick events
                allEvents =
                    List.map Control state.pendingControlEvents
                        ++ List.map Tick allElementEvents

                newState =
                    AnimState
                        { isRunning = stillRunning
                        , builder = state.builder
                        , pendingControlEvents = []
                        }
                        updatedElements
            in
            ( newState, allEvents )


{-| Update an element and return any events (Iteration or Ended).
-}
updateElementWithEvents : Float -> String -> AnimGroup -> ( AnimGroup, List TickEvent )
updateElementWithEvents deltaMs animGroupName animGroup =
    if animGroup.isPaused then
        ( animGroup, [] )

    else
        let
            updatedAnimations =
                Animations.map (\_ -> updateAnimatedProperty deltaMs) animGroup.animations

            allPropertiesComplete =
                Animations.list updatedAnimations
                    |> List.all isAnimatedPropertyComplete
        in
        if allPropertiesComplete && not animGroup.isComplete then
            -- Properties just finished - check if we need to iterate
            case animGroup.iterationCount of
                Builder.Infinite ->
                    -- Reset for next iteration
                    let
                        nextIteration =
                            animGroup.currentIteration + 1

                        resetProperties =
                            Animations.map (\_ -> resetAnimatedProperty) updatedAnimations
                    in
                    ( { animGroup
                        | animations = resetProperties
                        , currentIteration = nextIteration
                        , isComplete = False
                      }
                    , [ Iteration animGroupName nextIteration ]
                    )

                Builder.Times totalIterations ->
                    if animGroup.currentIteration < totalIterations then
                        -- More iterations to go
                        let
                            nextIteration =
                                animGroup.currentIteration + 1

                            resetProperties =
                                Animations.map (\_ -> resetAnimatedProperty) updatedAnimations
                        in
                        ( { animGroup
                            | animations = resetProperties
                            , currentIteration = nextIteration
                            , isComplete = False
                          }
                        , [ Iteration animGroupName nextIteration ]
                        )

                    else
                        -- All iterations done
                        ( { animGroup
                            | animations = updatedAnimations
                            , isComplete = True
                          }
                        , [ Ended animGroupName ]
                        )

                Builder.Once ->
                    -- Single iteration, just complete
                    ( { animGroup
                        | animations = updatedAnimations
                        , isComplete = True
                      }
                    , [ Ended animGroupName ]
                    )

        else
            let
                updatedAnimGroup =
                    { animGroup | animations = updatedAnimations }
            in
            -- Not all properties complete yet (or already complete)
            ( updatedAnimGroup
            , if updatedAnimGroup.isComplete then
                []

              else
                [ Progress animGroupName (overallProgress updatedAnimGroup) ]
            )


{-| Reset an animated property to its initial state for a new iteration.
-}
resetAnimatedProperty : Animation -> Animation
resetAnimatedProperty prop =
    let
        rewind anim =
            { anim | elapsedMs = 0, isComplete = False }
    in
    case prop of
        Translate a ->
            Translate (rewind a)

        Rotate a ->
            Rotate (rewind a)

        Scale a ->
            Scale (rewind a)

        BackgroundColor a ->
            BackgroundColor (rewind a)

        FontColor a ->
            FontColor (rewind a)

        Opacity a ->
            Opacity (rewind a)

        Size a ->
            Size (rewind a)


{-| Calculate overall element progress as the max progress across all properties.
Each property's progress accounts for its own delay and duration independently.
-}
overallProgress : AnimGroup -> Float
overallProgress { animations } =
    Animations.list animations
        |> List.map animatedPropertyProgress
        |> List.maximum
        |> Maybe.withDefault 0


animatedPropertyProgress : Animation -> Float
animatedPropertyProgress prop =
    case prop of
        Translate a ->
            propertyAnimationProgress a

        Rotate a ->
            propertyAnimationProgress a

        Scale a ->
            propertyAnimationProgress a

        BackgroundColor a ->
            propertyAnimationProgress a

        FontColor a ->
            propertyAnimationProgress a

        Opacity a ->
            propertyAnimationProgress a

        Size a ->
            propertyAnimationProgress a


propertyAnimationProgress : PropertyAnimation a -> Float
propertyAnimationProgress anim =
    if anim.isComplete || anim.totalDurationMs <= 0 then
        1.0

    else
        let
            animationElapsedMs =
                max 0 (anim.elapsedMs - anim.delayMs)
        in
        if animationElapsedMs <= 0 then
            0.0

        else
            min 1.0 (animationElapsedMs / anim.totalDurationMs)



-- SUBSCRIPTIONS


subscriptions : (AnimMsg -> msg) -> AnimState -> Sub msg
subscriptions toMsg (AnimState state _) =
    if state.isRunning then
        Browser.Events.onAnimationFrameDelta AnimationFrame
            |> Sub.map toMsg

    else
        Sub.none



-- VIEW


htmlAttributes : String -> AnimState -> List (Html.Attribute msg)
htmlAttributes animGroup (AnimState _ animGroups) =
    case AnimGroups.get animGroup animGroups of
        Nothing ->
            []

        Just elementAnimation ->
            let
                properties =
                    Animations.list elementAnimation.animations

                -- Extract transforms directly from animated properties
                transformParts =
                    List.foldl collectCurrentTransform Builder.emptyTransformParts properties

                -- Build transform string using stored transform order
                transformString =
                    elementAnimation.transformOrder
                        |> List.map (transformOrderToPart transformParts)
                        |> List.filter (not << String.isEmpty)
                        |> String.join " "

                sizeStyles =
                    List.concatMap getSizeStyleAttributes properties

                nonTransformStyles =
                    List.filterMap getNonTransformStyleAttribute properties

                transformStyle =
                    if String.isEmpty transformString then
                        []

                    else
                        [ Html.Attributes.style "transform" transformString ]
            in
            transformStyle ++ sizeStyles ++ nonTransformStyles


collectCurrentTransform : Animation -> Builder.TransformParts -> Builder.TransformParts
collectCurrentTransform prop acc =
    case prop of
        Translate anim ->
            { acc | translate = Translate.toCssString (computeCurrentValue anim interpolateTranslate) }

        Rotate anim ->
            { acc | rotate = Rotate.toCssString (computeCurrentValue anim interpolateRotate) }

        Scale anim ->
            { acc | scale = Scale.toCssString (computeCurrentValue anim interpolateScale) }

        _ ->
            acc


transformOrderToPart : Builder.TransformParts -> TransformOrder -> String
transformOrderToPart parts order =
    case order of
        TransformOrder.Translate ->
            parts.translate

        TransformOrder.Rotate ->
            parts.rotate

        TransformOrder.Scale ->
            parts.scale



-- Querying


allComplete : AnimState -> Maybe Bool
allComplete (AnimState _ animGroups) =
    if AnimGroups.isEmpty animGroups then
        Nothing

    else
        animGroups
            |> AnimGroups.values
            |> List.all .isComplete
            |> Just


anyRunning : AnimState -> Maybe Bool
anyRunning (AnimState _ animGroups) =
    case AnimGroups.values animGroups of
        [] ->
            Nothing

        values ->
            List.any (\el -> not el.isComplete) values
                |> Just


isAnimationRunning : String -> AnimState -> Maybe Bool
isAnimationRunning rawKey (AnimState _ animGroups) =
    AnimGroups.get rawKey animGroups
        |> Maybe.map
            (\animGroup ->
                not animGroup.isComplete
                    && (Animations.list animGroup.animations
                            |> List.any (not << isAnimatedPropertyComplete)
                       )
            )


isComplete : String -> AnimState -> Maybe Bool
isComplete rawKey (AnimState _ animGroups) =
    AnimGroups.get rawKey animGroups
        |> Maybe.map .isComplete


getProgress : String -> AnimState -> Maybe Float
getProgress rawKey (AnimState _ animGroups) =
    AnimGroups.get rawKey animGroups
        |> Maybe.map overallProgress


getPropertyRange : (Builder.ProcessedPropertyConfig -> Maybe a) -> String -> AnimState -> Maybe a
getPropertyRange matcher animGroup (AnimState state _) =
    let
        elements =
            Builder.process state.builder
                |> .groups
    in
    AnimGroups.get animGroup elements
        |> Maybe.andThen (.properties >> List.filterMap matcher >> List.head)


getPropertyValue : String -> (Animation -> Maybe a) -> String -> AnimState -> Maybe a
getPropertyValue propertyKey valueExtractor rawKey (AnimState _ animGroups) =
    AnimGroups.get rawKey animGroups
        |> Maybe.andThen (Animations.get propertyKey << .animations)
        |> Maybe.andThen valueExtractor


computeCurrentValue : PropertyAnimation a -> (Float -> a -> a -> a) -> a
computeCurrentValue anim interpolate =
    let
        animationElapsedMs =
            max 0 (anim.elapsedMs - anim.delayMs)

        progress =
            if anim.isComplete || anim.totalDurationMs <= 0 then
                1.0

            else if animationElapsedMs <= 0 then
                0.0

            else
                min 1.0 (animationElapsedMs / anim.totalDurationMs)

        easedProgress =
            anim.easingFunction progress
    in
    interpolate easedProgress anim.startValue anim.endValue


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
        (\prop ->
            case prop of
                BackgroundColor anim ->
                    Just (computeCurrentValue anim Color.interpolate)

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
        (\prop ->
            case prop of
                Opacity anim ->
                    Just (computeCurrentValue anim interpolateOpacity)

                _ ->
                    Nothing
        )


getTranslate : String -> AnimState -> Maybe Translate
getTranslate =
    getPropertyValue "translate"
        (\prop ->
            case prop of
                Translate anim ->
                    Just (computeCurrentValue anim interpolateTranslate)

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
        (\prop ->
            case prop of
                Rotate anim ->
                    Just (computeCurrentValue anim interpolateRotate)

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
        (\prop ->
            case prop of
                Scale anim ->
                    Just (computeCurrentValue anim interpolateScale)

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
        (\prop ->
            case prop of
                Size anim ->
                    Just (computeCurrentValue anim interpolateSize)

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


setInitialValues : AnimState -> String -> AnimGroup -> AnimBuilder -> AnimBuilder
setInitialValues animState animGroupName _ builderAcc =
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
        (\func acc -> func animGroupName animState acc)
        (Builder.for animGroupName builderAcc)
        funcList


extractCurrentStates : AnimGroups AnimGroup -> AnimGroups { propertySnapshot : Builder.PropertyEndStates }
extractCurrentStates elementAnimations =
    AnimGroups.map (\_ elemAnim -> { propertySnapshot = extractElementCurrentStates elemAnim }) elementAnimations


extractElementCurrentStates : AnimGroup -> Builder.PropertyEndStates
extractElementCurrentStates animGroup =
    Animations.foldl (\_ -> extractPropertyCurrentState)
        { translate = Nothing
        , rotate = Nothing
        , scale = Nothing
        , backgroundColor = Nothing
        , fontColor = Nothing
        , opacity = Nothing
        , size = Nothing
        }
        animGroup.animations


extractPropertyCurrentState : Animation -> Builder.PropertyEndStates -> Builder.PropertyEndStates
extractPropertyCurrentState prop states =
    case prop of
        Translate anim ->
            { states | translate = Just (computeCurrentValue anim interpolateTranslate) }

        Rotate anim ->
            { states | rotate = Just (computeCurrentValue anim interpolateRotate) }

        Scale anim ->
            { states | scale = Just (computeCurrentValue anim interpolateScale) }

        BackgroundColor anim ->
            { states | backgroundColor = Just (computeCurrentValue anim Color.interpolate) }

        FontColor anim ->
            { states | fontColor = Just (computeCurrentValue anim Color.interpolate) }

        Opacity anim ->
            { states | opacity = Just (computeCurrentValue anim interpolateOpacity) }

        Size anim ->
            { states | size = Just (computeCurrentValue anim interpolateSize) }


mapCurrentValue : (String -> AnimState -> maybeProp) -> (AnimBuilder -> maybeProp -> AnimBuilder) -> String -> AnimState -> AnimBuilder -> AnimBuilder
mapCurrentValue getter setter animGroupName animState animBuilder =
    getter animGroupName animState
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
        >> AnimGroups.values
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


createElementAnimState : Builder.Iterations -> List TransformOrder -> UnwrappedPropertyValues -> String -> { a | properties : List Builder.ProcessedPropertyConfig } -> AnimGroup
createElementAnimState iterationCount order startValues _ { properties } =
    { animations =
        List.filterMap (createPropertyAnimState startValues) properties
            |> Animations.fromList
    , isComplete = False
    , isPaused = False
    , transformOrder = order
    , iterationCount = iterationCount
    , currentIteration = 1
    }


createPropertyAnimState : UnwrappedPropertyValues -> Builder.ProcessedPropertyConfig -> Maybe ( String, Animation )
createPropertyAnimState startValues property =
    let
        buildPropertyAnimation start end duration_ delay_ easing_ =
            { startValue = start
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
            Just
                ( "translate"
                , Translate
                    (buildPropertyAnimation actualStart config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedRotateConfig config ->
            let
                actualStart =
                    Maybe.withDefault (Rotate.fromRecord startValues.rotate) config.start
            in
            Just
                ( "rotate"
                , Rotate
                    (buildPropertyAnimation actualStart config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedScaleConfig config ->
            let
                actualStart =
                    Maybe.withDefault (Scale.fromRecord startValues.scale) config.start
            in
            Just
                ( "scale"
                , Scale
                    (buildPropertyAnimation actualStart config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedBackgroundColorConfig config ->
            let
                actualStart =
                    Maybe.withDefault startValues.backgroundColor config.start
            in
            Just
                ( "backgroundColor"
                , BackgroundColor
                    (buildPropertyAnimation actualStart config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedFontColorConfig config ->
            let
                actualStart =
                    Maybe.withDefault startValues.fontColor config.start
            in
            Just
                ( "fontColor"
                , FontColor
                    (buildPropertyAnimation actualStart config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedOpacityConfig config ->
            let
                actualStart =
                    Maybe.withDefault (Opacity.fromFloat startValues.opacity) config.start
            in
            Just
                ( "opacity"
                , Opacity
                    (buildPropertyAnimation actualStart config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedSizeConfig config ->
            let
                actualStart =
                    Maybe.withDefault (Size.fromTuple ( startValues.size.width, startValues.size.height )) config.start
            in
            Just
                ( "size"
                , Size
                    (buildPropertyAnimation actualStart config.end config.duration config.delay config.easing)
                )


updateAnimatedProperty : Float -> Animation -> Animation
updateAnimatedProperty deltaMs prop =
    let
        tick anim =
            if anim.isComplete then
                anim

            else
                let
                    newElapsedMs =
                        anim.elapsedMs + deltaMs

                    animationElapsedMs =
                        max 0 (newElapsedMs - anim.delayMs)
                in
                { anim
                    | elapsedMs = newElapsedMs
                    , isComplete = animationElapsedMs >= anim.totalDurationMs
                }
    in
    case prop of
        Translate a ->
            Translate (tick a)

        Rotate a ->
            Rotate (tick a)

        Scale a ->
            Scale (tick a)

        BackgroundColor a ->
            BackgroundColor (tick a)

        FontColor a ->
            FontColor (tick a)

        Opacity a ->
            Opacity (tick a)

        Size a ->
            Size (tick a)


isAnimatedPropertyComplete : Animation -> Bool
isAnimatedPropertyComplete prop =
    case prop of
        Translate a ->
            a.isComplete

        Rotate a ->
            a.isComplete

        Scale a ->
            a.isComplete

        BackgroundColor a ->
            a.isComplete

        FontColor a ->
            a.isComplete

        Opacity a ->
            a.isComplete

        Size a ->
            a.isComplete


setAnimatedPropertyComplete : Bool -> Animation -> Animation
setAnimatedPropertyComplete val prop =
    let
        set anim =
            { anim | isComplete = val }
    in
    case prop of
        Translate a ->
            Translate (set a)

        Rotate a ->
            Rotate (set a)

        Scale a ->
            Scale (set a)

        BackgroundColor a ->
            BackgroundColor (set a)

        FontColor a ->
            FontColor (set a)

        Opacity a ->
            Opacity (set a)

        Size a ->
            Size (set a)


stopAnimatedProperty : Animation -> Animation
stopAnimatedProperty prop =
    let
        finish anim =
            { anim
                | elapsedMs = anim.totalDurationMs + anim.delayMs
                , isComplete = True
            }
    in
    case prop of
        Translate a ->
            Translate (finish a)

        Rotate a ->
            Rotate (finish a)

        Scale a ->
            Scale (finish a)

        BackgroundColor a ->
            BackgroundColor (finish a)

        FontColor a ->
            FontColor (finish a)

        Opacity a ->
            Opacity (finish a)

        Size a ->
            Size (finish a)



-- View Helpers


getSizeStyleAttributes : Animation -> List (Html.Attribute msg)
getSizeStyleAttributes prop =
    case prop of
        Size anim ->
            let
                size =
                    computeCurrentValue anim interpolateSize

                ( width, height ) =
                    Size.toTuple size
            in
            [ Html.Attributes.style "width" (String.fromFloat width ++ "px")
            , Html.Attributes.style "height" (String.fromFloat height ++ "px")
            ]

        _ ->
            []


getNonTransformStyleAttribute : Animation -> Maybe (Html.Attribute msg)
getNonTransformStyleAttribute prop =
    case prop of
        Translate _ ->
            Nothing

        Rotate _ ->
            Nothing

        Scale _ ->
            Nothing

        BackgroundColor anim ->
            Just (Html.Attributes.style "background-color" (Color.toCssString (computeCurrentValue anim Color.interpolate)))

        FontColor anim ->
            Just (Html.Attributes.style "color" (Color.toCssString (computeCurrentValue anim Color.interpolate)))

        Opacity anim ->
            Just (Html.Attributes.style "opacity" (String.fromFloat (Opacity.toFloat (computeCurrentValue anim interpolateOpacity))))

        Size _ ->
            -- Size is handled separately in getSizeStyleAttributes to set width and height
            Nothing



-- ANIMATION CONTROL


{-| Stop animation by jumping to its end state.
-}
stop : AnimGroupName -> AnimState -> AnimState
stop animGroupName (AnimState state animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            AnimState state animGroups

        Just animGroup ->
            let
                wasRunning =
                    not animGroup.isComplete && not animGroup.isPaused

                updatedProperties =
                    Animations.map (\_ -> stopAnimatedProperty) animGroup.animations

                updatedAnim =
                    { animGroup | animations = updatedProperties, isComplete = True, isPaused = False }

                updatedDict =
                    AnimGroups.insert animGroupName updatedAnim animGroups

                newPendingControlEvents =
                    if wasRunning then
                        state.pendingControlEvents ++ [ Cancelled animGroupName (overallProgress animGroup) ]

                    else
                        state.pendingControlEvents
            in
            AnimState { state | pendingControlEvents = newPendingControlEvents } updatedDict


{-| Reset animation by jumping to its start state.
-}
reset : String -> AnimState -> AnimState
reset animGroupName (AnimState state animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            AnimState state animGroups

        Just animGroup ->
            let
                wasRunning =
                    not animGroup.isComplete && not animGroup.isPaused

                updatedProperties =
                    Animations.map (\_ -> resetAnimatedProperty) animGroup.animations

                updatedAnim =
                    { animGroup | animations = updatedProperties, isComplete = False, isPaused = False }

                updatedDict =
                    AnimGroups.insert animGroupName updatedAnim animGroups

                newPendingControlEvents =
                    if wasRunning then
                        state.pendingControlEvents ++ [ Cancelled animGroupName (overallProgress animGroup) ]

                    else
                        state.pendingControlEvents
            in
            AnimState { state | isRunning = False, pendingControlEvents = newPendingControlEvents } updatedDict


{-| Restart animation from the beginning.
-}
restart : String -> AnimState -> AnimState
restart animGroup (AnimState state animGroups) =
    case AnimGroups.get animGroup animGroups of
        Nothing ->
            AnimState state animGroups

        Just elementAnim ->
            let
                updatedProperties =
                    Animations.map (\_ -> resetAnimatedProperty) elementAnim.animations

                updatedAnim =
                    { elementAnim | animations = updatedProperties, isComplete = False, isPaused = False }

                updatedDict =
                    AnimGroups.insert animGroup updatedAnim animGroups
            in
            AnimState { state | isRunning = True, pendingControlEvents = state.pendingControlEvents ++ [ Restarted animGroup ] } updatedDict


{-| Pause animation for a specific element.
-}
pause : AnimGroupName -> AnimState -> AnimState
pause animGroupName (AnimState state animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            AnimState state animGroups

        Just animGroup ->
            let
                wasRunning =
                    not animGroup.isComplete && not animGroup.isPaused

                updatedAnimations =
                    AnimGroups.update animGroupName
                        (Maybe.map (\ea -> { ea | isPaused = True }))
                        animGroups

                newPendingControlEvents =
                    if wasRunning then
                        state.pendingControlEvents ++ [ Paused animGroupName (overallProgress animGroup) ]

                    else
                        state.pendingControlEvents
            in
            AnimState { state | pendingControlEvents = newPendingControlEvents } updatedAnimations


{-| Resume animation for a specific element.
-}
resume : String -> AnimState -> AnimState
resume animGroup (AnimState state animGroups) =
    case AnimGroups.get animGroup animGroups of
        Nothing ->
            AnimState state animGroups

        Just elementAnim ->
            let
                wasPaused =
                    elementAnim.isPaused && not elementAnim.isComplete

                updatedAnimations =
                    AnimGroups.update animGroup
                        (Maybe.map (\ea -> { ea | isPaused = False }))
                        animGroups

                newPendingControlEvents =
                    if wasPaused then
                        state.pendingControlEvents ++ [ Resumed animGroup ]

                    else
                        state.pendingControlEvents
            in
            AnimState { state | isRunning = True, pendingControlEvents = newPendingControlEvents } updatedAnimations
