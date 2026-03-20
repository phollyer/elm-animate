module Anim.Internal.CSS.Keyframes exposing
    ( AnimState
    , KeyframeAnimation
    , KeyframeElementData
    , animate
    , animationNameDecoder
    , extractElementIdFromAnimationName
    , generateWithSuffix
    , generateWithSuffixFromProcessed
    , getElementAnimation
    , getElementKeyframes
    , init
    , keyframeEventsStopPropagation
    , keyframesAttribute
    , keyframesStyleNode
    , keyframesStyleNodeFor
    , keyframesStyles
    , onAnimationCancel
    , onAnimationCancelStopPropagation
    , onAnimationCancelWithSource
    , onAnimationCancelWithSourceStopPropagation
    , onAnimationEnd
    , onAnimationEndStopPropagation
    , onAnimationEndWithSource
    , onAnimationEndWithSourceStopPropagation
    , onAnimationIteration
    , onAnimationIterationStopPropagation
    , onAnimationIterationWithSource
    , onAnimationIterationWithSourceStopPropagation
    , onAnimationStart
    , onAnimationStartStopPropagation
    , onAnimationStartWithSource
    , onAnimationStartWithSourceStopPropagation
    , pauseAnimation
    , reset
    , restartAnimation
    , resumeAnimation
    , setDirection
    , setIterationCount
    , sourceEventDecoder
    , stopAnimation
    , toAttributeString
    )

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder
import Anim.Internal.CSS as InternalCSS exposing (AnimState(..), ElementState(..), SourceEventData)
import Anim.Internal.CSS.Transform as Transforms
import Anim.Internal.CSS.Transition as Transitions
import Anim.Internal.Easing as Easing
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Color as Color exposing (Color(..))
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Properties.Translate as Translate
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Char
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode


type alias AnimState =
    InternalCSS.AnimState KeyframeElementData


type alias KeyframeElementData =
    { styles : List ( String, String )
    , animationLayers : List KeyframeAnimation
    , restartCounter : Int
    }


type alias KeyframeAnimation =
    { animationName : String
    , keyframes : String
    , duration : Int
    , easing : String
    , delay : Int
    , properties : List String
    , iterationCount : Builder.IterationCount
    , direction : Builder.AnimationDirection
    }


getElementAnimation : String -> AnimState -> Maybe KeyframeElementData
getElementAnimation elementId animState =
    Dict.get elementId (InternalCSS.elementData animState)



-- Initialize


{-| Initialize animation state with optional property initializers.

Pass an empty list for empty state, or property initializers to set initial values.

-}
init : List (InternalCSS.AnimBuilder -> InternalCSS.AnimBuilder) -> AnimState
init propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { elementStates = Dict.empty
                , builder = Builder.init
                }
                Dict.empty

        _ ->
            let
                configuredBuilder =
                    List.foldl (\initializer b -> initializer b)
                        Builder.init
                        propertyInitializers

                elementIds =
                    configuredBuilder
                        |> Builder.elements
                        |> Dict.keys
            in
            AnimState
                { elementStates =
                    elementIds
                        |> List.map (\id -> ( id, NotStarted ))
                        |> Dict.fromList
                , builder =
                    configuredBuilder
                        |> Builder.clearElements
                }
                (configuredBuilder
                    |> Builder.elements
                    |> Dict.map (generateElementAnimation Nothing (Builder.discreteTransitionsEnabled configuredBuilder) (Builder.getIterationCount configuredBuilder) (Builder.getAnimationDirection configuredBuilder))
                )


animate : AnimState -> (InternalCSS.AnimBuilder -> InternalCSS.AnimBuilder) -> AnimState
animate ((AnimState state existingData) as animState) transform =
    let
        builder_ =
            animState
                |> InternalCSS.builder
                |> transform

        processedData =
            Builder.processAnimationData builder_

        elementIds =
            processedData.elements
                |> Dict.keys

        builderWithHistory =
            Dict.foldl
                (\elementId _ accBuilder ->
                    Builder.addAnimationToHistory elementId processedData Nothing accBuilder
                        |> Tuple.first
                )
                builder_
                processedData.elements

        newElementData =
            processedData.elements
                |> Dict.map (generateElementAnimationFromProcessed processedData.globalTransformOrder (Builder.discreteTransitionsEnabled builder_) (Builder.getIterationCount builder_) (Builder.getAnimationDirection builder_))

        mergedElementData =
            Dict.map
                (\elementId newElemData ->
                    case Dict.get elementId existingData of
                        Nothing ->
                            newElemData

                        Just existingElemData ->
                            let
                                newStyleKeys =
                                    List.map Tuple.first newElemData.styles

                                preservedStyles =
                                    List.filter
                                        (\( key, _ ) -> not (List.member key newStyleKeys))
                                        existingElemData.styles
                            in
                            { newElemData | styles = newElemData.styles ++ preservedStyles }
                )
                newElementData
    in
    AnimState
        { elementStates =
            elementIds
                |> List.map (\id -> ( id, NotStarted ))
                |> Dict.fromList
        , builder =
            builderWithHistory
                |> Builder.clearElements
        }
        mergedElementData



-- CSS ANIMATION EVENT HANDLERS


