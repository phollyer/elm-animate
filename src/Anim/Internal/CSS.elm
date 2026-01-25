module Anim.Internal.CSS exposing
    ( AnimBuilder
    , AnimState
    , ElementState(..)
    , Event(..)
    , TransformOrder(..)
    , allComplete
    , animate
    , animateWithOrder
    , animationStyleAttribute
    , anyRunning
    , builder
    , delay
    , duration
    , easing
    , getBackgroundColorRange
    , getElementAnimation
    , getElementKeyframes
    , getOpacityRange
    , getRotateRange
    , getScaleRange
    , getSizeRange
    , getStartTranslate
    , getState
    , getTranslate
    , getTranslateAnimationDuration
    , getTranslateRange
    , handleEvent
    , init
    , isElementComplete
    , isElementRunning
    , keyframesStyleNode
    , keyframesStyleNodeFor
    , onAnimationCancel
    , onAnimationEnd
    , onAnimationIteration
    , onAnimationStart
    , onTransitionCancel
    , onTransitionEnd
    , onTransitionRun
    , onTransitionStart
    , pauseAnimation
    , perspective
    , perspectiveStyles
    , resetAnimation
    , restartAnimation
    , resumeAnimation
    , speed
    , stopAnimation
    , transitionAttributes
    )

import Anim.Easing exposing (Easing)
import Anim.Internal.Builder as Builder
import Anim.Internal.Builders.Property as Property
import Anim.Internal.CSS.KeyframeAnimation as KeyframeAnimation exposing (KeyframeAnimation)
import Anim.Internal.CSS.Transform as Transforms
import Anim.Internal.CSS.Transition as Transitions
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Color as Color exposing (Color(..))
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Properties.Translate as Translate exposing (Translate)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode



-- Build


type alias AnimBuilder =
    Builder.AnimBuilder


type alias ElementId =
    String


type AnimState
    = AnimState
        { elementAnimations : Dict ElementId ElementAnimation
        , elementStates : Dict ElementId ElementState
        , builder : AnimBuilder
        }


type alias ElementAnimation =
    { styles : List ( String, String )
    , animationLayers : List KeyframeAnimation
    }


init : AnimState
init =
    AnimState
        { elementAnimations = Dict.empty
        , elementStates = Dict.empty
        , builder = Builder.init
        }


builder : AnimState -> AnimBuilder
builder (AnimState state) =
    state.builder


animate : AnimBuilder -> AnimState
animate builder_ =
    let
        builderWithCache =
            Builder.computeAndCachePerspectiveStyles builder_

        elementIds =
            builderWithCache
                |> Builder.elements
                |> Dict.keys
    in
    AnimState
        { elementAnimations =
            builderWithCache
                |> Builder.elements
                |> Dict.map (generateElementAnimation Nothing)
        , elementStates =
            elementIds
                |> List.map (\id -> ( id, NotStarted ))
                |> Dict.fromList
        , builder =
            builderWithCache
                |> Builder.markDirty
                |> Builder.clearCurrentElement
        }


type TransformOrder
    = Translate
    | Rotate
    | Scale


{-| Apply animation with custom transform ordering.
-}
animateWithOrder : List TransformOrder -> AnimBuilder -> AnimState
animateWithOrder order builder_ =
    let
        builderWithCache =
            Builder.computeAndCachePerspectiveStyles builder_

        elementIds =
            builderWithCache
                |> Builder.elements
                |> Dict.keys
    in
    AnimState
        { elementAnimations =
            builderWithCache
                |> Builder.elements
                |> Dict.map (generateElementAnimation (Just order))
        , elementStates =
            elementIds
                |> List.map (\id -> ( id, NotStarted ))
                |> Dict.fromList
        , builder = Builder.markDirty builderWithCache
        }


duration : Int -> AnimBuilder -> AnimBuilder
duration =
    Builder.duration


speed : Float -> AnimBuilder -> AnimBuilder
speed value =
    Builder.speed value


easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Builder.easing


delay : Int -> AnimBuilder -> AnimBuilder
delay =
    Builder.delay


