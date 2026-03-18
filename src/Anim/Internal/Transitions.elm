module Anim.Internal.Transitions exposing (..)

{-| Transitions-specific generation functions.

These produce individual CSS `translate`, `rotate`, `scale` properties
instead of the composite `transform` property, enabling independent
transitions per transform type.

-}

import Anim.Extra.Easing
import Anim.Internal.Builder as Builder
import Anim.Internal.CSS as InternalCSS exposing (AnimState(..), ElementState(..))
import Anim.Internal.CSS.Transition as Transitions
import Anim.Internal.Properties.Color as Color exposing (Color(..))
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Properties.Translate as Translate
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Dict
import Html
import Html.Attributes


type alias ElementAnimation =
    { styles : List ( String, String )
    }


init : List (Builder.AnimBuilder -> Builder.AnimBuilder) -> AnimState
init propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { elementAnimations = Dict.empty
                , elementStates = Dict.empty
                , builder = Builder.init
                , restartCounters = Dict.empty
                }

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
                { elementAnimations =
                    configuredBuilder
                        |> Builder.elements
                        |> Dict.map
                            (\elementId elementConfig ->
                                generateElementAnimation
                                    (Builder.discreteTransitionsEnabled configuredBuilder)
                                    elementId
                                    elementConfig
                                    |> toInternalElementAnimation
                            )
                , elementStates =
                    elementIds
                        |> List.map (\id -> ( id, NotStarted ))
                        |> Dict.fromList
                , builder =
                    configuredBuilder
                        |> Builder.clearCurrentElement
                , restartCounters = Dict.empty
                }


animate : AnimState -> (Builder.AnimBuilder -> Builder.AnimBuilder) -> AnimState
animate (AnimState state) transform =
    let
        builder_ =
            state.builder
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

        newElementAnimations =
            processedData.elements
                |> Dict.map
                    (\elementId processed ->
                        generateElementAnimationFromProcessed
                            (Builder.discreteTransitionsEnabled builder_)
                            elementId
                            processed
                            |> toInternalElementAnimation
                    )

        mergedAnimations =
            Dict.foldl
                (\elementId newAnim acc ->
                    case Dict.get elementId acc of
                        Nothing ->
                            Dict.insert elementId newAnim acc

                        Just existingAnim ->
                            let
                                newCssProps =
                                    Dict.get elementId processedData.elements
                                        |> Maybe.map (.properties >> cssPropertyNamesForProcessed)
                                        |> Maybe.withDefault []
                            in
                            Dict.insert elementId
                                (mergeElementStyles newCssProps newAnim existingAnim)
                                acc
                )
                state.elementAnimations
                newElementAnimations

        mergedElementStates =
            Dict.union
                (elementIds
                    |> List.map (\id -> ( id, NotStarted ))
                    |> Dict.fromList
                )
                state.elementStates
    in
    AnimState
        { elementAnimations = mergedAnimations
        , elementStates = mergedElementStates
        , builder =
            builderWithHistory
                |> Builder.clearCurrentElement
        , restartCounters = Dict.empty
        }


transitionAttributes : String -> AnimState -> List (Html.Attribute msg)
transitionAttributes elementId (AnimState state) =
    let
        styles =
            Dict.get elementId state.elementAnimations
                |> Maybe.map .styles
                |> Maybe.withDefault []

        styleAttrs =
            List.map (\( prop, value ) -> Html.Attributes.style prop value) styles

        dataAttr =
            Html.Attributes.attribute "data-anim-group-name" elementId
    in
    dataAttr :: styleAttrs


startingStyleNode : AnimState -> Html.Html msg
startingStyleNode ((AnimState state) as animState) =
    let
        elementIds =
            Dict.keys state.elementAnimations

        allStartingStyles =
            elementIds
                |> List.filterMap (\id -> generateStartingStyleForElement id animState)
                |> String.join "\n"
    in
    if String.isEmpty allStartingStyles then
        Html.text ""

    else
        Html.node "style" [] [ Html.text ("@starting-style {\n" ++ allStartingStyles ++ "\n}") ]


startingStyleNodeFor : String -> AnimState -> Html.Html msg
startingStyleNodeFor elementId animState =
    case generateStartingStyleForElement elementId animState of
        Just css ->
            Html.node "style" [] [ Html.text ("@starting-style {\n" ++ css ++ "\n}") ]

        Nothing ->
            Html.text ""


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


reset : String -> AnimState -> AnimState
reset elementId (AnimState state) =
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
                                                        (Maybe.withDefault
                                                            (Color.fromRGBA { r = 0, g = 0, b = 0, a = 1 })
                                                            config.start
                                                        )
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
                                                        (Maybe.withDefault
                                                            (Color.fromRGBA { r = 0, g = 0, b = 0, a = 1 })
                                                            config.start
                                                        )
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
        AnimState state

    else
        setStylesInstantly elementId NotStarted newElementConfig (AnimState state)



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
    -> InternalCSS.ElementAnimation
    -> InternalCSS.ElementAnimation
    -> InternalCSS.ElementAnimation
