module Anim.Internal.Engine.Keyframe exposing
    ( AnimEvent(..)
    , AnimMsg
    , AnimState
    , EngineBuilder
    , TimelineBuilder
    , animate
    , attributes
    , events
    , eventsStopPropagation
    , init
    , maybeKeyframesString
    , pause
    , reset
    , restart
    , resume
    , stop
    , styleNode
    , styleNodeFor
    , transformOrder
    , update
    )

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.CSS as CSS exposing (AnimState(..))
import Anim.Internal.Engine.CSS.Styles exposing (Styles)
import Anim.Internal.Engine.Keyframe.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Keyframe.Animation as Animation
import Anim.Internal.Engine.Keyframe.Generator as Generator exposing (DiscreteConfig)
import Anim.Internal.Engine.Keyframe.Styles as KeyframeStyles
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Shared.PlayState as PlayState
import Anim.Internal.Extra.Color exposing (Color(..))
import Anim.Internal.Property.Opacity exposing (Opacity(..))
import Anim.Internal.Property.Size exposing (Size(..))
import Html exposing (Html)
import Shared.TimeSpec exposing (TimeSpec(..))
import Task



-- ============================================================
-- TYPES
-- ============================================================


type alias AnimState =
    CSS.AnimState Builder.ForKeyframeEngine AnimGroup


type alias AnimGroupName =
    String


type alias TimelineBuilder engine =
    CSS.TimelineBuilder engine


type alias EngineBuilder =
    TimelineBuilder Builder.ForKeyframeEngine



-- ============================================================
-- INITIALIZE
-- ============================================================


init : List (EngineBuilder -> EngineBuilder) -> AnimState
init =
    let
        initGroup : EngineBuilder -> AnimGroupName -> Builder.AnimGroupConfig -> AnimGroup
        initGroup builder name config =
            let
                discrete : DiscreteConfig
                discrete =
                    { entry = Builder.getDiscreteEntryProperties builder
                    , exit = Builder.getDiscreteExitProperties builder
                    }

                resolvedOrder =
                    case config.transformOrder of
                        Just _ ->
                            config.transformOrder

                        Nothing ->
                            Builder.getTransformOrder name builder
            in
            Generator.init
                resolvedOrder
                (Builder.getIterations builder)
                (Builder.getAnimationDirection builder)
                discrete
                name
                config.properties
    in
    CSS.init initGroup



-- ============================================================
-- TRIGGER
-- ============================================================


animate : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
animate =
    let
        generateAnimGroup : Maybe (List TransformProperty) -> EngineBuilder -> AnimGroupName -> Builder.ProcessedAnimGroupConfig -> AnimGroup
        generateAnimGroup _ builder animGroupName config =
            let
                discrete : DiscreteConfig
                discrete =
                    { entry = Builder.getDiscreteEntryProperties builder
                    , exit = Builder.getDiscreteExitProperties builder
                    }
            in
            Generator.generateAnimation
                config.transformOrder
                (Builder.getIterations builder)
                (Builder.getAnimationDirection builder)
                (Builder.getBaseline animGroupName builder)
                discrete
                animGroupName
                config.properties

        insertAnimGroup : AnimGroups a -> AnimGroupName -> AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup
        insertAnimGroup _ animGroupName newAnimGroup acc =
            case AnimGroups.get animGroupName acc of
                Nothing ->
                    AnimGroups.insert animGroupName newAnimGroup acc

                Just currentGroup ->
                    AnimGroups.insert animGroupName
                        (AnimGroup.mergeStyles newAnimGroup currentGroup)
                        acc
    in
    CSS.animate AnimGroup.setPlayState generateAnimGroup insertAnimGroup



-- ============================================================
-- EVENTS
-- ============================================================


type alias CurrentTargetId =
    Maybe String


type alias TargetId =
    Maybe String


type alias Counter =
    Int


type AnimEvent
    = Started CurrentTargetId TargetId AnimGroupName
    | Ended CurrentTargetId TargetId AnimGroupName
    | Cancelled CurrentTargetId TargetId AnimGroupName
    | Iteration CurrentTargetId TargetId AnimGroupName Counter
    | Paused AnimGroupName
    | Resumed AnimGroupName
    | Restarted AnimGroupName



