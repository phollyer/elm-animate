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
import Anim.Internal.Engine.Animation.CSS.CSS as CSS exposing (AnimPlayState(..), AnimState(..), SourceEventData)
import Anim.Internal.Engine.Animation.CSS.Keyframe.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Animation.CSS.Keyframe.Animation as Animation
import Anim.Internal.Engine.Animation.CSS.Keyframe.Generator as Generator
import Anim.Internal.Engine.Animation.CSS.Keyframe.Styles as KeyframeStyles
import Anim.Internal.Engine.Animation.CSS.Styles as Styles
import Anim.Internal.Extra.Color exposing (Color(..))
import Anim.Internal.Property.Opacity exposing (Opacity(..))
import Anim.Internal.Property.Size exposing (Size(..))
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode
import Task


type alias AnimState =
    CSS.AnimState AnimGroup


type alias AnimGroupName =
    String



-- Initialize


{-| Initialize animation state with optional property initializers.

Pass an empty list for empty state, or property initializers to set initial values.

-}
init : List (AnimBuilder -> AnimBuilder) -> AnimState
init propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { animPlayStates = Dict.empty
                , builder = Builder.init []
                }
                Dict.empty

        _ ->
            let
                builder =
                    Builder.init propertyInitializers

                animGroups =
                    Builder.getAnimGroups builder

                initGroup : AnimGroupName -> Builder.AnimGroupConfig -> AnimGroup
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
                        |> Dict.keys
                        |> List.map (\id -> ( id, NotStarted ))
                        |> Dict.fromList
                , builder =
                    builder
                        |> Builder.mergeEndStates
                        |> Builder.clearAnimData
                }
                (Dict.map initGroup animGroups)


