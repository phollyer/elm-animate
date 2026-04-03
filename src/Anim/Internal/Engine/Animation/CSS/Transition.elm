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
import Anim.Internal.Engine.Animation.CSS.CSS as CSS exposing (AnimState(..), ElementState(..), SourceEventData)
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Extra.Easing as InternalEasing
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
    CSS.AnimState (List ( String, String ))


init : List (Builder.AnimBuilder -> Builder.AnimBuilder) -> AnimState
init propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { elementStates = Dict.empty
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
                { elementStates =
                    animGroupNames
                        |> List.map (\id -> ( id, NotStarted ))
                        |> Dict.fromList
                , builder =
                    configuredBuilder
                        |> Builder.clearCurrentElement
                , iterationCounts = Dict.empty
                }
                (configuredBuilder
                    |> Builder.elements
                    |> Dict.map
                        (\_ elementConfig ->
                            generateFromProcessedProps
                                (Builder.discreteTransitionsEnabled configuredBuilder)
                                (Builder.processElement Builder.initDefaults elementConfig).properties
                        )
                )


animate : AnimState -> (Builder.AnimBuilder -> Builder.AnimBuilder) -> AnimState
animate (AnimState state existingData) transform =
    let
        builder_ =
            state.builder
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
                    (\_ processed ->
                        generateFromProcessedProps
                            (Builder.discreteTransitionsEnabled builder_)
                            processed.properties
                    )

        mergedData =
            Dict.foldl
                (\animGroupName newStyles acc ->
                    case Dict.get animGroupName acc of
                        Nothing ->
                            Dict.insert animGroupName newStyles acc

                        Just existingStyles ->
                            let
                                newCssProps =
                                    Dict.get animGroupName processedData.elements
                                        |> Maybe.map (.properties >> cssPropertyNamesForProcessed)
                                        |> Maybe.withDefault []
                            in
                            Dict.insert animGroupName
                                (mergeElementStyles newCssProps newStyles existingStyles)
                                acc
                )
                existingData
                newElementData

        mergedElementStates =
            Dict.union
                (animGroupNames
                    |> List.map (\id -> ( id, NotStarted ))
                    |> Dict.fromList
                )
                state.elementStates
    in
    AnimState
        { elementStates = mergedElementStates
        , builder =
            builderWithHistory
                |> Builder.mergeEndStates
                |> Builder.clearAnimData
        , iterationCounts = state.iterationCounts
        }
        mergedData


type alias AnimGroupName =
    String


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
    let
        styles =
            Dict.get animGroupName data
                |> Maybe.withDefault []

        styleAttrs =
            List.map (\( prop, value ) -> Html.Attributes.style prop value) styles

        dataAttr =
            Html.Attributes.attribute "data-anim-group-name" animGroupName
    in
    dataAttr :: styleAttrs


startingStyleNode : AnimState -> Html.Html msg
startingStyleNode ((AnimState _ data) as animState) =
    let
        animGroupNames =
            Dict.keys data

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
    let
        properties =
            CSS.buildStopProperties animGroupName state.builder

        elementConfig =
            { properties = properties }
    in
    if List.isEmpty properties then
        animState

    else
        setStyles animGroupName Complete elementConfig animState


reset : String -> AnimState -> AnimState
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
        setStyles animGroupName NotStarted newElementConfig (AnimState state data)



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


mergeElementStyles :
    List String
    -> List ( String, String )
    -> List ( String, String )
    -> List ( String, String )
mergeElementStyles newCssProps newStyles existingStyles =
    let
        isMetaStyle key =
            key == "transition" || key == "transition-behavior"

        preservedOldStyles =
            existingStyles
                |> List.filter
                    (\( key, _ ) ->
                        not (isMetaStyle key) && not (List.member key newCssProps)
                    )

        newPropertyStyles =
            newStyles
                |> List.filter (\( key, _ ) -> not (isMetaStyle key))

        -- Parse transition string into individual parts, respecting parentheses
        -- e.g. "translate 3175ms cubic-bezier(0.175, 0.885, 0.32, 1.275) 0ms, transform 1600ms ease-in-out 0ms"
        -- must NOT split inside cubic-bezier(...)
        splitTransitionParts value =
            if value == "none" || String.isEmpty value then
                []

            else
                splitRespectingParens value

        transitionPartCssProp part =
            String.split " " (String.trim part)
                |> List.head
                |> Maybe.withDefault ""

        oldTransitionValue =
            existingStyles
                |> List.filter (\( key, _ ) -> key == "transition")
                |> List.head
                |> Maybe.map Tuple.second
                |> Maybe.withDefault "none"

        newTransitionValue =
            newStyles
                |> List.filter (\( key, _ ) -> key == "transition")
                |> List.head
                |> Maybe.map Tuple.second
                |> Maybe.withDefault "none"

        preservedOldTransitions =
            splitTransitionParts oldTransitionValue
                |> List.filter
                    (\part -> not (List.member (transitionPartCssProp part) newCssProps))

        mergedTransition =
            case preservedOldTransitions ++ splitTransitionParts newTransitionValue of
                [] ->
                    "none"

                parts ->
                    String.join ", " parts

        hasTransitionBehavior =
            List.any (\( key, _ ) -> key == "transition-behavior") existingStyles
                || List.any (\( key, _ ) -> key == "transition-behavior") newStyles

        transitionBehaviorStyles =
            if hasTransitionBehavior then
                [ ( "transition-behavior", "allow-discrete" ) ]

            else
                []
    in
    ( "transition", mergedTransition )
        :: newPropertyStyles
        ++ preservedOldStyles
        ++ transitionBehaviorStyles


{-| Split a CSS transition value string by commas, but only at the top level
(not inside parentheses like `cubic-bezier(0.175, 0.885, 0.32, 1.275)`).
-}
splitRespectingParens : String -> List String
splitRespectingParens value =
    let
        chars =
            String.toList value

        helper remaining depth current acc =
            case remaining of
                [] ->
                    let
                        part =
                            String.fromList (List.reverse current)
                    in
                    if String.isEmpty (String.trim part) then
                        List.reverse acc

                    else
                        List.reverse (part :: acc)

                '(' :: rest ->
                    helper rest (depth + 1) ('(' :: current) acc

                ')' :: rest ->
                    helper rest (max 0 (depth - 1)) (')' :: current) acc

                ',' :: rest ->
                    if depth == 0 then
                        let
                            part =
                                String.fromList (List.reverse current)

                            trimmedRest =
                                case rest of
                                    ' ' :: afterSpace ->
                                        afterSpace

                                    _ ->
                                        rest
                        in
                        helper trimmedRest 0 [] (part :: acc)

                    else
                        helper rest depth (',' :: current) acc

                c :: rest ->
                    helper rest depth (c :: current) acc
    in
    helper chars 0 [] []



-- INTERNAL GENERATION


setStyles : String -> ElementState -> Builder.ElementConfig -> AnimState -> AnimState
setStyles animGroupName targetState elementConfig (AnimState state data) =
    let
        styles =
            generateStylesOnly elementConfig
    in
    AnimState
        { state
            | elementStates = Dict.insert animGroupName targetState state.elementStates
        }
        (Dict.insert animGroupName styles data)


generateFromProcessedProps : Bool -> List Builder.ProcessedPropertyConfig -> List ( String, String )
generateFromProcessedProps discreteTransitions processedProps =
    let
        translateStyles =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.ProcessedTranslateConfig config ->
                            Just ( "translate", Translate.toCssPropertyValue config.end )

                        _ ->
                            Nothing
                )
                processedProps

        rotateStyles =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.ProcessedRotateConfig config ->
                            Just ( "transform", Rotate.toCssString config.end )

                        _ ->
                            Nothing
                )
                processedProps

        scaleStyles =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.ProcessedScaleConfig config ->
                            Just ( "scale", Scale.toCssPropertyValue config.end )

                        _ ->
                            Nothing
                )
                processedProps

        transitions =
            generate processedProps

        colorStyles =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.ProcessedBackgroundColorConfig config ->
                            Just ( "background-color", Color.toCssString config.end )

                        _ ->
                            Nothing
                )
                processedProps

        opacityStyles =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.ProcessedOpacityConfig config ->
                            Just ( "opacity", Opacity.toString config.end )

                        _ ->
                            Nothing
                )
                processedProps

        sizeStyles =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.ProcessedSizeConfig config ->
                            let
                                ( w, h ) =
                                    Size.toTuple config.end
                            in
                            Just
                                [ ( "width", String.fromFloat w ++ "px" )
                                , ( "height", String.fromFloat h ++ "px" )
                                ]

                        _ ->
                            Nothing
                )
                processedProps
                |> List.concat

        fontColorStyles =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.ProcessedFontColorConfig config ->
                            Just ( "color", Color.toCssString config.end )

                        _ ->
                            Nothing
                )
                processedProps

        transitionBehaviorStyle =
            if discreteTransitions then
                [ ( "transition-behavior", "allow-discrete" ) ]

            else
                []

        allStyles =
            ( "transition", transitions )
                :: translateStyles
                ++ rotateStyles
                ++ scaleStyles
                ++ sizeStyles
                ++ fontColorStyles
                ++ transitionBehaviorStyle
                ++ colorStyles
                ++ opacityStyles
                |> List.filter (\( _, value ) -> not (String.isEmpty value))
    in
    allStyles