onAnimationStart : msg -> Html.Attribute msg
onAnimationStart =
    Html.Events.on "animationstart"
        << Json.Decode.succeed


{-| Like `onAnimationStart` but stops event propagation.
-}
onAnimationStartStopPropagation : msg -> Html.Attribute msg
onAnimationStartStopPropagation msg =
    Html.Events.stopPropagationOn "animationstart"
        (Json.Decode.succeed ( msg, True ))


onAnimationEnd : msg -> Html.Attribute msg
onAnimationEnd =
    Html.Events.on "animationend"
        << Json.Decode.succeed


{-| Like `onAnimationEnd` but stops event propagation.
-}
onAnimationEndStopPropagation : msg -> Html.Attribute msg
onAnimationEndStopPropagation msg =
    Html.Events.stopPropagationOn "animationend"
        (Json.Decode.succeed ( msg, True ))


onAnimationIteration : msg -> Html.Attribute msg
onAnimationIteration =
    Html.Events.on "animationiteration"
        << Json.Decode.succeed


{-| Like `onAnimationIteration` but stops event propagation.
-}
onAnimationIterationStopPropagation : msg -> Html.Attribute msg
onAnimationIterationStopPropagation msg =
    Html.Events.stopPropagationOn "animationiteration"
        (Json.Decode.succeed ( msg, True ))


onAnimationCancel : msg -> Html.Attribute msg
onAnimationCancel =
    Html.Events.on "animationcancel"
        << Json.Decode.succeed


{-| Like `onAnimationCancel` but stops event propagation.
-}
onAnimationCancelStopPropagation : msg -> Html.Attribute msg
onAnimationCancelStopPropagation msg =
    Html.Events.stopPropagationOn "animationcancel"
        (Json.Decode.succeed ( msg, True ))



-- SOURCE-AWARE ANIMATION EVENT HANDLERS


{-| Decode the animationName property from an animation event.
-}
animationNameDecoder : Json.Decode.Decoder String
animationNameDecoder =
    Json.Decode.field "animationName" Json.Decode.string


{-| Extract element ID from animation name.

Animation names follow the format: `{elementId}-anim-{hash}` or `{elementId}-anim-{hash}-{suffix}`
So we split on "-anim-" and take the first part.

-}
extractElementIdFromAnimationName : String -> String
extractElementIdFromAnimationName animName =
    case String.split "-anim-" animName of
        elementId :: _ ->
            elementId

        [] ->
            animName


{-| Decode the source element data from an animation event.
-}
sourceEventDecoder : Json.Decode.Decoder SourceEventData
sourceEventDecoder =
    Json.Decode.map3 SourceEventData
        (animationNameDecoder |> Json.Decode.map extractElementIdFromAnimationName)
        InternalCSS.targetIdDecoder
        InternalCSS.currentTargetIdDecoder


{-| Animation start event that reports the actual source element.
-}
onAnimationStartWithSource : (SourceEventData -> msg) -> Html.Attribute msg
onAnimationStartWithSource toMsg =
    Html.Events.on "animationstart"
        (sourceEventDecoder |> Json.Decode.map toMsg)


{-| Like `onAnimationStartWithSource` but stops event propagation.
-}
onAnimationStartWithSourceStopPropagation : (SourceEventData -> msg) -> Html.Attribute msg
onAnimationStartWithSourceStopPropagation toMsg =
    Html.Events.stopPropagationOn "animationstart"
        (sourceEventDecoder |> Json.Decode.map (\data -> ( toMsg data, True )))


{-| Animation end event that reports the actual source element.
-}
onAnimationEndWithSource : (SourceEventData -> msg) -> Html.Attribute msg
onAnimationEndWithSource toMsg =
    Html.Events.on "animationend"
        (sourceEventDecoder |> Json.Decode.map toMsg)


{-| Like `onAnimationEndWithSource` but stops event propagation.
-}
onAnimationEndWithSourceStopPropagation : (SourceEventData -> msg) -> Html.Attribute msg
onAnimationEndWithSourceStopPropagation toMsg =
    Html.Events.stopPropagationOn "animationend"
        (sourceEventDecoder |> Json.Decode.map (\data -> ( toMsg data, True )))


{-| Animation iteration event that reports the actual source element.
-}
onAnimationIterationWithSource : (SourceEventData -> msg) -> Html.Attribute msg
onAnimationIterationWithSource toMsg =
    Html.Events.on "animationiteration"
        (sourceEventDecoder |> Json.Decode.map toMsg)


{-| Like `onAnimationIterationWithSource` but stops event propagation.
-}
onAnimationIterationWithSourceStopPropagation : (SourceEventData -> msg) -> Html.Attribute msg
onAnimationIterationWithSourceStopPropagation toMsg =
    Html.Events.stopPropagationOn "animationiteration"
        (sourceEventDecoder |> Json.Decode.map (\data -> ( toMsg data, True )))


{-| Animation cancel event that reports the actual source element.
-}
onAnimationCancelWithSource : (SourceEventData -> msg) -> Html.Attribute msg
onAnimationCancelWithSource toMsg =
    Html.Events.on "animationcancel"
        (sourceEventDecoder |> Json.Decode.map toMsg)