animate : AnimState -> (CSS.AnimBuilder -> CSS.AnimBuilder) -> AnimState
animate (AnimState state data) transform =
    let
        builder =
            transform state.builder

        processedAnimData =
            Builder.process builder

        generateAnimGroup : AnimGroupName -> Builder.ProcessedAnimGroupConfig -> AnimGroup
        generateAnimGroup animGroupName { properties } =
            Generator.generateAnimation
                processedAnimData.globalTransformOrder
                (Builder.getIterationCount builder)
                (Builder.getAnimationDirection builder)
                (Builder.getTargetValue animGroupName builder)
                animGroupName
                properties

        insertAnimGroup : AnimGroupName -> AnimGroup -> Dict AnimGroupName AnimGroup -> Dict AnimGroupName AnimGroup
        insertAnimGroup animGroupName animGroup acc =
            case Dict.get animGroupName acc of
                Nothing ->
                    Dict.insert animGroupName animGroup acc

                Just existing ->
                    Dict.insert animGroupName
                        (AnimGroup.mergeStyles animGroup existing)
                        acc
    in
    AnimState
        { animPlayStates =
            Dict.union
                (processedAnimData.groups
                    |> Dict.keys
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
            |> Dict.map generateAnimGroup
            |> Dict.foldl insertAnimGroup data
        )


type alias CurrentTargetId =
    String


type alias TargetId =
    String


{-| CSS keyframe animation lifecycle events.
-}
type AnimEvent
    = Started CurrentTargetId TargetId AnimGroupName
    | Ended CurrentTargetId TargetId AnimGroupName
    | Cancelled CurrentTargetId TargetId AnimGroupName
    | Iteration CurrentTargetId TargetId AnimGroupName Int
    | Paused AnimGroupName
    | Resumed AnimGroupName
    | Restarted AnimGroupName


type AnimMsg
    = GotStarted CSS.SourceEventData
    | GotEnded CSS.SourceEventData
    | GotCancelled CSS.SourceEventData
    | GotIteration CSS.SourceEventData
    | GotPaused String
    | GotResumed String
    | GotRestarted String


update : AnimMsg -> AnimState -> ( AnimState, AnimEvent )
update animMsg animState =
    let
        idOrEmpty =
            Maybe.withDefault ""
    in
    case animMsg of
        GotStarted data ->
            ( CSS.handleEvent (CSS.AnimationStarted data.animGroup) animState
            , Started (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup
            )

        GotEnded data ->
            ( CSS.handleEvent (CSS.AnimationEnded data.animGroup) animState
            , Ended (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup
            )

        GotCancelled data ->
            ( CSS.handleEvent (CSS.AnimationCancelled data.animGroup) animState
            , Cancelled (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup
            )

        GotIteration data ->
            let
                newAnimState =
                    animState
                        |> CSS.handleEvent (CSS.AnimationIteration data.animGroup)
                        |> incrementIterationCount data.animGroup

                count =
                    getIterationCount data.animGroup newAnimState
            in
            ( newAnimState
            , Iteration (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup count
            )

        GotPaused animGroup ->
            ( animState, Paused animGroup )

        GotResumed animGroup ->
            ( animState, Resumed animGroup )

        GotRestarted animGroup ->
            ( animState, Restarted animGroup )



-- CSS ANIMATION EVENT HANDLERS


events : (AnimMsg -> msg) -> List (Html.Attribute msg)
events toMsg =
    [ onStart (eventDataToMsg toMsg GotStarted)
    , onEnd (eventDataToMsg toMsg GotEnded)
    , onCancel (eventDataToMsg toMsg GotCancelled)
    , onIteration (eventDataToMsg toMsg GotIteration)
    ]


eventsStopPropagation : (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation toMsg =
    [ onStartStopPropagation (eventDataToMsg toMsg GotStarted)
    , onEndStopPropagation (eventDataToMsg toMsg GotEnded)
    , onCancelStopPropagation (eventDataToMsg toMsg GotCancelled)
    , onIterationStopPropagation (eventDataToMsg toMsg GotIteration)
    ]


eventDataToMsg : (AnimMsg -> msg) -> (SourceEventData -> AnimMsg) -> SourceEventData -> msg
eventDataToMsg toMsg msg =
    toMsg << msg


{-| Animation cancel event that reports the actual source element.
-}
onCancel : (SourceEventData -> msg) -> Html.Attribute msg
onCancel =
    onEvent "animationcancel"


{-| Like `onAnimationCancelWithSource` but stops event propagation.
-}
onCancelStopPropagation : (SourceEventData -> msg) -> Html.Attribute msg
onCancelStopPropagation =
    onEventStopPropagation "animationcancel"


{-| Animation end event that reports the actual source element.
-}
onEnd : (SourceEventData -> msg) -> Html.Attribute msg
onEnd =
    onEvent "animationend"


{-| Like `onAnimationEndWithSource` but stops event propagation.
-}
onEndStopPropagation : (SourceEventData -> msg) -> Html.Attribute msg
onEndStopPropagation =
    onEventStopPropagation "animationend"


{-| Animation iteration event that reports the actual source element.
-}
onIteration : (SourceEventData -> msg) -> Html.Attribute msg
onIteration =
    onEvent "animationiteration"


{-| Like `onAnimationIterationWithSource` but stops event propagation.
-}
onIterationStopPropagation : (SourceEventData -> msg) -> Html.Attribute msg
onIterationStopPropagation =
    onEventStopPropagation "animationiteration"


{-| Animation start event that reports the actual source element.
-}
onStart : (SourceEventData -> msg) -> Html.Attribute msg
onStart =
    onEvent "animationstart"


{-| Like `onAnimationStartWithSource` but stops event propagation.
-}
onStartStopPropagation : (SourceEventData -> msg) -> Html.Attribute msg
onStartStopPropagation =
    onEventStopPropagation "animationstart"


onEvent : String -> (SourceEventData -> msg) -> Html.Attribute msg
onEvent eventName toMsg =
    Html.Events.on eventName
        (Json.Decode.map toMsg sourceEventDecoder)


onEventStopPropagation : String -> (SourceEventData -> msg) -> Html.Attribute msg
onEventStopPropagation eventName toMsg =
    Html.Events.stopPropagationOn eventName <|
        Json.Decode.map
            (\data -> ( toMsg data, True ))
            sourceEventDecoder


{-| Decode the source element data from an animation event.
-}
sourceEventDecoder : Json.Decode.Decoder SourceEventData
sourceEventDecoder =
    Json.Decode.map3 SourceEventData
        (Json.Decode.map extractAnimGroupNameFromAnimationName animationNameDecoder)
        CSS.targetIdDecoder
        CSS.currentTargetIdDecoder


{-| Decode the animationName property from an animation event.
-}
animationNameDecoder : Json.Decode.Decoder String
animationNameDecoder =
    Json.Decode.field "animationName" Json.Decode.string


{-| Extract element ID from animation name.

Animation names follow the format: `{animGroupName}-anim-{hash}` or `{animGroupName}-anim-{hash}-{suffix}`
So we split on "-anim-" and take the first part.

-}
extractAnimGroupNameFromAnimationName : String -> String
extractAnimGroupNameFromAnimationName animName =
    case String.split "-anim-" animName of
        animGroupName :: _ ->
            animGroupName

        [] ->
            animName



-- VIEW


{-| Get all styles for keyframe-based animations as a list of Html attributes.
-}
attributes : String -> AnimState -> List (Html.Attribute msg)
attributes animGroupName (AnimState _ data) =
    case Dict.get animGroupName data of
        Just animGroup ->
            let
                animationAttr =
                    Html.Attributes.style "animation" <|
                        case AnimGroup.getAnimation animGroup of
                            Just anim ->
                                Animation.toCssString anim

                            Nothing ->
                                ""

                otherStyleAttrs =
                    AnimGroup.getStyles animGroup
                        |> Styles.remove "animation"
                        |> Styles.toAttrs animGroupName
            in
            animationAttr :: otherStyleAttrs

        Nothing ->
            []


styleNode : AnimState -> Html msg
styleNode (AnimState _ data) =
    let
        allKeyframes =
            Dict.values data
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
styleNodeFor animGroupName (AnimState _ data) =
    case Dict.get animGroupName data of
        Just animData ->
            case AnimGroup.getAnimation animData of
                Nothing ->
                    Html.text ""

                Just anim ->
                    Html.node "style" [] [ Html.text (Animation.getKeyframes anim) ]

        Nothing ->
            Html.text ""


maybeString : AnimGroupName -> AnimState -> Maybe String
maybeString animGroupName (AnimState _ data) =
    Dict.get animGroupName data
        |> Maybe.andThen AnimGroup.getAnimation
        |> Maybe.map Animation.getKeyframes



-- ANIMATION CONTROL


{-| Stop an animation by jumping instantly to its end state.
-}
stop : AnimGroupName -> AnimState -> AnimState
stop animGroupName ((AnimState state _) as animState) =
    simpleControl animGroupName Complete CSS.buildStopProperties state.builder animState


{-| Reset an animation by jumping instantly to its start state.
-}
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

        transforms =
            Generator.generateTransforms Nothing Nothing processedProps

        animGroup =
            AnimGroup.init
                |> AnimGroup.setStyles
                    (KeyframeStyles.fromProcessedProperties
                        [ ( "transform", transforms )
                        , ( "animation", "none" )
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


{-| Restart an animation from the beginning.
-}
restartAnimation : AnimGroupName -> List Builder.ProcessedPropertyConfig -> AnimState -> AnimState
restartAnimation animGroupName properties (AnimState state data) =
    let
        counter =
            Dict.get animGroupName data
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
    AnimState state data
        |> reset animGroupName
        |> setPlayState animGroupName Running
        |> updateAnimGroup animGroupName animGroup


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


toCmd : AnimGroupName -> (AnimMsg -> msg) -> (String -> AnimMsg) -> Cmd msg
toCmd animGroupName toMsg animMsg =
    Task.succeed (toMsg (animMsg animGroupName))
        |> Task.perform identity



-- HELPERS


addStyle : AnimGroupName -> String -> String -> AnimState -> AnimState
addStyle animGroupName key value (AnimState state data) =
    AnimState state <|
        Dict.update animGroupName
            (Maybe.map <|
                AnimGroup.addStyle key value
            )
            data


setPlayState : AnimGroupName -> AnimPlayState -> AnimState -> AnimState
setPlayState animGroupName animPlayState (AnimState state data) =
    AnimState { state | animPlayStates = Dict.insert animGroupName animPlayState state.animPlayStates } data


getIterationCount : AnimGroupName -> AnimState -> Int
getIterationCount animGroupName (AnimState _ data) =
    Dict.get animGroupName data
        |> Maybe.map AnimGroup.getIterationCount
        |> Maybe.withDefault 0


incrementIterationCount : AnimGroupName -> AnimState -> AnimState
incrementIterationCount animGroupName (AnimState state data) =
    AnimState state <|
        Dict.update animGroupName
            (Maybe.map <|
                AnimGroup.incrementIterationCount
            )
            data


updateAnimGroup : AnimGroupName -> AnimGroup -> AnimState -> AnimState
updateAnimGroup animGroupName animGroup (AnimState state data) =
    AnimState state <|
        Dict.insert animGroupName animGroup data
