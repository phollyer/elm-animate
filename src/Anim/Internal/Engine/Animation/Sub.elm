module Anim.Internal.Engine.Animation.Sub exposing
    ( AnimBuilder
    , AnimEvent(..)
    , AnimMsg
    , AnimState
    , ControlEvent(..)
    , FreezeProperty
    , TickEvent(..)
    , allComplete
    , alternate
    , animate
    , anyRunning
    , attributes
    , delay
    , discreteEntry
    , discreteExit
    , duration
    , easing
    , freezeAxes
    , freezeRotate
    , freezeScale
    , freezeTranslate
    , getBackgroundColorCurrent
    , getBackgroundColorEnd
    , getBackgroundColorRange
    , getBackgroundColorStart
    , getFontColorCurrent
    , getFontColorEnd
    , getFontColorRange
    , getFontColorStart
    , getOpacityCurrent
    , getOpacityEnd
    , getOpacityRange
    , getOpacityStart
    , getProgress
    , getRotateCurrent
    , getRotateEnd
    , getRotateRange
    , getRotateStart
    , getScaleCurrent
    , getScaleEnd
    , getScaleRange
    , getScaleStart
    , getSizeCurrent
    , getSizeEnd
    , getSizeRange
    , getSizeStart
    , getTranslateCurrent
    , getTranslateEnd
    , getTranslateRange
    , getTranslateStart
    , init
    , isComplete
    , isRunning
    , iterations
    , loopForever
    , pause
    , reset
    , restart
    , resume
    , speed
    , stop
    , subscriptions
    , transformOrder
    , unfreezeAxes
    , update
    )

import Anim.Extra.Easing exposing (Easing(..))
import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.Animation.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Animation.PlayState as PlayState
import Anim.Internal.Engine.Animation.Sub.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Animation.Sub.Animation as Animation exposing (Animation(..), PropertyAnimation)
import Anim.Internal.Engine.Animation.Sub.Animations as Animations
import Anim.Internal.Engine.Animation.Sub.Generator as Generator
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Property.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Anim.Internal.Property.Size as Size exposing (Size)
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Events
import Dict
import Html
import Html.Attributes


type alias AnimBuilder =
    Builder.AnimBuilder



{- ***** MODEL ***** -}


type AnimState
    = AnimState
        { builder : AnimBuilder
        , subscriptionsActive : Bool
        , pendingControlEvents : List ControlEvent
        }
        (AnimGroups AnimGroup)


type alias AnimGroupName =
    String



{- **** INITIALIZE **** -}


init : List (AnimBuilder -> AnimBuilder) -> AnimState
init propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { builder = Builder.init []
                , subscriptionsActive = False
                , pendingControlEvents = []
                }
                AnimGroups.init

        _ ->
            let
                builder =
                    Builder.init propertyInitializers

                animGroups =
                    Builder.getAnimGroups builder

                initGroup : AnimGroupName -> Builder.AnimGroupConfig -> AnimGroup
                initGroup _ { properties } =
                    Generator.init
                        (Builder.getDiscreteEntryProperties builder)
                        (Builder.getDiscreteExitProperties builder)
                        properties
            in
            AnimState
                { subscriptionsActive = False
                , builder =
                    builder
                        |> Builder.mergeBaselines
                        |> Builder.clearAnimData
                , pendingControlEvents = []
                }
                (AnimGroups.map initGroup animGroups)



{- ***** TRIGGER ***** -}


animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate (AnimState state animGroups) build =
    let
        builder =
            state.builder
                |> Builder.injectCurrentStates (setSnapshot animGroups)
                |> build

        processed =
            Builder.process builder

        generateAnimGroup : AnimGroupName -> Builder.ProcessedAnimGroupConfig -> AnimGroup
        generateAnimGroup _ { properties } =
            Generator.generateAnimation
                processed.iterationCount
                (Maybe.withDefault TransformProperty.default processed.globalTransformOrder)
                (Builder.getDiscreteEntryProperties builder)
                (Builder.getDiscreteExitProperties builder)
                properties

        insertAnimGroup : AnimGroupName -> AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup
        insertAnimGroup animGroupName animGroup acc =
            case AnimGroups.get animGroupName acc of
                Nothing ->
                    AnimGroups.insert animGroupName animGroup acc

                Just existing ->
                    AnimGroups.insert animGroupName
                        (AnimGroup.addAnimation (AnimGroup.getAnimations existing) animGroup)
                        acc

        startedEvents =
            AnimGroups.names processed.groups
                |> List.map Started
    in
    AnimState
        { subscriptionsActive = True
        , builder =
            builder
                |> Builder.addAnimationToHistory processed
                |> Builder.mergeBaselines
                |> Builder.clearAnimData
        , pendingControlEvents = state.pendingControlEvents ++ startedEvents
        }
        (processed.groups
            |> AnimGroups.map generateAnimGroup
            |> AnimGroups.foldl insertAnimGroup animGroups
        )


