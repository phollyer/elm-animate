module Anim.Internal.Engine.Sub exposing
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
    , calculateProgress
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
    , getColorPropertyCurrent
    , getColorPropertyEnd
    , getColorPropertyRange
    , getColorPropertyStart
    , getFontColorCurrent
    , getFontColorEnd
    , getFontColorRange
    , getFontColorStart
    , getOpacityCurrent
    , getOpacityEnd
    , getOpacityRange
    , getOpacityStart
    , getProgress
    , getPropertyCurrent
    , getPropertyEnd
    , getPropertyRange
    , getPropertyStart
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
    , interpolateEasedProgress
    , interpolateFloat
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

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.Property as Property
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.PlayState as PlayState
import Anim.Internal.Engine.Sub.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Sub.Animation as Animation exposing (Animation(..), PropertyAnimation)
import Anim.Internal.Engine.Sub.Animations as Animations
import Anim.Internal.Engine.Sub.Generator as Generator
import Anim.Internal.Engine.Sub.Interpolation as Interpolation
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.PropertyBuilder.Opacity as Opacity exposing (Opacity)
import Anim.Internal.PropertyBuilder.Rotate as Rotate exposing (Rotate)
import Anim.Internal.PropertyBuilder.Scale as Scale exposing (Scale)
import Anim.Internal.PropertyBuilder.Size as Size exposing (Size)
import Anim.Internal.PropertyBuilder.Skew as Skew exposing (Skew)
import Anim.Internal.PropertyBuilder.Translate as Translate exposing (Translate)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Events
import Dict
import Easing exposing (Easing(..))
import Html
import Html.Attributes



-- ============================================================
-- MODEL
-- ============================================================


type AnimState
    = AnimState
        { builder : AnimBuilder
        , subscriptionsActive : Bool
        , pendingControlEvents : List ControlEvent
        }
        (AnimGroups AnimGroup)


type alias AnimBuilder =
    Builder.AnimBuilder


type alias AnimGroupName =
    String



-- ============================================================
-- INITIALIZE
-- ============================================================


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



-- ============================================================
-- TRIGGER
-- ============================================================


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
        generateAnimGroup animGroupName config =
            Generator.generateAnimation
                processed.iterations
                processed.animationDirection
                config.transformOrder
                (Builder.getDiscreteEntryProperties builder)
                (Builder.getDiscreteExitProperties builder)
                (AnimGroups.get animGroupName animGroups)
                config.properties

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
            PropertyBaselines.setTranslate (interpolateEasedProgress interpolateTranslate a) states

        Rotate a ->
            PropertyBaselines.setRotate (interpolateEasedProgress interpolateRotate a) states

        Skew a ->
            PropertyBaselines.setSkew (interpolateEasedProgress interpolateSkew a) states

        Scale a ->
            PropertyBaselines.setScale (interpolateEasedProgress interpolateScale a) states

        BackgroundColor a ->
            PropertyBaselines.setBackgroundColor (interpolateEasedProgress Color.interpolate a) states

        FontColor a ->
            PropertyBaselines.setFontColor (interpolateEasedProgress Color.interpolate a) states

        Opacity a ->
            PropertyBaselines.setOpacity (interpolateEasedProgress interpolateOpacity a) states

        Size a ->
            PropertyBaselines.setSize (interpolateEasedProgress interpolateSize a) states

        CustomProperty cssName _ a ->
            PropertyBaselines.setCustomProperty cssName (interpolateEasedProgress interpolateFloat a) states

        CustomColorProperty cssName a ->
            PropertyBaselines.setCustomColorProperty cssName (interpolateEasedProgress Color.interpolate a) states



-- ============================================================
-- EVENTS
-- ============================================================


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



-- ============================================================
-- UPDATE
-- ============================================================


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
        nextIteration =
            AnimGroup.getCurrentIteration animGroup + 1

        shouldReverse =
            case AnimGroup.getAnimationDirection animGroup of
                Builder.Alternate ->
                    modBy 2 nextIteration == 0

                Builder.Normal ->
                    False

        anims =
            animations
                |> Animations.map
                    (\_ anim ->
                        let
                            reversed =
                                if shouldReverse then
                                    Animation.reverse anim

                                else
                                    anim
                        in
                        Animation.reset reversed
                    )
    in
    ( animGroup
        |> AnimGroup.setAnimations anims
        |> AnimGroup.setCurrentIteration nextIteration
        |> AnimGroup.setPlayState PlayState.Running
    , [ Iteration animGroupName nextIteration ]
    )



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


