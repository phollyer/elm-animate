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
import Anim.Internal.Engine.Animation.CSS.PlayStates as PlayStates
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
import Html exposing (Html)



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
                properties

        insertAnimGroup : AnimGroups Builder.ProcessedAnimGroupConfig -> AnimGroupName -> AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup
        insertAnimGroup animGroups animGroupName animGroup acc =
            case AnimGroups.get animGroupName acc of
                Nothing ->
                    AnimGroups.insert animGroupName animGroup acc

                Just existingStyles ->
                    let
                        newCssProps =
                            AnimGroups.get animGroupName animGroups
                                |> Maybe.map (.properties >> cssPropertyNamesForProcessed)
                                |> Maybe.withDefault []
                    in
                    AnimGroups.insert animGroupName
                        (AnimGroup.mergeStyles newCssProps animGroup existingStyles)
                        acc
    in
    CSS.animate generateAnimGroup insertAnimGroup



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


attributes : String -> AnimState -> List (Html.Attribute msg)
attributes animGroupName (AnimState _ data) =
    case AnimGroups.get animGroupName data of
        Nothing ->
            []

        Just animGroup ->
            CSS.animGroupDataAttribute animGroupName
                :: (animGroup
                        |> AnimGroup.getStyles
                        |> Styles.toAttrs animGroupName
                   )


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
stop animGroupName animState =
    case CSS.isActive animGroupName animState of
        Just True ->
            simpleControl PlayStates.Complete animGroupName animState

        _ ->
            animState


reset : AnimGroupName -> AnimState -> AnimState
reset =
    simpleControl PlayStates.Reset


simpleControl : PlayStates.State -> AnimGroupName -> AnimState -> AnimState
simpleControl playState =
    CSS.simpleControl playState (\styles -> AnimGroup.setStyles styles <| AnimGroup.init) <|
        TransitionStyles.fromProcessedProperties
            [ ( "animation", "none" )
            , ( "transition", "none" )
            ]



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