setSnapshot : AnimGroups AnimGroup -> AnimGroups { propertySnapshot : PropertyBaselines }
setSnapshot anims =
    AnimGroups.map (\_ anim -> { propertySnapshot = extractElementCurrentStates anim }) anims


extractElementCurrentStates : AnimGroup -> PropertyBaselines
extractElementCurrentStates =
    AnimGroup.getAnimations
        >> Animations.foldl (\_ -> extractPropertyCurrentState)
            PropertyBaselines.empty


extractPropertyCurrentState : Animation -> PropertyBaselines -> PropertyBaselines
extractPropertyCurrentState anim states =
    case anim of
        Translate a ->
            PropertyBaselines.setTranslate (computeCurrentValue interpolateTranslate a) states

        Rotate a ->
            PropertyBaselines.setRotate (computeCurrentValue interpolateRotate a) states

        Scale a ->
            PropertyBaselines.setScale (computeCurrentValue interpolateScale a) states

        BackgroundColor a ->
            PropertyBaselines.setBackgroundColor (computeCurrentValue Color.interpolate a) states

        FontColor a ->
            PropertyBaselines.setFontColor (computeCurrentValue Color.interpolate a) states

        Opacity a ->
            PropertyBaselines.setOpacity (computeCurrentValue interpolateOpacity a) states

        Size a ->
            PropertyBaselines.setSize (computeCurrentValue interpolateSize a) states



{- ***** EVENTS ***** -}


type alias Progress =
    Float


{-| Events generated naturally by animation frame ticks.
-}
type TickEvent
    = Progress AnimGroupName Progress
    | Ended AnimGroupName
    | Iteration AnimGroupName Int


{-| Events generated by control function calls (animate, stop, pause, etc.).
-}
type ControlEvent
    = Started AnimGroupName
    | Cancelled AnimGroupName Progress
    | Paused AnimGroupName Progress
    | Resumed AnimGroupName
    | Restarted AnimGroupName


type AnimEvent
    = Tick TickEvent
    | Control ControlEvent



{- ***** UPDATE ***** -}


type AnimMsg
    = AnimationFrame Float


update : AnimMsg -> AnimState -> ( AnimState, List AnimEvent )
update msg (AnimState state animGroups) =
    case msg of
        AnimationFrame deltaMs ->
            let
                ( groups, events ) =
                    animGroups
                        |> AnimGroups.toList
                        |> List.map (tick deltaMs)
                        |> List.unzip

                updatedGroups =
                    AnimGroups.fromList groups

                allEvents =
                    List.concat events

                stillRunning =
                    updatedGroups
                        |> AnimGroups.groups
                        |> List.any AnimGroup.isRunning
            in
            ( AnimState
                { subscriptionsActive = stillRunning
                , builder = state.builder
                , pendingControlEvents = []
                }
                updatedGroups
            , List.map Control state.pendingControlEvents
                ++ List.map Tick allEvents
            )


tick : Float -> ( AnimGroupName, AnimGroup ) -> ( ( AnimGroupName, AnimGroup ), List TickEvent )
tick deltaMs ( animGroupName, animGroup ) =
    let
        ( newAnimGroup, events ) =
            handleTick deltaMs animGroupName animGroup
    in
    ( ( animGroupName, newAnimGroup ), events )


