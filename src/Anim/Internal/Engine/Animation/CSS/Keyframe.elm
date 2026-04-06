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
import Anim.Internal.Engine.Animation.CSS.KeyframeGenerator as KeyframeGenerator exposing (AnimGroup, Animation)
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
                , builder = Builder.init
                , iterationCounts = Dict.empty
                }
                Dict.empty

        _ ->
            let
                builder =
                    List.foldl (\f b -> f b) Builder.init propertyInitializers

                animGroups =
                    Builder.animGroups builder

                initGroup : AnimGroupName -> Builder.AnimGroupConfig -> AnimGroup
                initGroup name =
                    .properties
                        >> Builder.processProperties Builder.initDefaults
                        >> KeyframeGenerator.generateInitialState
                            Nothing
                            (Builder.getIterationCount builder)
                            (Builder.getAnimationDirection builder)
                            name
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
                , iterationCounts = Dict.empty
                }
                (Dict.map initGroup animGroups)


animate : AnimState -> (CSS.AnimBuilder -> CSS.AnimBuilder) -> AnimState
animate ((AnimState state existingData) as animState) transform =
    let
        builder =
            animState
                |> CSS.builder
                |> transform

        processedData =
            Builder.processAnimationData builder

        newElementData =
            processedData.groups
                |> Dict.map
                    (\animGroupName { properties } ->
                        KeyframeGenerator.generateAnimation
                            processedData.globalTransformOrder
                            (Builder.getIterationCount builder)
                            (Builder.getAnimationDirection builder)
                            (Builder.getTargetValue animGroupName builder)
                            animGroupName
                            properties
                    )

        mergedElementData =
            Dict.foldl
                (\animGroupName newElemData acc ->
                    case Dict.get animGroupName acc of
                        Nothing ->
                            Dict.insert animGroupName newElemData acc

                        Just existingElemData ->
                            let
                                newStyleKeys =
                                    List.map Tuple.first newElemData.styles

                                preservedStyles =
                                    List.filter
                                        (\( key, _ ) -> not (List.member key newStyleKeys))
                                        existingElemData.styles
                            in
                            Dict.insert animGroupName
                                { newElemData | styles = newElemData.styles ++ preservedStyles }
                                acc
                )
                existingData
                newElementData

        mergedPlayStates =
            Dict.union
                (processedData.groups
                    |> Dict.keys
                    |> List.map (\id -> ( id, NotStarted ))
                    |> Dict.fromList
                )
                state.animPlayStates
    in
    AnimState
        { animPlayStates = mergedPlayStates
        , builder =
            builder
                |> Builder.addAnimationToHistory processedData
                |> Builder.mergeEndStates
                |> Builder.clearAnimData
        , iterationCounts = state.iterationCounts
        }
        mergedElementData


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
    | Paused CurrentTargetId TargetId AnimGroupName
    | Resumed CurrentTargetId TargetId AnimGroupName
    | Restarted CurrentTargetId TargetId AnimGroupName


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
        idOrEmpty maybeId =
            Maybe.withDefault "" maybeId
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
                    CSS.handleEvent (CSS.AnimationIteration data.animGroup) animState

                iterationCount =
                    CSS.getIterationCount data.animGroup newAnimState
            in
            ( newAnimState
            , Iteration (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup iterationCount
            )

        GotPaused animGroup ->
            ( animState, Paused "" "" animGroup )

        GotResumed animGroup ->
            ( animState, Resumed "" "" animGroup )

        GotRestarted animGroup ->
            ( animState, Restarted "" "" animGroup )



-- CSS ANIMATION EVENT HANDLERS


events : (AnimMsg -> msg) -> List (Html.Attribute msg)
events toMsg =
    [ onStart (\data -> toMsg (GotStarted data))
    , onEnd (\data -> toMsg (GotEnded data))
    , onCancel (\data -> toMsg (GotCancelled data))
    , onIteration (\data -> toMsg (GotIteration data))
    ]


eventsStopPropagation : (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation toMsg =
    [ onStartStopPropagation (\data -> toMsg (GotStarted data))
    , onEndStopPropagation (\data -> toMsg (GotEnded data))
    , onCancelStopPropagation (\data -> toMsg (GotCancelled data))
    , onIterationStopPropagation (\data -> toMsg (GotIteration data))
    ]


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


{-| Decode the source element data from an animation event.
-}
sourceEventDecoder : Json.Decode.Decoder SourceEventData
sourceEventDecoder =
    Json.Decode.map3 SourceEventData
        (animationNameDecoder |> Json.Decode.map extractAnimGroupNameFromAnimationName)
        CSS.targetIdDecoder
        CSS.currentTargetIdDecoder


{-| Animation cancel event that reports the actual source element.
-}
onCancel : (SourceEventData -> msg) -> Html.Attribute msg
onCancel toMsg =
    Html.Events.on "animationcancel"
        (sourceEventDecoder |> Json.Decode.map toMsg)


{-| Like `onAnimationCancelWithSource` but stops event propagation.
-}
onCancelStopPropagation : (SourceEventData -> msg) -> Html.Attribute msg
onCancelStopPropagation toMsg =
    Html.Events.stopPropagationOn "animationcancel"
        (sourceEventDecoder |> Json.Decode.map (\data -> ( toMsg data, True )))


{-| Animation end event that reports the actual source element.
-}
onEnd : (SourceEventData -> msg) -> Html.Attribute msg
onEnd toMsg =
    Html.Events.on "animationend"
        (sourceEventDecoder |> Json.Decode.map toMsg)


{-| Like `onAnimationEndWithSource` but stops event propagation.
-}
onEndStopPropagation : (SourceEventData -> msg) -> Html.Attribute msg
onEndStopPropagation toMsg =
    Html.Events.stopPropagationOn "animationend"
        (sourceEventDecoder |> Json.Decode.map (\data -> ( toMsg data, True )))


{-| Animation iteration event that reports the actual source element.
-}
onIteration : (SourceEventData -> msg) -> Html.Attribute msg
onIteration toMsg =
    Html.Events.on "animationiteration"
        (sourceEventDecoder |> Json.Decode.map toMsg)


{-| Like `onAnimationIterationWithSource` but stops event propagation.
-}
onIterationStopPropagation : (SourceEventData -> msg) -> Html.Attribute msg
onIterationStopPropagation toMsg =
    Html.Events.stopPropagationOn "animationiteration"
        (sourceEventDecoder |> Json.Decode.map (\data -> ( toMsg data, True )))


{-| Animation start event that reports the actual source element.
-}
onStart : (SourceEventData -> msg) -> Html.Attribute msg
onStart toMsg =
    Html.Events.on "animationstart"
        (sourceEventDecoder |> Json.Decode.map toMsg)


{-| Like `onAnimationStartWithSource` but stops event propagation.
-}
onStartStopPropagation : (SourceEventData -> msg) -> Html.Attribute msg
onStartStopPropagation toMsg =
    Html.Events.stopPropagationOn "animationstart"
        (sourceEventDecoder |> Json.Decode.map (\data -> ( toMsg data, True )))



-- VIEW


{-| Get all styles for keyframe-based animations as a list of Html attributes.
-}
attributes : String -> AnimState -> List (Html.Attribute msg)
attributes animGroupName (AnimState _ data) =
    case Dict.get animGroupName data of
        Just animGroup ->
            let
                animationAttr =
                    Html.Attributes.style "animation"
                        (toAttributeString animGroup.maybeAnimation)

                otherStyleAttrs =
                    animGroup.styles
                        |> List.filter (\( key, _ ) -> key /= "animation")
                        |> List.map (\( key, value ) -> Html.Attributes.style key value)
            in
            animationAttr :: otherStyleAttrs

        Nothing ->
            []


toAttributeString : Maybe Animation -> String
toAttributeString maybeAnimation =
    case maybeAnimation of
        Just anim ->
            let
                iterationString =
                    case anim.iterationCount of
                        Builder.Once ->
                            "1"

                        Builder.Times n ->
                            String.fromInt n

                        Builder.Infinite ->
                            "infinite"

                directionString =
                    case anim.direction of
                        Builder.Normal ->
                            "normal"

                        Builder.Alternate ->
                            "alternate"
            in
            anim.animationName
                ++ " "
                ++ String.fromInt anim.duration
                ++ "ms linear 0ms "
                ++ iterationString
                ++ " "
                ++ directionString
                ++ " forwards"

        Nothing ->
            ""


styleNode : AnimState -> Html msg
styleNode (AnimState _ data) =
    let
        allKeyframes =
            Dict.values data
                |> List.filterMap .maybeAnimation
                |> List.map .keyframes
                |> String.join "\n\n"
    in
    if String.isEmpty allKeyframes then
        Html.text ""

    else
        Html.node "style" [] [ Html.text allKeyframes ]


styleNodeFor : AnimGroupName -> AnimState -> Html msg
styleNodeFor animGroupName (AnimState _ data) =
    case Dict.get animGroupName data of
        Just animData ->
            case animData.maybeAnimation of
                Nothing ->
                    Html.text ""

                Just { keyframes } ->
                    Html.node "style" [] [ Html.text keyframes ]

        Nothing ->
            Html.text ""


maybeString : AnimGroupName -> AnimState -> Maybe String
maybeString animGroupName (AnimState _ data) =
    Dict.get animGroupName data
        |> Maybe.andThen .maybeAnimation
        |> Maybe.map .keyframes



-- ANIMATION CONTROL


{-| Stop an animation by jumping instantly to its end state.
-}
stop : AnimGroupName -> AnimState -> AnimState
stop animGroupName ((AnimState state _) as animState) =
    case CSS.buildStopProperties animGroupName state.builder of
        [] ->
            animState

        properties ->
            jumpTo animGroupName Complete properties animState


{-| Reset an animation by jumping instantly to its start state.
-}
reset : AnimGroupName -> AnimState -> AnimState
reset animGroupName ((AnimState state _) as animState) =
    case CSS.buildResetProperties animGroupName state.builder of
        [] ->
            animState

        properties ->
            jumpTo animGroupName NotStarted properties animState


jumpTo : AnimGroupName -> AnimPlayState -> List Builder.PropertyConfig -> AnimState -> AnimState
jumpTo animGroupName playState properties animState =
    let
        setStyles : List Builder.ProcessedPropertyConfig -> List ( String, String )
        setStyles props =
            let
                transforms =
                    KeyframeGenerator.generateTransforms Nothing Nothing props
            in
            CSS.generateStyles
                [ ( "transform", transforms )
                , ( "animation", "none" )
                , ( "transition", "none" )
                ]
                props
    in
    animState
        |> setPlayState animGroupName playState
        |> updateAnimGroup animGroupName
            { styles =
                properties
                    |> Builder.processProperties Builder.initDefaults
                    |> setStyles
            , maybeAnimation = Nothing
            , restartCounter = 0
            }


restart : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart animGroupName toMsg ((AnimState state _) as animState) =
    let
        maybeFromHistory =
            Builder.getCurrentAnimation animGroupName state.builder
                |> Maybe.andThen (\entry -> Dict.get animGroupName entry.groups)
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
        newCounter =
            getRestartCounter animGroupName data + 1

        animGroup =
            KeyframeGenerator.generateRestart
                newCounter
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
        |> updateRestartCounter animGroupName newCounter


pause : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
pause animGroupName toMsg ((AnimState state data) as animState) =
    case CSS.isRunning animGroupName animState of
        Just True ->
            let
                updatedData =
                    Dict.update animGroupName
                        (Maybe.map
                            (\element ->
                                { element
                                    | styles = element.styles ++ [ ( "animation-play-state", "paused" ) ]
                                }
                            )
                        )
                        data
            in
            ( setPlayState animGroupName CSS.Paused (AnimState state updatedData)
            , toCmd animGroupName toMsg GotPaused
            )

        _ ->
            ( animState, Cmd.none )


resume : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
resume animGroupName toMsg ((AnimState state data) as animState) =
    case CSS.isPaused animGroupName animState of
        Just True ->
            let
                updatedData =
                    Dict.update animGroupName
                        (Maybe.map
                            (\element ->
                                let
                                    filteredStyles =
                                        List.filter (\( key, _ ) -> key /= "animation-play-state") element.styles

                                    newStyles =
                                        filteredStyles ++ [ ( "animation-play-state", "running" ) ]
                                in
                                { element | styles = newStyles }
                            )
                        )
                        data
            in
            ( setPlayState animGroupName CSS.Running (AnimState state updatedData)
            , toCmd animGroupName toMsg GotResumed
            )

        _ ->
            ( animState, Cmd.none )


toCmd : AnimGroupName -> (AnimMsg -> msg) -> (String -> AnimMsg) -> Cmd msg
toCmd animGroupName toMsg animMsg =
    Task.succeed (toMsg (animMsg animGroupName))
        |> Task.perform identity



-- HELPERS


setPlayState : AnimGroupName -> AnimPlayState -> AnimState -> AnimState
setPlayState animGroupName animPlayState (AnimState state data) =
    AnimState { state | animPlayStates = Dict.insert animGroupName animPlayState state.animPlayStates } data


updateRestartCounter : AnimGroupName -> Int -> AnimState -> AnimState
updateRestartCounter animGroupName newCounter (AnimState state data) =
    AnimState state <|
        Dict.update animGroupName
            (Maybe.map (\animGroup -> { animGroup | restartCounter = newCounter }))
            data


getRestartCounter : AnimGroupName -> Dict AnimGroupName KeyframeGenerator.AnimGroup -> Int
getRestartCounter animGroupName =
    Dict.get animGroupName
        >> Maybe.map .restartCounter
        >> Maybe.withDefault 0


updateAnimGroup : AnimGroupName -> AnimGroup -> AnimState -> AnimState
updateAnimGroup animGroupName animGroup (AnimState state data) =
    AnimState state <|
        Dict.insert animGroupName animGroup data
