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
import Anim.Internal.Engine.Animation.CSS.KeyframeGenerator as KeyframeGenerator
import Anim.Internal.Extra.Color exposing (Color(..))
import Anim.Internal.Property.Opacity exposing (Opacity(..))
import Anim.Internal.Property.Size exposing (Size(..))
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Dict
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode
import Task


type alias AnimState =
    CSS.AnimState AnimGroup


type alias AnimGroup =
    { styles : List ( String, String )
    , animationLayers : Maybe Animation
    , restartCounter : Int
    }


type alias Animation =
    { animationName : String
    , keyframes : String
    , duration : Int
    , easing : String
    , delay : Int
    , iterationCount : Builder.IterationCount
    , direction : Builder.AnimationDirection
    }


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
                configuredBuilder =
                    List.foldl (\initializer b -> initializer b)
                        Builder.init
                        propertyInitializers

                animGroupNames =
                    configuredBuilder
                        |> Builder.elements
                        |> Dict.keys
            in
            AnimState
                { animPlayStates =
                    animGroupNames
                        |> List.map (\id -> ( id, NotStarted ))
                        |> Dict.fromList
                , builder =
                    configuredBuilder
                        |> Builder.mergeEndStates
                        |> Builder.clearAnimData
                , iterationCounts = Dict.empty
                }
                (configuredBuilder
                    |> Builder.elements
                    |> Dict.map (KeyframeGenerator.generateInitialState Nothing (Builder.getIterationCount configuredBuilder) (Builder.getAnimationDirection configuredBuilder))
                )


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
                    (\animGroupName processed ->
                        KeyframeGenerator.generateAnimation
                            processedData.globalTransformOrder
                            (Builder.getIterationCount builder_)
                            (Builder.getAnimationDirection builder_)
                            (Builder.getElementTarget animGroupName builder_)
                            animGroupName
                            processed
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
                        (toAttributeString elemData.animationLayers)

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
                |> List.filterMap .animationLayers
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
            case animData.animationLayers of
                Nothing ->
                    Html.text ""

                Just { keyframes } ->
                    Html.node "style" [] [ Html.text keyframes ]

        Nothing ->
            Html.text ""


maybeString : AnimGroupName -> AnimState -> Maybe String
maybeString animGroupName (AnimState _ data) =
    Dict.get animGroupName data
        |> Maybe.andThen .animationLayers
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
stop animGroupName ((AnimState state _) as animState) =
    let
        properties =
            CSS.buildStopProperties animGroupName state.builder

        elementConfig =
            { properties = properties }
    in
    if List.isEmpty properties then
        animState

    else
        setStylesInstantly animGroupName Complete elementConfig animState


{-| Reset an animation by jumping instantly to its start state.
-}
reset : AnimGroupName -> AnimState -> AnimState
reset animGroupName (AnimState state data) =
    let
        properties =
            CSS.buildResetProperties animGroupName state.builder

        newElementConfig =
            { properties = properties }
    in
    if List.isEmpty properties then
        AnimState state data

    else
        setStylesInstantly animGroupName NotStarted newElementConfig (AnimState state data)


restart : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart animGroupName toMsg animState =
    let
        newState =
            restartAnimation animGroupName animState

        cmd =
            if CSS.isRunning animGroupName animState |> Maybe.withDefault False then
                Task.succeed (toMsg (GotRestarted animGroupName))
                    |> Task.perform identity

            else
                Cmd.none
    in
    ( newState, cmd )


{-| Restart an animation from the beginning.
-}
restartAnimation : AnimGroupName -> AnimState -> AnimState
restartAnimation animGroupName ((AnimState state data) as animState) =
    let
        maybeFromHistory =
            Builder.getCurrentAnimation animGroupName state.builder
                |> Maybe.andThen (\entry -> Dict.get animGroupName entry.elements)

        currentCounter =
            Dict.get animGroupName data
                |> Maybe.map .restartCounter
                |> Maybe.withDefault 0

        newCounter =
            currentCounter + 1

        restartSuffix =
            "-r" ++ String.fromInt newCounter

        applyRestart : AnimGroup -> AnimState
        applyRestart elemData =
            let
                (AnimState resetState resetData) =
                    reset animGroupName animState
            in
            AnimState
                { resetState
                    | animPlayStates = Dict.insert animGroupName NotStarted resetState.animPlayStates
                }
                (Dict.insert animGroupName { elemData | restartCounter = newCounter } resetData)
    in
    case maybeFromHistory of
        Just processedElementConfig ->
            KeyframeGenerator.generateRestart (Builder.getTransformOrder state.builder) (Builder.getIterationCount state.builder) (Builder.getAnimationDirection state.builder) (Builder.getElementTarget animGroupName state.builder) restartSuffix animGroupName processedElementConfig
                |> applyRestart

        Nothing ->
            animState



-- HELPERS


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
                ++ "ms "
                ++ anim.easing
                ++ " "
                ++ String.fromInt anim.delay
                ++ "ms "
                ++ iterationString
                ++ " "
                ++ directionString
                ++ " forwards"

        Nothing ->
            ""


setStylesInstantly : AnimGroupName -> AnimPlayState -> Builder.AnimGroupConfig -> AnimState -> AnimState
setStylesInstantly animGroupName targetState elementConfig (AnimState state data) =
    let
        animPlayStates =
            Dict.insert animGroupName targetState state.animPlayStates

        elemData =
            generateStylesOnly Nothing elementConfig

        newData =
            Dict.insert animGroupName elemData data
    in
    AnimState
        { state | animPlayStates = animPlayStates }
        newData


generateStylesOnly : Maybe (List Builder.TransformOrder) -> Builder.AnimGroupConfig -> AnimGroup
generateStylesOnly maybeOrder elementConfig =
    let
        processed =
            Builder.processAnimGroupConfig Builder.initDefaults elementConfig

        processedProps =
            processed.properties

        transforms =
            case maybeOrder of
                Nothing ->
                    KeyframeGenerator.generateTransformString processedProps

                Just order ->
                    let
                        orderStrings =
                            List.map Builder.transformOrderToString order
                    in
                    KeyframeGenerator.generateWithOrder orderStrings processedProps

        allStyles =
            [ ( "transform", transforms )
            , ( "animation", "none" )
            , ( "transition", "none" )
            ]
                ++ CSS.getStyles processedProps
                |> List.filter (\( key, value ) -> key == "animation" || key == "transition" || not (String.isEmpty value))
    in
    { styles = allStyles
    , animationLayers = Nothing
    , restartCounter = 0
    }
