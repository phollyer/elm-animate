module Anim.Internal.Engine.Animation.CSS.Keyframe exposing
    ( AnimEvent(..)
    , AnimMsg
    , AnimState
    , animate
    , attributes
    , events
    , eventsStopPropagation
    , init
    , maybeString
    , pause
    , reset
    , restart
    , resume
    , stop
    , styleNode
    , styleNodeFor
    , update
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Engine.Animation.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Animation.CSS.CSS as CSS exposing (AnimPlayState(..), AnimState(..))
import Anim.Internal.Engine.Animation.CSS.Keyframe.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Animation.CSS.Keyframe.Animation as Animation
import Anim.Internal.Engine.Animation.CSS.Keyframe.Generator as Generator
import Anim.Internal.Engine.Animation.CSS.Keyframe.Styles as KeyframeStyles
import Anim.Internal.Engine.Animation.CSS.Styles as Styles
import Anim.Internal.Extra.Color exposing (Color(..))
import Anim.Internal.Property.Opacity exposing (Opacity(..))
import Anim.Internal.Property.Size exposing (Size(..))
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Dict
import Html exposing (Html)
import Task



{- ***** MODEL ***** -}


type alias AnimState =
    CSS.AnimState AnimGroup


type alias AnimGroupName =
    String


init : List (AnimBuilder -> AnimBuilder) -> AnimState
init propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { animPlayStates = Dict.empty
                , builder = Builder.init []
                }
                AnimGroups.init

        _ ->
            let
                builder =
                    Builder.init propertyInitializers

                animGroups =
                    Builder.getAnimGroups builder

                initGroup : AnimGroupName -> { a | properties : List Builder.PropertyConfig } -> AnimGroup
                initGroup name { properties } =
                    Generator.init
                        (Builder.getTransformOrder builder)
                        (Builder.getIterationCount builder)
                        (Builder.getAnimationDirection builder)
                        name
                        properties
            in
            AnimState
                { animPlayStates =
                    animGroups
                        |> AnimGroups.names
                        |> List.map (\name -> ( name, NotStarted ))
                        |> Dict.fromList
                , builder =
                    builder
                        |> Builder.mergeEndStates
                        |> Builder.clearAnimData
                }
                (AnimGroups.map initGroup animGroups)



{- ***** TRIGGER ***** -}


animate : AnimState -> (CSS.AnimBuilder -> CSS.AnimBuilder) -> AnimState
animate (AnimState state animGroups) transform =
    let
        builder =
            transform state.builder

        processedAnimData =
            Builder.process builder

        generateAnimGroup : AnimGroupName -> { a | properties : List Builder.ProcessedPropertyConfig } -> AnimGroup
        generateAnimGroup animGroupName { properties } =
            Generator.generateAnimation
                processedAnimData.globalTransformOrder
                (Builder.getIterationCount builder)
                (Builder.getAnimationDirection builder)
                (Builder.getTargetValue animGroupName builder)
                animGroupName
                properties

        insertAnimGroup : AnimGroupName -> AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup
        insertAnimGroup animGroupName animGroup acc =
            case AnimGroups.get animGroupName acc of
                Nothing ->
                    AnimGroups.insert animGroupName animGroup acc

                Just existing ->
                    AnimGroups.insert animGroupName
                        (AnimGroup.mergeStyles animGroup existing)
                        acc
    in
    AnimState
        { animPlayStates =
            Dict.union
                (processedAnimData.groups
                    |> AnimGroups.names
                    |> List.map (\groupName -> ( groupName, Running ))
                    |> Dict.fromList
                )
                state.animPlayStates
        , builder =
            builder
                |> Builder.addAnimationToHistory processedAnimData
                |> Builder.mergeEndStates
                |> Builder.clearAnimData
        }
        (processedAnimData.groups
            |> AnimGroups.map generateAnimGroup
            |> AnimGroups.foldl insertAnimGroup animGroups
        )



{- ***** UPDATE ***** -}


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
    let
        idOrEmpty =
            Maybe.withDefault ""
    in
    case animMsg of
        GotPaused animGroupName ->
            ( animState, Paused animGroupName )

        GotResumed animGroupName ->
            ( animState, Resumed animGroupName )

        GotRestarted animGroupName ->
            ( animState, Restarted animGroupName )

        GotStarted animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent (CSS.AnimationStarted animGroupName) animState
            , Started (idOrEmpty currentTargetId) (idOrEmpty targetId) animGroupName
            )

        GotEnded animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent (CSS.AnimationEnded animGroupName) animState
            , Ended (idOrEmpty currentTargetId) (idOrEmpty targetId) animGroupName
            )

        GotCancelled animGroupName data ->
            ( CSS.handleEvent (CSS.AnimationCancelled animGroupName) animState
            , Cancelled (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) animGroupName
            )

        GotIteration animGroupName data ->
            let
                ((AnimState _ animGroups) as newAnimState) =
                    animState
                        |> CSS.handleEvent (CSS.AnimationIteration animGroupName)
                        |> incrementIterationCount animGroupName

                count =
                    AnimGroups.get animGroupName animGroups
                        |> Maybe.map AnimGroup.getIterationCount
                        |> Maybe.withDefault 0
            in
            ( newAnimState
            , Iteration (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) animGroupName count
            )


