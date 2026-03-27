module Anim.Internal.CSS.Keyframes exposing
    ( AnimGroup
    , AnimState
    , Animation
    , animate
    , animationNameDecoder
    , extractAnimGroupNameFromAnimationName
    , generateWithSuffix
    , generateWithSuffixFromProcessed
    , getElementAnimation
    , getKeyframes
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
import Dict
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode


type alias AnimState =
    InternalCSS.AnimState AnimGroup


type alias AnimGroup =
    { styles : List ( String, String )
    , animationLayers : List Animation
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
    Dict.get animGroupName (InternalCSS.elementData animState)



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
                        |> Builder.mergeEndStates
                        |> Builder.clearAnimData
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

        animGroupNames =
            processedData.elements
                |> Dict.keys

        builderWithHistory =
            Dict.foldl
                (\animGroupName _ accBuilder ->
                    Builder.addAnimationToHistory animGroupName processedData Nothing accBuilder
                        |> Tuple.first
                )
                builder_
                processedData.elements

        newElementData =
            processedData.elements
                |> Dict.map
                    (\animGroupName processed ->
                        generateElementAnimationFromProcessed
                            processedData.globalTransformOrder
                            (Builder.discreteTransitionsEnabled builder_)
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
keyframesAttribute animGroupName animState =
    case getElementAnimation animGroupName animState of
        Just elemData ->
            Html.Attributes.style "animation"
                (toAttributeString elemData.animationLayers)

        Nothing ->
            Html.Attributes.style "animation" ""


{-| Get all styles for keyframe-based animations as a list of Html attributes.
-}
keyframesStyles : String -> AnimState -> List (Html.Attribute msg)
keyframesStyles animGroupName animState =
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


keyframesStyleNodeFor : AnimGroupName -> AnimState -> Html msg
keyframesStyleNodeFor animGroupName (AnimState _ data) =
    case Dict.get animGroupName data of
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


getKeyframes : AnimGroupName -> AnimState -> Maybe String
getKeyframes animGroupName (AnimState _ data) =
    Dict.get animGroupName data
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


{-| Resume a paused keyframe animation by setting animation-play-state to running.
-}
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
stopAnimation : AnimGroupName -> AnimState -> AnimState
stopAnimation animGroupName ((AnimState state _) as animState) =
    let
        properties =
            InternalCSS.buildStopProperties animGroupName state.builder

        elementConfig =
            { properties = properties, targetElement = Nothing }
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
            InternalCSS.buildResetProperties animGroupName state.builder

        newElementConfig =
            { properties = properties, targetElement = Nothing }
    in
    if List.isEmpty properties then
        AnimState state data

    else
        setStylesInstantly animGroupName NotStarted newElementConfig (AnimState state data)


{-| Restart an animation from the beginning.
-}
restartAnimation : AnimGroupName -> AnimState -> AnimState
restartAnimation animGroupName ((AnimState state data) as animState) =
    let
        maybeFromHistory =
            Builder.getCurrentAnimation animGroupName state.builder
                |> Maybe.andThen (\entry -> Dict.get animGroupName entry.processedData.elements)

        currentCounter =
            Dict.get animGroupName data
                |> Maybe.map .restartCounter
                |> Maybe.withDefault 0

        newCounter =
            currentCounter + 1

        restartSuffix =
            "r" ++ String.fromInt newCounter

        applyRestart : AnimGroup -> AnimState
        applyRestart elemData =
            let
                (AnimState resetState resetData) =
                    reset animGroupName animState
            in
            AnimState
                { resetState
                    | elementStates = Dict.insert animGroupName NotStarted resetState.elementStates
                }
                (Dict.insert animGroupName { elemData | restartCounter = newCounter } resetData)
    in
    case maybeFromHistory of
        Just processedElementConfig ->
            generateElementAnimationFromProcessedWithSuffix (Builder.getTransformOrder state.builder) (Builder.discreteTransitionsEnabled state.builder) (Builder.getIterationCount state.builder) (Builder.getAnimationDirection state.builder) (Builder.getElementTarget animGroupName state.builder) restartSuffix animGroupName processedElementConfig
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


{-| Build baseline transform parts from element targets, only for properties
not being animated in the current processedProps.
-}
baselineTransformParts : Maybe Builder.ElementEndStates -> List Builder.ProcessedPropertyConfig -> Builder.TransformParts
baselineTransformParts maybeTargets processedProps =
    case maybeTargets of
        Nothing ->
            { translate = "", rotate = "", scale = "" }

        Just targets ->
            let
                hasType checker =
                    List.any checker processedProps
            in
            { translate =
                if
                    hasType
                        (\p ->
                            case p of
                                Builder.ProcessedTranslateConfig _ ->
                                    True

                                _ ->
                                    False
                        )
                then
                    ""

                else
                    targets.translate |> Maybe.map Translate.toCssString |> Maybe.withDefault ""
            , rotate =
                if
                    hasType
                        (\p ->
                            case p of
                                Builder.ProcessedRotateConfig _ ->
                                    True

                                _ ->
                                    False
                        )
                then
                    ""

                else
                    targets.rotate |> Maybe.map Rotate.toCssString |> Maybe.withDefault ""
            , scale =
                if
                    hasType
                        (\p ->
                            case p of
                                Builder.ProcessedScaleConfig _ ->
                                    True

                                _ ->
                                    False
                        )
                then
                    ""

                else
                    targets.scale |> Maybe.map Scale.toCssString |> Maybe.withDefault ""
            }


mergeTransformParts : Builder.TransformParts -> Builder.TransformParts -> Builder.TransformParts
mergeTransformParts baseline animated =
    { translate =
        if animated.translate /= "" then
            animated.translate

        else
            baseline.translate
    , rotate =
        if animated.rotate /= "" then
            animated.rotate

        else
            baseline.rotate
    , scale =
        if animated.scale /= "" then
            animated.scale

        else
            baseline.scale
    }


transformPartsToString : Maybe (List Builder.TransformOrder) -> Builder.TransformParts -> String
transformPartsToString maybeOrder parts =
    let
        orderedParts =
            case maybeOrder of
                Nothing ->
                    [ parts.translate, parts.rotate, parts.scale ]

                Just order ->
                    List.filterMap
                        (\o ->
                            case o of
                                Builder.Translate ->
                                    if parts.translate /= "" then
                                        Just parts.translate

                                    else
                                        Nothing

                                Builder.Rotate ->
                                    if parts.rotate /= "" then
                                        Just parts.rotate

                                    else
                                        Nothing

                                Builder.Scale ->
                                    if parts.scale /= "" then
                                        Just parts.scale

                                    else
                                        Nothing
                        )
                        order
    in
    orderedParts
        |> List.filter (\s -> s /= "")
        |> String.join " "



-- CSS GENERATION


generateElementAnimation : Maybe (List Builder.TransformOrder) -> Bool -> Builder.IterationCount -> Builder.AnimationDirection -> AnimGroupName -> Builder.ElementConfig -> AnimGroup
generateElementAnimation maybeOrder discreteTransitions iterationCount direction animGroupName elementConfig =
    generateElementAnimationWithSuffix maybeOrder discreteTransitions iterationCount direction "" animGroupName elementConfig


generateElementAnimationWithSuffix : Maybe (List Builder.TransformOrder) -> Bool -> Builder.IterationCount -> Builder.AnimationDirection -> String -> AnimGroupName -> Builder.ElementConfig -> AnimGroup
generateElementAnimationWithSuffix maybeOrder discreteTransitions iterationCount direction suffix animGroupName elementConfig =
    let
        processed =
            Builder.processElement
                { globalTiming = Nothing
                , globalEasing = Nothing
                , globalDelay = Nothing
                , globalTransformOrder = Nothing
                , currentAnimGroup = Nothing
                , animGroups = Dict.empty
                , scrollTargets = []
                , scrollContainer = "document"
                , animationHistories = Dict.empty
                , nextAnimationId = 0
                , animationBaselines = Dict.empty
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
                    generate processedProps

                Just order ->
                    let
                        orderStrings =
                            List.map transformOrderToString order
                    in
                    generateWithOrder orderStrings processedProps

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
                ++ fontColorStyles
                ++ opacityStyles
                ++ sizeStyles
                |> List.filter (\( _, value ) -> not (String.isEmpty value))
    in
    { styles = allStyles
    , animationLayers =
        generateWithSuffix maybeOrder animGroupName suffix elementConfig.properties
            |> setIterationCount iterationCount
            |> setDirection direction
    , restartCounter = 0
    }


generateElementAnimationFromProcessed : Maybe (List Builder.TransformOrder) -> Bool -> Builder.IterationCount -> Builder.AnimationDirection -> Maybe Builder.ElementEndStates -> AnimGroupName -> Builder.ProcessedElementConfig -> AnimGroup
generateElementAnimationFromProcessed maybeOrder discreteTransitions iterationCount direction maybeTargets animGroupName processed =
    generateElementAnimationFromProcessedWithSuffix maybeOrder discreteTransitions iterationCount direction maybeTargets "" animGroupName processed


generateElementAnimationFromProcessedWithSuffix : Maybe (List Builder.TransformOrder) -> Bool -> Builder.IterationCount -> Builder.AnimationDirection -> Maybe Builder.ElementEndStates -> String -> AnimGroupName -> Builder.ProcessedElementConfig -> AnimGroup
generateElementAnimationFromProcessedWithSuffix maybeOrder discreteTransitions iterationCount direction maybeTargets suffix animGroupName processed =
    let
        processedProps =
            processed.properties

        baseline =
            baselineTransformParts maybeTargets processedProps

        animatedParts =
            Builder.extractTransformsFromProcessed processedProps

        transforms =
            transformPartsToString maybeOrder (mergeTransformParts baseline animatedParts)

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
                ++ fontColorStyles
                ++ opacityStyles
                ++ sizeStyles
                |> List.filter (\( _, value ) -> not (String.isEmpty value))
    in
    { styles = allStyles
    , animationLayers =
        generateWithSuffixFromProcessed maybeOrder maybeTargets animGroupName suffix processedProps
            |> setIterationCount iterationCount
            |> setDirection direction
    , restartCounter = 0
    }


generateStylesOnly : Maybe (List Builder.TransformOrder) -> Builder.ElementConfig -> AnimGroup
generateStylesOnly maybeOrder elementConfig =
    let
        processed =
            Builder.processElement
                { globalTiming = Nothing
                , globalEasing = Nothing
                , globalDelay = Nothing
                , globalTransformOrder = Nothing
                , currentAnimGroup = Nothing
                , animGroups = Dict.empty
                , scrollTargets = []
                , scrollContainer = "document"
                , animationHistories = Dict.empty
                , nextAnimationId = 0
                , animationBaselines = Dict.empty
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
                    generate processedProps

                Just order ->
                    let
                        orderStrings =
                            List.map transformOrderToString order
                    in
                    generateWithOrder orderStrings processedProps

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

        allStyles =
            [ ( "transform", transforms )
            , ( "animation", "none" )
            , ( "transition", "none" )
            ]
                ++ colorStyles
                ++ fontColorStyles
                ++ opacityStyles
                ++ sizeStyles
                |> List.filter (\( key, value ) -> key == "animation" || key == "transition" || not (String.isEmpty value))
    in
    { styles = allStyles
    , animationLayers = []
    , restartCounter = 0
    }


setStylesInstantly : AnimGroupName -> ElementState -> Builder.ElementConfig -> AnimState -> AnimState
setStylesInstantly animGroupName targetState elementConfig (AnimState state data) =
    let
        elementStates =
            Dict.insert animGroupName targetState state.elementStates

        elemData =
            generateStylesOnly Nothing elementConfig

        newData =
            Dict.insert animGroupName elemData data
    in
    AnimState
        { state | elementStates = elementStates }
        newData



-- KEYFRAME GENERATION


{-| Generate animation layers with an optional suffix for the animation name.
-}
generateWithSuffix : Maybe (List Builder.TransformOrder) -> AnimGroupName -> String -> List Builder.PropertyConfig -> List Animation
generateWithSuffix maybeOrder animGroupName suffix properties =
    if List.isEmpty properties then
        []

    else
        let
            processed =
                Builder.processElement
                    { globalTiming = Nothing
                    , globalEasing = Nothing
                    , globalDelay = Nothing
                    , globalTransformOrder = Nothing
                    , currentAnimGroup = Nothing
                    , animGroups = Dict.empty
                    , scrollTargets = []
                    , scrollContainer = "document"
                    , animationHistories = Dict.empty
                    , nextAnimationId = 0
                    , animationBaselines = Dict.empty
                    , elementTargets = Dict.empty
                    , discreteTransitions = False
                    , iterationCount = Builder.Once
                    , animationDirection = Builder.Normal
                    , targetElement = Nothing
                    , frozenAxes = Dict.empty
                    }
                    { properties = properties, targetElement = Nothing }
        in
        generateWithSuffixFromProcessed maybeOrder Nothing animGroupName suffix processed.properties


{-| Generate animation layers with a suffix, from already-processed properties.
-}
generateWithSuffixFromProcessed : Maybe (List Builder.TransformOrder) -> Maybe Builder.ElementEndStates -> AnimGroupName -> String -> List Builder.ProcessedPropertyConfig -> List Animation
generateWithSuffixFromProcessed maybeOrder maybeTargets animGroupName suffix processedProps =
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

                                baselineParts =
                                    baselineTransformParts maybeTargets processedProps

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
                                            baselineParts

                                transformComponents =
                                    (case maybeOrder of
                                        Nothing ->
                                            [ transformParts.translate, transformParts.rotate, transformParts.scale ]

                                        Just order ->
                                            List.filterMap
                                                (\o ->
                                                    case o of
                                                        Builder.Translate ->
                                                            if transformParts.translate /= "" then
                                                                Just transformParts.translate

                                                            else
                                                                Nothing

                                                        Builder.Rotate ->
                                                            if transformParts.rotate /= "" then
                                                                Just transformParts.rotate

                                                            else
                                                                Nothing

                                                        Builder.Scale ->
                                                            if transformParts.scale /= "" then
                                                                Just transformParts.scale

                                                            else
                                                                Nothing
                                                )
                                                order
                                    )
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

            orderHash =
                case maybeOrder of
                    Nothing ->
                        ""

                    Just order ->
                        "-order-" ++ (List.map transformOrderToString order |> String.join "-")

            contentForHash =
                animGroupName
                    ++ orderHash
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
                animGroupName
                    ++ "-anim-"
                    ++ String.fromInt betterHash
                    ++ (if String.isEmpty suffix then
                            ""

                        else
                            "-" ++ suffix
                       )

            keyframesString =
                buildKeyframesString animationName keyframeSteps
        in
        [ { animationName = animationName
          , keyframes = keyframesString
          , duration = totalAnimationTime
          , easing = "linear"
          , delay = 0
          , iterationCount = Builder.Once
          , direction = Builder.Normal
          }
        ]


setIterationCount : Builder.IterationCount -> List Animation -> List Animation
setIterationCount count layers =
    List.map (\layer -> { layer | iterationCount = count }) layers


setDirection : Builder.AnimationDirection -> List Animation -> List Animation
setDirection dir layers =
    List.map (\layer -> { layer | direction = dir }) layers


toAttributeString : List Animation -> String
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


{-| Generate the CSS transform string from processed properties.
-}
generate : List Builder.ProcessedPropertyConfig -> String
generate properties =
    let
        transformParts =
            extractTransformsFromProcessed properties
    in
    String.trim (transformParts.translate ++ " " ++ transformParts.rotate ++ " " ++ transformParts.scale)


{-| Generate transform from processed properties with custom ordering.
-}
generateWithOrder : List String -> List Builder.ProcessedPropertyConfig -> String
generateWithOrder order properties =
    let
        transformParts =
            extractTransformsFromProcessed properties

        -- Build transform string in the specified order
        orderedTransforms =
            List.filterMap (getTransformByName transformParts) order
    in
    String.trim (String.join " " orderedTransforms)


{-| Get the transform string for a given property name.
-}
getTransformByName : Builder.TransformParts -> String -> Maybe String
getTransformByName parts name =
    case name of
        "translate" ->
            if String.isEmpty parts.translate then
                Nothing

            else
                Just parts.translate

        "rotate" ->
            if String.isEmpty parts.rotate then
                Nothing

            else
                Just parts.rotate

        "scale" ->
            if String.isEmpty parts.scale then
                Nothing

            else
                Just parts.scale

        _ ->
            Nothing


{-| Extract transform parts from processed properties.
-}
extractTransformsFromProcessed : List Builder.ProcessedPropertyConfig -> Builder.TransformParts
extractTransformsFromProcessed properties =
    List.foldl collectProcessedTransform emptyTransformParts properties


emptyTransformParts : Builder.TransformParts
emptyTransformParts =
    { translate = ""
    , rotate = ""
    , scale = ""
    }


collectProcessedTransform : Builder.ProcessedPropertyConfig -> Builder.TransformParts -> Builder.TransformParts
collectProcessedTransform property acc =
    case property of
        Builder.ProcessedTranslateConfig config ->
            { acc | translate = Translate.toCssString config.end }

        Builder.ProcessedRotateConfig config ->
            { acc | rotate = Rotate.toCssString config.end }

        Builder.ProcessedScaleConfig config ->
            let
                ( x, y ) =
                    Scale.toTuple config.end
            in
            { acc | scale = "scale(" ++ String.fromFloat x ++ ", " ++ String.fromFloat y ++ ")" }

        _ ->
            acc