subscriptions : (AnimMsg -> msg) -> AnimState -> Sub msg
subscriptions toMsg (AnimState state _) =
    if state.subscriptionsActive then
        Browser.Events.onAnimationFrameDelta AnimationFrame
            |> Sub.map toMsg

    else
        Sub.none



-- ============================================================
-- VIEW
-- ============================================================


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

                currentOrder =
                    AnimGroup.getTransformOrder animGroup

                transformParts =
                    List.foldl collectCurrentTransform Builder.emptyTransformParts anims

                transformString =
                    currentOrder
                        |> List.map (transformOrderToPart transformParts)
                        |> List.filter (not << String.isEmpty)
                        |> String.join " "

                orderString =
                    currentOrder
                        |> List.map TransformProperty.toString
                        |> String.join " -> "

                loggedTransformString =
                    Debug.log ("Sub.transform | group=" ++ animGroupName ++ " | order=" ++ orderString) transformString

                transformStyle =
                    if String.isEmpty loggedTransformString then
                        []

                    else
                        [ Html.Attributes.style "transform" loggedTransformString ]

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
            { acc | translate = Translate.toCssString (interpolateEasedProgress interpolateTranslate a) }

        Rotate a ->
            { acc | rotate = Rotate.toCssString (interpolateEasedProgress interpolateRotate a) }

        Skew a ->
            { acc | skew = Skew.toCssString (interpolateEasedProgress interpolateSkew a) }

        Scale a ->
            { acc | scale = Scale.toCssString (interpolateEasedProgress interpolateScale a) }

        _ ->
            acc


transformOrderToPart : Builder.TransformParts -> TransformProperty -> String
transformOrderToPart parts property =
    case property of
        TransformProperty.Translate ->
            parts.translate

        TransformProperty.Rotate ->
            parts.rotate

        TransformProperty.Skew ->
            parts.skew

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

        Skew _ ->
            []

        BackgroundColor a ->
            [ Html.Attributes.style "background-color" (Color.toCssString (interpolateEasedProgress Color.interpolate a)) ]

        FontColor a ->
            [ Html.Attributes.style "color" (Color.toCssString (interpolateEasedProgress Color.interpolate a)) ]

        Opacity a ->
            [ Html.Attributes.style "opacity" (String.fromFloat (Opacity.toFloat (interpolateEasedProgress interpolateOpacity a))) ]

        Size a ->
            let
                size =
                    interpolateEasedProgress interpolateSize a

                ( width, height ) =
                    Size.toTuple size
            in
            [ Html.Attributes.style "width" (String.fromFloat width ++ "px")
            , Html.Attributes.style "height" (String.fromFloat height ++ "px")
            ]

        CustomProperty cssName unit a ->
            [ Html.Attributes.style cssName (String.fromFloat (interpolateEasedProgress interpolateFloat a) ++ unit) ]

        CustomColorProperty cssName a ->
            [ Html.Attributes.style cssName (Color.toCssString (interpolateEasedProgress Color.interpolate a)) ]



-- ============================================================
-- PLAYBACK SETTINGS
-- ============================================================


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



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


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



-- ============================================================
-- TRANSFORM ORDER
-- ============================================================


transformOrder : List TransformProperty -> AnimBuilder -> AnimBuilder
transformOrder =
    Builder.transformOrder



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


discreteEntry : String -> String -> AnimBuilder -> AnimBuilder
discreteEntry =
    Builder.discreteEntry


discreteExit : String -> String -> String -> AnimBuilder -> AnimBuilder
discreteExit =
    Builder.discreteExit



-- ============================================================
-- FREEZE / UNFREEZE PROPERTIES
-- ============================================================


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



-- ============================================================
-- FREEZE AXES
-- ============================================================


freezeAxes : List String -> List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeAxes =
    Builder.freezeAxes



-- ============================================================
-- UNFREEZE AXES
-- ============================================================


unfreezeAxes : List String -> List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeAxes =
    Builder.unfreezeAxes



-- ============================================================
-- STATE QUERIES
-- ============================================================


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