perspective : String -> Float -> AnimBuilder -> AnimBuilder
perspective =
    Builder.perspective


perspectiveStyles : String -> AnimState -> List (Html.Attribute msg)
perspectiveStyles containerId (AnimState state) =
    case Builder.getPerspectiveStylesCache state.builder of
        Just cache ->
            case Dict.get containerId cache of
                Just styles ->
                    List.map (\{ attribute, value } -> Html.Attributes.style attribute value) styles

                Nothing ->
                    []

        Nothing ->
            []


{-| Individual element animation lifecycle state.
-}
type ElementState
    = NotStarted
    | Running
    | Complete



-- Update


{-| Animation lifecycle events.
-}
type Event
    = AnimationStarted String
    | AnimationEnded String
    | AnimationCancelled String
    | AnimationIteration String
    | TransitionStarted String
    | TransitionEnded String
    | TransitionRun String
    | TransitionCancelled String


{-| Handle animation lifecycle events to update element states.
-}
handleEvent : Event -> AnimState -> AnimState
handleEvent event (AnimState state) =
    let
        ( elementId, newElementState ) =
            case event of
                AnimationStarted id ->
                    ( id, Running )

                AnimationEnded id ->
                    ( id, Complete )

                AnimationCancelled id ->
                    ( id, Complete )

                AnimationIteration id ->
                    ( id, Running )

                TransitionStarted id ->
                    ( id, Running )

                TransitionEnded id ->
                    ( id, Complete )

                TransitionRun id ->
                    ( id, Running )

                TransitionCancelled id ->
                    ( id, Complete )
    in
    AnimState
        { state
            | elementStates =
                Dict.insert elementId newElementState state.elementStates
        }



-- Event Handlers
-- Keyframe ANIMATION EVENT HANDLERS


onTransitionStart : msg -> Html.Attribute msg
onTransitionStart =
    Html.Events.on "transitionstart"
        << Json.Decode.succeed


onTransitionEnd : msg -> Html.Attribute msg
onTransitionEnd =
    Html.Events.on "transitionend"
        << Json.Decode.succeed


onTransitionRun : msg -> Html.Attribute msg
onTransitionRun =
    Html.Events.on "transitionrun"
        << Json.Decode.succeed


onTransitionCancel : msg -> Html.Attribute msg
onTransitionCancel =
    Html.Events.on "transitioncancel"
        << Json.Decode.succeed



-- CSS ANIMATION EVENT HANDLERS


onAnimationStart : msg -> Html.Attribute msg
onAnimationStart =
    Html.Events.on "animationstart"
        << Json.Decode.succeed


onAnimationEnd : msg -> Html.Attribute msg
onAnimationEnd =
    Html.Events.on "animationend"
        << Json.Decode.succeed


onAnimationIteration : msg -> Html.Attribute msg
onAnimationIteration =
    Html.Events.on "animationiteration"
        << Json.Decode.succeed


onAnimationCancel : msg -> Html.Attribute msg
onAnimationCancel =
    Html.Events.on "animationcancel"
        << Json.Decode.succeed



-- Query


{-| Check if any animations are currently running.
-}
anyRunning : AnimState -> Bool
anyRunning (AnimState state) =
    case Dict.values state.elementStates of
        [] ->
            False

        values ->
            List.any (\elementState -> elementState == Running) values


{-| Check if all animations are complete.
-}
allComplete : AnimState -> Maybe Bool
allComplete (AnimState state) =
    if Dict.isEmpty state.elementStates then
        Nothing

    else
        state.elementStates
            |> Dict.values
            |> List.all (\elementState -> elementState == Complete)
            |> Just


{-| Check if a specific element has any animations currently running.
-}
isElementRunning : String -> AnimState -> Bool
isElementRunning elementId (AnimState state) =
    Dict.get elementId state.elementStates == Just Running


