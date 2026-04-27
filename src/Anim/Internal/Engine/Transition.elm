module Anim.Internal.Engine.Transition exposing
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

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Engine.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.CSS.CSS as CSS exposing (AnimState(..))
import Anim.Internal.Engine.CSS.Styles exposing (Styles)
import Anim.Internal.Engine.Transition.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Transition.Generator as Generator exposing (AnimGroupName)
import Anim.Internal.Engine.Transition.Styles as TransitionStyles
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Skew as Skew
import Anim.Internal.Property.Translate as Translate
import Dict
import Html exposing (Html)
import Html.Attributes



-- ============================================================
-- MODEL
-- ============================================================


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



-- ============================================================
-- TRIGGER
-- ============================================================


animate : AnimState -> (Builder.AnimBuilder -> Builder.AnimBuilder) -> AnimState
animate =
    let
        generateAnimGroup : Maybe (List TransformProperty) -> AnimBuilder -> AnimGroupName -> { a | properties : List Builder.ProcessedPropertyConfig } -> AnimGroup
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
                        styles =
                            AnimGroups.get animGroupName animGroupsConfig
                                |> Maybe.map (.properties >> toCssPropertyNames)
                                |> Maybe.withDefault []
                                |> AnimGroup.mergeStyles newAnimGroup currentGroup
                    in
                    AnimGroups.insert animGroupName styles acc
    in
    CSS.animate AnimGroup.setPlayState generateAnimGroup insertAnimGroup


toCssPropertyNames : List Builder.ProcessedPropertyConfig -> List String
toCssPropertyNames props =
    List.concatMap
        (\prop ->
            case prop of
                Builder.ProcessedCustomPropertyConfig cssName _ _ ->
                    [ cssName ]

                Builder.ProcessedCustomColorPropertyConfig cssName _ ->
                    [ cssName ]

                Builder.ProcessedOpacityConfig _ ->
                    [ "opacity" ]

                Builder.ProcessedRotateConfig _ ->
                    [ "transform" ]

                Builder.ProcessedScaleConfig _ ->
                    [ "scale" ]

                Builder.ProcessedSizeConfig _ ->
                    [ "width", "height" ]

                Builder.ProcessedSkewConfig _ ->
                    [ "transform" ]

                Builder.ProcessedTranslateConfig _ ->
                    [ "translate" ]
        )
        props


type StartingStylePart
    = TransformPart String
    | CssDeclaration String


propertyToStartingStylePart : Builder.ProcessedPropertyConfig -> Maybe StartingStylePart
propertyToStartingStylePart prop =
    case prop of
        Builder.ProcessedCustomPropertyConfig cssName unit config ->
            config.start
                |> Maybe.map (\start -> CssDeclaration (cssName ++ ": " ++ String.fromFloat start ++ unit ++ ";"))

        Builder.ProcessedCustomColorPropertyConfig cssName config ->
            config.start
                |> Maybe.map (\start -> CssDeclaration (cssName ++ ": " ++ Color.toCssString start ++ ";"))

        Builder.ProcessedOpacityConfig config ->
            config.start
                |> Maybe.map (\start -> CssDeclaration ("opacity: " ++ Opacity.toString start ++ ";"))

        Builder.ProcessedRotateConfig config ->
            config.start
                |> Maybe.map (Rotate.toCssString >> TransformPart)

        Builder.ProcessedScaleConfig config ->
            config.start
                |> Maybe.map (Scale.toCssString >> TransformPart)

        Builder.ProcessedSizeConfig config ->
            config.start
                |> Maybe.map
                    (\start ->
                        let
                            ( w, h ) =
                                Size.toTuple start
                        in
                        CssDeclaration ("width: " ++ String.fromFloat w ++ "px; height: " ++ String.fromFloat h ++ "px;")
                    )

        Builder.ProcessedSkewConfig config ->
            config.start
                |> Maybe.map (Skew.toCssString >> TransformPart)

        Builder.ProcessedTranslateConfig config ->
            config.start
                |> Maybe.map (Translate.toCssString >> TransformPart)


extractStartingStyles : List Builder.ProcessedPropertyConfig -> List String
extractStartingStyles properties =
    let
        parts =
            List.filterMap propertyToStartingStylePart properties

        ( transformParts, cssDeclarations ) =
            List.foldl
                (\part ( transforms, declarations ) ->
                    case part of
                        TransformPart t ->
                            ( t :: transforms, declarations )

                        CssDeclaration d ->
                            ( transforms, d :: declarations )
                )
                ( [], [] )
                parts

        transformStyle =
            if List.isEmpty transformParts then
                []

            else
                [ "transform: " ++ String.join " " (List.reverse transformParts) ++ ";" ]
    in
    transformStyle ++ List.reverse cssDeclarations



-- ============================================================
-- EVENTS
-- ============================================================


type alias CurrentTargetId =
    Maybe String


type alias TargetId =
    Maybe String


type AnimEvent
    = Started CurrentTargetId TargetId AnimGroupName
    | Ended CurrentTargetId TargetId AnimGroupName
    | Cancelled CurrentTargetId TargetId AnimGroupName
    | Run CurrentTargetId TargetId AnimGroupName



-- ============================================================
-- UPDATE
-- ============================================================


type AnimMsg
    = GotStarted AnimGroupName CSS.SourceEventData
    | GotEnded AnimGroupName CSS.SourceEventData
    | GotCancelled AnimGroupName CSS.SourceEventData
    | GotRun AnimGroupName CSS.SourceEventData


update : AnimMsg -> AnimState -> ( AnimState, AnimEvent )
update animMsg animState =
    case animMsg of
        GotStarted animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.TransitionStarted animGroupName) animState
            , Started currentTargetId targetId animGroupName
            )

        GotEnded animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.TransitionEnded animGroupName) animState
            , Ended currentTargetId targetId animGroupName
            )

        GotRun animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.TransitionRun animGroupName) animState
            , Run currentTargetId targetId animGroupName
            )

        GotCancelled animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.TransitionCancelled animGroupName) animState
            , Cancelled currentTargetId targetId animGroupName
            )



-- ============================================================
-- VIEW
-- ============================================================


attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes animGroupName ((AnimState _ data) as animState) =
    case AnimGroups.get animGroupName data of
        Nothing ->
            []

        Just animGroup ->
            let
                isComplete =
                    AnimGroup.isComplete animGroup

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



-- ============================================================
-- EVENT LISTENERS
-- ============================================================


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



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


stop : AnimGroupName -> AnimState -> AnimState
stop =
    CSS.stop
        AnimGroup.setPlayState
        AnimGroup.isActive
        TransitionStyles.fromProcessedProperties
        setStyles


reset : AnimGroupName -> AnimState -> AnimState
reset =
    CSS.reset
        AnimGroup.setPlayState
        TransitionStyles.fromProcessedProperties
        setStyles


setStyles : Styles -> AnimGroup
setStyles styles =
    AnimGroup.setStyles styles AnimGroup.init