-- ============================================================
-- PROPERTY QUERIES
-- ============================================================


getBuilder : AnimState -> Builder.AnimBuilder
getBuilder (AnimState state _) =
    state.builder


getPropertyValue : String -> (Animation -> Maybe a) -> AnimGroupName -> AnimState -> Maybe a
getPropertyValue propertyKey valueExtractor animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (Animations.get propertyKey << AnimGroup.getAnimations)
        |> Maybe.andThen valueExtractor



-- ============================
-- BACKGROUND COLOR
-- ============================


getBackgroundColorRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange animGroupName =
    getBuilder >> Property.getBackgroundColorRange animGroupName


getBackgroundColorStart : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorStart animGroupName =
    getBuilder >> Property.getBackgroundColorStart animGroupName


getBackgroundColorEnd : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorEnd animGroupName =
    getBuilder >> Property.getBackgroundColorEnd animGroupName


getBackgroundColorCurrent : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorCurrent =
    getPropertyValue "backgroundColor"
        (\prop ->
            case prop of
                BackgroundColor a ->
                    Just (interpolateEasedProgress Color.interpolate a)

                _ ->
                    Nothing
        )



-- ============================
-- FONT COLOR
-- ============================


getFontColorRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Color, end : Color }
getFontColorRange animGroupName =
    getBuilder >> Property.getFontColorRange animGroupName


getFontColorStart : AnimGroupName -> AnimState -> Maybe Color
getFontColorStart animGroupName =
    getBuilder >> Property.getFontColorStart animGroupName


getFontColorEnd : AnimGroupName -> AnimState -> Maybe Color
getFontColorEnd animGroupName =
    getBuilder >> Property.getFontColorEnd animGroupName


getFontColorCurrent : AnimGroupName -> AnimState -> Maybe Color
getFontColorCurrent =
    getPropertyValue "fontColor"
        (\prop ->
            case prop of
                FontColor a ->
                    Just (interpolateEasedProgress Color.interpolate a)

                _ ->
                    Nothing
        )



-- ============================
-- OPACITY
-- ============================


getOpacityRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Float, end : Float }
getOpacityRange animGroupName =
    getBuilder >> Property.getOpacityRange animGroupName


getOpacityStart : AnimGroupName -> AnimState -> Maybe Float
getOpacityStart animGroupName =
    getBuilder >> Property.getOpacityStart animGroupName


getOpacityEnd : AnimGroupName -> AnimState -> Maybe Float
getOpacityEnd animGroupName =
    getBuilder >> Property.getOpacityEnd animGroupName


getOpacityCurrent : AnimGroupName -> AnimState -> Maybe Float
getOpacityCurrent =
    getPropertyValue "opacity"
        (\prop ->
            case prop of
                Opacity config ->
                    config
                        |> interpolateEasedProgress interpolateOpacity
                        |> Opacity.toFloat
                        |> Just

                _ ->
                    Nothing
        )


interpolateOpacity : Float -> Opacity -> Opacity -> Opacity
interpolateOpacity =
    Interpolation.interpolateOpacity



-- ============================
-- ROTATE
-- ============================


getRotateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange animGroupName =
    getBuilder >> Property.getRotateRange animGroupName


getRotateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateStart animGroupName =
    getBuilder >> Property.getRotateStart animGroupName


getRotateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd animGroupName =
    getBuilder >> Property.getRotateEnd animGroupName


getRotateCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateCurrent =
    getPropertyValue "rotate"
        (\prop ->
            case prop of
                Rotate config ->
                    config
                        |> interpolateEasedProgress interpolateRotate
                        |> Rotate.toRecord
                        |> Just

                _ ->
                    Nothing
        )


interpolateRotate : Float -> Rotate -> Rotate -> Rotate
interpolateRotate =
    Interpolation.interpolateRotate


interpolateSkew : Float -> Skew -> Skew -> Skew
interpolateSkew =
    Interpolation.interpolateSkew



-- ============================
-- SCALE
-- ============================


getScaleRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange animGroupName =
    getBuilder >> Property.getScaleRange animGroupName


getScaleStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleStart animGroupName =
    getBuilder >> Property.getScaleStart animGroupName


getScaleEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd animGroupName =
    getBuilder >> Property.getScaleEnd animGroupName


getScaleCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleCurrent =
    getPropertyValue "scale"
        (\prop ->
            case prop of
                Scale config ->
                    Just (interpolateEasedProgress interpolateScale config |> Scale.toRecord)

                _ ->
                    Nothing
        )


interpolateScale : Float -> Scale -> Scale -> Scale
interpolateScale =
    Interpolation.interpolateScale



-- ============================
-- SIZE
-- ============================


getSizeRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange animGroupName =
    getBuilder >> Property.getSizeRange animGroupName


getSizeStart : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeStart animGroupName =
    getBuilder >> Property.getSizeStart animGroupName


getSizeEnd : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd animGroupName =
    getBuilder >> Property.getSizeEnd animGroupName


getSizeCurrent : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeCurrent =
    getPropertyValue "size"
        (\prop ->
            case prop of
                Size config ->
                    config
                        |> interpolateEasedProgress interpolateSize
                        |> Size.toRecord
                        |> Just

                _ ->
                    Nothing
        )


interpolateSize : Float -> Size -> Size -> Size
interpolateSize =
    Interpolation.interpolateSize



-- ============================
-- TRANSLATE
-- ============================


getTranslateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange animGroupName =
    getBuilder >> Property.getTranslateRange animGroupName


getTranslateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart animGroupName =
    getBuilder >> Property.getTranslateStart animGroupName


getTranslateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd animGroupName =
    getBuilder >> Property.getTranslateEnd animGroupName


getTranslateCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateCurrent =
    getPropertyValue "translate"
        (\prop ->
            case prop of
                Translate config ->
                    config
                        |> interpolateEasedProgress interpolateTranslate
                        |> Translate.toRecord
                        |> Just

                _ ->
                    Nothing
        )


interpolateTranslate : Float -> Translate -> Translate -> Translate
interpolateTranslate =
    Interpolation.interpolateTranslate



-- ============================
-- CUSTOM PROPERTY
-- ============================


getPropertyRange : AnimGroupName -> String -> AnimState -> Maybe { start : Maybe Float, end : Float }
getPropertyRange animGroupName cssName =
    getBuilder >> Property.getPropertyRange animGroupName cssName


getPropertyStart : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyStart animGroupName cssName =
    getBuilder >> Property.getPropertyStart animGroupName cssName


getPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyEnd animGroupName cssName =
    getBuilder >> Property.getPropertyEnd animGroupName cssName


getPropertyCurrent : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyCurrent animGroupName cssName =
    getPropertyValue ("custom:" ++ cssName)
        (\prop ->
            case prop of
                CustomProperty propName _ config ->
                    if propName == cssName then
                        config
                            |> interpolateEasedProgress interpolateFloat
                            |> Just

                    else
                        Nothing

                _ ->
                    Nothing
        )
        animGroupName



-- ============================
-- CUSTOM COLOR PROPERTY
-- ============================


getColorPropertyRange : AnimGroupName -> String -> AnimState -> Maybe { start : Maybe Color, end : Color }
getColorPropertyRange animGroupName cssName =
    getBuilder >> Property.getColorPropertyRange animGroupName cssName


getColorPropertyStart : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyStart animGroupName cssName =
    getBuilder >> Property.getColorPropertyStart animGroupName cssName


getColorPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyEnd animGroupName cssName =
    getBuilder >> Property.getColorPropertyEnd animGroupName cssName


getColorPropertyCurrent : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyCurrent animGroupName cssName =
    getPropertyValue ("customColor:" ++ cssName)
        (\prop ->
            case prop of
                CustomColorProperty propName config ->
                    if propName == cssName then
                        config
                            |> interpolateEasedProgress Color.interpolate
                            |> Just

                    else
                        Nothing

                _ ->
                    Nothing
        )
        animGroupName



-- ============================================================
-- INTERPOLATION (delegated to Sub.Interpolation)
-- ============================================================


calculateProgress : { a | elapsedMs : Float, delayMs : Float, totalDurationMs : Float, isComplete : Bool } -> Float
calculateProgress =
    Interpolation.calculateProgress


interpolateEasedProgress : (Float -> a -> a -> a) -> PropertyAnimation a -> a
interpolateEasedProgress =
    Interpolation.interpolateEasedProgress


interpolateFloat : Float -> Float -> Float -> Float
interpolateFloat =
    Interpolation.interpolateFloat