{-| Like `onAnimationCancelWithSource` but stops event propagation.
-}
onAnimationCancelWithSourceStopPropagation : (SourceEventData -> msg) -> Html.Attribute msg
onAnimationCancelWithSourceStopPropagation toMsg =
    Html.Events.stopPropagationOn "animationcancel"
        (sourceEventDecoder |> Json.Decode.map (\data -> ( toMsg data, True )))


{-| All keyframe animation event handlers with propagation stopped.
-}
keyframeEventsStopPropagation : msg -> List (Html.Attribute msg)
keyframeEventsStopPropagation msg =
    [ onAnimationStartStopPropagation msg
    , onAnimationEndStopPropagation msg
    , onAnimationIterationStopPropagation msg
    , onAnimationCancelStopPropagation msg
    ]



-- VIEW


{-| Get the animation attribute for keyframe-based animations.
-}
keyframesAttribute : String -> AnimState -> Html.Attribute msg
keyframesAttribute elementId animState =
    case getElementAnimation elementId animState of
        Just elemData ->
            Html.Attributes.style "animation"
                (toAttributeString elemData.animationLayers)

        Nothing ->
            Html.Attributes.style "animation" ""


{-| Get all styles for keyframe-based animations as a list of Html attributes.
-}
keyframesStyles : String -> AnimState -> List (Html.Attribute msg)
keyframesStyles elementId animState =
    case getElementAnimation elementId animState of
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


keyframesStyleNode : AnimState -> Html msg
keyframesStyleNode (AnimState _ data) =
    let
        allKeyframes =
            Dict.values data
                |> List.concatMap .animationLayers
                |> List.map .keyframes
                |> String.join "\n\n"
    in
    if String.isEmpty allKeyframes then
        Html.text ""

    else
        Html.node "style" [] [ Html.text allKeyframes ]


keyframesStyleNodeFor : String -> AnimState -> Html msg
keyframesStyleNodeFor elementId (AnimState _ data) =
    case Dict.get elementId data of
        Just elemData ->
            if List.isEmpty elemData.animationLayers then
                Html.text ""

            else
                let
                    elementKeyframes =
                        elemData.animationLayers
                            |> List.map .keyframes
                            |> String.join "\n\n"
                in
                Html.node "style" [] [ Html.text elementKeyframes ]

        Nothing ->
            Html.text ""


getElementKeyframes : String -> AnimState -> Maybe String
getElementKeyframes elementId (AnimState _ data) =
    Dict.get elementId data
        |> Maybe.andThen
            (\elemData ->
                if List.isEmpty elemData.animationLayers then
                    Nothing

                else
                    elemData.animationLayers
                        |> List.map .keyframes
                        |> String.join "\n\n"
                        |> Just
            )



-- ANIMATION CONTROL


{-| Pause a keyframe animation by setting animation-play-state to paused.
-}
pauseAnimation : String -> AnimState -> AnimState
pauseAnimation elementId (AnimState state data) =
    let
        updatedData =
            Dict.update elementId
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


{-| Resume a paused keyframe animation by setting animation-play-state to running.
-}
resumeAnimation : String -> AnimState -> AnimState
resumeAnimation elementId (AnimState state data) =
    let
        updatedData =
            Dict.update elementId
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
stopAnimation : String -> AnimState -> AnimState
stopAnimation elementId animState =
    let
        makeInstantConfig : a -> Builder.AnimationConfig a
        makeInstantConfig value =
            { start = Just value
            , end = value
            , duration = 0
            , speed = 0
            , distance = 0
            , timing = Just (Duration 0)
            , easing = Just Anim.Extra.Easing.Linear
            , delay = Nothing
            }

        properties =
            [ InternalCSS.getTranslateRange elementId animState
                |> Maybe.map (\range -> Builder.TranslateConfig (makeInstantConfig range.end))
            , InternalCSS.getScaleRange elementId animState
                |> Maybe.map (\range -> Builder.ScaleConfig (makeInstantConfig range.end))
            , InternalCSS.getRotateRange elementId animState
                |> Maybe.map (\range -> Builder.RotateConfig (makeInstantConfig range.end))
            , InternalCSS.getOpacityRange elementId animState
                |> Maybe.map (\range -> Builder.OpacityConfig (makeInstantConfig range.end))
            , InternalCSS.getBackgroundColorRange elementId animState
                |> Maybe.map (\range -> Builder.BackgroundColorConfig (makeInstantConfig range.end))
            , InternalCSS.getSizeRange elementId animState
                |> Maybe.map (\range -> Builder.SizeConfig (makeInstantConfig range.end))
            ]
                |> List.filterMap identity

        elementConfig =
            { properties = properties, targetElement = Nothing }
    in
    if List.isEmpty properties then
        animState

    else
        setStylesInstantly elementId Complete elementConfig animState


