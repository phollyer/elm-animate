module Anim.Internal.Engine.WAAPI exposing
    ( AnimBuilder
    , AnimEvent(..)
    , AnimMsg
    , AnimState
    , EngineBuilder
    , FreezeProperty
    , TimelineBuilder
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
    , fireAndForget
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
import Anim.Internal.Builder as Builder exposing (AnimationDirection(..))
import Anim.Internal.Builder.Opacity as Opacity
import Anim.Internal.Builder.Property as Property
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Builder.Rotate as Rotate
import Anim.Internal.Builder.Scale as Scale
import Anim.Internal.Builder.Size as Size
import Anim.Internal.Builder.Skew as Skew
import Anim.Internal.Builder.Translate as Translate
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.WAAPI.AnimGroup as AnimGroup exposing (AnimGroup, AnimationStatus, PropertyState)
import Anim.Internal.Engine.WAAPI.Encoder exposing (..)
import Anim.Internal.Engine.WAAPI.Generator as Generator
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Property.Custom as CustomProperty
import Anim.Internal.Property.CustomColor as CustomColorProperty
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Skew as Skew
import Anim.Internal.Property.Translate as Translate
import Anim.Internal.Resize.Builder as ResizeBuilder
import Anim.Resize exposing (Bounds, Strategy(..))
import Dict
import Html
import Html.Attributes
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Motion.Easing exposing (Easing(..))
import Motion.Spring exposing (Spring)
import Set exposing (Set)



-- ============================================================
-- TYPES
-- ============================================================


type AnimState msg
    = AnimState
        { subscriptionsActive : Bool
        , commandPort : Encode.Value -> Cmd msg
        , subscriptionPort : (Decode.Value -> msg) -> Sub msg
        , builder : EngineBuilder
        }
        (AnimGroups AnimGroup)


type alias AnimBuilder mode =
    Builder.AnimBuilder mode


type alias TimelineBuilder engine =
    Builder.AnimBuilder (Builder.ForDocumentTimeline engine)


type alias EngineBuilder =
    Builder.AnimBuilder (Builder.ForDocumentTimeline Builder.ForWAAPIEngine)


type alias AnimGroupName =
    String



-- ============================================================
-- INITIALIZE
-- ============================================================


init : (Encode.Value -> Cmd msg) -> ((Decode.Value -> msg) -> Sub msg) -> List (EngineBuilder -> EngineBuilder) -> AnimState msg
init commandPort subscriptionPort propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { builder = Builder.init []
                , subscriptionsActive = False
                , commandPort = commandPort
                , subscriptionPort = subscriptionPort
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
                , commandPort = commandPort
                , subscriptionPort = subscriptionPort
                }
                (AnimGroups.map initGroup animGroups)



-- ============================================================
-- TRIGGER
-- ============================================================


fireAndForget : (Encode.Value -> Cmd msg) -> (EngineBuilder -> EngineBuilder) -> Cmd msg
fireAndForget sendToPort pipeline =
    Builder.init [ pipeline ]
        |> Builder.process
        |> encodeProcessedData
        |> sendToPort


animate : AnimState msg -> (EngineBuilder -> EngineBuilder) -> ( AnimState msg, Cmd msg )
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
                        (AnimGroup.addPropertyStates animGroup existing)
                        acc

        processedAnimGroups =
            processed.groups
                |> AnimGroups.map generateAnimGroup
                |> AnimGroups.foldl insertAnimGroup animGroups
    in
    ( AnimState
        { state
            | builder =
                builder
                    |> Builder.addAnimationToHistory processed
                    |> Builder.mergeBaselines
                    |> Builder.clearAnimData
            , subscriptionsActive = True
        }
        processedAnimGroups
    , state.commandPort <|
        encode processedAnimGroups processed
    )


setSnapshot : AnimGroups AnimGroup -> AnimGroups { propertySnapshot : PropertyBaselines }
setSnapshot anims =
    AnimGroups.map (\_ anim -> { propertySnapshot = AnimGroup.getPropertySnapshot anim }) anims


{-| Like [animate](#animate), but inherits in-flight timing for any property
the engine currently reports as `Running` (per-property). Use when you want a
new build to "continue" a property mid-flight instead of starting fresh — for
example when a window resize fires repeatedly and you only want smooth
retargeting while the box is in motion.

`continueFor` reads the running set populated here; idle properties fall back
to `for`-style snap behaviour.

-}
retarget : AnimState msg -> (EngineBuilder -> EngineBuilder) -> ( AnimState msg, Cmd msg )
retarget ((AnimState _ animGroups) as animState) build =
    animate animState
        (Builder.injectRunningProperties (extractRunningProperties animGroups) >> build)


extractRunningProperties : AnimGroups AnimGroup -> Dict.Dict String (Set String)
extractRunningProperties =
    AnimGroups.foldl
        (\animGroupName animGroup acc ->
            let
                running =
                    AnimGroup.getPropertyStates animGroup
                        |> AnimGroups.toList
                        |> List.filterMap
                            (\( propKey, propState ) ->
                                if propState.status == AnimGroup.Running then
                                    Just propKey

                                else
                                    Nothing
                            )
                        |> Set.fromList
            in
            if Set.isEmpty running then
                acc

            else
                Dict.insert animGroupName running acc
        )
        Dict.empty



-- ============================================================
-- RESIZE
-- ============================================================


{-| Adjust the in-flight properties of every anim group named in the
builder to new bounding ranges, using the directives composed in a
[`Anim.Resize.Builder`](Anim-Resize#Builder).

Compatible with the Sub engine's `onResize`. For each property with a
directive, sends an appropriate `resize` command on the WAAPI port; the
JS side updates the running Web Animation in place (replacing keyframes,
updating timing, and setting `currentTime`) so the element continues
moving smoothly without restarting.

Groups with no in-flight directive-targeted property emit no command.
Multiple groups in a single call have their commands batched.

-}
onResize : AnimState msg -> (ResizeBuilder.Builder -> ResizeBuilder.Builder) -> ( AnimState msg, Cmd msg )
onResize animState buildResize =
    let
        builder =
            ResizeBuilder.build buildResize

        ( finalState, accCmds ) =
            List.foldl (applyGroupResize builder)
                ( animState, [] )
                (ResizeBuilder.groups builder)
    in
    ( finalState, Cmd.batch (List.reverse accCmds) )


applyGroupResize :
    ResizeBuilder.Builder
    -> AnimGroupName
    -> ( AnimState msg, List (Cmd msg) )
    -> ( AnimState msg, List (Cmd msg) )
applyGroupResize builder animGroupName ( animState, accCmds ) =
    let
        ( afterTranslate, translateCmd ) =
            case ResizeBuilder.getTranslate animGroupName builder of
                Nothing ->
                    ( animState, Cmd.none )

                Just { strategy, bounds } ->
                    applyTranslateResize animGroupName (fromStrategy strategy) bounds animState

        ( afterScale, scaleCmd ) =
            case ResizeBuilder.getScale animGroupName builder of
                Nothing ->
                    ( afterTranslate, Cmd.none )

                Just { strategy, bounds } ->
                    applyScaleResize animGroupName (fromStrategy strategy) bounds afterTranslate
    in
    ( afterScale, scaleCmd :: translateCmd :: accCmds )


applyTranslateResize : AnimGroupName -> Strategy -> Bounds -> AnimState msg -> ( AnimState msg, Cmd msg )
applyTranslateResize animGroupName strategy bounds ((AnimState state animGroups) as animState) =
    if ResizeBuilder.isEmpty bounds then
        ( animState, Cmd.none )

    else
        case computeResizePayload animGroupName strategy bounds animState of
            Nothing ->
                ( animState, Cmd.none )

            Just payload ->
                let
                    updatedAnimGroups =
                        AnimGroups.update animGroupName
                            (Maybe.map
                                (AnimGroup.setSnapshot payload.newSnapshot
                                    >> AnimGroup.setCurrentTranslateState
                                        { start = payload.command.start
                                        , end = payload.command.end
                                        , durationMs = payload.command.durationMs
                                        }
                                )
                            )
                            animGroups
                in
                ( AnimState state updatedAnimGroups
                , state.commandPort (encodeResize payload.command)
                )


computeResizePayload :
    AnimGroupName
    -> Strategy
    -> Bounds
    -> AnimState msg
    ->
        Maybe
            { command :
                { animGroupName : AnimGroupName
                , property : String
                , start : { x : Float, y : Float, z : Float }
                , end : { x : Float, y : Float, z : Float }
                , current : { x : Float, y : Float, z : Float }
                , durationMs : Float
                , currentTimeMs : Maybe Float
                , hasAnimationBaseline : Bool
                }
            , newSnapshot : PropertyBaselines
            }
computeResizePayload animGroupName strategy_ bounds (AnimState state animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen
            (\animGroup ->
                let
                    snapshot =
                        AnimGroup.getPropertySnapshot animGroup
                in
                PropertyBaselines.getTranslate snapshot
                    |> Maybe.andThen
                        (\currentTranslate ->
                            let
                                resolvedBaseline =
                                    resolveResizeBaseline animGroupName animGroup state.builder

                                hasAnimationBaseline =
                                    resolvedBaseline /= Nothing

                                baseline =
                                    resolvedBaseline
                                        |> Maybe.withDefault
                                            -- No animation config registered for this group's
                                            -- translate (init-only property). Synthesize a
                                            -- degenerate baseline from the current snapshot so
                                            -- `applyAxis` can clamp the value into the new bounds
                                            -- via its `oldRange == 0` branch. The snapshot update
                                            -- in `applyTranslateResize` causes `WAAPI.attributes`
                                            -- to re-render the new transform inline.
                                            { start = Translate.toRecord currentTranslate
                                            , end = Translate.toRecord currentTranslate
                                            , durationMs = 0
                                            }
                            in
                            let
                                iters =
                                    AnimGroup.getIterations animGroup

                                isLooping =
                                    case iters of
                                        Builder.Once ->
                                            False

                                        _ ->
                                            True

                                -- Mirror the Sub engine fix: a one-shot animation that
                                -- isn't actively progressing (completed or paused) must
                                -- preserve the *full* new leg (`legStart` -> `legEnd`)
                                -- rather than collapsing `start` to `current`. Collapsing
                                -- degenerates the Proportional formula on the next resize
                                -- (oldRange shrinks, oldCurrent sits at oldStart, the box
                                -- maps proportionally to `b.min` and teleports back to the
                                -- top - even on sub-pixel layout wobble). Preserving the
                                -- full leg also keeps Reset/Restart honest because they
                                -- re-animate from the original `legStart`.
                                treatAsSettled =
                                    (AnimGroup.isComplete animGroup
                                        || AnimGroup.isPaused animGroup
                                    )
                                        && not isLooping

                                effectiveLooping =
                                    isLooping || treatAsSettled

                                oldStart =
                                    baseline.start

                                oldEnd =
                                    baseline.end

                                oldCurrent =
                                    Translate.toRecord currentTranslate

                                strategy =
                                    toStrategy strategy_

                                rx =
                                    ResizeBuilder.applyAxis strategy effectiveLooping bounds.x oldStart.x oldEnd.x oldCurrent.x

                                ry =
                                    ResizeBuilder.applyAxis strategy effectiveLooping bounds.y oldStart.y oldEnd.y oldCurrent.y

                                rz =
                                    ResizeBuilder.applyAxis strategy effectiveLooping bounds.z oldStart.z oldEnd.z oldCurrent.z

                                newStart =
                                    { x = rx.start, y = ry.start, z = rz.start }

                                newEnd =
                                    { x = rx.end, y = ry.end, z = rz.end }

                                newCurrent =
                                    { x = rx.current, y = ry.current, z = rz.current }

                                noChange =
                                    translateRecordsEqual newStart oldStart
                                        && translateRecordsEqual newEnd oldEnd
                                        && translateRecordsEqual newCurrent oldCurrent

                                newDurationMs =
                                    scaleDurationForResize
                                        { oldStart = Translate.fromRecord oldStart
                                        , oldEnd = Translate.fromRecord oldEnd
                                        , newStart = Translate.fromRecord newStart
                                        , newEnd = Translate.fromRecord newEnd
                                        , oldDurationMs = baseline.durationMs
                                        }

                                currentTimeMs =
                                    case strategy of
                                        ResizeBuilder.Proportional ->
                                            if treatAsSettled then
                                                if AnimGroup.isComplete animGroup then
                                                    -- Completed one-shot: snap WAAPI past
                                                    -- the iteration end so the box stays
                                                    -- pinned at the new `legEnd`.
                                                    Just newDurationMs

                                                else
                                                    -- Paused one-shot: full leg preserved
                                                    -- by `effectiveLooping = True`. Seek
                                                    -- to the same in-iteration progress so
                                                    -- the eased visual position lands at
                                                    -- the proportionally-correct spot.
                                                    Just (AnimGroup.getProgress animGroup * newDurationMs)

                                            else if isLooping then
                                                -- Preserve full-iteration count + in-iteration
                                                -- progress so looping/alternate keep advancing
                                                -- through the right iteration after the resize.
                                                Just <|
                                                    (toFloat (AnimGroup.getCurrentIteration animGroup)
                                                        + AnimGroup.getProgress animGroup
                                                    )
                                                        * newDurationMs

                                            else
                                                -- Mid-flight one-shot: Resize.applyAxis collapsed
                                                -- the leg to (current -> end). Restart the easing
                                                -- curve from the new leg start so non-linear
                                                -- easings (e.g. BounceOut) don't snap mid-curve.
                                                Just 0

                                        ResizeBuilder.Clamp ->
                                            -- Let JS solve for the currentTime that places the
                                            -- box at the supplied `current` value (legacy linear
                                            -- inversion - exact for Linear easing, approximate
                                            -- for non-linear, matching Clamp's "preserve current
                                            -- value" promise).
                                            Nothing
                            in
                            if noChange then
                                Nothing

                            else
                                Just
                                    { command =
                                        { animGroupName = animGroupName
                                        , property = "translate"
                                        , start = newStart
                                        , end = newEnd
                                        , current = newCurrent
                                        , durationMs = newDurationMs
                                        , currentTimeMs = currentTimeMs
                                        , hasAnimationBaseline = hasAnimationBaseline
                                        }
                                    , newSnapshot =
                                        PropertyBaselines.setTranslate
                                            (Translate.fromRecord newCurrent)
                                            snapshot
                                    }
                        )
            )


{-| Rescale the leg duration so the box keeps the same speed (px/ms) when
the bounding range changes. Returns the original duration when either the
old or new leg distance is zero (no motion to scale against).

The JS side uses this duration as input to `effect.updateTiming`, then
preserves the animation's fractional `currentTime` so the visual progress
within the current iteration stays put across the resize. WAAPI itself
preserves `currentIteration` and the alternating-leg phase, so no
forward/reverse-leg math is needed here.

-}
scaleDurationForResize :
    { oldStart : Translate.Translate
    , oldEnd : Translate.Translate
    , newStart : Translate.Translate
    , newEnd : Translate.Translate
    , oldDurationMs : Float
    }
    -> Float
scaleDurationForResize r =
    let
        oldDistance =
            Translate.distance r.oldStart r.oldEnd

        newDistance =
            Translate.distance r.newStart r.newEnd
    in
    if oldDistance > 0 && newDistance > 0 && r.oldDurationMs > 0 then
        (newDistance / oldDistance) * r.oldDurationMs

    else
        r.oldDurationMs


{-| Per-axis equality on translate records. Used by `computeResizePayload`
to short-circuit a resize that would result in no visual change (e.g. a
viewport resize event whose new bounds match the running animation's
current bounds). Without this guard the library would `cancel()` the
running WAAPI animation and recreate it, which causes a visible jump on
alternate-loop animations.
-}
translateRecordsEqual : { x : Float, y : Float, z : Float } -> { x : Float, y : Float, z : Float } -> Bool
translateRecordsEqual a b =
    a.x == b.x && a.y == b.y && a.z == b.z


{-| Resolve the resize baseline for a group's translate. Prefers the
last-applied resize state (cached on the AnimGroup) so successive resizes
see the _current_ effective bounds & duration rather than the original
`animate()` configuration. Falls back to the builder config for the very
first resize on a freshly-animated group, since `animate` resets the
cached state on the new AnimGroup.
-}
resolveResizeBaseline :
    AnimGroupName
    -> AnimGroup
    -> Builder.AnimBuilder mode
    -> Maybe { start : { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float }, durationMs : Float }
resolveResizeBaseline animGroupName animGroup builder =
    case AnimGroup.getCurrentTranslateState animGroup of
        Just cached ->
            rejectDegenerateBaseline cached

        Nothing ->
            findCurrentTranslate animGroupName builder
                |> Maybe.map
                    (\cfg ->
                        { start =
                            cfg.start
                                |> Maybe.withDefault Translate.default
                                |> Translate.toRecord
                        , end = Translate.toRecord cfg.end
                        , durationMs = toFloat cfg.duration
                        }
                    )
                |> Maybe.andThen rejectDegenerateBaseline


findCurrentTranslate : AnimGroupName -> Builder.AnimBuilder mode -> Maybe (Builder.ProcessedAnimationConfig Translate.Translate)
findCurrentTranslate animGroupName builder =
    Builder.getAnimationConfigs animGroupName builder
        |> List.filterMap
            (\group ->
                group.properties
                    |> List.filterMap
                        (\p ->
                            case p of
                                Builder.ProcessedTranslateConfig cfg ->
                                    Just cfg

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )
        |> List.head


{-| Filter out "degenerate" resize baselines — ones whose `durationMs <= 0`
indicate no real animation timeline (e.g. a synthesized cached state for
an init-only `Scale.init` / `Translate.init` value). These are kept on
the AnimGroup so `applyAxis` can still clamp into new bounds, but they
must not signal `hasAnimationBaseline = True` to JS, which would trigger
a `currentTime` seek on the shared merged-transform animation and reset
co-running animations (e.g. a spinning Rotate) to the start.
-}
rejectDegenerateBaseline :
    { start : { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float }, durationMs : Float }
    -> Maybe { start : { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float }, durationMs : Float }
rejectDegenerateBaseline baseline =
    if baseline.durationMs <= 0 then
        Nothing

    else
        Just baseline


{-| Rewrite a `ProcessedTranslateConfig` so its `start`/`end`/`duration`
match the cached, resize-aware translate state captured by the most recent
`onResize`. Non-translate properties pass through unchanged. Used by
`restart` so a Restart triggered after a resize re-animates within the
current bounds rather than the original (pre-resize) ones.
-}
rebaseTranslateConfig :
    { start : { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float }, durationMs : Float }
    -> Builder.ProcessedPropertyConfig
    -> Builder.ProcessedPropertyConfig
rebaseTranslateConfig cached config =
    case config of
        Builder.ProcessedTranslateConfig cfg ->
            Builder.ProcessedTranslateConfig
                { cfg
                    | start = Just (Translate.fromRecord cached.start)
                    , end = Translate.fromRecord cached.end
                    , duration = round cached.durationMs
                }

        _ ->
            config


applyScaleResize : AnimGroupName -> Strategy -> Bounds -> AnimState msg -> ( AnimState msg, Cmd msg )
applyScaleResize animGroupName strategy bounds ((AnimState state animGroups) as animState) =
    if ResizeBuilder.isEmpty bounds then
        ( animState, Cmd.none )

    else
        case computeScaleResizePayload animGroupName strategy bounds animState of
            Nothing ->
                ( animState, Cmd.none )

            Just payload ->
                let
                    updatedAnimGroups =
                        AnimGroups.update animGroupName
                            (Maybe.map
                                (AnimGroup.setSnapshot payload.newSnapshot
                                    >> AnimGroup.setCurrentScaleState
                                        { start = payload.command.start
                                        , end = payload.command.end
                                        , durationMs = payload.command.durationMs
                                        }
                                )
                            )
                            animGroups
                in
                ( AnimState state updatedAnimGroups
                , state.commandPort (encodeResize payload.command)
                )


computeScaleResizePayload :
    AnimGroupName
    -> Strategy
    -> Bounds
    -> AnimState msg
    ->
        Maybe
            { command :
                { animGroupName : AnimGroupName
                , property : String
                , start : { x : Float, y : Float, z : Float }
                , end : { x : Float, y : Float, z : Float }
                , current : { x : Float, y : Float, z : Float }
                , durationMs : Float
                , currentTimeMs : Maybe Float
                , hasAnimationBaseline : Bool
                }
            , newSnapshot : PropertyBaselines
            }
computeScaleResizePayload animGroupName strategy_ bounds (AnimState state animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen
            (\animGroup ->
                let
                    snapshot =
                        AnimGroup.getPropertySnapshot animGroup
                in
                PropertyBaselines.getScale snapshot
                    |> Maybe.andThen
                        (\currentScale ->
                            let
                                resolvedBaseline =
                                    resolveScaleResizeBaseline animGroupName animGroup state.builder

                                hasAnimationBaseline =
                                    resolvedBaseline /= Nothing

                                baseline =
                                    resolvedBaseline
                                        |> Maybe.withDefault
                                            -- No animation config registered for this group's
                                            -- scale (init-only property). Synthesize a degenerate
                                            -- baseline from the current snapshot so `applyAxis`
                                            -- can clamp the value into the new bounds via its
                                            -- `oldRange == 0` branch. The snapshot update in
                                            -- `applyScaleResize` causes `WAAPI.attributes` to
                                            -- re-render the new transform inline.
                                            { start = Scale.toRecord currentScale
                                            , end = Scale.toRecord currentScale
                                            , durationMs = 0
                                            }
                            in
                            let
                                iters =
                                    AnimGroup.getIterations animGroup

                                isLooping =
                                    case iters of
                                        Builder.Once ->
                                            False

                                        _ ->
                                            True

                                treatAsSettled =
                                    (AnimGroup.isComplete animGroup
                                        || AnimGroup.isPaused animGroup
                                    )
                                        && not isLooping

                                effectiveLooping =
                                    isLooping || treatAsSettled

                                oldStart =
                                    baseline.start

                                oldEnd =
                                    baseline.end

                                oldCurrent =
                                    Scale.toRecord currentScale

                                strategy =
                                    toStrategy strategy_

                                rx =
                                    ResizeBuilder.applyAxis strategy effectiveLooping bounds.x oldStart.x oldEnd.x oldCurrent.x

                                ry =
                                    ResizeBuilder.applyAxis strategy effectiveLooping bounds.y oldStart.y oldEnd.y oldCurrent.y

                                rz =
                                    ResizeBuilder.applyAxis strategy effectiveLooping bounds.z oldStart.z oldEnd.z oldCurrent.z

                                newStart =
                                    { x = rx.start, y = ry.start, z = rz.start }

                                newEnd =
                                    { x = rx.end, y = ry.end, z = rz.end }

                                newCurrent =
                                    { x = rx.current, y = ry.current, z = rz.current }

                                noChange =
                                    translateRecordsEqual newStart oldStart
                                        && translateRecordsEqual newEnd oldEnd
                                        && translateRecordsEqual newCurrent oldCurrent

                                newDurationMs =
                                    scaleScaleDurationForResize
                                        { oldStart = Scale.fromRecord oldStart
                                        , oldEnd = Scale.fromRecord oldEnd
                                        , newStart = Scale.fromRecord newStart
                                        , newEnd = Scale.fromRecord newEnd
                                        , oldDurationMs = baseline.durationMs
                                        }

                                currentTimeMs =
                                    case strategy of
                                        ResizeBuilder.Proportional ->
                                            if treatAsSettled then
                                                if AnimGroup.isComplete animGroup then
                                                    Just newDurationMs

                                                else
                                                    Just (AnimGroup.getProgress animGroup * newDurationMs)

                                            else if isLooping then
                                                Just <|
                                                    (toFloat (AnimGroup.getCurrentIteration animGroup)
                                                        + AnimGroup.getProgress animGroup
                                                    )
                                                        * newDurationMs

                                            else
                                                Just 0

                                        ResizeBuilder.Clamp ->
                                            Nothing
                            in
                            if noChange then
                                Nothing

                            else
                                Just
                                    { command =
                                        { animGroupName = animGroupName
                                        , property = "scale"
                                        , start = newStart
                                        , end = newEnd
                                        , current = newCurrent
                                        , durationMs = newDurationMs
                                        , currentTimeMs = currentTimeMs
                                        , hasAnimationBaseline = hasAnimationBaseline
                                        }
                                    , newSnapshot =
                                        PropertyBaselines.setScale
                                            (Scale.fromRecord newCurrent)
                                            snapshot
                                    }
                        )
            )


fromStrategy : ResizeBuilder.Strategy -> Strategy
fromStrategy strategy =
    case strategy of
        ResizeBuilder.Clamp ->
            Clamp

        ResizeBuilder.Proportional ->
            Proportional


toStrategy : Strategy -> ResizeBuilder.Strategy
toStrategy strategy =
    case strategy of
        Clamp ->
            ResizeBuilder.Clamp

        Proportional ->
            ResizeBuilder.Proportional


{-| Scale's mirror of [`scaleDurationForResize`](#scaleDurationForResize).
-}
scaleScaleDurationForResize :
    { oldStart : Scale.Scale
    , oldEnd : Scale.Scale
    , newStart : Scale.Scale
    , newEnd : Scale.Scale
    , oldDurationMs : Float
    }
    -> Float
scaleScaleDurationForResize r =
    let
        oldDistance =
            Scale.distance r.oldStart r.oldEnd

        newDistance =
            Scale.distance r.newStart r.newEnd
    in
    if oldDistance > 0 && newDistance > 0 && r.oldDurationMs > 0 then
        (newDistance / oldDistance) * r.oldDurationMs

    else
        r.oldDurationMs


resolveScaleResizeBaseline :
    AnimGroupName
    -> AnimGroup
    -> Builder.AnimBuilder mode
    -> Maybe { start : { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float }, durationMs : Float }
resolveScaleResizeBaseline animGroupName animGroup builder =
    case AnimGroup.getCurrentScaleState animGroup of
        Just cached ->
            rejectDegenerateBaseline cached

        Nothing ->
            findCurrentScale animGroupName builder
                |> Maybe.map
                    (\cfg ->
                        { start =
                            cfg.start
                                |> Maybe.withDefault Scale.default
                                |> Scale.toRecord
                        , end = Scale.toRecord cfg.end
                        , durationMs = toFloat cfg.duration
                        }
                    )
                |> Maybe.andThen rejectDegenerateBaseline


findCurrentScale : AnimGroupName -> Builder.AnimBuilder mode -> Maybe (Builder.ProcessedAnimationConfig Scale.Scale)
findCurrentScale animGroupName builder =
    Builder.getAnimationConfigs animGroupName builder
        |> List.filterMap
            (\group ->
                group.properties
                    |> List.filterMap
                        (\p ->
                            case p of
                                Builder.ProcessedScaleConfig cfg ->
                                    Just cfg

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )
        |> List.head


{-| Scale's mirror of [`rebaseTranslateConfig`](#rebaseTranslateConfig).
-}
rebaseScaleConfig :
    { start : { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float }, durationMs : Float }
    -> Builder.ProcessedPropertyConfig
    -> Builder.ProcessedPropertyConfig
rebaseScaleConfig cached config =
    case config of
        Builder.ProcessedScaleConfig cfg ->
            Builder.ProcessedScaleConfig
                { cfg
                    | start = Just (Scale.fromRecord cached.start)
                    , end = Scale.fromRecord cached.end
                    , duration = round cached.durationMs
                }

        _ ->
            config



-- ============================================================
-- EVENTS
-- ============================================================


type AnimEvent
    = Started AnimGroupName
    | Ended AnimGroupName
    | Cancelled AnimGroupName Float
    | Restarted AnimGroupName
    | Paused AnimGroupName Float
    | Resumed AnimGroupName
    | Iteration AnimGroupName Int
    | Progress AnimGroupName Float
    | AnimError String



-- ============================================================
-- UPDATE
-- ============================================================


type AnimMsg
    = JavascriptUpdate Decode.Value


update : AnimMsg -> AnimState msg -> ( AnimState msg, Maybe AnimEvent )
update msg ((AnimState state animGroups) as animState) =
    case msg of
        JavascriptUpdate jsonValue ->
            case Decode.decodeValue (Decode.field "type" Decode.string) jsonValue of
                Ok "animationUpdate" ->
                    -- Ignore events from scroll/view-driven engines — they are handled
                    -- by ScrollTimeline.update and ViewTimeline.update respectively.
                    let
                        engineField =
                            Decode.decodeValue (Decode.field "engine" Decode.string) jsonValue
                    in
                    case engineField of
                        Ok "scrollTimeline" ->
                            ( animState, Nothing )

                        Ok "viewTimeline" ->
                            ( animState, Nothing )

                        _ ->
                            case Decode.decodeValue animEventDecoder jsonValue of
                                Ok animEvent ->
                                    ( handleLifecycleEvent animEvent animState
                                    , Just animEvent
                                    )

                                Err error ->
                                    ( animState
                                    , Just <|
                                        AnimError <|
                                            "Failed to decode animation event: "
                                                ++ Decode.errorToString error
                                    )

                Ok "propertyUpdate" ->
                    case Decode.decodeValue animationUpdateDecoder jsonValue of
                        Ok animUpdate ->
                            let
                                updatedAnimations =
                                    AnimGroups.update animUpdate.animGroupName
                                        (Maybe.map (updateAnimGroup animUpdate))
                                        animGroups

                                -- Update global isRunning based on animation status
                                hasRunningAnimations =
                                    AnimGroups.groups updatedAnimations
                                        |> List.any
                                            (AnimGroup.getPropertyStates
                                                >> AnimGroups.groups
                                                >> List.any (\prop -> prop.status == AnimGroup.Running)
                                            )
                            in
                            ( AnimState { state | subscriptionsActive = hasRunningAnimations } updatedAnimations
                            , Just (Progress animUpdate.animGroupName animUpdate.progress)
                            )

                        Err error ->
                            ( animState
                            , Just (AnimError ("Failed to decode animation update: " ++ Decode.errorToString error))
                            )

                Ok unknown ->
                    ( animState
                    , Just (AnimError ("Unknown message type: " ++ unknown))
                    )

                Err error ->
                    ( animState
                    , Just (AnimError ("Unknown message type: " ++ Decode.errorToString error))
                    )


handleLifecycleEvent : AnimEvent -> AnimState msg -> AnimState msg
handleLifecycleEvent animEvent (AnimState state animGroups) =
    let
        animGroupName =
            animEventGroupName animEvent

        newStatus =
            animEventToStatus animEvent

        applyIteration : AnimGroup -> AnimGroup
        applyIteration =
            case animEvent of
                Iteration _ iter ->
                    AnimGroup.setCurrentIteration iter

                _ ->
                    identity

        updatedAnimGroups =
            AnimGroups.update animGroupName
                (Maybe.map
                    (AnimGroup.setStatus newStatus
                        >> AnimGroup.setProgress
                            (case animEvent of
                                Paused _ progress ->
                                    progress

                                Cancelled _ progress ->
                                    progress

                                Progress _ progress ->
                                    progress

                                _ ->
                                    0
                            )
                        >> applyIteration
                    )
                )
                animGroups
    in
    AnimState
        { state
            | subscriptionsActive =
                AnimGroups.groups updatedAnimGroups
                    |> List.any AnimGroup.isRunning
        }
        updatedAnimGroups


updateAnimGroup : AnimationUpdate -> AnimGroup -> AnimGroup
updateAnimGroup animUpdate animGroup =
    let
        buildProp : (AnimationUpdate -> Maybe a) -> (b -> PropertyBaselines -> PropertyBaselines) -> (a -> b) -> PropertyBaselines -> PropertyBaselines
        buildProp propFn setterFn converterFn b =
            case propFn animUpdate of
                Just val ->
                    setterFn (converterFn val) b

                Nothing ->
                    b

        updateStatus : String -> PropertyState -> PropertyState
        updateStatus propType propAnim =
            case AnimGroups.get propType animUpdate.propertyVersions of
                Nothing ->
                    propAnim

                Just currentVersion ->
                    if currentVersion == propAnim.version then
                        { propAnim
                            | status =
                                if animUpdate.isAnimating then
                                    AnimGroup.Running

                                else
                                    AnimGroup.Complete
                        }

                    else
                        propAnim
    in
    animGroup
        |> AnimGroup.setProgress animUpdate.progress
        |> AnimGroup.setPropertyStates (AnimGroups.map updateStatus (AnimGroup.getPropertyStates animGroup))
        |> AnimGroup.setSnapshot
            (animGroup
                |> AnimGroup.getPropertySnapshot
                |> buildProp .opacity PropertyBaselines.setOpacity Opacity.fromFloat
                |> buildProp .perspectiveOrigin PropertyBaselines.setPerspectiveOrigin perspectiveOriginFromRecord
                |> buildProp .rotate PropertyBaselines.setRotate Rotate.fromRecord
                |> buildProp .scale PropertyBaselines.setScale Scale.fromRecord
                |> buildProp .size PropertyBaselines.setSize Size.fromRecord
                |> buildProp .translate PropertyBaselines.setTranslate Translate.fromRecord
                |> PropertyBaselines.updateCustomProperties animUpdate.customProperties
                |> PropertyBaselines.updateCustomColorProperties animUpdate.customColorProperties
            )


{-| Decoder for AnimEvent from lifecycle events.
-}
animEventDecoder : Decode.Decoder AnimEvent
animEventDecoder =
    Decode.map3 statusToAnimEvent
        (Decode.oneOf [ Decode.at [ "payload", "animGroup" ] Decode.string, Decode.at [ "payload", "elementId" ] Decode.string ])
        (Decode.at [ "payload", "status" ] Decode.string)
        (Decode.at [ "payload", "progress" ] Decode.float)


{-| Map a decoded status string to the appropriate AnimEvent constructor.
-}
statusToAnimEvent : String -> String -> Float -> AnimEvent
statusToAnimEvent animGroupName status progress =
    case status of
        "started" ->
            Started animGroupName

        "paused" ->
            Paused animGroupName progress

        "resumed" ->
            Resumed animGroupName

        "completed" ->
            Ended animGroupName

        "cancelled" ->
            Cancelled animGroupName progress

        "stopped" ->
            Ended animGroupName

        "reset" ->
            Cancelled animGroupName progress

        "restarted" ->
            Restarted animGroupName

        "iteration" ->
            Iteration animGroupName (round progress)

        invalid ->
            AnimError ("Unknown status: " ++ invalid)


animEventGroupName : AnimEvent -> String
animEventGroupName animEvent =
    case animEvent of
        Started name ->
            name

        Ended name ->
            name

        Cancelled name _ ->
            name

        Restarted name ->
            name

        Paused name _ ->
            name

        Resumed name ->
            name

        Iteration name _ ->
            name

        Progress name _ ->
            name

        AnimError _ ->
            ""


animEventToStatus : AnimEvent -> AnimationStatus
animEventToStatus animEvent =
    case animEvent of
        Started _ ->
            AnimGroup.Running

        Ended _ ->
            AnimGroup.Complete

        Cancelled _ _ ->
            AnimGroup.Complete

        Restarted _ ->
            AnimGroup.Running

        Paused _ _ ->
            AnimGroup.Paused

        Resumed _ ->
            AnimGroup.Running

        Iteration _ _ ->
            AnimGroup.Running

        Progress _ _ ->
            AnimGroup.Running

        AnimError _ ->
            AnimGroup.Complete



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


subscriptions : (AnimMsg -> msg) -> AnimState msg -> Sub msg
subscriptions toMsg (AnimState state _) =
    state.subscriptionPort <|
        (toMsg << JavascriptUpdate)



-- ============================================================
-- VIEW
-- ============================================================


{-| Get the list of HTML attributes to apply to an element for a given animation group.

The `data-anim-target` attribute allows the JavaScript companion to find the
element without requiring an HTML `id`. It is always present, even when no
animation is active, so the element is discoverable as soon as an animation
is triggered.

This also ensures initial values set via `init` are rendered synchronously,
avoiding a flash of unstyled content before JavaScript processes the port command.

-}
attributes : AnimGroupName -> AnimState msg -> List (Html.Attribute msg)
attributes animGroupName (AnimState _ data) =
    let
        dataAttr =
            Html.Attributes.attribute "data-anim-target" animGroupName
    in
    case AnimGroups.get animGroupName data of
        Nothing ->
            [ dataAttr ]

        Just animGroup ->
            let
                snapshot =
                    AnimGroup.getPropertySnapshot animGroup

                propertyStates =
                    AnimGroup.getPropertyStates animGroup

                -- A property key is "JS-owned" once it has an entry in
                -- `propertyStates`. `Generator.init` only writes to the
                -- snapshot, leaving `propertyStates` empty for that key, so
                -- `init`-only properties remain Elm-owned. `WAAPI.animate`
                -- adds an entry, flipping ownership to JS for the lifetime
                -- of the group (JS `commitAnimatedStyles` keeps the visual
                -- after the animation finishes).
                isElmOwned propType =
                    not (AnimGroups.member propType propertyStates)

                simpleStyles =
                    List.filterMap identity
                        [ if isElmOwned "opacity" then
                            PropertyBaselines.getOpacity snapshot
                                |> Maybe.map (\o -> Html.Attributes.style "opacity" (Opacity.toString o))

                          else
                            Nothing
                        , if isElmOwned "perspectiveOrigin" then
                            PropertyBaselines.getPerspectiveOrigin snapshot
                                |> Maybe.map (\po -> Html.Attributes.style "perspective-origin" (PerspectiveOrigin.toCssString po))

                          else
                            Nothing
                        ]

                sizeStyles =
                    if isElmOwned "size" then
                        PropertyBaselines.getSize snapshot
                            |> Maybe.map
                                (\s ->
                                    [ Html.Attributes.style "width" (Size.widthToCssString s)
                                    , Html.Attributes.style "height" (Size.heightToCssString s)
                                    ]
                                )
                            |> Maybe.withDefault []

                    else
                        []

                customPropertyStyles =
                    PropertyBaselines.getAllCustomProperties snapshot
                        |> List.filter (\( name, _ ) -> isElmOwned ("custom:" ++ name))
                        |> List.map (\( name, cssValue ) -> Html.Attributes.style name cssValue)

                customColorPropertyStyles =
                    PropertyBaselines.getAllCustomColorProperties snapshot
                        |> List.filter (\( name, _ ) -> isElmOwned ("customColor:" ++ name))
                        |> List.map (\( name, color ) -> Html.Attributes.style name (Color.toCssString color))

                -- The CSS `transform` slot is monolithic: only one inline
                -- value can exist. If any transform sub-property is
                -- JS-owned, JS owns the whole slot; Elm must not emit
                -- `transform` at all, otherwise it would clobber the
                -- JS-managed value for the other sub-properties.
                transformOwnedByElm =
                    List.all isElmOwned [ "translate", "rotate", "scale", "skew" ]

                transformStyles =
                    if transformOwnedByElm then
                        buildTransformStyles (AnimGroup.getTransformOrder animGroup) snapshot

                    else
                        []
            in
            dataAttr
                :: transformStyles
                ++ simpleStyles
                ++ sizeStyles
                ++ customPropertyStyles
                ++ customColorPropertyStyles
                ++ discreteEntryStyles animGroup
                ++ discreteExitStyles animGroup


buildTransformStyles : List TransformProperty -> PropertyBaselines -> List (Html.Attribute msg)
buildTransformStyles order snapshot =
    let
        translatePart =
            PropertyBaselines.getTranslate snapshot
                |> Maybe.map Translate.toCssString
                |> Maybe.withDefault ""

        rotatePart =
            PropertyBaselines.getRotate snapshot
                |> Maybe.map Rotate.toCssString
                |> Maybe.withDefault ""

        scalePart =
            PropertyBaselines.getScale snapshot
                |> Maybe.map Scale.toCssString
                |> Maybe.withDefault ""

        skewPart =
            PropertyBaselines.getSkew snapshot
                |> Maybe.map Skew.toCssString
                |> Maybe.withDefault ""

        transformString =
            order
                |> List.map (transformOrderToPart translatePart rotatePart skewPart scalePart)
                |> List.filter (not << String.isEmpty)
                |> String.join " "
    in
    if String.isEmpty transformString then
        []

    else
        [ Html.Attributes.style "transform" transformString ]


{-| Convert a TransformProperty to its corresponding CSS string part.
-}
transformOrderToPart : String -> String -> String -> String -> TransformProperty -> String
transformOrderToPart translatePart rotatePart skewPart scalePart order =
    case order of
        TransformProperty.Translate ->
            translatePart

        TransformProperty.Rotate ->
            rotatePart

        TransformProperty.Skew ->
            skewPart

        TransformProperty.Scale ->
            scalePart


discreteEntryStyles : AnimGroup -> List (Html.Attribute msg)
discreteEntryStyles =
    AnimGroup.getDiscreteEntry
        >> Dict.toList
        >> List.map (\( prop, value ) -> Html.Attributes.style prop value)


discreteExitStyles : AnimGroup -> List (Html.Attribute msg)
discreteExitStyles animGroup =
    animGroup
        |> AnimGroup.getDiscreteExit
        |> Dict.toList
        |> List.map
            (\( prop, { from, to } ) ->
                if AnimGroup.isComplete animGroup then
                    Html.Attributes.style prop to

                else
                    Html.Attributes.style prop from
            )



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


stop : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
stop animGroupName (AnimState state animGroups) =
    let
        endStates =
            Builder.getCurrentAnimationConfig animGroupName state.builder
                |> Maybe.map (.properties >> Generator.propertyBounds >> .end)
                |> Maybe.withDefault PropertyBaselines.empty

        updatedElementAnimations =
            AnimGroups.update animGroupName
                (Maybe.map
                    (\anim ->
                        AnimGroup.setSnapshot
                            (PropertyBaselines.merge
                                (AnimGroup.getPropertySnapshot anim)
                                endStates
                            )
                            anim
                    )
                )
                animGroups
    in
    ( AnimState state updatedElementAnimations
    , state.commandPort <|
        encodeCommandWithProperties "stop" animGroupName Nothing
    )


pause : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
pause animGroupName (AnimState state animGroups) =
    ( AnimState state animGroups
    , state.commandPort <|
        encodeCommandWithProperties "pause" animGroupName Nothing
    )


reset : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
reset animGroupName animState =
    resetSingleKey animGroupName animState


resetSingleKey : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
resetSingleKey animGroupName (AnimState state animGroups) =
    case Builder.getCurrentAnimationConfig animGroupName state.builder of
        Nothing ->
            ( AnimState state animGroups, Cmd.none )

        Just { properties } ->
            let
                -- Extract start and end states from the animation history
                states =
                    Generator.propertyBounds properties

                startStates =
                    states.start

                -- Get properties that were in the original animation
                animatedPropertyTypes =
                    List.map Generator.propertyTypeString properties

                resetBuilder =
                    Builder.init []
                        |> Builder.duration 0
                        |> Builder.easing Linear
                        |> Builder.for animGroupName
                        |> resetProperties animGroupName properties startStates

                processedData =
                    Builder.process resetBuilder
            in
            case AnimGroups.get animGroupName animGroups of
                Nothing ->
                    -- No tracking entry, create one with property versions
                    let
                        newProperties =
                            animatedPropertyTypes
                                |> List.map (\propType -> ( propType, { version = 1, status = AnimGroup.NotStarted } ))
                                |> AnimGroups.fromList

                        newAnimGroup =
                            AnimGroup.init
                                |> AnimGroup.setSnapshot startStates
                                |> AnimGroup.setPropertyStates newProperties

                        updatedElementAnimations =
                            AnimGroups.insert animGroupName newAnimGroup animGroups

                        updatedAnimState =
                            AnimState
                                { state | subscriptionsActive = False }
                                updatedElementAnimations
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encode updatedElementAnimations processedData
                    )

                Just animGroup ->
                    -- Existing tracking entry, increment versions for reset properties
                    let
                        updatedPropertyStates =
                            animGroup
                                |> AnimGroup.bumpPropertyVersions animatedPropertyTypes
                                |> AnimGroup.getPropertyStates

                        resetAnimGroup =
                            animGroup
                                |> AnimGroup.setSnapshot startStates
                                |> AnimGroup.setPropertyStates updatedPropertyStates
                                |> AnimGroup.setProgress 0

                        updatedAnimGroup =
                            AnimGroups.insert animGroupName resetAnimGroup animGroups
                    in
                    ( AnimState
                        { state
                            | subscriptionsActive =
                                AnimGroups.groups updatedAnimGroup
                                    |> List.any AnimGroup.isRunning
                        }
                        updatedAnimGroup
                    , state.commandPort <|
                        encode updatedAnimGroup processedData
                    )


restart : String -> AnimState msg -> ( AnimState msg, Cmd msg )
restart animGroup animState =
    restartSingleKey animGroup animState


restartSingleKey : String -> AnimState msg -> ( AnimState msg, Cmd msg )
restartSingleKey resolvedKey (AnimState state animGroups) =
    case Builder.getCurrentAnimationConfig resolvedKey state.builder of
        Nothing ->
            ( AnimState state animGroups, Cmd.none )

        Just processedData ->
            -- Get properties that are being restarted
            let
                restartedPropertyTypes =
                    processedData.properties
                        |> List.map Generator.propertyTypeString

                startStates =
                    (Generator.propertyBounds processedData.properties).start
            in
            case AnimGroups.get resolvedKey animGroups of
                Nothing ->
                    -- No tracking entry exists, create one with property versions
                    let
                        newProperties =
                            restartedPropertyTypes
                                |> List.map (\propType -> ( propType, { version = 1, status = AnimGroup.NotStarted } ))
                                |> AnimGroups.fromList

                        newAnimGroup =
                            AnimGroup.init
                                |> AnimGroup.setSnapshot startStates
                                |> AnimGroup.setPropertyStates newProperties

                        updatedElementAnimations =
                            AnimGroups.insert resolvedKey newAnimGroup animGroups

                        updatedAnimState =
                            AnimState
                                { state | subscriptionsActive = True }
                                updatedElementAnimations
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeRestart
                            (AnimGroup.getIterations newAnimGroup)
                            (AnimGroup.getAnimationDirection newAnimGroup)
                            updatedElementAnimations
                            (AnimGroups.singleton resolvedKey processedData)
                    )

                Just animGroup ->
                    -- Update existing entry, incrementing versions for restarted properties
                    let
                        -- A previous resize may have shifted the translate
                        -- bounds since the original `animate` call. The
                        -- cached translate state is the resize-aware truth
                        -- (computed via `Resize.applyAxis` and stored on the
                        -- group); use it to override the stale `start`/`end`/
                        -- `duration` baked into `processedData`, otherwise
                        -- Restart re-animates to the original (pre-resize)
                        -- target.
                        cachedTranslate =
                            AnimGroup.getCurrentTranslateState animGroup

                        cachedScale =
                            AnimGroup.getCurrentScaleState animGroup

                        rebasedProcessedData =
                            let
                                afterTranslate =
                                    case cachedTranslate of
                                        Just cached ->
                                            { processedData
                                                | properties =
                                                    List.map (rebaseTranslateConfig cached) processedData.properties
                                            }

                                        Nothing ->
                                            processedData
                            in
                            case cachedScale of
                                Just cached ->
                                    { afterTranslate
                                        | properties =
                                            List.map (rebaseScaleConfig cached) afterTranslate.properties
                                    }

                                Nothing ->
                                    afterTranslate

                        rebasedStartStates =
                            (Generator.propertyBounds rebasedProcessedData.properties).start

                        updatedProperties =
                            restartedPropertyTypes
                                |> List.foldl
                                    (\propType acc ->
                                        let
                                            newVersion =
                                                animGroup
                                                    |> AnimGroup.getPropertyStates
                                                    |> AnimGroups.get propType
                                                    |> Maybe.map .version
                                                    |> Maybe.map ((+) 1)
                                                    |> Maybe.withDefault 1
                                        in
                                        AnimGroups.insert propType
                                            { version = newVersion, status = AnimGroup.NotStarted }
                                            acc
                                    )
                                    (AnimGroup.getPropertyStates animGroup)

                        resetElementAnimation =
                            animGroup
                                |> AnimGroup.setSnapshot rebasedStartStates
                                |> AnimGroup.setPropertyStates updatedProperties
                                |> AnimGroup.setProgress 0

                        updatedElementAnimations =
                            AnimGroups.insert resolvedKey resetElementAnimation animGroups

                        updatedAnimState =
                            AnimState
                                { state | subscriptionsActive = True }
                                updatedElementAnimations
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeRestart
                            (AnimGroup.getIterations animGroup)
                            (AnimGroup.getAnimationDirection animGroup)
                            updatedElementAnimations
                            (AnimGroups.singleton resolvedKey rebasedProcessedData)
                    )


resume : String -> AnimState msg -> ( AnimState msg, Cmd msg )
resume animGroup (AnimState state animGroups) =
    ( AnimState state animGroups
    , state.commandPort <|
        encodeCommandWithProperties "resume" animGroup Nothing
    )


resetProperties : String -> List Builder.ProcessedPropertyConfig -> PropertyBaselines -> EngineBuilder -> EngineBuilder
resetProperties animGroupName properties startStates =
    let
        -- Use the actual stored start states to reset each property that was animated
        buildFromStartState : (PropertyBaselines -> Maybe a) -> (a -> EngineBuilder -> EngineBuilder) -> EngineBuilder -> EngineBuilder
        buildFromStartState accessor builderFn animBuilder =
            case accessor startStates of
                Just start ->
                    builderFn start animBuilder

                Nothing ->
                    animBuilder

        opacityBuilder start =
            Opacity.for animGroupName
                >> Opacity.to start
                >> Opacity.build

        rotateBuilder start =
            Rotate.for animGroupName
                >> Rotate.to start
                >> Rotate.build

        scaleBuilder start =
            Scale.for animGroupName
                >> Scale.to start
                >> Scale.build

        sizeBuilder start =
            Size.for animGroupName
                >> Size.to start
                >> Size.build

        translateBuilder start =
            Translate.for animGroupName
                >> Translate.to start
                >> Translate.build

        buildCustomFromStartState : Builder.ProcessedPropertyConfig -> (EngineBuilder -> EngineBuilder)
        buildCustomFromStartState propertyConfig =
            case propertyConfig of
                Builder.ProcessedCustomPropertyConfig cssName unit _ ->
                    case PropertyBaselines.getCustomProperty cssName startStates of
                        Just start ->
                            CustomProperty.for animGroupName cssName unit
                                >> CustomProperty.to start
                                >> CustomProperty.build

                        Nothing ->
                            identity

                Builder.ProcessedCustomColorPropertyConfig cssName _ ->
                    case PropertyBaselines.getCustomColorProperty cssName startStates of
                        Just start ->
                            CustomColorProperty.for animGroupName cssName
                                >> CustomColorProperty.to start
                                >> CustomColorProperty.build

                        Nothing ->
                            identity

                _ ->
                    identity
    in
    buildFromStartState PropertyBaselines.getOpacity opacityBuilder
        >> buildFromStartState PropertyBaselines.getRotate rotateBuilder
        >> buildFromStartState PropertyBaselines.getScale scaleBuilder
        >> buildFromStartState PropertyBaselines.getSize sizeBuilder
        >> buildFromStartState PropertyBaselines.getTranslate translateBuilder
        >> List.foldl (>>) identity (List.map buildCustomFromStartState properties)



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



-- ============================================================
-- FREEZE
-- ============================================================


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


allComplete : AnimState msg -> Maybe Bool
allComplete (AnimState _ animGroups) =
    if AnimGroups.isEmpty animGroups then
        Nothing

    else
        AnimGroups.groups animGroups
            |> List.all AnimGroup.isComplete
            |> Just


anyRunning : AnimState msg -> Maybe Bool
anyRunning (AnimState state animGroups) =
    if AnimGroups.isEmpty animGroups then
        Nothing

    else
        Just state.subscriptionsActive


isComplete : AnimGroupName -> AnimState msg -> Maybe Bool
isComplete animGroupName (AnimState _ data) =
    AnimGroups.get animGroupName data
        |> Maybe.map AnimGroup.isComplete


getProgress : AnimGroupName -> AnimState msg -> Maybe Float
getProgress animGroupName (AnimState _ data) =
    AnimGroups.get animGroupName data
        |> Maybe.map AnimGroup.getProgress


isRunning : AnimGroupName -> AnimState msg -> Maybe Bool
isRunning animGroupName (AnimState _ data) =
    AnimGroups.get animGroupName data
        |> Maybe.map AnimGroup.isRunning



-- ============================================================
-- PROPERTY QUERIES
-- ============================================================


getBuilder : AnimState msg -> EngineBuilder
getBuilder (AnimState state _) =
    state.builder



-- ============================
-- CUSTOM PROPERTY
-- ============================


getPropertyStart : AnimGroupName -> String -> AnimState msg -> Maybe Float
getPropertyStart animGroupName cssName =
    getBuilder >> Property.getCustomPropertyStart animGroupName cssName


getPropertyEnd : AnimGroupName -> String -> AnimState msg -> Maybe Float
getPropertyEnd animGroupName cssName =
    getBuilder >> Property.getCustomPropertyEnd animGroupName cssName


getPropertyCurrent : AnimGroupName -> String -> AnimState msg -> Maybe Float
getPropertyCurrent animGroupName cssName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getCustomProperty cssName)


getPropertyRange : AnimGroupName -> String -> AnimState msg -> Maybe { start : Maybe Float, end : Float }
getPropertyRange animGroupName cssName =
    getBuilder >> Property.getCustomPropertyRange animGroupName cssName



-- ============================
-- CUSTOM COLOR PROPERTY
-- ============================


getColorPropertyStart : AnimGroupName -> String -> AnimState msg -> Maybe Color
getColorPropertyStart animGroupName cssName =
    getBuilder >> Property.getCustomColorPropertyStart animGroupName cssName


getColorPropertyEnd : AnimGroupName -> String -> AnimState msg -> Maybe Color
getColorPropertyEnd animGroupName cssName =
    getBuilder >> Property.getCustomColorPropertyEnd animGroupName cssName


getColorPropertyCurrent : AnimGroupName -> String -> AnimState msg -> Maybe Color
getColorPropertyCurrent animGroupName cssName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getCustomColorProperty cssName)


getColorPropertyRange : AnimGroupName -> String -> AnimState msg -> Maybe { start : Maybe Color, end : Color }
getColorPropertyRange animGroupName cssName =
    getBuilder >> Property.getCustomColorPropertyRange animGroupName cssName



-- ============================
-- OPACITY
-- ============================


getOpacityStart : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityStart animGroupName =
    getBuilder >> Property.getOpacityStart animGroupName


getOpacityEnd : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityEnd animGroupName =
    getBuilder >> Property.getOpacityEnd animGroupName


getOpacityCurrent : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityCurrent animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getOpacity)
        |> Maybe.map Opacity.toFloat


getOpacityRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe Float, end : Float }
getOpacityRange animGroupName =
    getBuilder >> Property.getOpacityRange animGroupName



-- ============================
-- ROTATE
-- ============================


getRotateStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateStart animGroupName =
    getBuilder >> Property.getRotateStart animGroupName


getRotateEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd animGroupName =
    getBuilder >> Property.getRotateEnd animGroupName


getRotateCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateCurrent animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getRotate)
        |> Maybe.map Rotate.toRecord


getRotateRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange animGroupName =
    getBuilder >> Property.getRotateRange animGroupName



-- ============================
-- SCALE
-- ============================


getScaleStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleStart animGroupName =
    getBuilder >> Property.getScaleStart animGroupName


getScaleEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd animGroupName =
    getBuilder >> Property.getScaleEnd animGroupName


getScaleCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleCurrent animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getScale)
        |> Maybe.map Scale.toRecord


getScaleRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange animGroupName =
    getBuilder >> Property.getScaleRange animGroupName



-- ============================
-- SIZE
-- ============================


getSizeStart : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeStart animGroupName =
    getBuilder >> Property.getSizeStart animGroupName


getSizeEnd : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeEnd animGroupName =
    getBuilder >> Property.getSizeEnd animGroupName


getSizeCurrent : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeCurrent animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getSize)
        |> Maybe.map Size.toRecord


getSizeRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange animGroupName =
    getBuilder >> Property.getSizeRange animGroupName



-- ============================
-- PERSPECTIVE ORIGIN
-- ============================


getPerspectiveOriginStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getPerspectiveOriginStart animGroupName =
    getBuilder >> Property.getPerspectiveOriginStart animGroupName


getPerspectiveOriginEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getPerspectiveOriginEnd animGroupName =
    getBuilder >> Property.getPerspectiveOriginEnd animGroupName


getPerspectiveOriginCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getPerspectiveOriginCurrent animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getPerspectiveOrigin)
        |> Maybe.map PerspectiveOrigin.toRecord


getPerspectiveOriginRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getPerspectiveOriginRange animGroupName =
    getBuilder >> Property.getPerspectiveOriginRange animGroupName



-- ============================
-- SKEW
-- ============================


getSkewStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getSkewStart animGroupName =
    getBuilder >> Property.getSkewStart animGroupName


getSkewEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getSkewEnd animGroupName =
    getBuilder >> Property.getSkewEnd animGroupName


getSkewCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getSkewCurrent animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getSkew)
        |> Maybe.map Skew.toRecord


getSkewRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getSkewRange animGroupName =
    getBuilder >> Property.getSkewRange animGroupName



-- ============================
-- TRANSLATE
-- ============================


getTranslateStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart animGroupName =
    getBuilder >> Property.getTranslateStart animGroupName


getTranslateEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd animGroupName =
    getBuilder >> Property.getTranslateEnd animGroupName


getTranslateCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateCurrent animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getTranslate)
        |> Maybe.map Translate.toRecord


getTranslateRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange animGroupName =
    getBuilder >> Property.getTranslateRange animGroupName



-- ============================
-- DECODERS
-- ============================