-- ============================================================
-- UPDATE
-- ============================================================


type AnimMsg
    = GotStarted AnimGroupName CSS.SourceEventData
    | GotEnded AnimGroupName CSS.SourceEventData
    | GotCancelled AnimGroupName CSS.SourceEventData
    | GotIteration AnimGroupName CSS.SourceEventData
    | GotPaused AnimGroupName
    | GotResumed AnimGroupName
    | GotRestarted AnimGroupName


update : AnimMsg -> AnimState -> ( AnimState, AnimEvent )
update animMsg animState =
    case animMsg of
        GotPaused animGroupName ->
            ( animState, Paused animGroupName )

        GotResumed animGroupName ->
            ( animState, Resumed animGroupName )

        GotRestarted animGroupName ->
            ( animState, Restarted animGroupName )

        GotStarted animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.AnimationStarted animGroupName) animState
            , Started currentTargetId targetId animGroupName
            )

        GotEnded animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.AnimationEnded animGroupName) animState
            , Ended currentTargetId targetId animGroupName
            )

        GotCancelled animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.AnimationCancelled animGroupName) animState
            , Cancelled currentTargetId targetId animGroupName
            )

        GotIteration animGroupName { currentTargetId, targetId } ->
            let
                (AnimState state animGroups) =
                    animState
                        |> CSS.handleEvent AnimGroup.setPlayState (CSS.AnimationIteration animGroupName)
                        |> incrementIterationCount animGroupName

                count =
                    AnimGroups.get animGroupName animGroups
                        |> Maybe.map AnimGroup.getIterationCount
                        |> Maybe.withDefault 0
            in
            ( AnimState state animGroups
            , Iteration currentTargetId targetId animGroupName count
            )


incrementIterationCount : AnimGroupName -> AnimState -> AnimState
incrementIterationCount animGroupName (AnimState state animGroups) =
    AnimState state <|
        AnimGroups.update animGroupName
            (Maybe.map AnimGroup.incrementIterationCount)
            animGroups



-- ============================================================
-- VIEW
-- ============================================================


attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes animGroupName ((AnimState _ animGroups) as animState) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            []

        Just animGroup ->
            let
                animationAttribute =
                    case AnimGroup.getAnimation animGroup of
                        Just anim ->
                            Animation.toCssString anim

                        Nothing ->
                            "none"
            in
            CSS.attributes
                [ ( "animation", animationAttribute ) ]
                AnimGroup.getStyles
                animGroupName
                animState


styleNode : AnimState -> Html msg
styleNode (AnimState _ animGroups) =
    let
        allKeyframes =
            AnimGroups.groups animGroups
                |> List.filterMap AnimGroup.getAnimation
                |> List.map Animation.getKeyframes
    in
    case allKeyframes of
        [] ->
            Html.text ""

        _ ->
            Html.node "style" [] <|
                [ Html.text <|
                    String.join "\n\n" allKeyframes
                ]


styleNodeFor : AnimGroupName -> AnimState -> Html msg
styleNodeFor animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen AnimGroup.getAnimation
        |> Maybe.map (\anim -> Html.node "style" [] [ Html.text (Animation.getKeyframes anim) ])
        |> Maybe.withDefault (Html.text "")


maybeKeyframesString : AnimGroupName -> AnimState -> Maybe String
maybeKeyframesString animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen AnimGroup.getAnimation
        |> Maybe.map Animation.getKeyframes



-- ============================================================
-- EVENT LISTENERS
-- ============================================================


events : (AnimMsg -> msg) -> List (Html.Attribute msg)
events toMsg =
    [ CSS.onEvent "animationstart" toMsg GotStarted
    , CSS.onEvent "animationend" toMsg GotEnded
    , CSS.onEvent "animationcancel" toMsg GotCancelled
    , CSS.onEvent "animationiteration" toMsg GotIteration
    ]