handleTick : Float -> AnimGroupName -> AnimGroup -> ( AnimGroup, List TickEvent )
handleTick deltaMs animGroupName animGroup =
    if AnimGroup.isPaused animGroup then
        ( animGroup, [] )

    else
        let
            updatedAnimations =
                animGroup
                    |> AnimGroup.getAnimations
                    |> Animations.map (\_ -> updateTiming deltaMs)

            allPropertiesComplete =
                updatedAnimations
                    |> Animations.list
                    |> List.all (Animation.foldTiming .isComplete)
        in
        if allPropertiesComplete && AnimGroup.isRunning animGroup then
            -- Properties just finished - check if we need to iterate
            let
                shouldIterate =
                    case AnimGroup.getIterations animGroup of
                        Builder.Infinite ->
                            True

                        Builder.Times totalIterations ->
                            AnimGroup.getCurrentIteration animGroup < totalIterations

                        Builder.Once ->
                            False
            in
            if shouldIterate then
                iterateAnimGroup animGroupName animGroup updatedAnimations

            else
                ( animGroup
                    |> AnimGroup.setAnimations updatedAnimations
                    |> AnimGroup.setPlayState PlayState.Complete
                , [ Ended animGroupName ]
                )

        else
            let
                updatedAnimGroup =
                    AnimGroup.setAnimations updatedAnimations animGroup
            in
            -- Not all properties complete yet (or already complete)
            ( updatedAnimGroup
            , if AnimGroup.isRunning updatedAnimGroup then
                [ Progress animGroupName (overallProgress updatedAnimGroup) ]

              else
                []
            )


updateTiming : Float -> Animation -> Animation
updateTiming deltaMs =
    Animation.mapTiming
        (\timing ->
            if timing.isComplete then
                timing

            else
                let
                    newElapsedMs =
                        timing.elapsedMs + deltaMs

                    animationElapsedMs =
                        max 0 (newElapsedMs - timing.delayMs)
                in
                { timing
                    | elapsedMs = newElapsedMs
                    , isComplete = animationElapsedMs >= timing.totalDurationMs
                }
        )


iterateAnimGroup : AnimGroupName -> AnimGroup -> Animations.Animations -> ( AnimGroup, List TickEvent )
iterateAnimGroup animGroupName animGroup animations =
    let
        anims =
            Animations.map (\_ -> Animation.reset) animations

        nextIteration =
            AnimGroup.getCurrentIteration animGroup + 1
    in
    ( animGroup
        |> AnimGroup.setAnimations anims
        |> AnimGroup.setCurrentIteration nextIteration
        |> AnimGroup.setPlayState PlayState.Running
    , [ Iteration animGroupName nextIteration ]
    )



{- ***** SUBSCRIPTIONS ***** -}


subscriptions : (AnimMsg -> msg) -> AnimState -> Sub msg
subscriptions toMsg (AnimState state _) =
    if state.subscriptionsActive then
        Browser.Events.onAnimationFrameDelta AnimationFrame
            |> Sub.map toMsg

    else
        Sub.none



{- ***** VIEW ***** -}


attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes animGroupName (AnimState _ animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            []

        Just animGroup ->
            let
                anims =
                    animGroup
                        |> AnimGroup.getAnimations
                        |> Animations.list

                transformParts =
                    List.foldl collectCurrentTransform Builder.emptyTransformParts anims

                transformString =
                    animGroup
                        |> AnimGroup.getTransformOrder
                        |> List.map (transformOrderToPart transformParts)
                        |> List.filter (not << String.isEmpty)
                        |> String.join " "

                transformStyle =
                    if String.isEmpty transformString then
                        []

                    else
                        [ Html.Attributes.style "transform" transformString ]

                nonTransformStyles =
                    List.concatMap getNonTransformStyleAttribute anims

                discreteStyles =
                    discreteEntryStyles animGroup
                        ++ discreteExitStyles animGroup
            in
            transformStyle ++ nonTransformStyles ++ discreteStyles


collectCurrentTransform : Animation -> Builder.TransformParts -> Builder.TransformParts
collectCurrentTransform anim acc =
    case anim of
        Translate a ->
            { acc | translate = Translate.toCssString (computeCurrentValue interpolateTranslate a) }

        Rotate a ->
            { acc | rotate = Rotate.toCssString (computeCurrentValue interpolateRotate a) }

        Scale a ->
            { acc | scale = Scale.toCssString (computeCurrentValue interpolateScale a) }

        _ ->
            acc


transformOrderToPart : Builder.TransformParts -> TransformProperty -> String
transformOrderToPart parts property =
    case property of
        TransformProperty.Translate ->
            parts.translate

        TransformProperty.Rotate ->
            parts.rotate

        TransformProperty.Scale ->
            parts.scale


discreteEntryStyles : AnimGroup -> List (Html.Attribute msg)
discreteEntryStyles =
    AnimGroup.getDiscreteEntry
        >> Dict.toList
        >> List.map
            (\( prop, value ) ->
                Html.Attributes.style prop value
            )


discreteExitStyles : AnimGroup -> List (Html.Attribute msg)
discreteExitStyles animGroup =
    AnimGroup.getDiscreteExit animGroup
        |> Dict.toList
        |> List.map
            (\( prop, { from, to } ) ->
                if AnimGroup.isComplete animGroup then
                    Html.Attributes.style prop to

                else
                    Html.Attributes.style prop from
            )


getNonTransformStyleAttribute : Animation -> List (Html.Attribute msg)
getNonTransformStyleAttribute anim =
    case anim of
        Translate _ ->
            []

        Rotate _ ->
            []

        Scale _ ->
            []

        BackgroundColor a ->
            [ Html.Attributes.style "background-color" (Color.toCssString (computeCurrentValue Color.interpolate a)) ]

        FontColor a ->
            [ Html.Attributes.style "color" (Color.toCssString (computeCurrentValue Color.interpolate a)) ]

        Opacity a ->
            [ Html.Attributes.style "opacity" (String.fromFloat (Opacity.toFloat (computeCurrentValue interpolateOpacity a))) ]

        Size a ->
            let
                size =
                    computeCurrentValue interpolateSize a

                ( width, height ) =
                    Size.toTuple size
            in
            [ Html.Attributes.style "width" (String.fromFloat width ++ "px")
            , Html.Attributes.style "height" (String.fromFloat height ++ "px")
            ]



{- ***** CONTROL ***** -}


stop : AnimGroupName -> AnimState -> AnimState
stop animGroupName =
    applyControlAction animGroupName Cancelled <|
        \animGroup ->
            let
                animations =
                    mapAnimations Animation.stop animGroup
            in
            AnimGroups.insert animGroupName
                (animGroup
                    |> AnimGroup.setAnimations animations
                    |> AnimGroup.setPlayState PlayState.Complete
                )


reset : AnimGroupName -> AnimState -> AnimState
reset animGroupName =
    applyControlAction animGroupName Cancelled <|
        \animGroup animGroups ->
            let
                animations =
                    mapAnimations Animation.reset animGroup
            in
            AnimGroups.insert animGroupName
                (animGroup
                    |> AnimGroup.setAnimations animations
                    |> AnimGroup.setPlayState PlayState.Reset
                )
                animGroups


restart : AnimGroupName -> AnimState -> AnimState
restart animGroupName (AnimState state animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            AnimState state animGroups

        Just animGroup ->
            let
                animations =
                    mapAnimations Animation.reset animGroup

                updatedAnimGroup =
                    animGroup
                        |> AnimGroup.setAnimations animations
                        |> AnimGroup.setPlayState PlayState.Running
            in
            AnimState
                { state
                    | subscriptionsActive = True
                    , pendingControlEvents = state.pendingControlEvents ++ [ Restarted animGroupName ]
                }
                (AnimGroups.insert animGroupName updatedAnimGroup animGroups)


pause : AnimGroupName -> AnimState -> AnimState
pause animGroupName =
    applyControlAction animGroupName Paused <|
        \_ animGroups ->
            AnimGroups.update animGroupName
                (Maybe.map (AnimGroup.setPlayState PlayState.Paused))
                animGroups


mapAnimations : (Animation -> Animation) -> AnimGroup -> Animations.Animations
mapAnimations fn =
    AnimGroup.getAnimations
        >> Animations.map (\_ -> fn)


applyControlAction :
    AnimGroupName
    -> (AnimGroupName -> Float -> ControlEvent)
    -> (AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup)
    -> AnimState
    -> AnimState
applyControlAction animGroupName toEvent transformGroups (AnimState state animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            AnimState state animGroups

        Just animGroup ->
            let
                updatedAnimGroups =
                    transformGroups animGroup animGroups
            in
            AnimState
                { state
                    | subscriptionsActive =
                        updatedAnimGroups
                            |> AnimGroups.groups
                            |> List.any AnimGroup.isRunning
                    , pendingControlEvents =
                        if AnimGroup.isRunning animGroup then
                            state.pendingControlEvents ++ [ toEvent animGroupName (overallProgress animGroup) ]

                        else
                            state.pendingControlEvents
                }
                updatedAnimGroups


resume : AnimGroupName -> AnimState -> AnimState
resume animGroupName (AnimState state animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            AnimState state animGroups

        Just animGroup ->
            let
                wasPaused =
                    AnimGroup.isPaused animGroup

                newPendingControlEvents =
                    if wasPaused then
                        state.pendingControlEvents ++ [ Resumed animGroupName ]

                    else
                        state.pendingControlEvents
            in
            AnimState
                { state
                    | subscriptionsActive = True
                    , pendingControlEvents = newPendingControlEvents
                }
                (AnimGroups.update animGroupName
                    (Maybe.map (AnimGroup.setPlayState PlayState.Running))
                    animGroups
                )



{- ***** STATE QUERIES ***** -}


anyRunning : AnimState -> Maybe Bool
anyRunning (AnimState state animGroups) =
    case AnimGroups.groups animGroups of
        [] ->
            Nothing

        _ ->
            Just state.subscriptionsActive


isRunning : AnimGroupName -> AnimState -> Maybe Bool
isRunning animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map AnimGroup.isRunning


isComplete : AnimGroupName -> AnimState -> Maybe Bool
isComplete animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map AnimGroup.isComplete


allComplete : AnimState -> Maybe Bool
allComplete (AnimState _ animGroups) =
    if AnimGroups.isEmpty animGroups then
        Nothing

    else
        animGroups
            |> AnimGroups.groups
            |> List.all AnimGroup.isComplete
            |> Just


getProgress : AnimGroupName -> AnimState -> Maybe Float
getProgress animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map overallProgress


overallProgress : AnimGroup -> Float
overallProgress =
    AnimGroup.getAnimations
        >> Animations.list
        >> List.map (Animation.foldTiming calculateProgress)
        >> List.maximum
        >> Maybe.withDefault 0



{- ***** PROPERTY QUERIES ***** -}
--
--
--
{- *** BACKGROUND COLOR *** -}


getBackgroundColorRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedBackgroundColorConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


getBackgroundColorStart : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorStart =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedBackgroundColorConfig config ->
                    config.start

                _ ->
                    Nothing
        )


getBackgroundColorEnd : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorEnd =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedBackgroundColorConfig config ->
                    Just config.end

                _ ->
                    Nothing
        )


getBackgroundColorCurrent : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorCurrent =
    getPropertyValue "backgroundColor"
        (\prop ->
            case prop of
                BackgroundColor a ->
                    Just (computeCurrentValue Color.interpolate a)

                _ ->
                    Nothing
        )



{- *** FONT COLOR *** -}


getFontColorRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Color, end : Color }
getFontColorRange =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedFontColorConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


getFontColorStart : AnimGroupName -> AnimState -> Maybe Color
getFontColorStart =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedFontColorConfig config ->
                    config.start

                _ ->
                    Nothing
        )


