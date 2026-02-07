module Anim.Internal.CSS exposing
    ( AnimBuilder
    , AnimState
    , ElementState(..)
    , Event(..)
    , TransformOrder(..)
    , allComplete
    , animate
    , animateWithOrder
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
    , isComplete
    , isRunning
    , keyframesAttribute
    , keyframesStyleNode
    , keyframesStyleNodeFor
    , keyframesStyles
    , onAnimationCancel
    , onAnimationEnd
    , onAnimationIteration
    , onAnimationStart
    , onTransitionCancel
    , onTransitionEnd
    , onTransitionRun
    , onTransitionStart
    , pauseAnimation
    , reset
    , restartAnimation
    , resumeAnimation
    , speed
    , startingStyleNode
    , startingStyleNodeFor
    , stopAnimation
    , transitionAttributes
    )

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder
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
        , restartCounters : Dict ElementId Int
        }


type alias ElementAnimation =
    { styles : List ( String, String )
    , animationLayers : List KeyframeAnimation
    }


{-| Initialize animation state with optional property initializers.

Pass an empty list for empty state, or property initializers to set initial values.

-}
init : List (AnimBuilder -> AnimBuilder) -> AnimState
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
                -- Apply all property initializers to a fresh builder
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
                        |> Dict.map (generateElementAnimation Nothing (Builder.discreteTransitionsEnabled configuredBuilder) (Builder.getIterationCount configuredBuilder))
                , elementStates =
                    elementIds
                        |> List.map (\id -> ( id, NotStarted ))
                        |> Dict.fromList
                , builder =
                    configuredBuilder
                        |> Builder.markDirty
                        |> Builder.clearCurrentElement
                , restartCounters = Dict.empty
                }


builder : AnimState -> AnimBuilder
builder (AnimState state) =
    state.builder


animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate animState transform =
    let
        builder_ =
            animState
                |> builder
                |> transform

        elementIds =
            builder_
                |> Builder.elements
                |> Dict.keys
    in
    AnimState
        { elementAnimations =
            builder_
                |> Builder.elements
                |> Dict.map (generateElementAnimation Nothing (Builder.discreteTransitionsEnabled builder_) (Builder.getIterationCount builder_))
        , elementStates =
            elementIds
                |> List.map (\id -> ( id, NotStarted ))
                |> Dict.fromList
        , builder =
            builder_
                |> Builder.clearCurrentElement
        , restartCounters = Dict.empty
        }


type TransformOrder
    = Translate
    | Rotate
    | Scale


{-| Normalize a transform order list:

1.  Remove duplicates, keeping the first occurrence
2.  Append any missing transforms in the default order (Translate → Rotate → Scale)

Examples:

  - `[Scale]` → `[Scale, Translate, Rotate]`
  - `[Rotate, Scale]` → `[Rotate, Scale, Translate]`
  - `[Scale, Scale, Rotate]` → `[Scale, Rotate, Translate]`

-}
normalizeTransformOrder : List TransformOrder -> List TransformOrder
normalizeTransformOrder order =
    let
        -- Remove duplicates, keeping first occurrence
        removeDuplicates : List TransformOrder -> List TransformOrder -> List TransformOrder
        removeDuplicates seen remaining =
            case remaining of
                [] ->
                    List.reverse seen

                x :: xs ->
                    if List.member x seen then
                        removeDuplicates seen xs

                    else
                        removeDuplicates (x :: seen) xs

        deduped =
            removeDuplicates [] order

        -- Default order for missing transforms
        defaultOrder =
            [ Translate, Rotate, Scale ]

        -- Find missing transforms and add them in default order
        missing =
            List.filter (\t -> not (List.member t deduped)) defaultOrder
    in
    deduped ++ missing