eventsStopPropagation : (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation toMsg =
    [ CSS.onEventStopPropagation "animationstart" toMsg GotStarted
    , CSS.onEventStopPropagation "animationend" toMsg GotEnded
    , CSS.onEventStopPropagation "animationcancel" toMsg GotCancelled
    , CSS.onEventStopPropagation "animationiteration" toMsg GotIteration
    ]



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


stop : AnimGroupName -> AnimState -> AnimState
stop =
    CSS.stop
        AnimGroup.setPlayState
        AnimGroup.isActive
        (KeyframeStyles.fromProcessedProperties Nothing Nothing)
        setStyles


reset : AnimGroupName -> AnimState -> AnimState
reset =
    CSS.reset
        AnimGroup.setPlayState
        (KeyframeStyles.fromProcessedProperties Nothing Nothing)
        setStyles


setStyles : Styles -> AnimGroup
setStyles styles =
    AnimGroup.setStyles styles AnimGroup.init


restart : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart animGroupName toMsg ((AnimState state _) as animState) =
    let
        maybeFromHistory =
            Builder.getCurrentAnimationConfig animGroupName state.builder
    in
    case maybeFromHistory of
        Nothing ->
            ( animState, Cmd.none )

        Just { properties } ->
            ( restartAnimation animGroupName properties animState
            , toCmd animGroupName toMsg GotRestarted
            )


restartAnimation : AnimGroupName -> List Builder.ProcessedPropertyConfig -> AnimState -> AnimState
restartAnimation animGroupName properties (AnimState state animGroups) =
    let
        counter =
            AnimGroups.get animGroupName animGroups
                |> Maybe.map AnimGroup.getRestartCounter
                |> Maybe.withDefault 0

        discrete : DiscreteConfig
        discrete =
            { entry = Builder.getDiscreteEntryProperties state.builder
            , exit = Builder.getDiscreteExitProperties state.builder
            }

        animGroup =
            Generator.generateRestart
                counter
                (Builder.getTransformOrder animGroupName state.builder)
                (Builder.getIterations state.builder)
                (Builder.getAnimationDirection state.builder)
                (Builder.getBaseline animGroupName state.builder)
                discrete
                animGroupName
                properties
    in
    AnimState state animGroups
        |> reset animGroupName
        |> setPlayState animGroupName PlayState.Running
        |> updateAnimGroup animGroupName animGroup


updateAnimGroup : AnimGroupName -> AnimGroup -> AnimState -> AnimState
updateAnimGroup animGroupName animGroup (AnimState state animGroups) =
    AnimState state <|
        AnimGroups.insert animGroupName animGroup animGroups


pause : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
pause animGroupName toMsg animState =
    case CSS.isRunning AnimGroup.isRunning animGroupName animState of
        Just True ->
            ( setPlayState animGroupName PlayState.Paused animState
            , toCmd animGroupName toMsg GotPaused
            )

        _ ->
            ( animState, Cmd.none )


resume : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
resume animGroupName toMsg animState =
    case CSS.isPaused AnimGroup.isPaused animGroupName animState of
        Just True ->
            ( setPlayState animGroupName PlayState.Running animState
            , toCmd animGroupName toMsg GotResumed
            )

        _ ->
            ( animState, Cmd.none )


setPlayState : AnimGroupName -> PlayState.PlayState -> AnimState -> AnimState
setPlayState animGroupName playState (AnimState state animGroups) =
    let
        playStateStr =
            PlayState.toCssString playState
    in
    AnimState state <|
        AnimGroups.update animGroupName
            (Maybe.map <|
                \animGroup ->
                    animGroup
                        |> AnimGroup.setPlayState playState
                        |> AnimGroup.addStyle "animation-play-state" playStateStr
            )
            animGroups


toCmd : AnimGroupName -> (AnimMsg -> msg) -> (String -> AnimMsg) -> Cmd msg
toCmd animGroupName toMsg animMsg =
    Task.succeed (toMsg (animMsg animGroupName))
        |> Task.perform identity



-- ============================================================
-- TRANSFORM ORDER
-- ============================================================


transformOrder : List TransformProperty -> EngineBuilder -> EngineBuilder
transformOrder =
    Builder.transformOrder