getFontColorEnd : AnimGroupName -> AnimState -> Maybe Color
getFontColorEnd =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedFontColorConfig config ->
                    Just config.end

                _ ->
                    Nothing
        )


getFontColorCurrent : AnimGroupName -> AnimState -> Maybe Color
getFontColorCurrent =
    getPropertyValue "fontColor"
        (\prop ->
            case prop of
                FontColor a ->
                    Just (computeCurrentValue Color.interpolate a)

                _ ->
                    Nothing
        )



{- *** OPACITY *** -}


getOpacityRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Float, end : Float }
getOpacityRange =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedOpacityConfig config ->
                    Just { start = Maybe.map Opacity.toFloat config.start, end = Opacity.toFloat config.end }

                _ ->
                    Nothing
        )


getOpacityStart : AnimGroupName -> AnimState -> Maybe Float
getOpacityStart =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedOpacityConfig config ->
                    Maybe.map Opacity.toFloat config.start

                _ ->
                    Nothing
        )


getOpacityEnd : AnimGroupName -> AnimState -> Maybe Float
getOpacityEnd =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedOpacityConfig config ->
                    Just (Opacity.toFloat config.end)

                _ ->
                    Nothing
        )


getOpacityCurrent : AnimGroupName -> AnimState -> Maybe Float
getOpacityCurrent =
    getPropertyValue "opacity"
        (\prop ->
            case prop of
                Opacity config ->
                    config
                        |> computeCurrentValue interpolateOpacity
                        |> Opacity.toFloat
                        |> Just

                _ ->
                    Nothing
        )



