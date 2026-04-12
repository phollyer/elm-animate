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

import Anim.Extra.TransformOrder exposing (TransformOrder)
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Engine.Animation.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Animation.CSS.CSS as CSS exposing (AnimPlayState(..), AnimState(..))
import Anim.Internal.Engine.Animation.CSS.Styles exposing (Styles)
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



{- ***** MODEL ***** -}


type alias AnimState =
    CSS.AnimState AnimGroup


type alias AnimGroupName =
    String


init : List (Builder.AnimBuilder -> Builder.AnimBuilder) -> AnimState
init =
    let
        initGroup : AnimBuilder -> AnimGroupName -> Builder.AnimGroupConfig -> AnimGroup
        initGroup builder _ { properties } =
            Generator.init
                (Builder.discreteTransitionsEnabled builder)
                (Builder.getDiscreteEntryProperties builder)
                (Builder.getDiscreteExitProperties builder)
                properties
    in
    CSS.init initGroup



{- ***** TRIGGER ***** -}


animate : AnimState -> (Builder.AnimBuilder -> Builder.AnimBuilder) -> AnimState
animate =
    let
        generateAnimGroup : Maybe (List TransformOrder) -> AnimBuilder -> AnimGroupName -> { a | properties : List Builder.ProcessedPropertyConfig } -> AnimGroup
        generateAnimGroup _ builder _ { properties } =
            Generator.generateAnimation
                (Builder.discreteTransitionsEnabled builder)
                (Builder.getDiscreteEntryProperties builder)
                (Builder.getDiscreteExitProperties builder)
                properties
                |> AnimGroup.setStartingStyles (extractStartingStyles properties)

        insertAnimGroup : AnimGroups Builder.ProcessedAnimGroupConfig -> AnimGroupName -> AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup
        insertAnimGroup animGroupsConfig animGroupName newAnimGroup acc =
            case AnimGroups.get animGroupName acc of
                Nothing ->
                    AnimGroups.insert animGroupName newAnimGroup acc

                Just currentGroup ->
                    let
                        newCssProps =
                            AnimGroups.get animGroupName animGroupsConfig
                                |> Maybe.map (.properties >> cssPropertyNamesForProcessed)
                                |> Maybe.withDefault []
                    in
                    AnimGroups.insert animGroupName
                        (AnimGroup.mergeStyles newCssProps newAnimGroup currentGroup)
                        acc
    in
    CSS.animate generateAnimGroup insertAnimGroup


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



{- ***** UPDATE ***** -}


type AnimMsg
    = GotStarted AnimGroupName CSS.SourceEventData
    | GotEnded AnimGroupName CSS.SourceEventData
    | GotCancelled AnimGroupName CSS.SourceEventData
    | GotRun AnimGroupName CSS.SourceEventData


update : AnimMsg -> AnimState -> ( AnimState, AnimEvent )
update animMsg animState =
    case animMsg of
        GotStarted animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent (CSS.TransitionStarted animGroupName) animState
            , Started currentTargetId targetId animGroupName
            )

        GotEnded animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent (CSS.TransitionEnded animGroupName) animState
            , Ended currentTargetId targetId animGroupName
            )

        GotRun animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent (CSS.TransitionRun animGroupName) animState
            , Run currentTargetId targetId animGroupName
            )

        GotCancelled animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent (CSS.TransitionCancelled animGroupName) animState
            , Cancelled currentTargetId targetId animGroupName
            )



{- ***** EVENTS ***** -}


type alias CurrentTargetId =
    Maybe String


type alias TargetId =
    Maybe String


type AnimEvent
    = Started CurrentTargetId TargetId AnimGroupName
    | Ended CurrentTargetId TargetId AnimGroupName
    | Cancelled CurrentTargetId TargetId AnimGroupName
    | Run CurrentTargetId TargetId AnimGroupName



{- ***** VIEW ***** -}


attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes animGroupName ((AnimState _ data) as animState) =
    case AnimGroups.get animGroupName data of
        Nothing ->
            []

        Just animGroup ->
            let
                isComplete =
                    CSS.isComplete animGroupName animState == Just True

                discreteExitAttrs =
                    AnimGroup.getDiscreteExit animGroup
                        |> Dict.toList
                        |> List.map
                            (\( prop, { from, to } ) ->
                                if isComplete then
                                    Html.Attributes.style prop to

                                else
                                    Html.Attributes.style prop from
                            )
            in
            CSS.attributes
                []
                AnimGroup.getStyles
                animGroupName
                animState
                ++ discreteExitAttrs


startingStyleNode : AnimState -> Html.Html msg
startingStyleNode ((AnimState _ animGroups) as animState) =
    let
        startingStyles =
            animGroups
                |> AnimGroups.names
                |> List.filterMap (\id -> generateStartingStyle id animState)
                |> String.join "\n"
    in
    if String.isEmpty startingStyles then
        Html.text ""

    else
        Html.node "style" [] <|
            [ Html.text ("@starting-style {\n" ++ startingStyles ++ "\n}") ]


startingStyleNodeFor : AnimGroupName -> AnimState -> Html msg
startingStyleNodeFor animGroupName animState =
    case generateStartingStyle animGroupName animState of
        Just css ->
            Html.node "style" [] <|
                [ Html.text ("@starting-style {\n" ++ css ++ "\n}") ]

        Nothing ->
            Html.text ""


generateStartingStyle : AnimGroupName -> AnimState -> Maybe String
generateStartingStyle animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen
            (\animGroup ->
                let
                    allStyles =
                        AnimGroup.getStartingStyles animGroup
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


extractStartingStyles : List Builder.ProcessedPropertyConfig -> List String
extractStartingStyles properties =
    let
        nonTransformStyles =
            List.filterMap propertyToNonTransformStartingStyle properties

        transformParts =
            List.filterMap propertyToTransformPart properties

        transformStyle =
            if List.isEmpty transformParts then
                []

            else
                [ "transform: " ++ String.join " " transformParts ++ ";" ]
    in
    transformStyle ++ nonTransformStyles



{- ***** EVENT HANDLERS ***** -}


events : (AnimMsg -> msg) -> List (Html.Attribute msg)
events toMsg =
    [ CSS.onEvent "transitionstart" toMsg GotStarted
    , CSS.onEvent "transitionend" toMsg GotEnded
    , CSS.onEvent "transitionrun" toMsg GotRun
    , CSS.onEvent "transitioncancel" toMsg GotCancelled
    ]


eventsStopPropagation : (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation toMsg =
    [ CSS.onEventStopPropagation "transitionstart" toMsg GotStarted
    , CSS.onEventStopPropagation "transitionend" toMsg GotEnded
    , CSS.onEventStopPropagation "transitionrun" toMsg GotRun
    , CSS.onEventStopPropagation "transitioncancel" toMsg GotCancelled
    ]



{- ***** CONTROL ***** -}


stop : AnimGroupName -> AnimState -> AnimState
stop =
    CSS.stop
        TransitionStyles.fromProcessedProperties
        setStyles


reset : AnimGroupName -> AnimState -> AnimState
reset =
    CSS.reset
        TransitionStyles.fromProcessedProperties
        setStyles


setStyles : Styles -> AnimGroup
setStyles styles =
    AnimGroup.setStyles styles AnimGroup.init
