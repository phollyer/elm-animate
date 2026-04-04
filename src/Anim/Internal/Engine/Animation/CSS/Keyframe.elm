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

import Anim.Internal.Builder as Builder
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


getElementAnimation : AnimGroupName -> AnimState -> Maybe AnimGroup
getElementAnimation animGroupName animState =
    Dict.get animGroupName (CSS.elementData animState)



-- Initialize


{-| Initialize animation state with optional property initializers.

Pass an empty list for empty state, or property initializers to set initial values.

-}
init : List (CSS.AnimBuilder -> CSS.AnimBuilder) -> AnimState
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
                    List.foldl (\f b -> f b)
                        Builder.init
                        propertyInitializers

                animGroups =
                    Builder.animGroups builder

                animGroupNames =
                    Dict.keys animGroups
            in
            AnimState
                { animPlayStates =
                    animGroupNames
                        |> List.map (\id -> ( id, NotStarted ))
                        |> Dict.fromList
                , builder =
                    builder
                        |> Builder.mergeEndStates
                        |> Builder.clearAnimData
                , iterationCounts = Dict.empty
                }
                (Dict.map (initGroup builder) animGroups)


initGroup : Builder.AnimBuilder -> AnimGroupName -> Builder.AnimGroupConfig -> AnimGroup
initGroup builder name =
    Builder.processAnimGroupConfig Builder.initDefaults
        >> .properties
        >> KeyframeGenerator.generateInitialState
            Nothing
            (Builder.getIterationCount builder)
            (Builder.getAnimationDirection builder)
            name


animate : AnimState -> (CSS.AnimBuilder -> CSS.AnimBuilder) -> AnimState
animate ((AnimState state existingData) as animState) transform =
    let
        builder_ =
            animState
                |> CSS.builder
                |> transform

        processedData =
            Builder.processAnimationData builder_

        animGroupNames =
            processedData.elements
                |> Dict.keys

        builderWithHistory =
            Dict.foldl
                (\animGroupName _ accBuilder ->
                    Builder.addAnimationToHistory animGroupName processedData accBuilder
                )
                builder_
                processedData.elements

        newElementData =
            processedData.elements
                |> Dict.map
                    (\animGroupName { properties } ->
                        KeyframeGenerator.generateAnimation
                            processedData.globalTransformOrder
                            (Builder.getIterationCount builder_)
                            (Builder.getAnimationDirection builder_)
                            (Builder.getTargetValue animGroupName builder_)
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
                (animGroupNames
                    |> List.map (\id -> ( id, NotStarted ))
                    |> Dict.fromList
                )
                state.animPlayStates
    in
    AnimState
        { animPlayStates = mergedPlayStates
        , builder =
            builderWithHistory
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
attributes animGroupName animState =
    case getElementAnimation animGroupName animState of
        Just elemData ->
            let
                animationAttr =
                    Html.Attributes.style "animation"
                        (toAttributeString elemData.maybeAnimation)

                otherStyleAttrs =
                    elemData.styles
                        |> List.filter (\( key, _ ) -> key /= "animation")
                        |> List.map (\( key, value ) -> Html.Attributes.style key value)
            in
            animationAttr :: otherStyleAttrs

        Nothing ->
            []


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


pause : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
pause animGroupName toMsg animState =
    let
        newState =
            pauseAnimation animGroupName animState

        cmd =
            if CSS.isRunning animGroupName animState |> Maybe.withDefault False then
                Task.succeed (toMsg (GotPaused animGroupName))
                    |> Task.perform identity

            else
                Cmd.none
    in
    ( newState, cmd )


{-| Pause a keyframe animation by setting animation-play-state to paused.
-}
pauseAnimation : AnimGroupName -> AnimState -> AnimState
pauseAnimation animGroupName (AnimState state data) =
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
    AnimState state updatedData


resume : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
resume animGroupName toMsg animState =
    let
        newState =
            resumeAnimation animGroupName animState

        cmd =
            if CSS.isRunning animGroupName animState |> Maybe.withDefault False then
                Task.succeed (toMsg (GotResumed animGroupName))
                    |> Task.perform identity

            else
                Cmd.none
    in
    ( newState, cmd )


resumeAnimation : AnimGroupName -> AnimState -> AnimState
resumeAnimation animGroupName (AnimState state data) =
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
    AnimState state updatedData


{-| Stop an animation by jumping instantly to its end state.
-}
stop : AnimGroupName -> AnimState -> AnimState
stop animGroupName (AnimState state data) =
    case CSS.buildStopProperties animGroupName state.builder of
        [] ->
            AnimState state data

        properties ->
            let
                animGroup =
                    { styles =
                        properties
                            |> processProperties
                            |> resetStyles
                    , maybeAnimation = Nothing
                    , restartCounter = 0
                    }
            in
            AnimState state data
                |> setPlayState animGroupName Complete
                |> updateAnimGroup animGroupName animGroup


{-| Reset an animation by jumping instantly to its start state.
-}
reset : AnimGroupName -> AnimState -> AnimState
reset animGroupName (AnimState state data) =
    case CSS.buildResetProperties animGroupName state.builder of
        [] ->
            AnimState state data

        properties ->
            let
                animGroup =
                    { styles =
                        properties
                            |> processProperties
                            |> resetStyles
                    , maybeAnimation = Nothing
                    , restartCounter = 0
                    }
            in
            AnimState state data
                |> setPlayState animGroupName NotStarted
                |> updateAnimGroup animGroupName animGroup


restart : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart animGroupName toMsg ((AnimState state _) as animState) =
    let
        maybeFromHistory =
            Builder.getCurrentAnimation animGroupName state.builder
                |> Maybe.andThen (\entry -> Dict.get animGroupName entry.elements)
    in
    case maybeFromHistory of
        Nothing ->
            ( animState, Cmd.none )

        Just { properties } ->
            let
                msg =
                    GotRestarted animGroupName
                        |> toMsg
            in
            ( restartAnimation animGroupName properties animState
            , Task.succeed msg
                |> Task.perform identity
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



-- HELPERS


resetStyles : List Builder.ProcessedPropertyConfig -> List ( String, String )
resetStyles properties =
    let
        transforms =
            KeyframeGenerator.generateTransforms Nothing Nothing properties
    in
    CSS.generateStyles
        [ ( "transform", transforms )
        , ( "animation", "none" )
        , ( "transition", "none" )
        ]
        properties


setPlayState : AnimGroupName -> AnimPlayState -> AnimState -> AnimState
setPlayState animGroupName animPlayState (AnimState state data) =
    AnimState { state | animPlayStates = Dict.insert animGroupName animPlayState state.animPlayStates } data


processProperties : List Builder.PropertyConfig -> List Builder.ProcessedPropertyConfig
processProperties props =
    { properties = props }
        |> Builder.processAnimGroupConfig Builder.initDefaults
        |> .properties


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
