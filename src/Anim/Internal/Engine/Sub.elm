module Anim.Internal.Engine.Sub exposing
    ( AnimBuilder
    , AnimEvent(..)
    , AnimMsg(..)
    , AnimState
    , ControlEvent(..)
    , EngineBuilder
    , FreezeProperty
    , TickEvent(..)
    , TimelineBuilder
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
    , freezeSkew
    , freezeTranslate
    , getColorPropertyCurrent
    , getColorPropertyEnd
    , getColorPropertyRange
    , getColorPropertyStart
    , getOpacityCurrent
    , getOpacityEnd
    , getOpacityRange
    , getOpacityStart
    , getPerspectiveOriginCurrent
    , getPerspectiveOriginEnd
    , getPerspectiveOriginRange
    , getPerspectiveOriginStart
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
    , getSkewCurrent
    , getSkewEnd
    , getSkewRange
    , getSkewStart
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
    , onResize
    , pause
    , reset
    , restart
    , resume
    , retarget
    , speed
    , spring
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
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Shared.PlayState as PlayState
import Anim.Internal.Engine.Shared.Resize as Resize
import Anim.Internal.Engine.Sub.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Sub.Animation as Animation exposing (Animation(..), PropertyAnimation)
import Anim.Internal.Engine.Sub.Animations as Animations
import Anim.Internal.Engine.Sub.Generator as Generator
import Anim.Internal.Engine.Sub.Interpolation as Interpolation
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Property.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin exposing (PerspectiveOrigin)
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Anim.Internal.Property.Size as Size exposing (Size)
import Anim.Internal.Property.Skew as Skew exposing (Skew)
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Anim.Internal.Resize.Builder as ResizeBuilder
import Anim.Resize exposing (Strategy(..))
import Browser.Events
import Dict
import Html
import Html.Attributes
import Motion.Easing exposing (Easing(..))
import Motion.Spring exposing (Spring)
import Set exposing (Set)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- TYPES
-- ============================================================


type AnimState
    = AnimState
        { builder : EngineBuilder
        , subscriptionsActive : Bool
        , pendingControlEvents : List ControlEvent
        }
        (AnimGroups AnimGroup)


type alias AnimBuilder mode =
    Builder.AnimBuilder mode


type alias TimelineBuilder engine =
    Builder.AnimBuilder (Builder.ForDocumentTimeline engine)


type alias EngineBuilder =
    TimelineBuilder Builder.ForSubEngine


type alias AnimGroupName =
    String



-- ============================================================
-- INITIALIZE
-- ============================================================


init : List (EngineBuilder -> EngineBuilder) -> AnimState
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


animate : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
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


{-| Like [animate](#animate), but inherits in-flight timing for any property
that is currently mid-animation (per-property). `continueFor` reads the
running set populated here; idle properties fall back to `for`-style snap
behaviour.
-}
retarget : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
retarget ((AnimState _ animGroups) as animState) build =
    animate animState
        (Builder.injectRunningProperties (extractRunningProperties animGroups) >> build)



-- ============================================================
-- RESIZE
-- ============================================================


{-| Adjust a group's in-flight properties to match a new bounding range
using the directives composed in a [`Anim.Resize.Builder.Builder`](Anim-Resize-Builder#Builder).

Properties without a directive are left alone. Axes set to `Nothing` are
left alone. If the group does not exist, no-op.

-}
onResize : AnimGroupName -> AnimState -> (ResizeBuilder.Builder -> ResizeBuilder.Builder) -> AnimState
onResize animGroupName ((AnimState _ _) as animState) buildResize =
    let
        builder =
            ResizeBuilder.build buildResize
    in
    case ResizeBuilder.getTranslate builder of
        Nothing ->
            animState

        Just { strategy, bounds } ->
            applyTranslateResize animGroupName strategy bounds animState


applyTranslateResize : AnimGroupName -> Resize.Strategy -> Resize.ResizeBounds -> AnimState -> AnimState
applyTranslateResize animGroupName strategy bounds (AnimState state animGroups) =
    if Resize.isEmpty bounds then
        AnimState state animGroups

    else
        case AnimGroups.get animGroupName animGroups of
            Nothing ->
                AnimState state animGroups

            Just animGroup ->
                let
                    isLooping =
                        case AnimGroup.getIterations animGroup of
                            Builder.Once ->
                                False

                            _ ->
                                True

                    isPaused =
                        AnimGroup.isPaused animGroup

                    updatedAnimations =
                        AnimGroup.getAnimations animGroup
                            |> Animations.map
                                (\_ anim ->
                                    case anim of
                                        Translate cfg ->
                                            Translate (resizeTranslate strategy bounds isLooping isPaused cfg)

                                        _ ->
                                            anim
                                )

                    updatedGroup =
                        AnimGroup.setAnimations updatedAnimations animGroup

                    updatedAnimGroups =
                        AnimGroups.insert animGroupName updatedGroup animGroups
                in
                AnimState
                    { state
                        | subscriptionsActive =
                            updatedAnimGroups
                                |> AnimGroups.groups
                                |> List.any AnimGroup.isRunning
                    }
                    updatedAnimGroups


{-| Resize the in-memory translate animation to match new bounds.
-}
resizeTranslate : Resize.Strategy -> Resize.ResizeBounds -> Bool -> Bool -> PropertyAnimation Translate -> PropertyAnimation Translate
resizeTranslate strategy bounds isLooping isPaused cfg =
    let
        oldStart =
            Translate.toRecord cfg.start

        oldEnd =
            Translate.toRecord cfg.end

        oldCurrent =
            cfg
                |> interpolateEasedProgress interpolateTranslate
                |> Translate.toRecord

        -- A one-shot animation that isn't actively progressing (completed or
        -- paused) should preserve the full new leg (`legStart` → `legEnd`)
        -- rather than collapsing `start` to `current`. Collapsing degenerates
        -- the Proportional formula on the *next* resize (oldRange shrinks to
        -- ~0, oldCurrent sits at oldStart, so the ball maps proportionally to
        -- `b.min` and teleports back to the top - even on sub-pixel layout
        -- wobble). Preserving the full leg also keeps Reset/Restart honest
        -- because they re-animate from the original `legStart`.
        treatAsSettled =
            (cfg.isComplete || isPaused) && not isLooping

        effectiveLooping =
            isLooping || treatAsSettled

        rx =
            Resize.applyAxis strategy effectiveLooping bounds.x oldStart.x oldEnd.x oldCurrent.x

        ry =
            Resize.applyAxis strategy effectiveLooping bounds.y oldStart.y oldEnd.y oldCurrent.y

        rz =
            Resize.applyAxis strategy effectiveLooping bounds.z oldStart.z oldEnd.z oldCurrent.z

        newStart =
            Translate.fromRecord { x = rx.start, y = ry.start, z = rz.start }

        newEnd =
            Translate.fromRecord { x = rx.end, y = ry.end, z = rz.end }

        -- The proportionally-remapped current position. Only used by the
        -- mid-flight one-shot branch as the new "continue from here" start;
        -- the complete branch snaps to `newEnd` and the paused/looping
        -- branches preserve the temporal progress ratio (so `current` is
        -- recomputed from elapsedMs at render time).
        newCurrent =
            Translate.fromRecord { x = rx.current, y = ry.current, z = rz.current }

        oldDistance =
            Translate.distance cfg.start cfg.end

        newLegDistance =
            Translate.distance newStart newEnd
    in
    if treatAsSettled then
        if cfg.isComplete then
            { cfg
                | start = newStart
                , end = newEnd
                , elapsedMs = cfg.totalDurationMs
                , isComplete = True
            }

        else
            -- Paused: preserve the full leg and the visual position of the
            -- ball along it. The exact derivation depends on strategy
            -- (see `preserveProgress`).
            preserveProgress
                { strategy = strategy
                , cfg = cfg
                , newStart = newStart
                , newEnd = newEnd
                , newCurrent = newCurrent
                , oldDistance = oldDistance
                , newLegDistance = newLegDistance
                }

    else if newLegDistance == 0 then
        { cfg
            | start = newStart
            , end = newEnd
            , elapsedMs = cfg.totalDurationMs
            , isComplete = True
        }

    else if isLooping then
        preserveProgress
            { strategy = strategy
            , cfg = cfg
            , newStart = newStart
            , newEnd = newEnd
            , newCurrent = newCurrent
            , oldDistance = oldDistance
            , newLegDistance = newLegDistance
            }

    else
        let
            -- One-shot: continue from current toward target.
            oneShotStart =
                newCurrent

            oneShotDistance =
                Translate.distance oneShotStart newEnd

            newDuration =
                if oldDistance > 0 && cfg.totalDurationMs > 0 then
                    (oneShotDistance / oldDistance) * cfg.totalDurationMs

                else
                    cfg.totalDurationMs
        in
        if oneShotDistance == 0 then
            { cfg
                | start = oneShotStart
                , end = newEnd
                , elapsedMs = cfg.totalDurationMs
                , isComplete = True
            }

        else
            { cfg
                | start = oneShotStart
                , end = newEnd
                , elapsedMs = 0
                , totalDurationMs = newDuration
                , isComplete = False
            }


{-| Update a translate animation that is preserving its full leg across a
resize - either looping (active leg-cycling) or paused (frozen mid-leg).

The derivation depends on the resize strategy:

  - `Proportional` preserves the **temporal progress ratio**
    (`elapsedMs / totalDurationMs`). Because eased progress is a function of
    that ratio, leaving the ratio alone makes the ball land at the same
    proportional, eased position along the new leg automatically - no
    easing inversion required. Both `elapsedMs` and `totalDurationMs` scale
    by the leg-length factor so resume-speed matches the new leg.

  - `Clamp` preserves the **literal `current` value** (its explicit promise:
    "keep the current value, just re-clamp the bounds"). Progress is
    derived by inverting the leg position linearly. This is exact for
    `Linear` easing; for non-linear easings the recovered `elapsedMs` is
    approximate but Clamp makes no eased-position guarantee, so the
    approximation is acceptable.

-}
preserveProgress :
    { strategy : Resize.Strategy
    , cfg : PropertyAnimation Translate
    , newStart : Translate
    , newEnd : Translate
    , newCurrent : Translate
    , oldDistance : Float
    , newLegDistance : Float
    }
    -> PropertyAnimation Translate
preserveProgress { strategy, cfg, newStart, newEnd, newCurrent, oldDistance, newLegDistance } =
    let
        scale =
            if oldDistance > 0 then
                newLegDistance / oldDistance

            else
                1

        newTotalDuration =
            if cfg.totalDurationMs > 0 then
                scale * cfg.totalDurationMs

            else
                cfg.totalDurationMs

        newElapsedMs =
            case strategy of
                Proportional ->
                    -- Preserve the temporal ratio.
                    scale * cfg.elapsedMs

                Clamp ->
                    -- Preserve `newCurrent` by inverting leg position
                    -- linearly. Exact for Linear easing; approximate for
                    -- non-linear easings (see doc comment).
                    if newLegDistance > 0 then
                        clamp 0 1 (Translate.distance newStart newCurrent / newLegDistance)
                            * newTotalDuration

                    else
                        0
    in
    { cfg
        | start = newStart
        , end = newEnd
        , totalDurationMs = newTotalDuration
        , elapsedMs = newElapsedMs
        , isComplete = False
    }


extractRunningProperties : AnimGroups AnimGroup -> Dict.Dict String (Set String)
extractRunningProperties =
    AnimGroups.foldl
        (\animGroupName animGroup acc ->
            if not (AnimGroup.isRunning animGroup) then
                acc

            else
                let
                    running =
                        AnimGroup.getAnimations animGroup
                            |> Animations.foldl
                                (\_ anim s ->
                                    if Animation.foldTiming .isComplete anim then
                                        s

                                    else
                                        Set.insert (Animation.toPropertyKey anim) s
                                )
                                Set.empty
                in
                if Set.isEmpty running then
                    acc

                else
                    Dict.insert animGroupName running acc
        )
        Dict.empty


extractElementCurrentStates : AnimGroup -> PropertyBaselines
extractElementCurrentStates =
    AnimGroup.getAnimations
        >> Animations.foldl (\_ -> extractPropertyCurrentState)
            PropertyBaselines.empty


extractPropertyCurrentState : Animation -> PropertyBaselines -> PropertyBaselines
extractPropertyCurrentState anim states =
    case anim of
        CustomProperty cssName unit a ->
            PropertyBaselines.setCustomProperty cssName (interpolateEasedProgress interpolateFloat a) unit states

        CustomColorProperty cssName a ->
            PropertyBaselines.setCustomColorProperty cssName (interpolateEasedProgress Color.interpolate a) states

        Opacity a ->
            PropertyBaselines.setOpacity (interpolateEasedProgress interpolateOpacity a) states

        PerspectiveOrigin a ->
            PropertyBaselines.setPerspectiveOrigin (interpolateEasedProgress interpolatePerspectiveOrigin a) states

        Rotate a ->
            PropertyBaselines.setRotate (interpolateEasedProgress interpolateRotate a) states

        Scale a ->
            PropertyBaselines.setScale (interpolateEasedProgress interpolateScale a) states

        Size a ->
            PropertyBaselines.setSize (interpolateEasedProgress interpolateSize a) states

        Skew a ->
            PropertyBaselines.setSkew (interpolateEasedProgress interpolateSkew a) states

        Translate a ->
            PropertyBaselines.setTranslate (interpolateEasedProgress interpolateTranslate a) states



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
                    -- `Animation.reverse` physically swaps each property's
                    -- start/end. To produce a true ping-pong we must swap on
                    -- every iteration boundary so the next leg plays in the
                    -- opposite direction to the leg that just finished.
                    True

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
        CustomProperty cssName unit a ->
            [ Html.Attributes.style cssName (String.fromFloat (interpolateEasedProgress interpolateFloat a) ++ unit) ]

        CustomColorProperty cssName a ->
            [ Html.Attributes.style cssName (Color.toCssString (interpolateEasedProgress Color.interpolate a)) ]

        Opacity a ->
            [ Html.Attributes.style "opacity" (String.fromFloat (Opacity.toFloat (interpolateEasedProgress interpolateOpacity a))) ]

        PerspectiveOrigin a ->
            [ Html.Attributes.style "perspective-origin" (PerspectiveOrigin.toCssString (interpolateEasedProgress interpolatePerspectiveOrigin a)) ]

        Rotate _ ->
            []

        Scale _ ->
            []

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

        Skew _ ->
            []

        Translate _ ->
            []



-- ============================================================
-- PLAYBACK
-- ============================================================


iterations : Int -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
iterations =
    Builder.iterations


loopForever : Builder.AnimBuilder mode -> Builder.AnimBuilder mode
loopForever =
    Builder.loopForever


alternate : Builder.AnimBuilder mode -> Builder.AnimBuilder mode
alternate =
    Builder.alternate



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
delay =
    Builder.delay


duration : Int -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
duration =
    Builder.duration


speed : Float -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
speed =
    Builder.speed



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
easing =
    Builder.easing



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
spring =
    Builder.spring



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


transformOrder : List TransformProperty -> EngineBuilder -> EngineBuilder
transformOrder =
    Builder.transformOrder



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


discreteEntry : String -> String -> EngineBuilder -> EngineBuilder
discreteEntry =
    Builder.discreteEntry


discreteExit : String -> String -> String -> EngineBuilder -> EngineBuilder
discreteExit =
    Builder.discreteExit



-- ============================================================
-- FREEZE
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


freezeSkew : FreezeProperty
freezeSkew =
    Builder.FreexeSkew


freezeAxes : List String -> List FreezeProperty -> EngineBuilder -> EngineBuilder
freezeAxes =
    Builder.freezeAxes



-- ============================================================
-- UNFREEZE
-- ============================================================


unfreezeAxes : List String -> List FreezeProperty -> EngineBuilder -> EngineBuilder
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


getBuilder : AnimState -> EngineBuilder
getBuilder (AnimState state _) =
    state.builder


getPropertyValue : String -> (Animation -> Maybe a) -> AnimGroupName -> AnimState -> Maybe a
getPropertyValue propertyKey valueExtractor animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (Animations.get propertyKey << AnimGroup.getAnimations)
        |> Maybe.andThen valueExtractor



-- ============================
-- CUSTOM PROPERTY
-- ============================


getPropertyRange : AnimGroupName -> String -> AnimState -> Maybe { start : Maybe Float, end : Float }
getPropertyRange animGroupName cssName =
    getBuilder >> Property.getCustomPropertyRange animGroupName cssName


getPropertyStart : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyStart animGroupName cssName =
    getBuilder >> Property.getCustomPropertyStart animGroupName cssName


getPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyEnd animGroupName cssName =
    getBuilder >> Property.getCustomPropertyEnd animGroupName cssName


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
    getBuilder >> Property.getCustomColorPropertyRange animGroupName cssName


getColorPropertyStart : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyStart animGroupName cssName =
    getBuilder >> Property.getCustomColorPropertyStart animGroupName cssName


getColorPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyEnd animGroupName cssName =
    getBuilder >> Property.getCustomColorPropertyEnd animGroupName cssName


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
-- PERSPECTIVE ORIGIN
-- ============================


getPerspectiveOriginRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getPerspectiveOriginRange animGroupName =
    getBuilder >> Property.getPerspectiveOriginRange animGroupName


getPerspectiveOriginStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getPerspectiveOriginStart animGroupName =
    getBuilder >> Property.getPerspectiveOriginStart animGroupName


getPerspectiveOriginEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getPerspectiveOriginEnd animGroupName =
    getBuilder >> Property.getPerspectiveOriginEnd animGroupName


getPerspectiveOriginCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getPerspectiveOriginCurrent =
    getPropertyValue "perspectiveOrigin"
        (\prop ->
            case prop of
                PerspectiveOrigin config ->
                    config
                        |> interpolateEasedProgress interpolatePerspectiveOrigin
                        |> PerspectiveOrigin.toRecord
                        |> Just

                _ ->
                    Nothing
        )


interpolatePerspectiveOrigin : Float -> PerspectiveOrigin -> PerspectiveOrigin -> PerspectiveOrigin
interpolatePerspectiveOrigin =
    Interpolation.interpolatePerspectiveOrigin



-- ============================
-- SKEW
-- ============================


getSkewRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getSkewRange animGroupName =
    getBuilder >> Property.getSkewRange animGroupName


getSkewStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewStart animGroupName =
    getBuilder >> Property.getSkewStart animGroupName


getSkewEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewEnd animGroupName =
    getBuilder >> Property.getSkewEnd animGroupName


getSkewCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewCurrent =
    getPropertyValue "skew"
        (\prop ->
            case prop of
                Skew config ->
                    config
                        |> interpolateEasedProgress interpolateSkew
                        |> Skew.toRecord
                        |> Just

                _ ->
                    Nothing
        )


interpolateSkew : Float -> Skew -> Skew -> Skew
interpolateSkew =
    Interpolation.interpolateSkew



-- ============================
-- TRANSLATE
-- ============================


getTranslateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange animGroupName state =
    case getRuntimeTranslate animGroupName state of
        Just cfg ->
            Just
                { start = Just (Translate.toRecord cfg.start)
                , end = Translate.toRecord cfg.end
                }

        Nothing ->
            (getBuilder >> Property.getTranslateRange animGroupName) state


getTranslateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart animGroupName state =
    case getRuntimeTranslate animGroupName state of
        Just cfg ->
            Just (Translate.toRecord cfg.start)

        Nothing ->
            (getBuilder >> Property.getTranslateStart animGroupName) state


getTranslateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd animGroupName state =
    case getRuntimeTranslate animGroupName state of
        Just cfg ->
            Just (Translate.toRecord cfg.end)

        Nothing ->
            (getBuilder >> Property.getTranslateEnd animGroupName) state


{-| Look up the live `PropertyAnimation Translate` for a group, if any.

Translate is the only property whose runtime state can diverge from the
builder snapshot (via [`onResize`](#onResize)), so its getters consult the
runtime first and fall back to the builder.

-}
getRuntimeTranslate : AnimGroupName -> AnimState -> Maybe (PropertyAnimation Translate)
getRuntimeTranslate animGroupName =
    getPropertyValue "translate"
        (\prop ->
            case prop of
                Translate cfg ->
                    Just cfg

                _ ->
                    Nothing
        )
        animGroupName


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