{- *** ROTATE *** -}


getRotateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedRotateConfig config ->
                    Just { start = Maybe.map Rotate.toRecord config.start, end = Rotate.toRecord config.end }

                _ ->
                    Nothing
        )


getRotateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateStart =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedRotateConfig config ->
                    Maybe.map Rotate.toRecord config.start

                _ ->
                    Nothing
        )


getRotateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedRotateConfig config ->
                    Just (Rotate.toRecord config.end)

                _ ->
                    Nothing
        )


getRotateCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateCurrent =
    getPropertyValue "rotate"
        (\prop ->
            case prop of
                Rotate config ->
                    config
                        |> computeCurrentValue interpolateRotate
                        |> Rotate.toRecord
                        |> Just

                _ ->
                    Nothing
        )



{- *** SCALE *** -}


getScaleRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedScaleConfig config ->
                    Just
                        { start = Maybe.map Scale.toRecord config.start
                        , end = Scale.toRecord config.end
                        }

                _ ->
                    Nothing
        )


getScaleStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleStart =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedScaleConfig config ->
                    Maybe.map Scale.toRecord config.start

                _ ->
                    Nothing
        )


getScaleEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedScaleConfig config ->
                    Just (Scale.toRecord config.end)

                _ ->
                    Nothing
        )


getScaleCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleCurrent =
    getPropertyValue "scale"
        (\prop ->
            case prop of
                Scale config ->
                    Just (computeCurrentValue interpolateScale config |> Scale.toRecord)

                _ ->
                    Nothing
        )



{- *** SIZE *** -}


getSizeRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedSizeConfig config ->
                    Just { start = Maybe.map Size.toRecord config.start, end = Size.toRecord config.end }

                _ ->
                    Nothing
        )


getSizeStart : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeStart =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedSizeConfig config ->
                    Maybe.map Size.toRecord config.start

                _ ->
                    Nothing
        )


getSizeEnd : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedSizeConfig config ->
                    Just (Size.toRecord config.end)

                _ ->
                    Nothing
        )


getSizeCurrent : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeCurrent =
    getPropertyValue "size"
        (\prop ->
            case prop of
                Size config ->
                    config
                        |> computeCurrentValue interpolateSize
                        |> Size.toRecord
                        |> Just

                _ ->
                    Nothing
        )



{- *** TRANSLATE *** -}


getTranslateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedTranslateConfig config ->
                    Just
                        { start = Maybe.map Translate.toRecord config.start
                        , end = Translate.toRecord config.end
                        }

                _ ->
                    Nothing
        )


getTranslateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedTranslateConfig config ->
                    Maybe.map Translate.toRecord config.start

                _ ->
                    Nothing
        )


getTranslateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedTranslateConfig config ->
                    Just (Translate.toRecord config.end)

                _ ->
                    Nothing
        )


getTranslateCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateCurrent =
    getPropertyValue "translate"
        (\prop ->
            case prop of
                Translate config ->
                    config
                        |> computeCurrentValue interpolateTranslate
                        |> Translate.toRecord
                        |> Just

                _ ->
                    Nothing
        )



{- *** PROPERTY HELPERS *** -}


getPropertyConfig : (Builder.ProcessedPropertyConfig -> Maybe config) -> AnimGroupName -> AnimState -> Maybe config
getPropertyConfig matcher animGroupName (AnimState state _) =
    Builder.getCurrentAnimation animGroupName state.builder
        |> Maybe.andThen (.properties >> List.filterMap matcher >> List.head)