{-| Check if a specific element's animations have completed.
-}
isElementComplete : String -> AnimState -> Maybe Bool
isElementComplete elementId (AnimState state) =
    Dict.get elementId state.elementStates
        |> Maybe.map
            (\elementState ->
                case elementState of
                    Complete ->
                        True

                    _ ->
                        False
            )


getElementAnimation : String -> AnimState -> Maybe ElementAnimation
getElementAnimation elementId (AnimState state) =
    Dict.get elementId state.elementAnimations


getTranslate : String -> AnimState -> Maybe Translate
getTranslate elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedTranslateConfig config ->
                                    Just config.end

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get the starting translate for an element's animation.
Returns Nothing if the element has no translate animation or no explicit start translate.
-}
getStartTranslate : String -> AnimState -> Maybe Translate
getStartTranslate elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedTranslateConfig config ->
                                    config.start

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


getState : String -> AnimState -> Maybe ElementState
getState elementId (AnimState state) =
    Dict.get elementId state.elementStates


{-| Get both start and end translates for an element's animation.
Returns Nothing if the element has no translate animation.
-}
getTranslateRange : String -> AnimState -> Maybe { start : Maybe Translate, end : Translate }
getTranslateRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedTranslateConfig config ->
                                    Just { start = config.start, end = config.end }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end scales for an element's animation.
Returns Nothing if the element has no scale animation.
-}
getScaleRange : String -> AnimState -> Maybe { start : Maybe Scale.Scale, end : Scale.Scale }
getScaleRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedScaleConfig config ->
                                    Just { start = config.start, end = config.end }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end rotations for an element's animation.
Returns Nothing if the element has no rotate animation.
-}
getRotateRange : String -> AnimState -> Maybe { start : Maybe Rotate.Rotate, end : Rotate.Rotate }
getRotateRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedRotateConfig config ->
                                    Just { start = config.start, end = config.end }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end background colors for an element's animation.
Returns Nothing if the element has no background color animation.
-}
getBackgroundColorRange : String -> AnimState -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedBackgroundColorConfig config ->
                                    Just { start = config.start, end = config.end }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end opacity for an element's animation.
Returns Nothing if the element has no opacity animation.
-}
getOpacityRange : String -> AnimState -> Maybe { start : Maybe Opacity.Opacity, end : Opacity.Opacity }
getOpacityRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedOpacityConfig config ->
                                    Just { start = config.start, end = config.end }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end sizes for an element's animation.
Returns Nothing if the element has no size animation.
-}
getSizeRange : String -> AnimState -> Maybe { start : Maybe Size.Size, end : Size.Size }
getSizeRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedSizeConfig config ->
                                    Just { start = config.start, end = config.end }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get the animation duration for a translate animation in milliseconds.
Returns Nothing if the element has no translate animation.
-}
getTranslateAnimationDuration : String -> AnimState -> Maybe Int
getTranslateAnimationDuration elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedTranslateConfig config ->
                                    Just config.duration

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )



-- View


animationStyleAttribute : String -> AnimState -> Html.Attribute msg
animationStyleAttribute elementId animationState =
    case getElementAnimation elementId animationState of
        Just elementAnimation ->
            let
                animationValues =
                    KeyframeAnimation.toAttributeString elementAnimation.animationLayers
            in
            Html.Attributes.style "animation" animationValues

        Nothing ->
            Html.Attributes.style "animation" ""


transitionAttributes : String -> AnimState -> List (Html.Attribute msg)
transitionAttributes elementId animationResult =
    let
        styles =
            getElementStyles elementId animationResult

        attrs =
            List.map (\( prop, value ) -> Html.Attributes.style prop value) styles
    in
    attrs


keyframesStyleNode : AnimState -> Html msg
keyframesStyleNode (AnimState state) =
    let
        allKeyframes =
            Dict.values state.elementAnimations
                |> List.concatMap .animationLayers
                |> List.map .keyframes
                |> String.join "\n\n"
    in
    if String.isEmpty allKeyframes then
        Html.text ""

    else
        Html.node "style" [] [ Html.text allKeyframes ]