{-| Reset an animation by jumping instantly to its start state.
-}
reset : String -> AnimState -> AnimState
reset elementId (AnimState state data) =
    let
        makeInstantConfig : a -> Builder.AnimationConfig a
        makeInstantConfig value =
            { start = Just value
            , end = value
            , duration = 0
            , speed = 0
            , distance = 0
            , timing = Just (Duration 0)
            , easing = Just Anim.Extra.Easing.Linear
            , delay = Nothing
            }

        maybeFromHistory =
            Builder.getCurrentAnimation elementId state.builder
                |> Maybe.andThen (\entry -> Dict.get elementId entry.processedData.elements)
                |> Maybe.map
                    (\processedElementConfig ->
                        processedElementConfig.properties
                            |> List.filterMap
                                (\prop ->
                                    case prop of
                                        Builder.ProcessedTranslateConfig config ->
                                            Just <|
                                                Builder.TranslateConfig
                                                    (makeInstantConfig
                                                        (Maybe.withDefault Translate.default config.start)
                                                    )

                                        Builder.ProcessedScaleConfig config ->
                                            Just <|
                                                Builder.ScaleConfig
                                                    (makeInstantConfig
                                                        (Maybe.withDefault (Scale.fromUniform 1.0) config.start)
                                                    )

                                        Builder.ProcessedRotateConfig config ->
                                            Just <|
                                                Builder.RotateConfig
                                                    (makeInstantConfig
                                                        (Maybe.withDefault Rotate.default config.start)
                                                    )

                                        Builder.ProcessedOpacityConfig config ->
                                            Just <|
                                                Builder.OpacityConfig
                                                    (makeInstantConfig
                                                        (Maybe.withDefault Opacity.default config.start)
                                                    )

                                        Builder.ProcessedBackgroundColorConfig config ->
                                            Just <|
                                                Builder.BackgroundColorConfig
                                                    (makeInstantConfig
                                                        (Maybe.withDefault BackgroundColor.default config.start)
                                                    )

                                        Builder.ProcessedSizeConfig config ->
                                            Just <|
                                                Builder.SizeConfig
                                                    (makeInstantConfig
                                                        (Maybe.withDefault Size.default config.start)
                                                    )

                                        Builder.ProcessedFontColorConfig _ ->
                                            Nothing
                                )
                    )

        maybeFromBuilder =
            Builder.getElementConfig elementId state.builder
                |> Maybe.map
                    (\elementConfig ->
                        elementConfig.properties
                            |> List.filterMap
                                (\prop ->
                                    case prop of
                                        Builder.TranslateConfig config ->
                                            Just <|
                                                Builder.TranslateConfig
                                                    (makeInstantConfig
                                                        (Maybe.withDefault Translate.default config.start)
                                                    )

                                        Builder.ScaleConfig config ->
                                            Just <|
                                                Builder.ScaleConfig
                                                    (makeInstantConfig
                                                        (Maybe.withDefault (Scale.fromUniform 1.0) config.start)
                                                    )

                                        Builder.RotateConfig config ->
                                            Just <|
                                                Builder.RotateConfig
                                                    (makeInstantConfig
                                                        (Maybe.withDefault Rotate.default config.start)
                                                    )

                                        Builder.OpacityConfig config ->
                                            Just <|
                                                Builder.OpacityConfig
                                                    (makeInstantConfig
                                                        (Maybe.withDefault Opacity.default config.start)
                                                    )

                                        Builder.BackgroundColorConfig config ->
                                            Just <|
                                                Builder.BackgroundColorConfig
                                                    (makeInstantConfig
                                                        (Maybe.withDefault BackgroundColor.default config.start)
                                                    )

                                        Builder.SizeConfig config ->
                                            Just <|
                                                Builder.SizeConfig
                                                    (makeInstantConfig
                                                        (Maybe.withDefault Size.default config.start)
                                                    )

                                        Builder.FontColorConfig _ ->
                                            Nothing
                                )
                    )

        properties =
            maybeFromHistory
                |> Maybe.withDefault (Maybe.withDefault [] maybeFromBuilder)

        newElementConfig =
            { properties = properties, targetElement = Nothing }
    in
    if List.isEmpty properties then
        AnimState state data

    else
        setStylesInstantly elementId NotStarted newElementConfig (AnimState state data)


{-| Restart an animation from the beginning.
-}
restartAnimation : String -> AnimState -> AnimState
restartAnimation elementId ((AnimState state data) as animState) =
    let
        maybeFromHistory =
            Builder.getCurrentAnimation elementId state.builder
                |> Maybe.andThen (\entry -> Dict.get elementId entry.processedData.elements)

        maybeFromBuilder =
            Builder.getElementConfig elementId state.builder

        currentCounter =
            Dict.get elementId data
                |> Maybe.map .restartCounter
                |> Maybe.withDefault 0

        newCounter =
            currentCounter + 1

        restartSuffix =
            "r" ++ String.fromInt newCounter

        applyRestart : KeyframeElementData -> AnimState
        applyRestart elemData =
            let
                (AnimState resetState resetData) =
                    reset elementId animState
            in
            AnimState
                { resetState
                    | elementStates = Dict.insert elementId NotStarted resetState.elementStates
                }
                (Dict.insert elementId { elemData | restartCounter = newCounter } resetData)
    in
    case maybeFromHistory of
        Just processedElementConfig ->
            generateElementAnimationFromProcessedWithSuffix (Builder.getTransformOrder state.builder) (Builder.discreteTransitionsEnabled state.builder) (Builder.getIterationCount state.builder) (Builder.getAnimationDirection state.builder) restartSuffix elementId processedElementConfig
                |> applyRestart

        Nothing ->
            case maybeFromBuilder of
                Just elementConfig ->
                    generateElementAnimationWithSuffix (Builder.getTransformOrder state.builder) (Builder.discreteTransitionsEnabled state.builder) (Builder.getIterationCount state.builder) (Builder.getAnimationDirection state.builder) restartSuffix elementId elementConfig
                        |> applyRestart

                Nothing ->
                    animState



