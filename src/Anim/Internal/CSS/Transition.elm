module Anim.Internal.CSS.Transition exposing
    ( generateFromProcessed
    , generateStartingStyleForElement
    , onTransitionCancel
    , onTransitionCancelStopPropagation
    , onTransitionCancelWithSource
    , onTransitionCancelWithSourceStopPropagation
    , onTransitionEnd
    , onTransitionEndStopPropagation
    , onTransitionEndWithSource
    , onTransitionEndWithSourceStopPropagation
    , onTransitionRun
    , onTransitionRunStopPropagation
    , onTransitionRunWithSource
    , onTransitionRunWithSourceStopPropagation
    , onTransitionStart
    , onTransitionStartStopPropagation
    , onTransitionStartWithSource
    , onTransitionStartWithSourceStopPropagation
    , startingStyleNode
    , startingStyleNodeFor
    , transitionAttributes
    , transitionEventsStopPropagation
    , transitionSourceDecoder
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.CSS as InternalCSS exposing (AnimState(..), SourceEventData)
import Anim.Internal.Easing as InternalEasing
import Anim.Internal.Properties.Color as Color exposing (Color(..))
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Properties.Translate as Translate
import Dict
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode



-- CSS TRANSITION STRING GENERATION


{-| Generate transitions from processed properties.
-}
generateFromProcessed : List Builder.ProcessedPropertyConfig -> String
generateFromProcessed properties =
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


transitionAttributes : String -> AnimState (List ( String, String )) -> List (Html.Attribute msg)
transitionAttributes elementId animationResult =
    let
        styles =
            InternalCSS.elementData animationResult
                |> Dict.get elementId
                |> Maybe.withDefault []

        styleAttrs =
            List.map (\( prop, value ) -> Html.Attributes.style prop value) styles

        dataAttr =
            Html.Attributes.attribute "data-anim-group-name" elementId
    in
    dataAttr :: styleAttrs


{-| Generate a style node containing @starting-style rules for all animated elements.
-}
startingStyleNode : AnimState a -> Html msg
startingStyleNode ((AnimState _ data) as animState) =
    let
        elementIds =
            Dict.keys data

        allStartingStyles =
            elementIds
                |> List.filterMap (\id -> generateStartingStyleForElement id animState)
                |> String.join "\n"
    in
    if String.isEmpty allStartingStyles then
        Html.text ""

    else
        Html.node "style" [] [ Html.text ("@starting-style {\n" ++ allStartingStyles ++ "\n}") ]


{-| Generate a style node containing @starting-style rules for a specific element.
-}
startingStyleNodeFor : String -> AnimState a -> Html msg
startingStyleNodeFor elementId animState =
    case generateStartingStyleForElement elementId animState of
        Just css ->
            Html.node "style" [] [ Html.text ("@starting-style {\n" ++ css ++ "\n}") ]

        Nothing ->
            Html.text ""


{-| Generate the CSS content for @starting-style for a single element.
Returns Nothing if the element has no animations with start values.
-}
generateStartingStyleForElement : String -> AnimState a -> Maybe String
generateStartingStyleForElement elementId (AnimState state _) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
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
                    Just ("  [data-anim-group-name=\"" ++ elementId ++ "\"] {\n" ++ String.join "\n" (List.map (\s -> "    " ++ s) allStyles) ++ "\n  }")
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



-- TRANSITION EVENT HANDLERS


onTransitionStart : msg -> Html.Attribute msg
onTransitionStart =
    Html.Events.on "transitionstart"
        << Json.Decode.succeed


{-| Like `onTransitionStart` but stops event propagation.
-}
onTransitionStartStopPropagation : msg -> Html.Attribute msg
onTransitionStartStopPropagation msg =
    Html.Events.stopPropagationOn "transitionstart"
        (Json.Decode.succeed ( msg, True ))


onTransitionEnd : msg -> Html.Attribute msg
onTransitionEnd =
    Html.Events.on "transitionend"
        << Json.Decode.succeed


{-| Like `onTransitionEnd` but stops event propagation.
-}
onTransitionEndStopPropagation : msg -> Html.Attribute msg
onTransitionEndStopPropagation msg =
    Html.Events.stopPropagationOn "transitionend"
        (Json.Decode.succeed ( msg, True ))


onTransitionRun : msg -> Html.Attribute msg
onTransitionRun =
    Html.Events.on "transitionrun"
        << Json.Decode.succeed


{-| Like `onTransitionRun` but stops event propagation.
-}
onTransitionRunStopPropagation : msg -> Html.Attribute msg
onTransitionRunStopPropagation msg =
    Html.Events.stopPropagationOn "transitionrun"
        (Json.Decode.succeed ( msg, True ))


onTransitionCancel : msg -> Html.Attribute msg
onTransitionCancel =
    Html.Events.on "transitioncancel"
        << Json.Decode.succeed


{-| Like `onTransitionCancel` but stops event propagation.
-}
onTransitionCancelStopPropagation : msg -> Html.Attribute msg
onTransitionCancelStopPropagation msg =
    Html.Events.stopPropagationOn "transitioncancel"
        (Json.Decode.succeed ( msg, True ))



-- SOURCE-AWARE TRANSITION EVENT HANDLERS


{-| Decode source element data from transition events.
-}
transitionSourceDecoder : String -> Json.Decode.Decoder SourceEventData
transitionSourceDecoder animGroup =
    Json.Decode.map2 (SourceEventData animGroup)
        InternalCSS.targetIdDecoder
        InternalCSS.currentTargetIdDecoder


{-| Transition start event that reports the actual source element.
-}
onTransitionStartWithSource : String -> (SourceEventData -> msg) -> Html.Attribute msg
onTransitionStartWithSource animGroup toMsg =
    Html.Events.on "transitionstart"
        (transitionSourceDecoder animGroup |> Json.Decode.map toMsg)


{-| Like `onTransitionStartWithSource` but stops event propagation.
-}
onTransitionStartWithSourceStopPropagation : String -> (SourceEventData -> msg) -> Html.Attribute msg
onTransitionStartWithSourceStopPropagation animGroup toMsg =
    Html.Events.stopPropagationOn "transitionstart"
        (transitionSourceDecoder animGroup |> Json.Decode.map (\data -> ( toMsg data, True )))


{-| Transition end event that reports the actual source element.
-}
onTransitionEndWithSource : String -> (SourceEventData -> msg) -> Html.Attribute msg
onTransitionEndWithSource animGroup toMsg =
    Html.Events.on "transitionend"
        (transitionSourceDecoder animGroup |> Json.Decode.map toMsg)


{-| Like `onTransitionEndWithSource` but stops event propagation.
-}
onTransitionEndWithSourceStopPropagation : String -> (SourceEventData -> msg) -> Html.Attribute msg
onTransitionEndWithSourceStopPropagation animGroup toMsg =
    Html.Events.stopPropagationOn "transitionend"
        (transitionSourceDecoder animGroup |> Json.Decode.map (\data -> ( toMsg data, True )))


{-| Transition run event that reports the actual source element.
-}
onTransitionRunWithSource : String -> (SourceEventData -> msg) -> Html.Attribute msg
onTransitionRunWithSource animGroup toMsg =
    Html.Events.on "transitionrun"
        (transitionSourceDecoder animGroup |> Json.Decode.map toMsg)


{-| Like `onTransitionRunWithSource` but stops event propagation.
-}
onTransitionRunWithSourceStopPropagation : String -> (SourceEventData -> msg) -> Html.Attribute msg
onTransitionRunWithSourceStopPropagation animGroup toMsg =
    Html.Events.stopPropagationOn "transitionrun"
        (transitionSourceDecoder animGroup |> Json.Decode.map (\data -> ( toMsg data, True )))


{-| Transition cancel event that reports the actual source element.
-}
onTransitionCancelWithSource : String -> (SourceEventData -> msg) -> Html.Attribute msg
onTransitionCancelWithSource animGroup toMsg =
    Html.Events.on "transitioncancel"
        (transitionSourceDecoder animGroup |> Json.Decode.map toMsg)


{-| Like `onTransitionCancelWithSource` but stops event propagation.
-}
onTransitionCancelWithSourceStopPropagation : String -> (SourceEventData -> msg) -> Html.Attribute msg
onTransitionCancelWithSourceStopPropagation animGroup toMsg =
    Html.Events.stopPropagationOn "transitioncancel"
        (transitionSourceDecoder animGroup |> Json.Decode.map (\data -> ( toMsg data, True )))


{-| All transition event handlers with propagation stopped.
-}
transitionEventsStopPropagation : msg -> List (Html.Attribute msg)
transitionEventsStopPropagation msg =
    [ onTransitionStartStopPropagation msg
    , onTransitionEndStopPropagation msg
    , onTransitionRunStopPropagation msg
    , onTransitionCancelStopPropagation msg
    ]