keyframesStyleNodeFor : String -> AnimState -> Html msg
keyframesStyleNodeFor elementId (AnimState state) =
    case Dict.get elementId state.elementAnimations of
        Just elementAnimation ->
            if List.isEmpty elementAnimation.animationLayers then
                Html.text ""

            else
                let
                    elementKeyframes =
                        elementAnimation.animationLayers
                            |> List.map .keyframes
                            |> String.join "\n\n"
                in
                Html.node "style" [] [ Html.text elementKeyframes ]

        Nothing ->
            Html.text ""


getElementKeyframes : String -> AnimState -> Maybe String
getElementKeyframes elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen
            (\elementAnimation ->
                if List.isEmpty elementAnimation.animationLayers then
                    Nothing

                else
                    elementAnimation.animationLayers
                        |> List.map .keyframes
                        |> String.join "\n\n"
                        |> Just
            )



-- HELPERS


{-| Convert TransformOrder to string for the transform generation.
-}
transformOrderToString : TransformOrder -> String
transformOrderToString order =
    case order of
        Translate ->
            "translate"

        Rotate ->
            "rotate"

        Scale ->
            "scale"



-- CSS GENERATION


generateElementAnimation : Maybe (List TransformOrder) -> String -> Builder.ElementConfig -> ElementAnimation
generateElementAnimation maybeOrder elementId elementConfig =
    let
        -- Process properties first (like keyframes do) for consistency
        processed =
            Builder.processElement
                { globalTiming = Nothing
                , globalEasing = Nothing
                , globalDelay = Nothing
                , globalPerspective = Nothing
                , currentElementId = Nothing
                , elements = Dict.empty
                , scrollTargets = []
                , scrollContainer = "document"
                , perspectiveStylesCache = Nothing
                , animationHistories = Dict.empty
                , nextAnimationId = 0
                , elementBaselines = Dict.empty
                }
                elementConfig

        processedProps =
            processed.properties

        transforms =
            case maybeOrder of
                Nothing ->
                    -- Use default ordering: Position -> Rotate -> Scale
                    Transforms.generateFromProcessed processedProps

                Just order ->
                    -- Use custom ordering
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

        allStyles =
            [ ( "transform", transforms )
            , ( "transition", transitions )
            ]
                ++ colorStyles
                ++ opacityStyles
                |> List.filter (\( _, value ) -> not (String.isEmpty value))
    in
    { styles = allStyles
    , animationLayers = KeyframeAnimation.generate elementId elementConfig.properties
    }


getElementStyles : String -> AnimState -> List ( String, String )
getElementStyles elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.map .styles
        |> Maybe.withDefault []



-- ANIMATION CONTROL


{-| Pause a keyframe animation by setting animation-play-state to paused.
Note: This only works with keyframe animations, not CSS transitions.
-}
pauseAnimation : String -> AnimState -> AnimState
pauseAnimation elementId (AnimState state) =
    let
        updatedAnimations =
            Dict.update elementId
                (Maybe.map
                    (\element ->
                        { element
                            | styles = element.styles ++ [ ( "animation-play-state", "paused" ) ]
                        }
                    )
                )
                state.elementAnimations
    in
    AnimState { state | elementAnimations = updatedAnimations }


{-| Resume a paused keyframe animation by setting animation-play-state to running.
Note: This only works with keyframe animations, not CSS transitions.
-}
resumeAnimation : String -> AnimState -> AnimState
resumeAnimation elementId (AnimState state) =
    let
        updatedAnimations =
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
                state.elementAnimations
    in
    AnimState { state | elementAnimations = updatedAnimations }