generateStylesOnly : Builder.ElementConfig -> List ( String, String )
generateStylesOnly elementConfig =
    let
        processed =
            Builder.processElement Builder.initDefaults elementConfig

        processedProps =
            processed.properties

        translateStyles =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.ProcessedTranslateConfig config ->
                            Just ( "translate", Translate.toCssPropertyValue config.end )

                        _ ->
                            Nothing
                )
                processedProps

        rotateStyles =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.ProcessedRotateConfig config ->
                            Just ( "transform", Rotate.toCssString config.end )

                        _ ->
                            Nothing
                )
                processedProps

        scaleStyles =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.ProcessedScaleConfig config ->
                            Just ( "scale", Scale.toCssPropertyValue config.end )

                        _ ->
                            Nothing
                )
                processedProps

        colorStyles =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.ProcessedBackgroundColorConfig config ->
                            Just ( "background-color", Color.toCssString config.end )

                        _ ->
                            Nothing
                )
                processedProps

        opacityStyles =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.ProcessedOpacityConfig config ->
                            Just ( "opacity", Opacity.toString config.end )

                        _ ->
                            Nothing
                )
                processedProps

        sizeStyles =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.ProcessedSizeConfig config ->
                            let
                                ( w, h ) =
                                    Size.toTuple config.end
                            in
                            Just
                                [ ( "width", String.fromFloat w ++ "px" )
                                , ( "height", String.fromFloat h ++ "px" )
                                ]

                        _ ->
                            Nothing
                )
                processedProps
                |> List.concat

        fontColorStyles =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.ProcessedFontColorConfig config ->
                            Just ( "color", Color.toCssString config.end )

                        _ ->
                            Nothing
                )
                processedProps

        allStyles =
            ( "transition", "none" )
                :: translateStyles
                ++ rotateStyles
                ++ scaleStyles
                ++ sizeStyles
                ++ fontColorStyles
                ++ colorStyles
                ++ opacityStyles
                |> List.filter (\( key, value ) -> key == "transition" || not (String.isEmpty value))
    in
    allStyles



