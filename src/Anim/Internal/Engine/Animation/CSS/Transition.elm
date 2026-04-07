module Anim.Internal.Engine.Animation.CSS.Transition exposing
    ( AnimEvent(..)
    , AnimMsg
    , AnimState
    , animate
    , attributes
    , events
    , eventsStopPropagation
    , init
    , reset
    , startingStyleNode
    , startingStyleNodeFor
    , stop
    , update
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Animation.CSS.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Animation.CSS.CSS as CSS exposing (AnimPlayState(..), AnimState(..), SourceEventData)
import Anim.Internal.Engine.Animation.CSS.Styles as Styles
import Anim.Internal.Engine.Animation.CSS.Transition.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Animation.CSS.Transition.Generator as Generator exposing (AnimGroupName)
import Anim.Internal.Engine.Animation.CSS.Transition.Styles as TransitionStyles
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Translate as Translate
import Dict
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode


type alias AnimState =
    CSS.AnimState AnimGroup


type alias AnimGroupName =
    String


init : List (Builder.AnimBuilder -> Builder.AnimBuilder) -> AnimState
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

                initGroup : AnimGroupName -> Builder.AnimGroupConfig -> AnimGroup
                initGroup _ { properties } =
                    Generator.init
                        (Builder.discreteTransitionsEnabled builder)
                        properties
            in
            AnimState
                { animPlayStates =
                    animGroups
                        |> AnimGroups.names
                        |> List.map (\id -> ( id, NotStarted ))
                        |> Dict.fromList
                , builder =
                    builder
                        |> Builder.mergeEndStates
                        |> Builder.clearAnimData
                }
                (AnimGroups.map initGroup animGroups)


animate : AnimState -> (Builder.AnimBuilder -> Builder.AnimBuilder) -> AnimState
animate (AnimState state existingData) transform =
    let
        builder =
            state.builder
                |> transform

        processedAnimData =
            Builder.process builder

        generateAnimGroup : AnimGroupName -> Builder.ProcessedAnimGroupConfig -> AnimGroup
        generateAnimGroup _ { properties } =
            Generator.generateAnimation
                (Builder.discreteTransitionsEnabled builder)
                properties

        insertAnimGroup : AnimGroupName -> AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup
        insertAnimGroup animGroupName animGroup acc =
            case AnimGroups.get animGroupName acc of
                Nothing ->
                    AnimGroups.insert animGroupName animGroup acc

                Just existingStyles ->
                    let
                        newCssProps =
                            AnimGroups.get animGroupName processedAnimData.groups
                                |> Maybe.map (.properties >> cssPropertyNamesForProcessed)
                                |> Maybe.withDefault []
                    in
                    AnimGroups.insert animGroupName
                        (AnimGroup.mergeStyles newCssProps animGroup existingStyles)
                        acc
    in
    AnimState
        { animPlayStates =
            Dict.union
                (processedAnimData.groups
                    |> AnimGroups.names
                    |> List.map (\id -> ( id, Running ))
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
            |> AnimGroups.foldl insertAnimGroup existingData
        )


type alias CurrentTargetId =
    String


type alias TargetId =
    String


type AnimEvent
    = Started CurrentTargetId TargetId AnimGroupName
    | Ended CurrentTargetId TargetId AnimGroupName
    | Cancelled CurrentTargetId TargetId AnimGroupName
    | Run CurrentTargetId TargetId AnimGroupName


type AnimMsg
    = GotStarted CSS.SourceEventData
    | GotEnded CSS.SourceEventData
    | GotCancelled CSS.SourceEventData
    | GotRun CSS.SourceEventData


update : AnimMsg -> AnimState -> ( AnimState, AnimEvent )
update animMsg animState =
    let
        idOrEmpty maybeId =
            Maybe.withDefault "" maybeId
    in
    case animMsg of
        GotStarted data ->
            ( CSS.handleEvent (CSS.TransitionStarted data.animGroup) animState
            , Started (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup
            )

        GotEnded data ->
            ( CSS.handleEvent (CSS.TransitionEnded data.animGroup) animState
            , Ended (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup
            )

        GotRun data ->
            ( CSS.handleEvent (CSS.TransitionRun data.animGroup) animState
            , Run (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup
            )

        GotCancelled data ->
            ( CSS.handleEvent (CSS.TransitionCancelled data.animGroup) animState
            , Cancelled (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup
            )


attributes : String -> AnimState -> List (Html.Attribute msg)
attributes animGroupName (AnimState _ data) =
    case AnimGroups.get animGroupName data of
        Nothing ->
            []

        Just animGroup ->
            animGroup
                |> AnimGroup.getStyles
                |> Styles.toAttrs animGroupName


startingStyleNode : AnimState -> Html.Html msg
startingStyleNode ((AnimState _ data) as animState) =
    let
        animGroupNames =
            AnimGroups.names data

        allStartingStyles =
            animGroupNames
                |> List.filterMap (\id -> generateStartingStyle id animState)
                |> String.join "\n"
    in
    if String.isEmpty allStartingStyles then
        Html.text ""

    else
        Html.node "style" [] [ Html.text ("@starting-style {\n" ++ allStartingStyles ++ "\n}") ]


stop : String -> AnimState -> AnimState
stop animGroupName ((AnimState state _) as animState) =
    simpleControl animGroupName NotStarted CSS.buildStopProperties state.builder animState


reset : String -> AnimState -> AnimState
reset animGroupName ((AnimState state _) as animState) =
    simpleControl animGroupName NotStarted CSS.buildResetProperties state.builder animState


simpleControl : AnimGroupName -> AnimPlayState -> (AnimGroupName -> Builder.AnimBuilder -> List Builder.PropertyConfig) -> Builder.AnimBuilder -> AnimState -> AnimState
simpleControl animGroupName playState buildProperties builder animState =
    case buildProperties animGroupName builder of
        [] ->
            animState

        properties ->
            jumpTo animGroupName playState properties animState


jumpTo : AnimGroupName -> AnimPlayState -> List Builder.PropertyConfig -> AnimState -> AnimState
jumpTo animGroupName playState properties (AnimState state data) =
    let
        processedProps =
            Builder.processProperties Builder.initDefaults properties

        animGroup =
            AnimGroup.init
                |> AnimGroup.setStyles
                    (TransitionStyles.fromProcessedProperties
                        [ ( "animation", "none" )
                        , ( "transition", "none" )
                        ]
                        processedProps
                    )
    in
    AnimState state data
        |> setPlayState animGroupName playState
        |> updateAnimGroup animGroupName animGroup


updateAnimGroup : AnimGroupName -> AnimGroup -> AnimState -> AnimState
updateAnimGroup animGroupName animGroup (AnimState state data) =
    AnimState state <|
        AnimGroups.insert animGroupName animGroup data



-- MERGING


cssPropertyNamesForProcessed : List Builder.ProcessedPropertyConfig -> List String
cssPropertyNamesForProcessed props =
    List.concatMap
        (\prop ->
            case prop of
                Builder.ProcessedTranslateConfig _ ->
                    [ "translate" ]

                Builder.ProcessedRotateConfig _ ->
                    [ "transform" ]

                Builder.ProcessedScaleConfig _ ->
                    [ "scale" ]

                Builder.ProcessedBackgroundColorConfig _ ->
                    [ "background-color" ]

                Builder.ProcessedOpacityConfig _ ->
                    [ "opacity" ]

                Builder.ProcessedSizeConfig _ ->
                    [ "width", "height" ]

                Builder.ProcessedFontColorConfig _ ->
                    [ "color" ]
        )
        props



-- INTERNAL GENERATION


setPlayState : AnimGroupName -> AnimPlayState -> AnimState -> AnimState
setPlayState animGroupName animPlayState (AnimState state data) =
    AnimState { state | animPlayStates = Dict.insert animGroupName animPlayState state.animPlayStates } data



-- VIEW


{-| Generate a style node containing @starting-style rules for a specific element.
-}
startingStyleNodeFor : String -> AnimState -> Html msg
startingStyleNodeFor animGroupName animState =
    case generateStartingStyle animGroupName animState of
        Just css ->
            Html.node "style" [] [ Html.text ("@starting-style {\n" ++ css ++ "\n}") ]

        Nothing ->
            Html.text ""


{-| Generate the CSS content for @starting-style for a single element.
Returns Nothing if the element has no animations with start values.
-}
generateStartingStyle : String -> AnimState -> Maybe String
generateStartingStyle animGroupName (AnimState state _) =
    let
        processedData =
            Builder.process state.builder
    in
    AnimGroups.get animGroupName processedData.groups
        |> Maybe.andThen
            (\groupConfig ->
                let
                    nonTransformStyles =
                        groupConfig.properties
                            |> List.filterMap propertyToNonTransformStartingStyle

                    transformParts =
                        groupConfig.properties
                            |> List.filterMap propertyToTransformPart

                    transformStyle =
                        if List.isEmpty transformParts then
                            []

                        else
                            [ "transform: " ++ String.join " " transformParts ++ ";" ]

                    allStyles =
                        transformStyle ++ nonTransformStyles
                in
                if List.isEmpty allStyles then
                    Nothing

                else
                    Just ("  [data-anim-group-name=\"" ++ animGroupName ++ "\"] {\n" ++ String.join "\n" (List.map (\s -> "    " ++ s) allStyles) ++ "\n  }")
            )


propertyToNonTransformStartingStyle : Builder.ProcessedPropertyConfig -> Maybe String
propertyToNonTransformStartingStyle prop =
    case prop of
        Builder.ProcessedOpacityConfig config ->
            config.start
                |> Maybe.map (\start -> "opacity: " ++ Opacity.toString start ++ ";")

        Builder.ProcessedBackgroundColorConfig config ->
            config.start
                |> Maybe.map (\start -> "background-color: " ++ Color.toCssString start ++ ";")

        Builder.ProcessedSizeConfig config ->
            config.start
                |> Maybe.map
                    (\start ->
                        let
                            ( w, h ) =
                                Size.toTuple start
                        in
                        "width: " ++ String.fromFloat w ++ "px; height: " ++ String.fromFloat h ++ "px;"
                    )

        Builder.ProcessedFontColorConfig config ->
            config.start
                |> Maybe.map (\start -> "color: " ++ Color.toCssString start ++ ";")

        _ ->
            Nothing


propertyToTransformPart : Builder.ProcessedPropertyConfig -> Maybe String
propertyToTransformPart prop =
    case prop of
        Builder.ProcessedTranslateConfig config ->
            config.start
                |> Maybe.map Translate.toCssString

        Builder.ProcessedRotateConfig config ->
            config.start
                |> Maybe.map Rotate.toCssString

        Builder.ProcessedScaleConfig config ->
            config.start
                |> Maybe.map Scale.toCssString

        _ ->
            Nothing



-- EVENT HANDLERS


events : AnimGroupName -> (AnimMsg -> msg) -> List (Html.Attribute msg)
events animGroup toMsg =
    List.map (Html.Attributes.map toMsg) <|
        [ onStart animGroup GotStarted
        , onEnd animGroup GotEnded
        , onRun animGroup GotRun
        , onCancel animGroup GotCancelled
        ]


eventsStopPropagation : AnimGroupName -> (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation animGroup toMsg =
    List.map (Html.Attributes.map toMsg) <|
        [ onStartStopPropagation animGroup GotStarted
        , onEndStopPropagation animGroup GotEnded
        , onRunStopPropagation animGroup GotRun
        , onCancelStopPropagation animGroup GotCancelled
        ]



-- SOURCE-AWARE TRANSITION EVENT HANDLERS


transitionSourceDecoder : String -> Json.Decode.Decoder SourceEventData
transitionSourceDecoder animGroup =
    Json.Decode.map2 (SourceEventData animGroup)
        CSS.targetIdDecoder
        CSS.currentTargetIdDecoder


onStart : String -> (SourceEventData -> msg) -> Html.Attribute msg
onStart animGroup toMsg =
    Html.Events.on "transitionstart"
        (transitionSourceDecoder animGroup |> Json.Decode.map toMsg)


onStartStopPropagation : String -> (SourceEventData -> msg) -> Html.Attribute msg
onStartStopPropagation animGroup toMsg =
    Html.Events.stopPropagationOn "transitionstart"
        (transitionSourceDecoder animGroup |> Json.Decode.map (\data -> ( toMsg data, True )))


onEnd : String -> (SourceEventData -> msg) -> Html.Attribute msg
onEnd animGroup toMsg =
    Html.Events.on "transitionend"
        (transitionSourceDecoder animGroup |> Json.Decode.map toMsg)


onEndStopPropagation : String -> (SourceEventData -> msg) -> Html.Attribute msg
onEndStopPropagation animGroup toMsg =
    Html.Events.stopPropagationOn "transitionend"
        (transitionSourceDecoder animGroup |> Json.Decode.map (\data -> ( toMsg data, True )))


onRun : String -> (SourceEventData -> msg) -> Html.Attribute msg
onRun animGroup toMsg =
    Html.Events.on "transitionrun"
        (transitionSourceDecoder animGroup |> Json.Decode.map toMsg)


onRunStopPropagation : String -> (SourceEventData -> msg) -> Html.Attribute msg
onRunStopPropagation animGroup toMsg =
    Html.Events.stopPropagationOn "transitionrun"
        (transitionSourceDecoder animGroup |> Json.Decode.map (\data -> ( toMsg data, True )))


onCancel : String -> (SourceEventData -> msg) -> Html.Attribute msg
onCancel animGroup toMsg =
    Html.Events.on "transitioncancel"
        (transitionSourceDecoder animGroup |> Json.Decode.map toMsg)


onCancelStopPropagation : String -> (SourceEventData -> msg) -> Html.Attribute msg
onCancelStopPropagation animGroup toMsg =
    Html.Events.stopPropagationOn "transitioncancel"
        (transitionSourceDecoder animGroup |> Json.Decode.map (\data -> ( toMsg data, True )))
