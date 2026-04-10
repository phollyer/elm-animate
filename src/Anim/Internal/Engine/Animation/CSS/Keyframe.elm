module Anim.Internal.Engine.Animation.CSS.Keyframe exposing
    ( AnimEvent(..)
    , AnimMsg
    , AnimState
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
                { animPlayStates = AnimGroups.init
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
                        |> AnimGroups.fromList
                , builder =
                    builder
                        |> Builder.mergeEndStates
                        |> Builder.clearAnimData
                }
                (AnimGroups.map initGroup animGroups)



{- ***** TRIGGER ***** -}


animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
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
            AnimGroups.union
                (processedAnimData.groups
                    |> AnimGroups.names
                    |> List.map (\groupName -> ( groupName, Running ))
                    |> AnimGroups.fromList
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
    case animMsg of
        GotPaused animGroupName ->
            ( animState, Paused animGroupName )

        GotResumed animGroupName ->
            ( animState, Resumed animGroupName )

        GotRestarted animGroupName ->
            ( animState, Restarted animGroupName )

        GotStarted animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent (CSS.AnimationStarted animGroupName) animState
            , Started currentTargetId targetId animGroupName
            )

        GotEnded animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent (CSS.AnimationEnded animGroupName) animState
            , Ended currentTargetId targetId animGroupName
            )

        GotCancelled animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent (CSS.AnimationCancelled animGroupName) animState
            , Cancelled currentTargetId targetId animGroupName
            )

        GotIteration animGroupName { currentTargetId, targetId } ->
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
            , Iteration currentTargetId targetId animGroupName count
            )


incrementIterationCount : AnimGroupName -> AnimState -> AnimState
incrementIterationCount animGroupName (AnimState state animGroups) =
    AnimState state <|
        AnimGroups.update animGroupName
            (Maybe.map AnimGroup.incrementIterationCount)
            animGroups



{- ***** EVENTS ***** -}


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



{- ***** VIEW ***** -}


attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
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
stop =
    simpleControl Complete


reset : AnimGroupName -> AnimState -> AnimState
reset =
    simpleControl NotStarted


simpleControl : AnimPlayState -> AnimGroupName -> AnimState -> AnimState
simpleControl playState =
    CSS.simpleControl playState (\styles -> AnimGroup.setStyles styles <| AnimGroup.init) <|
        KeyframeStyles.fromProcessedProperties
            Nothing
            Nothing
            [ ( "animation", "none" )
            , ( "transition", "none" )
            ]


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


toCmd : AnimGroupName -> (AnimMsg -> msg) -> (String -> AnimMsg) -> Cmd msg
toCmd animGroupName toMsg animMsg =
    Task.succeed (toMsg (animMsg animGroupName))
        |> Task.perform identity


updateAnimGroup : AnimGroupName -> AnimGroup -> AnimState -> AnimState
updateAnimGroup animGroupName animGroup (AnimState state animGroups) =
    AnimState state <|
        AnimGroups.insert animGroupName animGroup animGroups


pause : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
pause animGroupName toMsg animState =
    case CSS.isRunning animGroupName animState of
        Just True ->
            ( setPlayState animGroupName CSS.Paused animState
            , toCmd animGroupName toMsg GotPaused
            )

        _ ->
            ( animState, Cmd.none )


resume : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
resume animGroupName toMsg animState =
    case CSS.isPaused animGroupName animState of
        Just True ->
            ( setPlayState animGroupName CSS.Running animState
            , toCmd animGroupName toMsg GotResumed
            )

        _ ->
            ( animState, Cmd.none )


setPlayState : AnimGroupName -> AnimPlayState -> AnimState -> AnimState
setPlayState animGroupName animPlayState (AnimState state animGroups) =
    AnimState { state | animPlayStates = AnimGroups.insert animGroupName animPlayState state.animPlayStates } <|
        AnimGroups.update animGroupName
            (Maybe.map <|
                AnimGroup.addStyle "animation-play-state" <|
                    case animPlayState of
                        CSS.Running ->
                            "running"

                        CSS.Paused ->
                            "paused"

                        _ ->
                            ""
            )
            animGroups