-- CSS TRANSITION STRING GENERATION


{-| Generate transitions from processed properties.
-}
generate : List Builder.ProcessedPropertyConfig -> String
generate properties =
    let
        allDurationsZero =
            properties
                |> List.all
                    (\prop ->
                        case prop of
                            Builder.ProcessedTranslateConfig config ->
                                config.duration == 0

                            Builder.ProcessedRotateConfig config ->
                                config.duration == 0

                            Builder.ProcessedScaleConfig config ->
                                config.duration == 0

                            Builder.ProcessedBackgroundColorConfig config ->
                                config.duration == 0

                            Builder.ProcessedOpacityConfig config ->
                                config.duration == 0

                            Builder.ProcessedSizeConfig config ->
                                config.duration == 0

                            Builder.ProcessedFontColorConfig config ->
                                config.duration == 0
                    )
    in
    if allDurationsZero then
        "none"

    else
        let
            allTransitions =
                List.filterMap transitionFromProcessed properties
        in
        String.join ", " allTransitions


transitionFromProcessed : Builder.ProcessedPropertyConfig -> Maybe String
transitionFromProcessed property =
    case property of
        Builder.ProcessedTranslateConfig config ->
            Just ("translate " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedRotateConfig config ->
            Just ("transform " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedScaleConfig config ->
            Just ("scale " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedBackgroundColorConfig config ->
            Just ("background-color " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedOpacityConfig config ->
            Just ("opacity " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedSizeConfig config ->
            Just ("width " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms, height " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedFontColorConfig config ->
            Just ("color " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")



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
            Builder.processAnimationData state.builder
    in
    Dict.get animGroupName processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                let
                    nonTransformStyles =
                        elementConfig.properties
                            |> List.filterMap propertyToNonTransformStartingStyle

                    transformParts =
                        elementConfig.properties
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