{-| Apply animation with custom transform ordering.
-}
animateWithOrder : List TransformOrder -> AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animateWithOrder order animState transform =
    let
        normalizedOrder =
            normalizeTransformOrder order

        builder_ =
            animState
                |> builder
                |> transform

        elementIds =
            builder_
                |> Builder.elements
                |> Dict.keys
    in
    AnimState
        { elementAnimations =
            builder_
                |> Builder.elements
                |> Dict.map (generateElementAnimation (Just normalizedOrder) (Builder.discreteTransitionsEnabled builder_) (Builder.getIterationCount builder_))
        , elementStates =
            elementIds
                |> List.map (\id -> ( id, NotStarted ))
                |> Dict.fromList
        , builder = Builder.clearCurrentElement builder_
        , restartCounters = Dict.empty
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
isRunning : String -> AnimState -> Bool
isRunning elementId (AnimState state) =
    Dict.get elementId state.elementStates == Just Running


{-| Check if a specific element's animations have completed.
-}
isComplete : String -> AnimState -> Maybe Bool
isComplete elementId (AnimState state) =
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


{-| Get the animation attribute for keyframe-based animations.
When animations are active, returns the animation property from keyframe layers.
When no animations are active (after reset/stop), returns an empty animation.
Note: Use `keyframesStyles` to get all styles including transform for instant jumps.
-}
keyframesAttribute : String -> AnimState -> Html.Attribute msg
keyframesAttribute elementId animState =
    case getElementAnimation elementId animState of
        Just elementAnimation ->
            let
                animationValues =
                    KeyframeAnimation.toAttributeString elementAnimation.animationLayers
            in
            Html.Attributes.style "animation" animationValues

        Nothing ->
            Html.Attributes.style "animation" ""


{-| Get all styles for keyframe-based animations as a list of Html attributes.
This includes both the animation property (when active) and any other styles
like transform (for instant jumps after reset/stop).
Use this instead of `keyframesAttribute` when you need full style support.
-}
keyframesStyles : String -> AnimState -> List (Html.Attribute msg)
keyframesStyles elementId animState =
    case getElementAnimation elementId animState of
        Just elementAnimation ->
            let
                -- Get animation from layers
                animationAttr =
                    Html.Attributes.style "animation"
                        (KeyframeAnimation.toAttributeString elementAnimation.animationLayers)

                -- Get other styles (transform, etc.)
                otherStyleAttrs =
                    elementAnimation.styles
                        |> List.filter (\( key, _ ) -> key /= "animation")
                        |> List.map (\( key, value ) -> Html.Attributes.style key value)
            in
            animationAttr :: otherStyleAttrs

        Nothing ->
            []


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


{-| Generate a style node containing @starting-style rules for all animated elements.

This is required for entry animations when using discrete transitions (like display/visibility).
Include this in your view alongside the animated elements.

    view model =
        div []
            [ CSS.startingStyleNode model.animState
            , div (CSS.transitionAttributes "my-element" model.animState) [ text "Animated" ]
            ]

-}
startingStyleNode : AnimState -> Html msg
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


{-| Generate a style node containing @starting-style rules for a specific element.

Use this when you only need starting styles for one element.

-}
startingStyleNodeFor : String -> AnimState -> Html msg
startingStyleNodeFor elementId animState =
    case generateStartingStyleForElement elementId animState of
        Just css ->
            Html.node "style" [] [ Html.text ("@starting-style {\n" ++ css ++ "\n}") ]

        Nothing ->
            Html.text ""


{-| Generate the CSS content for @starting-style for a single element.
Returns Nothing if the element has no animations with start values.
-}
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
                    -- Collect non-transform starting styles
                    nonTransformStyles =
                        elementConfig.properties
                            |> List.filterMap propertyToNonTransformStartingStyle

                    -- Collect transform parts and combine into single declaration
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
                    Just ("  #" ++ elementId ++ " {\n" ++ String.join "\n" (List.map (\s -> "    " ++ s) allStyles) ++ "\n  }")
            )


{-| Convert a processed property config to a non-transform CSS starting style declaration.
Only returns a value for non-transform properties with defined start values.
-}
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


{-| Extract a transform function string from a transform property's start value.
Returns Nothing for non-transform properties or properties without start values.
-}
propertyToTransformPart : Builder.ProcessedPropertyConfig -> Maybe String
propertyToTransformPart prop =
    case prop of
        Builder.ProcessedTranslateConfig config ->
            config.start
                |> Maybe.map (\start -> "translate3d(" ++ Translate.toCssString start ++ ")")

        Builder.ProcessedRotateConfig config ->
            config.start
                |> Maybe.map Rotate.toCssString

        Builder.ProcessedScaleConfig config ->
            config.start
                |> Maybe.map Scale.toCssString

        _ ->
            Nothing



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


generateElementAnimation : Maybe (List TransformOrder) -> Bool -> Builder.IterationCount -> String -> Builder.ElementConfig -> ElementAnimation
generateElementAnimation maybeOrder discreteTransitions iterationCount elementId elementConfig =
    generateElementAnimationWithSuffix maybeOrder discreteTransitions iterationCount "" elementId elementConfig


{-| Generate element animation with a suffix for the animation name.
Used for restarting animations - passing a unique suffix forces the browser to treat it as a new animation.
-}
generateElementAnimationWithSuffix : Maybe (List TransformOrder) -> Bool -> Builder.IterationCount -> String -> String -> Builder.ElementConfig -> ElementAnimation
generateElementAnimationWithSuffix maybeOrder discreteTransitions iterationCount suffix elementId elementConfig =
    let
        -- Process properties first (like keyframes do) for consistency
        processed =
            Builder.processElement
                { globalTiming = Nothing
                , globalEasing = Nothing
                , globalDelay = Nothing
                , currentElementId = Nothing
                , elements = Dict.empty
                , scrollTargets = []
                , scrollContainer = "document"
                , animationHistories = Dict.empty
                , nextAnimationId = 0
                , elementBaselines = Dict.empty
                , discreteTransitions = discreteTransitions
                , iterationCount = iterationCount
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

        -- Add transition-behavior for discrete properties
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
        KeyframeAnimation.generateWithSuffix elementId suffix elementConfig.properties
            |> KeyframeAnimation.setIterationCount iterationCount
    }