type alias AnimationUpdate =
    { animGroupName : String
    , progress : Float
    , translate : Maybe { x : Float, y : Float, z : Float }
    , opacity : Maybe Float
    , perspectiveOrigin : Maybe { x : Float, y : Float, unit : String }
    , rotate : Maybe { x : Float, y : Float, z : Float }
    , scale : Maybe { x : Float, y : Float, z : Float }
    , size : Maybe { width : Float, height : Float }
    , customProperties : Dict.Dict String Float
    , customColorProperties : Dict.Dict String String
    , isAnimating : Bool
    , propertyVersions : AnimGroups Int -- Maps property type to version number
    }


animationUpdateDecoder : Decoder AnimationUpdate
animationUpdateDecoder =
    Decode.succeed AnimationUpdate
        |> andMap (Decode.oneOf [ Decode.field "animGroup" Decode.string, Decode.field "elementId" Decode.string ])
        |> andMap (Decode.oneOf [ Decode.field "progress" Decode.float, Decode.succeed 0 ])
        |> andMap (Decode.maybe (Decode.field "translate" (Decode.map3 (\x y z -> { x = x, y = y, z = z }) (Decode.field "x" Decode.float) (Decode.field "y" Decode.float) (Decode.field "z" Decode.float))))
        |> andMap (Decode.maybe (Decode.field "opacity" Decode.float))
        |> andMap (Decode.maybe (Decode.field "perspectiveOrigin" (Decode.map3 (\x y unit -> { x = x, y = y, unit = unit }) (Decode.field "x" Decode.float) (Decode.field "y" Decode.float) (Decode.field "unit" Decode.string))))
        |> andMap (Decode.maybe (Decode.field "rotate" (Decode.map3 (\x y z -> { x = x, y = y, z = z }) (Decode.field "x" Decode.float) (Decode.field "y" Decode.float) (Decode.field "z" Decode.float))))
        |> andMap (Decode.maybe (Decode.field "scale" (Decode.map3 (\x y z -> { x = x, y = y, z = z }) (Decode.field "x" Decode.float) (Decode.field "y" Decode.float) (Decode.field "z" Decode.float))))
        |> andMap (Decode.maybe (Decode.field "size" (Decode.map2 (\w h -> { width = w, height = h }) (Decode.field "width" Decode.float) (Decode.field "height" Decode.float))))
        |> andMap (Decode.oneOf [ Decode.field "customProperties" (Decode.dict Decode.float), Decode.succeed Dict.empty ])
        |> andMap (Decode.oneOf [ Decode.field "customColorProperties" (Decode.dict Decode.string), Decode.succeed Dict.empty ])
        |> andMap (Decode.field "isAnimating" Decode.bool)
        |> andMap propertyVersionDecoder


perspectiveOriginFromRecord : { x : Float, y : Float, unit : String } -> PerspectiveOrigin.PerspectiveOrigin
perspectiveOriginFromRecord { x, y, unit } =
    let
        normalizedUnit =
            String.toLower unit
    in
    if normalizedUnit == "percent" || normalizedUnit == "%" then
        PerspectiveOrigin.fromRecord PerspectiveOrigin.PercentUnit { x = x, y = y }

    else
        PerspectiveOrigin.fromRecord PerspectiveOrigin.PxUnit { x = x, y = y }


propertyVersionDecoder : Decoder (AnimGroups Int)
propertyVersionDecoder =
    Decode.field "propertyVersions" (Decode.dict Decode.int)
        |> Decode.map AnimGroups.fromDict


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)