{-| Stop an animation by jumping to its end state with transition: none.
-}
stopAnimation : String -> AnimState -> AnimState
stopAnimation elementId animState =
    let
        -- Start with a fresh builder with 0ms duration for the element
        baseBuilder =
            animState
                |> builder
                |> Builder.duration 0
                |> easing Anim.Easing.Linear

        -- Build new animation with all current values using Property.add
        withAllProperties =
            baseBuilder
                |> addPropertyIfExists
                    (getTranslateRange elementId animState)
                    (\range ->
                        let
                            endPos =
                                range.end
                        in
                        Builder.TranslateConfig
                            { start = Just endPos
                            , end = endPos
                            , duration = 0
                            , speed = 0
                            , distance = 0
                            , timing = Just (Duration 0)
                            , easing = Just Anim.Easing.Linear
                            , delay = Nothing
                            , perspective = Nothing
                            , isDirty = True
                            }
                    )
                |> addPropertyIfExists
                    (getScaleRange elementId animState)
                    (\range ->
                        let
                            endScale =
                                range.end
                        in
                        Builder.ScaleConfig
                            { start = Just endScale
                            , end = endScale
                            , duration = 0
                            , speed = 0
                            , distance = 0
                            , timing = Just (Duration 0)
                            , easing = Just Anim.Easing.Linear
                            , delay = Nothing
                            , perspective = Nothing
                            , isDirty = True
                            }
                    )
                |> addPropertyIfExists
                    (getRotateRange elementId animState)
                    (\range ->
                        let
                            endRotate =
                                range.end
                        in
                        Builder.RotateConfig
                            { start = Just endRotate
                            , end = endRotate
                            , duration = 0
                            , speed = 0
                            , distance = 0
                            , timing = Just (Duration 0)
                            , easing = Just Anim.Easing.Linear
                            , delay = Nothing
                            , perspective = Nothing
                            , isDirty = True
                            }
                    )
                |> addPropertyIfExists
                    (getOpacityRange elementId animState)
                    (\range ->
                        let
                            endOpacity =
                                range.end
                        in
                        Builder.OpacityConfig
                            { start = Just endOpacity
                            , end = endOpacity
                            , duration = 0
                            , speed = 0
                            , distance = 0
                            , timing = Just (Duration 0)
                            , easing = Just Anim.Easing.Linear
                            , delay = Nothing
                            , perspective = Nothing
                            , isDirty = True
                            }
                    )
                |> addPropertyIfExists
                    (getBackgroundColorRange elementId animState)
                    (\range ->
                        let
                            endColor =
                                range.end
                        in
                        Builder.BackgroundColorConfig
                            { start = Just endColor
                            , end = endColor
                            , duration = 0
                            , speed = 0
                            , distance = 0
                            , timing = Just (Duration 0)
                            , easing = Just Anim.Easing.Linear
                            , delay = Nothing
                            , perspective = Nothing
                            , isDirty = True
                            }
                    )
                |> addPropertyIfExists
                    (getSizeRange elementId animState)
                    (\range ->
                        let
                            endSize =
                                range.end
                        in
                        Builder.SizeConfig
                            { start = Just endSize
                            , end = endSize
                            , duration = 0
                            , speed = 0
                            , distance = 0
                            , timing = Just (Duration 0)
                            , easing = Just Anim.Easing.Linear
                            , delay = Nothing
                            , perspective = Nothing
                            , isDirty = True
                            }
                    )

        -- Helper function to add a property if it exists
        addPropertyIfExists : Maybe a -> (a -> Builder.PropertyConfig) -> Builder.AnimBuilder -> Builder.AnimBuilder
        addPropertyIfExists maybeRange toConfig builder_ =
            case maybeRange of
                Just range ->
                    Property.add (toConfig range) builder_

                Nothing ->
                    builder_
    in
    animate withAllProperties