getPropertyValue : String -> (Animation -> Maybe a) -> AnimGroupName -> AnimState -> Maybe a
getPropertyValue propertyKey valueExtractor animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (Animations.get propertyKey << AnimGroup.getAnimations)
        |> Maybe.andThen valueExtractor


calculateProgress : { a | elapsedMs : Float, delayMs : Float, totalDurationMs : Float, isComplete : Bool } -> Float
calculateProgress timing =
    if timing.isComplete || timing.totalDurationMs <= 0 then
        1.0

    else
        let
            animationElapsedMs =
                max 0 (timing.elapsedMs - timing.delayMs)
        in
        if animationElapsedMs <= 0 then
            0.0

        else
            min 1.0 (animationElapsedMs / timing.totalDurationMs)


computeCurrentValue : (Float -> a -> a -> a) -> PropertyAnimation a -> a
computeCurrentValue interpolate anim =
    let
        easedProgress =
            anim.easingFunction (calculateProgress anim)
    in
    interpolate easedProgress anim.start anim.end


interpolateFloat : Float -> Float -> Float -> Float
interpolateFloat t start end =
    start + (end - start) * t


interpolateOpacity : Float -> Opacity -> Opacity -> Opacity
interpolateOpacity t start end =
    Opacity.fromFloat (interpolateFloat t (Opacity.toFloat start) (Opacity.toFloat end))


interpolateRotate : Float -> Rotate -> Rotate -> Rotate
interpolateRotate =
    interpolateTriple Rotate.toTriple Rotate.fromTriple


interpolateScale : Float -> Scale -> Scale -> Scale
interpolateScale =
    interpolateTriple Scale.toTriple Scale.fromTriple


interpolateSize : Float -> Size -> Size -> Size
interpolateSize =
    interpolateTuple Size.toTuple Size.fromTuple


interpolateTranslate : Float -> Translate -> Translate -> Translate
interpolateTranslate =
    interpolateTriple Translate.toTriple Translate.fromTriple


interpolateTriple : (a -> ( Float, Float, Float )) -> (( Float, Float, Float ) -> a) -> Float -> a -> a -> a
interpolateTriple toTriple fromTriple t start end =
    let
        ( s1, s2, s3 ) =
            toTriple start

        ( e1, e2, e3 ) =
            toTriple end
    in
    fromTriple ( interpolateFloat t s1 e1, interpolateFloat t s2 e2, interpolateFloat t s3 e3 )


interpolateTuple : (a -> ( Float, Float )) -> (( Float, Float ) -> a) -> Float -> a -> a -> a
interpolateTuple toTuple fromTuple t start end =
    let
        ( s1, s2 ) =
            toTuple start

        ( e1, e2 ) =
            toTuple end
    in
    fromTuple ( interpolateFloat t s1 e1, interpolateFloat t s2 e2 )



{- **** Builder Wrappers **** -}


type alias FreezeProperty =
    Builder.FreezeProperty


freezeTranslate : FreezeProperty
freezeTranslate =
    Builder.FreezeTranslate


freezeRotate : FreezeProperty
freezeRotate =
    Builder.FreezeRotate


freezeScale : FreezeProperty
freezeScale =
    Builder.FreezeScale


delay : Int -> AnimBuilder -> AnimBuilder
delay =
    Builder.delay


duration : Int -> AnimBuilder -> AnimBuilder
duration =
    Builder.duration


speed : Float -> AnimBuilder -> AnimBuilder
speed =
    Builder.speed


easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Builder.easing


iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    Builder.iterations


loopForever : AnimBuilder -> AnimBuilder
loopForever =
    Builder.loopForever


alternate : AnimBuilder -> AnimBuilder
alternate =
    Builder.alternate


discreteEntry : String -> String -> AnimBuilder -> AnimBuilder
discreteEntry =
    Builder.discreteEntry


discreteExit : String -> String -> String -> AnimBuilder -> AnimBuilder
discreteExit =
    Builder.discreteExit


transformOrder : List TransformProperty -> AnimBuilder -> AnimBuilder
transformOrder =
    Builder.transformOrder


freezeAxes : List String -> List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeAxes =
    Builder.freezeAxes


unfreezeAxes : List String -> List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeAxes =
    Builder.unfreezeAxes