-- HELPERS


transformOrderToString : Builder.TransformOrder -> String
transformOrderToString order =
    case order of
        Builder.Translate ->
            "translate"

        Builder.Rotate ->
            "rotate"

        Builder.Scale ->
            "scale"



-- CSS GENERATION


generateElementAnimation : Maybe (List Builder.TransformOrder) -> Bool -> Builder.IterationCount -> Builder.AnimationDirection -> String -> Builder.ElementConfig -> KeyframeElementData
generateElementAnimation maybeOrder discreteTransitions iterationCount direction elementId elementConfig =
    generateElementAnimationWithSuffix maybeOrder discreteTransitions iterationCount direction "" elementId elementConfig


generateElementAnimationWithSuffix : Maybe (List Builder.TransformOrder) -> Bool -> Builder.IterationCount -> Builder.AnimationDirection -> String -> String -> Builder.ElementConfig -> KeyframeElementData
generateElementAnimationWithSuffix maybeOrder discreteTransitions iterationCount direction suffix elementId elementConfig =
    let
        processed =
            Builder.processElement
                { globalTiming = Nothing
                , globalEasing = Nothing
                , globalDelay = Nothing
                , globalTransformOrder = Nothing
                , currentElementId = Nothing
                , elements = Dict.empty
                , scrollTargets = []
                , scrollContainer = "document"
                , animationHistories = Dict.empty
                , nextAnimationId = 0
                , elementBaselines = Dict.empty
                , elementTargets = Dict.empty
                , discreteTransitions = discreteTransitions
                , iterationCount = iterationCount
                , animationDirection = direction
                , targetElement = Nothing
                , frozenAxes = Dict.empty
                }
                elementConfig

        processedProps =
            processed.properties

        transforms =
            case maybeOrder of
                Nothing ->
                    Transforms.generateFromProcessed processedProps

                Just order ->
                    let
                        orderStrings =
                            List.map transformOrderToString order
                    in
                    Transforms.generateFromProcessedWithOrder orderStrings processedProps

        transitions =
            Transitions.generateFromProcessed processedProps

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

        transitionBehaviorStyle =
            if discreteTransitions then
                [ ( "transition-behavior", "allow-discrete" ) ]

            else
                []

        allStyles =
            [ ( "transform", transforms )
            , ( "transition", transitions )
            ]
                ++ transitionBehaviorStyle
                ++ colorStyles
                ++ opacityStyles
                |> List.filter (\( _, value ) -> not (String.isEmpty value))
    in
    { styles = allStyles
    , animationLayers =
        generateWithSuffix elementId suffix elementConfig.properties
            |> setIterationCount iterationCount
            |> setDirection direction
    , restartCounter = 0
    }


generateElementAnimationFromProcessed : Maybe (List Builder.TransformOrder) -> Bool -> Builder.IterationCount -> Builder.AnimationDirection -> String -> Builder.ProcessedElementConfig -> KeyframeElementData
generateElementAnimationFromProcessed maybeOrder discreteTransitions iterationCount direction elementId processed =
    generateElementAnimationFromProcessedWithSuffix maybeOrder discreteTransitions iterationCount direction "" elementId processed


generateElementAnimationFromProcessedWithSuffix : Maybe (List Builder.TransformOrder) -> Bool -> Builder.IterationCount -> Builder.AnimationDirection -> String -> String -> Builder.ProcessedElementConfig -> KeyframeElementData
generateElementAnimationFromProcessedWithSuffix maybeOrder discreteTransitions iterationCount direction suffix elementId processed =
    let
        processedProps =
            processed.properties

        transforms =
            case maybeOrder of
                Nothing ->
                    Transforms.generateFromProcessed processedProps

                Just order ->
                    let
                        orderStrings =
                            List.map transformOrderToString order
                    in
                    Transforms.generateFromProcessedWithOrder orderStrings processedProps

        transitions =
            Transitions.generateFromProcessed processedProps

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

        transitionBehaviorStyle =
            if discreteTransitions then
                [ ( "transition-behavior", "allow-discrete" ) ]

            else
                []

        allStyles =
            [ ( "transform", transforms )
            , ( "transition", transitions )
            ]
                ++ transitionBehaviorStyle
                ++ colorStyles
                ++ opacityStyles
                |> List.filter (\( _, value ) -> not (String.isEmpty value))
    in
    { styles = allStyles
    , animationLayers =
        generateWithSuffixFromProcessed elementId suffix processedProps
            |> setIterationCount iterationCount
            |> setDirection direction
    , restartCounter = 0
    }