{-| Reset an animation by jumping to its start state with a 0ms transition.
-}
resetAnimation : String -> AnimState -> AnimState
resetAnimation elementId animState =
    let
        -- Helper to always use the start value (or default if not provided)
        getStartValue : Maybe a -> a -> a
        getStartValue maybeStart defaultValue =
            Maybe.withDefault defaultValue maybeStart

        -- Start with a fresh builder with 0ms duration for the element
        baseBuilder =
            animState
                |> builder
                |> Builder.duration 0
                |> easing Anim.Easing.Linear
                |> Builder.for elementId

        -- Build new animation with all start values using Property.add
        withAllProperties =
            baseBuilder
                |> addPropertyIfExists
                    (getTranslateRange elementId animState)
                    (\range ->
                        let
                            startPos =
                                getStartValue range.start Translate.default
                        in
                        Builder.TranslateConfig
                            { start = Just startPos
                            , end = startPos
                            , duration = 0
                            , speed = 0
                            , distance = 0
                            , timing = Just (Duration 0)
                            , easing = Just Anim.Easing.Linear
                            , delay = Nothing
                            , perspective = Nothing
                            , isDirty = True
                            }
                    )
                |> addPropertyIfExists
                    (getScaleRange elementId animState)
                    (\range ->
                        let
                            startScale =
                                getStartValue range.start (Scale.fromUniform 1.0)
                        in
                        Builder.ScaleConfig
                            { start = Just startScale
                            , end = startScale
                            , duration = 0
                            , speed = 0
                            , distance = 0
                            , timing = Just (Duration 0)
                            , easing = Just Anim.Easing.Linear
                            , delay = Nothing
                            , perspective = Nothing
                            , isDirty = True
                            }
                    )
                |> addPropertyIfExists
                    (getRotateRange elementId animState)
                    (\range ->
                        let
                            startRotate =
                                getStartValue range.start Rotate.default
                        in
                        Builder.RotateConfig
                            { start = Just startRotate
                            , end = startRotate
                            , duration = 0
                            , speed = 0
                            , distance = 0
                            , timing = Just (Duration 0)
                            , easing = Just Anim.Easing.Linear
                            , delay = Nothing
                            , perspective = Nothing
                            , isDirty = True
                            }
                    )
                |> addPropertyIfExists
                    (getOpacityRange elementId animState)
                    (\range ->
                        let
                            startOpacity =
                                getStartValue range.start Opacity.default
                        in
                        Builder.OpacityConfig
                            { start = Just startOpacity
                            , end = startOpacity
                            , duration = 0
                            , speed = 0
                            , distance = 0
                            , timing = Just (Duration 0)
                            , easing = Just Anim.Easing.Linear
                            , delay = Nothing
                            , perspective = Nothing
                            , isDirty = True
                            }
                    )
                |> addPropertyIfExists
                    (getBackgroundColorRange elementId animState)
                    (\range ->
                        let
                            startColor =
                                getStartValue range.start BackgroundColor.default
                        in
                        Builder.BackgroundColorConfig
                            { start = Just startColor
                            , end = startColor
                            , duration = 0
                            , speed = 0
                            , distance = 0
                            , timing = Just (Duration 0)
                            , easing = Just Anim.Easing.Linear
                            , delay = Nothing
                            , perspective = Nothing
                            , isDirty = True
                            }
                    )
                |> addPropertyIfExists
                    (getSizeRange elementId animState)
                    (\range ->
                        let
                            startSize =
                                getStartValue range.start Size.default
                        in
                        Builder.SizeConfig
                            { start = Just startSize
                            , end = startSize
                            , duration = 0
                            , speed = 0
                            , distance = 0
                            , timing = Just (Duration 0)
                            , easing = Just Anim.Easing.Linear
                            , delay = Nothing
                            , perspective = Nothing
                            , isDirty = True
                            }
                    )

        -- Helper function to add a property if it exists
        addPropertyIfExists : Maybe a -> (a -> Builder.PropertyConfig) -> Builder.AnimBuilder -> Builder.AnimBuilder
        addPropertyIfExists maybeRange toConfig builder_ =
            case maybeRange of
                Just range ->
                    Property.add (toConfig range) builder_

                Nothing ->
                    builder_
    in
    animate withAllProperties


{-| Restart an animation from the beginning.
-}
restartAnimation : String -> AnimState -> AnimState
restartAnimation elementId ((AnimState state) as animState) =
    case getElementAnimation elementId animState of
        Nothing ->
            animState

        Just _ ->
            -- Mark the element as NotStarted to re-trigger the animation
            let
                updatedElements =
                    Dict.insert elementId NotStarted state.elementStates
            in
            AnimState { state | elementStates = updatedElements }