mergeElementStyles newCssProps newAnim existingAnim =
    let
        isMetaStyle key =
            key == "transition" || key == "transition-behavior"

        preservedOldStyles =
            existingAnim.styles
                |> List.filter
                    (\( key, _ ) ->
                        not (isMetaStyle key) && not (List.member key newCssProps)
                    )

        newPropertyStyles =
            newAnim.styles
                |> List.filter (\( key, _ ) -> not (isMetaStyle key))

        -- Parse transition string into individual parts
        splitTransitionParts value =
            if value == "none" || String.isEmpty value then
                []

            else
                String.split ", " value

        transitionPartCssProp part =
            String.split " " part
                |> List.head
                |> Maybe.withDefault ""

        oldTransitionValue =
            existingAnim.styles
                |> List.filter (\( key, _ ) -> key == "transition")
                |> List.head
                |> Maybe.map Tuple.second
                |> Maybe.withDefault "none"

        newTransitionValue =
            newAnim.styles
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
            List.any (\( key, _ ) -> key == "transition-behavior") existingAnim.styles
                || List.any (\( key, _ ) -> key == "transition-behavior") newAnim.styles

        transitionBehaviorStyles =
            if hasTransitionBehavior then
                [ ( "transition-behavior", "allow-discrete" ) ]

            else
                []
    in
    { styles =
        ( "transition", mergedTransition )
            :: newPropertyStyles
            ++ preservedOldStyles
            ++ transitionBehaviorStyles
    , animationLayers = []
    }



-- INTERNAL GENERATION


toInternalElementAnimation : ElementAnimation -> InternalCSS.ElementAnimation
toInternalElementAnimation ea =
    { styles = ea.styles
    , animationLayers = []
    }


setStylesInstantly : String -> ElementState -> Builder.ElementConfig -> AnimState -> AnimState
setStylesInstantly elementId targetState elementConfig (AnimState state) =
    let
        elementAnimation =
            generateStylesOnly elementConfig
                |> toInternalElementAnimation
    in
    AnimState
        { state
            | elementAnimations = Dict.insert elementId elementAnimation state.elementAnimations
            , elementStates = Dict.insert elementId targetState state.elementStates
        }


generateElementAnimation : Bool -> String -> Builder.ElementConfig -> ElementAnimation
generateElementAnimation discreteTransitions elementId elementConfig =
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
                , iterationCount = Builder.Once
                , animationDirection = Builder.Normal
                , targetElement = Nothing
                , frozenAxes = Dict.empty
                }
                elementConfig
    in
    generateFromProcessedProps discreteTransitions processed.properties


generateElementAnimationFromProcessed : Bool -> String -> Builder.ProcessedElementConfig -> ElementAnimation
generateElementAnimationFromProcessed discreteTransitions elementId processed =
    generateFromProcessedProps discreteTransitions processed.properties


generateFromProcessedProps : Bool -> List Builder.ProcessedPropertyConfig -> ElementAnimation
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
    { styles = allStyles }


generateStylesOnly : Builder.ElementConfig -> ElementAnimation
generateStylesOnly elementConfig =
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
    { styles = allStyles }


generateStartingStyleForElement : String -> AnimState -> Maybe String
generateStartingStyleForElement elementId (AnimState state) =
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

                    translateStyles =
                        elementConfig.properties
                            |> List.filterMap
                                (\prop ->
                                    case prop of
                                        Builder.ProcessedTranslateConfig config ->
                                            config.start
                                                |> Maybe.map (\start -> "translate: " ++ Translate.toCssPropertyValue start ++ ";")

                                        _ ->
                                            Nothing
                                )

                    rotateStyles =
                        elementConfig.properties
                            |> List.filterMap
                                (\prop ->
                                    case prop of
                                        Builder.ProcessedRotateConfig config ->
                                            config.start
                                                |> Maybe.map (\start -> "transform: " ++ Rotate.toCssString start ++ ";")

                                        _ ->
                                            Nothing
                                )

                    scaleStyles =
                        elementConfig.properties
                            |> List.filterMap
                                (\prop ->
                                    case prop of
                                        Builder.ProcessedScaleConfig config ->
                                            config.start
                                                |> Maybe.map (\start -> "scale: " ++ Scale.toCssPropertyValue start ++ ";")

                                        _ ->
                                            Nothing
                                )

                    allStyles =
                        translateStyles ++ rotateStyles ++ scaleStyles ++ nonTransformStyles
                in
                if List.isEmpty allStyles then
                    Nothing

                else
                    Just
                        ("  [data-anim-group-name=\""
                            ++ elementId
                            ++ "\"] {\n"
                            ++ String.join "\n" (List.map (\s -> "    " ++ s) allStyles)
                            ++ "\n  }"
                        )
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