generateStylesOnly : Maybe (List Builder.TransformOrder) -> Builder.ElementConfig -> KeyframeElementData
generateStylesOnly maybeOrder elementConfig =
    let
        processed =
            Builder.processElement
                { globalTiming = Nothing
                , globalEasing = Nothing
                , globalDelay = Nothing
                , globalTransformOrder = Nothing
                , currentElementId = Nothing
                , elements = Dict.empty
                , scrollTargets = []
                , scrollContainer = "document"
                , animationHistories = Dict.empty
                , nextAnimationId = 0
                , elementBaselines = Dict.empty
                , elementTargets = Dict.empty
                , discreteTransitions = False
                , iterationCount = Builder.Once
                , animationDirection = Builder.Normal
                , targetElement = Nothing
                , frozenAxes = Dict.empty
                }
                elementConfig

        processedProps =
            processed.properties

        transforms =
            case maybeOrder of
                Nothing ->
                    Transforms.generateFromProcessed processedProps

                Just order ->
                    let
                        orderStrings =
                            List.map transformOrderToString order
                    in
                    Transforms.generateFromProcessedWithOrder orderStrings processedProps

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

        allStyles =
            [ ( "transform", transforms )
            , ( "animation", "none" )
            , ( "transition", "none" )
            ]
                ++ colorStyles
                ++ opacityStyles
                |> List.filter (\( key, value ) -> key == "animation" || key == "transition" || not (String.isEmpty value))
    in
    { styles = allStyles
    , animationLayers = []
    , restartCounter = 0
    }


setStylesInstantly : String -> ElementState -> Builder.ElementConfig -> AnimState -> AnimState
setStylesInstantly elementId targetState elementConfig (AnimState state data) =
    let
        elemData =
            generateStylesOnly Nothing elementConfig
    in
    AnimState
        { state
            | elementStates = Dict.insert elementId targetState state.elementStates
        }
        (Dict.insert elementId elemData data)



-- KEYFRAME GENERATION


{-| Generate animation layers with an optional suffix for the animation name.
-}
generateWithSuffix : String -> String -> List Builder.PropertyConfig -> List KeyframeAnimation
generateWithSuffix elementId suffix properties =
    if List.isEmpty properties then
        []

    else
        let
            processed =
                Builder.processElement
                    { globalTiming = Nothing, globalEasing = Nothing, globalDelay = Nothing, globalTransformOrder = Nothing, currentElementId = Nothing, elements = Dict.empty, scrollTargets = [], scrollContainer = "document", animationHistories = Dict.empty, nextAnimationId = 0, elementBaselines = Dict.empty, elementTargets = Dict.empty, discreteTransitions = False, iterationCount = Builder.Once, animationDirection = Builder.Normal, targetElement = Nothing, frozenAxes = Dict.empty }
                    { properties = properties, targetElement = Nothing }
        in
        generateWithSuffixFromProcessed elementId suffix processed.properties