incrementIterationCount : AnimGroupName -> AnimState -> AnimState
incrementIterationCount animGroupName (AnimState state data) =
    AnimState state <|
        AnimGroups.update animGroupName
            (Maybe.map <|
                AnimGroup.incrementIterationCount
            )
            data



{- ***** EVENTS ***** -}


type alias CurrentTargetId =
    String


type alias TargetId =
    String


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



{- ***** VIEW ***** -}


attributes : String -> AnimState -> List (Html.Attribute msg)
attributes animGroupName (AnimState _ animGroups) =
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
            CSS.animGroupDataAttribute animGroupName
                :: (AnimGroup.getStyles animGroup
                        |> Styles.insert "animation" animationAttribute
                        |> Styles.toAttrs animGroupName
                   )


styleNode : AnimState -> Html msg
styleNode (AnimState _ animGroups) =
    let
        allKeyframes =
            AnimGroups.values animGroups
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
    case AnimGroups.get animGroupName animGroups of
        Just animData ->
            case AnimGroup.getAnimation animData of
                Nothing ->
                    Html.text ""

                Just anim ->
                    Html.node "style" [] [ Html.text (Animation.getKeyframes anim) ]

        Nothing ->
            Html.text ""


maybeString : AnimGroupName -> AnimState -> Maybe String
maybeString animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen AnimGroup.getAnimation
        |> Maybe.map Animation.getKeyframes



{- ***** EVENT HANDLERS ***** -}


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



{- ***** CONTROL ***** -}


stop : AnimGroupName -> AnimState -> AnimState
stop animGroupName ((AnimState state _) as animState) =
    simpleControl animGroupName Complete CSS.buildStopProperties state.builder animState


reset : AnimGroupName -> AnimState -> AnimState
reset animGroupName ((AnimState state _) as animState) =
    simpleControl animGroupName NotStarted CSS.buildResetProperties state.builder animState


simpleControl : AnimGroupName -> AnimPlayState -> (AnimGroupName -> Builder.AnimBuilder -> List Builder.PropertyConfig) -> AnimBuilder -> AnimState -> AnimState
simpleControl animGroupName playState buildProperties builder animState =
    case buildProperties animGroupName builder of
        [] ->
            animState

        properties ->
            jumpTo animGroupName playState properties animState


jumpTo : AnimGroupName -> AnimPlayState -> List Builder.PropertyConfig -> AnimState -> AnimState
jumpTo animGroupName playState properties animState =
    let
        processedProps =
            Builder.processProperties Builder.initDefaults properties

        animGroup =
            AnimGroup.init
                |> AnimGroup.setStyles
                    (KeyframeStyles.fromProcessedProperties
                        Nothing
                        Nothing
                        [ ( "animation", "none" )
                        , ( "transition", "none" )
                        ]
                        processedProps
                    )
    in
    animState
        |> setPlayState animGroupName playState
        |> updateAnimGroup animGroupName animGroup


restart : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart animGroupName toMsg ((AnimState state _) as animState) =
    let
        maybeFromHistory =
            Builder.getCurrentAnimation animGroupName state.builder
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

        animGroup =
            Generator.generateRestart
                counter
                (Builder.getTransformOrder state.builder)
                (Builder.getIterationCount state.builder)
                (Builder.getAnimationDirection state.builder)
                (Builder.getTargetValue animGroupName state.builder)
                animGroupName
                properties
    in
    AnimState state animGroups
        |> reset animGroupName
        |> setPlayState animGroupName Running
        |> updateAnimGroup animGroupName animGroup


updateAnimGroup : AnimGroupName -> AnimGroup -> AnimState -> AnimState
updateAnimGroup animGroupName animGroup (AnimState state animGroups) =
    AnimState state <|
        AnimGroups.insert animGroupName animGroup animGroups


pause : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
pause animGroupName toMsg animState =
    case CSS.isRunning animGroupName animState of
        Just True ->
            ( animState
                |> setPlayState animGroupName CSS.Paused
                |> addStyle animGroupName "animation-play-state" "paused"
            , toCmd animGroupName toMsg GotPaused
            )

        _ ->
            ( animState, Cmd.none )


resume : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
resume animGroupName toMsg animState =
    case CSS.isPaused animGroupName animState of
        Just True ->
            ( animState
                |> setPlayState animGroupName CSS.Running
                |> addStyle animGroupName "animation-play-state" "running"
            , toCmd animGroupName toMsg GotResumed
            )

        _ ->
            ( animState, Cmd.none )


setPlayState : AnimGroupName -> AnimPlayState -> AnimState -> AnimState
setPlayState animGroupName animPlayState (AnimState state animGroups) =
    AnimState { state | animPlayStates = Dict.insert animGroupName animPlayState state.animPlayStates } animGroups


addStyle : AnimGroupName -> String -> String -> AnimState -> AnimState
addStyle animGroupName key value (AnimState state animGroups) =
    AnimState state <|
        AnimGroups.update animGroupName
            (Maybe.map <|
                AnimGroup.addStyle key value
            )
            animGroups


toCmd : AnimGroupName -> (AnimMsg -> msg) -> (String -> AnimMsg) -> Cmd msg
toCmd animGroupName toMsg animMsg =
    Task.succeed (toMsg (animMsg animGroupName))
        |> Task.perform identity