{-| Generate styles-only for instant jumps (no keyframe animations).
Used by reset and stop to instantly move to a position without animation.
-}
generateStylesOnly : Maybe (List TransformOrder) -> Builder.ElementConfig -> ElementAnimation
generateStylesOnly maybeOrder elementConfig =
    let
        processed =
            Builder.processElement
                { globalTiming = Nothing
                , globalEasing = Nothing
                , globalDelay = Nothing
                , currentElementId = Nothing
                , elements = Dict.empty
                , scrollTargets = []
                , scrollContainer = "document"
                , animationHistories = Dict.empty
                , nextAnimationId = 0
                , elementBaselines = Dict.empty
                , discreteTransitions = False
                , iterationCount = Builder.Once
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

        -- For instant jumps, we set the transform directly and clear any running animation
        allStyles =
            [ ( "transform", transforms )
            , ( "animation", "none" ) -- Clear any running keyframe animation
            , ( "transition", "none" ) -- Clear any CSS transition for instant jump
            ]
                ++ colorStyles
                ++ opacityStyles
                |> List.filter (\( key, value ) -> key == "animation" || key == "transition" || not (String.isEmpty value))
    in
    { styles = allStyles
    , animationLayers = [] -- No keyframes for instant jumps
    }


{-| Set styles instantly for an element without creating keyframe animations.
Used internally by reset and stop for instant position jumps.
-}
setStylesInstantly : String -> ElementState -> Builder.ElementConfig -> AnimState -> AnimState
setStylesInstantly elementId targetState elementConfig (AnimState state) =
    let
        elementAnimation =
            generateStylesOnly Nothing elementConfig
    in
    AnimState
        { state
            | elementAnimations = Dict.insert elementId elementAnimation state.elementAnimations
            , elementStates = Dict.insert elementId targetState state.elementStates
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


{-| Stop an animation by jumping instantly to its end state.
Sets styles directly without creating keyframe animations.
-}
stopAnimation : String -> AnimState -> AnimState
stopAnimation elementId animState =
    let
        -- Helper to build a minimal PropertyConfig for instant positioning
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
            , isDirty = True
            }

        -- Collect all properties with their end values
        properties =
            [ getTranslateRange elementId animState
                |> Maybe.map (\range -> Builder.TranslateConfig (makeInstantConfig range.end))
            , getScaleRange elementId animState
                |> Maybe.map (\range -> Builder.ScaleConfig (makeInstantConfig range.end))
            , getRotateRange elementId animState
                |> Maybe.map (\range -> Builder.RotateConfig (makeInstantConfig range.end))
            , getOpacityRange elementId animState
                |> Maybe.map (\range -> Builder.OpacityConfig (makeInstantConfig range.end))
            , getBackgroundColorRange elementId animState
                |> Maybe.map (\range -> Builder.BackgroundColorConfig (makeInstantConfig range.end))
            , getSizeRange elementId animState
                |> Maybe.map (\range -> Builder.SizeConfig (makeInstantConfig range.end))
            ]
                |> List.filterMap identity

        elementConfig =
            { properties = properties }
    in
    if List.isEmpty properties then
        animState

    else
        setStylesInstantly elementId Complete elementConfig animState


{-| Reset an animation by jumping instantly to its start state.
Sets styles directly without creating keyframe animations.
Uses the original animation config (not processed/baseline-merged) to get true start values.
-}
reset : String -> AnimState -> AnimState
reset elementId (AnimState state) =
    case Builder.getElementConfig elementId state.builder of
        Nothing ->
            AnimState state

        Just elementConfig ->
            let
                -- Helper to build a minimal PropertyConfig for instant positioning
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
                    , isDirty = True
                    }

                -- Extract start values from the ORIGINAL config (not processed)
                -- This ensures we get the true animation start, not baseline-merged values
                properties =
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
                                        -- FontColor not supported in reset yet
                                        Nothing
                            )

                newElementConfig =
                    { properties = properties }
            in
            if List.isEmpty properties then
                AnimState state

            else
                setStylesInstantly elementId NotStarted newElementConfig (AnimState state)


{-| Restart an animation from the beginning.
First resets to start position, then re-applies the original animation keyframes with a new name to force browser restart.
-}
restartAnimation : String -> AnimState -> AnimState
restartAnimation elementId ((AnimState state) as animState) =
    case Builder.getElementConfig elementId state.builder of
        Nothing ->
            animState

        Just elementConfig ->
            let
                -- First reset to start position (instantly)
                resetState =
                    reset elementId animState

                (AnimState resetStateData) =
                    resetState

                -- Increment restart counter for this element
                currentCounter =
                    Dict.get elementId state.restartCounters
                        |> Maybe.withDefault 0

                newCounter =
                    currentCounter + 1

                -- Generate animation with restart suffix to force browser to treat as new animation
                suffix =
                    "r" ++ String.fromInt newCounter

                elementAnimation =
                    generateElementAnimationWithSuffix Nothing (Builder.discreteTransitionsEnabled state.builder) (Builder.getIterationCount state.builder) suffix elementId elementConfig
            in
            AnimState
                { resetStateData
                    | elementAnimations = Dict.insert elementId elementAnimation resetStateData.elementAnimations
                    , elementStates = Dict.insert elementId NotStarted resetStateData.elementStates
                    , restartCounters = Dict.insert elementId newCounter resetStateData.restartCounters
                }