{-| Generate animation layers with a suffix, from already-processed properties.
-}
generateWithSuffixFromProcessed : String -> String -> List Builder.ProcessedPropertyConfig -> List KeyframeAnimation
generateWithSuffixFromProcessed elementId suffix processedProps =
    if List.isEmpty processedProps then
        []

    else
        let
            maxDuration =
                processedProps
                    |> List.map
                        (\p ->
                            case p of
                                Builder.ProcessedTranslateConfig cfg ->
                                    cfg.duration

                                Builder.ProcessedScaleConfig cfg ->
                                    cfg.duration

                                Builder.ProcessedRotateConfig cfg ->
                                    cfg.duration

                                Builder.ProcessedBackgroundColorConfig cfg ->
                                    cfg.duration

                                Builder.ProcessedFontColorConfig cfg ->
                                    cfg.duration

                                Builder.ProcessedOpacityConfig cfg ->
                                    cfg.duration

                                Builder.ProcessedSizeConfig cfg ->
                                    cfg.duration
                        )
                    |> List.maximum
                    |> Maybe.withDefault 0

            maxDelay =
                processedProps
                    |> List.map
                        (\p ->
                            case p of
                                Builder.ProcessedTranslateConfig cfg ->
                                    cfg.delay

                                Builder.ProcessedScaleConfig cfg ->
                                    cfg.delay

                                Builder.ProcessedRotateConfig cfg ->
                                    cfg.delay

                                Builder.ProcessedBackgroundColorConfig cfg ->
                                    cfg.delay

                                Builder.ProcessedFontColorConfig cfg ->
                                    cfg.delay

                                Builder.ProcessedOpacityConfig cfg ->
                                    cfg.delay

                                Builder.ProcessedSizeConfig cfg ->
                                    cfg.delay
                        )
                    |> List.maximum
                    |> Maybe.withDefault 0

            totalAnimationTime =
                maxDuration + maxDelay

            keyframeCount =
                30

            keyframeSteps =
                List.range 0 keyframeCount
                    |> List.map
                        (\i ->
                            let
                                globalProgress =
                                    toFloat i / toFloat keyframeCount

                                totalTime =
                                    globalProgress * toFloat totalAnimationTime

                                calculateProgress : Int -> Int -> Easing -> Float
                                calculateProgress propDelay propDuration propEasing =
                                    let
                                        linearProgress =
                                            if totalTime < toFloat propDelay then
                                                0

                                            else if propDuration == 0 then
                                                1.0

                                            else
                                                let
                                                    animationTime =
                                                        totalTime - toFloat propDelay
                                                in
                                                clamp 0 1 (animationTime / toFloat propDuration)

                                        easingFunction =
                                            Easing.toFunction (toFloat propDuration) propEasing
                                    in
                                    easingFunction linearProgress

                                transformParts =
                                    processedProps
                                        |> List.foldl
                                            (\p acc ->
                                                case p of
                                                    Builder.ProcessedTranslateConfig cfg ->
                                                        let
                                                            progress =
                                                                calculateProgress cfg.delay cfg.duration cfg.easing

                                                            startPos =
                                                                case cfg.start of
                                                                    Just s ->
                                                                        s

                                                                    Nothing ->
                                                                        Translate.default

                                                            interpolatedPos =
                                                                Translate.interpolate progress startPos cfg.end
                                                        in
                                                        { acc | translate = Translate.toCssString interpolatedPos }

                                                    Builder.ProcessedRotateConfig cfg ->
                                                        let
                                                            progress =
                                                                calculateProgress cfg.delay cfg.duration cfg.easing

                                                            startRot =
                                                                case cfg.start of
                                                                    Just s ->
                                                                        s

                                                                    Nothing ->
                                                                        Rotate.default

                                                            interpolatedRot =
                                                                Rotate.interpolate progress startRot cfg.end
                                                        in
                                                        { acc | rotate = Rotate.toCssString interpolatedRot }

                                                    Builder.ProcessedScaleConfig cfg ->
                                                        let
                                                            progress =
                                                                calculateProgress cfg.delay cfg.duration cfg.easing

                                                            startScale =
                                                                case cfg.start of
                                                                    Just s ->
                                                                        s

                                                                    Nothing ->
                                                                        Scale.default

                                                            interpolatedScale =
                                                                Scale.interpolate progress startScale cfg.end
                                                        in
                                                        { acc | scale = Scale.toCssString interpolatedScale }

                                                    _ ->
                                                        acc
                                            )
                                            { translate = "", rotate = "", scale = "" }

                                transformComponents =
                                    [ transformParts.translate, transformParts.rotate, transformParts.scale ]
                                        |> List.filter (\s -> s /= "")

                                transformStyle =
                                    if List.isEmpty transformComponents then
                                        Nothing

                                    else
                                        Just ( "transform", String.join " " transformComponents )

                                otherStyles =
                                    processedProps
                                        |> List.filterMap
                                            (\p ->
                                                case p of
                                                    Builder.ProcessedBackgroundColorConfig cfg ->
                                                        let
                                                            progress =
                                                                calculateProgress cfg.delay cfg.duration cfg.easing

                                                            startColor =
                                                                case cfg.start of
                                                                    Just c ->
                                                                        c

                                                                    Nothing ->
                                                                        BackgroundColor.default

                                                            interpolatedColor =
                                                                Color.interpolate startColor cfg.end progress
                                                        in
                                                        Just
                                                            [ ( "background-color", Color.toCssString interpolatedColor ) ]

                                                    Builder.ProcessedOpacityConfig cfg ->
                                                        let
                                                            progress =
                                                                calculateProgress cfg.delay cfg.duration cfg.easing

                                                            startOpacity =
                                                                case cfg.start of
                                                                    Just s ->
                                                                        s

                                                                    Nothing ->
                                                                        Opacity.default

                                                            interpolatedOpacity =
                                                                Opacity.interpolate progress startOpacity cfg.end
                                                        in
                                                        Just
                                                            [ ( "opacity", Opacity.toString interpolatedOpacity ) ]

                                                    Builder.ProcessedSizeConfig cfg ->
                                                        let
                                                            progress =
                                                                calculateProgress cfg.delay cfg.duration cfg.easing

                                                            startSize =
                                                                case cfg.start of
                                                                    Just s ->
                                                                        s

                                                                    Nothing ->
                                                                        Size.default

                                                            interpolated =
                                                                Size.interpolate progress startSize cfg.end

                                                            ( interpolatedW, interpolatedH ) =
                                                                Size.toTuple interpolated
                                                        in
                                                        Just
                                                            [ ( "width", String.fromFloat interpolatedW ++ "px" )
                                                            , ( "height", String.fromFloat interpolatedH ++ "px" )
                                                            ]

                                                    _ ->
                                                        Nothing
                                            )

                                styles =
                                    case transformStyle of
                                        Just t ->
                                            t :: List.concat otherStyles

                                        Nothing ->
                                            List.concat otherStyles
                            in
                            ( globalProgress, styles )
                        )

            contentForHash =
                elementId
                    ++ String.fromInt maxDuration
                    ++ String.fromInt maxDelay
                    ++ (processedProps
                            |> List.map
                                (\p ->
                                    case p of
                                        Builder.ProcessedTranslateConfig cfg ->
                                            "pos-" ++ String.fromInt cfg.duration ++ "-" ++ String.fromInt cfg.delay ++ "-" ++ Translate.toCssString cfg.end ++ "-" ++ (cfg.start |> Maybe.map Translate.toCssString |> Maybe.withDefault "none")

                                        Builder.ProcessedScaleConfig cfg ->
                                            "scale-" ++ String.fromInt cfg.duration ++ "-" ++ String.fromInt cfg.delay ++ "-" ++ Scale.toCssString cfg.end ++ "-" ++ (cfg.start |> Maybe.map Scale.toCssString |> Maybe.withDefault "none")

                                        Builder.ProcessedRotateConfig cfg ->
                                            "rot-" ++ String.fromInt cfg.duration ++ "-" ++ String.fromInt cfg.delay ++ "-" ++ Rotate.toCssString cfg.end ++ "-" ++ (cfg.start |> Maybe.map Rotate.toCssString |> Maybe.withDefault "none")

                                        Builder.ProcessedBackgroundColorConfig cfg ->
                                            "bg-" ++ String.fromInt cfg.duration ++ "-" ++ String.fromInt cfg.delay ++ "-" ++ Color.toCssString cfg.end ++ "-" ++ (cfg.start |> Maybe.map Color.toCssString |> Maybe.withDefault "none")

                                        Builder.ProcessedFontColorConfig cfg ->
                                            "color-" ++ String.fromInt cfg.duration ++ "-" ++ String.fromInt cfg.delay ++ "-" ++ Color.toCssString cfg.end ++ "-" ++ (cfg.start |> Maybe.map Color.toCssString |> Maybe.withDefault "none")

                                        Builder.ProcessedOpacityConfig cfg ->
                                            "opacity-" ++ String.fromInt cfg.duration ++ "-" ++ String.fromInt cfg.delay ++ "-" ++ Opacity.toString cfg.end ++ "-" ++ (cfg.start |> Maybe.map Opacity.toString |> Maybe.withDefault "none")

                                        Builder.ProcessedSizeConfig cfg ->
                                            "size-" ++ String.fromInt cfg.duration ++ "-" ++ String.fromInt cfg.delay ++ "-" ++ Size.toString cfg.end ++ "-" ++ (cfg.start |> Maybe.map Size.toString |> Maybe.withDefault "none")
                                )
                            |> String.join "-"
                       )

            betterHash =
                contentForHash
                    |> String.toList
                    |> List.foldl
                        (\char acc ->
                            let
                                code =
                                    Char.toCode char
                            in
                            (acc * 31 + code) |> modBy 1000000007
                        )
                        0

            animationName =
                elementId
                    ++ "-anim-"
                    ++ String.fromInt betterHash
                    ++ (if String.isEmpty suffix then
                            ""

                        else
                            "-" ++ suffix
                       )

            keyframesString =
                buildKeyframesString animationName keyframeSteps

            animatedProperties =
                [ "transform", "background-color", "opacity", "width", "height" ]
        in
        [ { animationName = animationName
          , keyframes = keyframesString
          , duration = totalAnimationTime
          , easing = "linear"
          , delay = 0
          , properties = animatedProperties
          , iterationCount = Builder.Once
          , direction = Builder.Normal
          }
        ]


setIterationCount : Builder.IterationCount -> List KeyframeAnimation -> List KeyframeAnimation
setIterationCount count layers =
    List.map (\layer -> { layer | iterationCount = count }) layers


setDirection : Builder.AnimationDirection -> List KeyframeAnimation -> List KeyframeAnimation
setDirection dir layers =
    List.map (\layer -> { layer | direction = dir }) layers


toAttributeString : List KeyframeAnimation -> String
toAttributeString animationLayers =
    if not (List.isEmpty animationLayers) then
        animationLayers
            |> List.map
                (\layer ->
                    let
                        iterationString =
                            case layer.iterationCount of
                                Builder.Once ->
                                    "1"

                                Builder.Times n ->
                                    String.fromInt n

                                Builder.Infinite ->
                                    "infinite"

                        directionString =
                            case layer.direction of
                                Builder.Normal ->
                                    "normal"

                                Builder.Alternate ->
                                    "alternate"
                    in
                    layer.animationName
                        ++ " "
                        ++ String.fromInt layer.duration
                        ++ "ms "
                        ++ layer.easing
                        ++ " "
                        ++ String.fromInt layer.delay
                        ++ "ms "
                        ++ iterationString
                        ++ " "
                        ++ directionString
                        ++ " forwards"
                )
            |> String.join ", "

    else
        ""


buildKeyframesString : String -> List ( Float, List ( String, String ) ) -> String
buildKeyframesString name steps =
    let
        stepToString : ( Float, List ( String, String ) ) -> String
        stepToString ( progress, styles ) =
            let
                percentage =
                    String.fromFloat (progress * 100) ++ "%"

                styleStrings =
                    List.map (\( prop, value ) -> "  " ++ prop ++ ": " ++ value ++ ";") styles
            in
            percentage ++ " {\n" ++ String.join "\n" styleStrings ++ "\n}"

        stepsString =
            List.map stepToString steps |> String.join "\n\n"

        animationPropertiesComment =
            "\n\n/* Animation properties for "
                ++ name
                ++ " */\n"
    in
    "@keyframes " ++ name ++ " {\n" ++ stepsString ++ "\n}" ++ animationPropertiesComment
