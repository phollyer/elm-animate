module Anim.Internal.CSS exposing
    ( AnimBuilder
    , AnimEvent(..)
    , AnimState(..)
    , ElementAnimation
    , ElementState(..)
    , SourceEventData
    , allComplete
    , animate
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
    , hasAnimation
    , init
    , isComplete
    , isRunning
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
    , pauseAnimation
    , reset
    , restartAnimation
    , resumeAnimation
    , speed
    , startingStyleNode
    , startingStyleNodeFor
    , stopAnimation
    , transitionAttributes
    , transitionEventsStopPropagation
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
                        |> Dict.map (generateElementAnimation Nothing (Builder.discreteTransitionsEnabled configuredBuilder) (Builder.getIterationCount configuredBuilder) (Builder.getAnimationDirection configuredBuilder))
                , elementStates =
                    elementIds
                        |> List.map (\id -> ( id, NotStarted ))
                        |> Dict.fromList
                , builder =
                    configuredBuilder
                        |> Builder.clearCurrentElement
                , restartCounters = Dict.empty
                }


builder : AnimState -> AnimBuilder
builder (AnimState state) =
    state.builder


animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate (AnimState state) transform =
    let
        builder_ =
            AnimState state
                |> builder
                |> transform

        -- Process all elements to get processed data
        processedData =
            Builder.processAnimationData builder_

        elementIds =
            processedData.elements
                |> Dict.keys

        -- Add each element to animation history
        builderWithHistory =
            Dict.foldl
                (\elementId _ accBuilder ->
                    Builder.addAnimationToHistory elementId processedData Nothing accBuilder
                        |> Tuple.first
                )
                builder_
                processedData.elements
    in
    AnimState
        { elementAnimations =
            processedData.elements
                |> Dict.map (generateElementAnimationFromProcessed processedData.globalTransformOrder (Builder.discreteTransitionsEnabled builder_) (Builder.getIterationCount builder_) (Builder.getAnimationDirection builder_))
        , elementStates =
            elementIds
                |> List.map (\id -> ( id, NotStarted ))
                |> Dict.fromList
        , builder =
            builderWithHistory
                |> Builder.clearCurrentElement
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
type AnimEvent
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
handleEvent : AnimEvent -> AnimState -> AnimState
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
-- TRANSITION EVENT HANDLERS


onTransitionStart : msg -> Html.Attribute msg
onTransitionStart =
    Html.Events.on "transitionstart"
        << Json.Decode.succeed


{-| Like `onTransitionStart` but stops event propagation.
Use this to prevent events from bubbling up to parent elements with listeners.
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
Use this to prevent events from bubbling up to parent elements with listeners.
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
Use this to prevent events from bubbling up to parent elements with listeners.
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
Use this to prevent events from bubbling up to parent elements with listeners.
-}
onTransitionCancelStopPropagation : msg -> Html.Attribute msg
onTransitionCancelStopPropagation msg =
    Html.Events.stopPropagationOn "transitioncancel"
        (Json.Decode.succeed ( msg, True ))


{-| Decode source element data from transition events.
Unlike animation events, transition events don't contain the animation name,
so the animGroup must be passed explicitly.
-}
transitionSourceDecoder : String -> Json.Decode.Decoder SourceEventData
transitionSourceDecoder animGroup =
    Json.Decode.map2 (SourceEventData animGroup)
        targetIdDecoder
        currentTargetIdDecoder


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



-- CSS ANIMATION EVENT HANDLERS


onAnimationStart : msg -> Html.Attribute msg
onAnimationStart =
    Html.Events.on "animationstart"
        << Json.Decode.succeed


{-| Like `onAnimationStart` but stops event propagation.
Use this to prevent events from bubbling up to parent elements with listeners.
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
Use this to prevent events from bubbling up to parent elements with listeners.
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
Use this to prevent events from bubbling up to parent elements with listeners.
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
Use this to prevent events from bubbling up to parent elements with listeners.
-}
onAnimationCancelStopPropagation : msg -> Html.Attribute msg
onAnimationCancelStopPropagation msg =
    Html.Events.stopPropagationOn "animationcancel"
        (Json.Decode.succeed ( msg, True ))



-- SOURCE-AWARE EVENT HANDLERS
-- These handlers decode the animationName from the DOM event and extract
-- the source element ID, enabling proper event attribution even when events bubble.
-- They also decode the target element's DOM id attribute for distinguishing elements.


{-| Data decoded from animation events for source identification.

  - `animGroup`: The animation group name extracted from the CSS animation name
  - `targetId`: The HTML id attribute of the event target element (if set)
  - `currentTargetId`: The HTML id attribute of the element where the handler is attached (if set)

-}
type alias SourceEventData =
    { animGroup : String
    , targetId : Maybe String
    , currentTargetId : Maybe String
    }


{-| Decode the animationName property from an animation event.
-}
animationNameDecoder : Json.Decode.Decoder String
animationNameDecoder =
    Json.Decode.field "animationName" Json.Decode.string


{-| Decode an element id attribute from a given path.
Returns Nothing if the id is empty or not set.
-}
elementIdDecoder : List String -> Json.Decode.Decoder (Maybe String)
elementIdDecoder path =
    Json.Decode.at path Json.Decode.string
        |> Json.Decode.map
            (\id ->
                if String.isEmpty id then
                    Nothing

                else
                    Just id
            )
        |> Json.Decode.maybe
        |> Json.Decode.map (Maybe.andThen identity)


{-| Decode the target element's id attribute.
Returns Nothing if the id is empty or not set.
-}
targetIdDecoder : Json.Decode.Decoder (Maybe String)
targetIdDecoder =
    elementIdDecoder [ "target", "id" ]


{-| Decode the currentTarget element's id attribute.
Returns Nothing if the id is empty or not set.
-}
currentTargetIdDecoder : Json.Decode.Decoder (Maybe String)
currentTargetIdDecoder =
    elementIdDecoder [ "currentTarget", "id" ]


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
        targetIdDecoder
        currentTargetIdDecoder


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



-- COMBINED EVENT HELPERS


{-| All transition event handlers with propagation stopped.
Use this to prevent events from bubbling up to parent elements with listeners.

    div
        (CSS.transitionAttributes "myElement" model.animState
            ++ CSS.transitionEventsStopPropagation AnimEvent
        )
        [ text "Animated element" ]

-}
transitionEventsStopPropagation : msg -> List (Html.Attribute msg)
transitionEventsStopPropagation msg =
    [ onTransitionStartStopPropagation msg
    , onTransitionEndStopPropagation msg
    , onTransitionRunStopPropagation msg
    , onTransitionCancelStopPropagation msg
    ]


{-| All keyframe animation event handlers with propagation stopped.
Use this to prevent events from bubbling up to parent elements with listeners.

    div
        (CSS.keyframesStyles "myElement" model.animState
            ++ CSS.keyframeEventsStopPropagation AnimEvent
        )
        [ text "Animated element" ]

-}
keyframeEventsStopPropagation : msg -> List (Html.Attribute msg)
keyframeEventsStopPropagation msg =
    [ onAnimationStartStopPropagation msg
    , onAnimationEndStopPropagation msg
    , onAnimationIterationStopPropagation msg
    , onAnimationCancelStopPropagation msg
    ]



-- Query


{-| Check if any animations are currently running.
-}
anyRunning : AnimState -> Maybe Bool
anyRunning (AnimState state) =
    case Dict.values state.elementStates of
        [] ->
            Nothing

        values ->
            List.any (\elementState -> elementState == Running) values
                |> Just


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
isRunning : String -> AnimState -> Maybe Bool
isRunning elementId (AnimState state) =
    Dict.get elementId state.elementStates
        |> Maybe.map (\elementState -> elementState == Running)


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


{-| Check if an animation exists for the given element ID.
-}
hasAnimation : String -> AnimState -> Bool
hasAnimation elementId (AnimState state) =
    Dict.member elementId state.elementAnimations


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

        styleAttrs =
            List.map (\( prop, value ) -> Html.Attributes.style prop value) styles

        dataAttr =
            Html.Attributes.attribute "data-anim-group-name" elementId
    in
    dataAttr :: styleAttrs


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
            , div (CSS.attributes "animGroupName" model.animState) [ text "Animated" ]
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
                    Just ("  [data-anim-group-name=\"" ++ elementId ++ "\"] {\n" ++ String.join "\n" (List.map (\s -> "    " ++ s) allStyles) ++ "\n  }")
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
                |> Maybe.map Translate.toCssString

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


generateElementAnimation : Maybe (List Builder.TransformOrder) -> Bool -> Builder.IterationCount -> Builder.AnimationDirection -> String -> Builder.ElementConfig -> ElementAnimation
generateElementAnimation maybeOrder discreteTransitions iterationCount direction elementId elementConfig =
    generateElementAnimationWithSuffix maybeOrder discreteTransitions iterationCount direction "" elementId elementConfig


{-| Generate element animation with a suffix for the animation name.
Used for restarting animations - passing a unique suffix forces the browser to treat it as a new animation.
-}
generateElementAnimationWithSuffix : Maybe (List Builder.TransformOrder) -> Bool -> Builder.IterationCount -> Builder.AnimationDirection -> String -> String -> Builder.ElementConfig -> ElementAnimation
generateElementAnimationWithSuffix maybeOrder discreteTransitions iterationCount direction suffix elementId elementConfig =
    let
        -- Process properties first (like keyframes do) for consistency
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
                , frozenProperties = []
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
            |> KeyframeAnimation.setDirection direction
    }


{-| Generate element animation from already-processed element config.
Used when generating from animation history where data is already processed.
-}
generateElementAnimationFromProcessed : Maybe (List Builder.TransformOrder) -> Bool -> Builder.IterationCount -> Builder.AnimationDirection -> String -> Builder.ProcessedElementConfig -> ElementAnimation
generateElementAnimationFromProcessed maybeOrder discreteTransitions iterationCount direction elementId processed =
    generateElementAnimationFromProcessedWithSuffix maybeOrder discreteTransitions iterationCount direction "" elementId processed


{-| Generate element animation from processed config with a suffix.
Used for restarting animations from history.
-}
generateElementAnimationFromProcessedWithSuffix : Maybe (List Builder.TransformOrder) -> Bool -> Builder.IterationCount -> Builder.AnimationDirection -> String -> String -> Builder.ProcessedElementConfig -> ElementAnimation
generateElementAnimationFromProcessedWithSuffix maybeOrder discreteTransitions iterationCount direction suffix elementId processed =
    let
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
        KeyframeAnimation.generateWithSuffixFromProcessed elementId suffix processedProps
            |> KeyframeAnimation.setIterationCount iterationCount
            |> KeyframeAnimation.setDirection direction
    }


{-| Generate styles-only for instant jumps (no keyframe animations).
Used by reset and stop to instantly move to a position without animation.
-}
generateStylesOnly : Maybe (List Builder.TransformOrder) -> Builder.ElementConfig -> ElementAnimation
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
                , frozenProperties = []
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
            { properties = properties, targetElement = Nothing }
    in
    if List.isEmpty properties then
        animState

    else
        setStylesInstantly elementId Complete elementConfig animState


{-| Reset an animation by jumping instantly to its start state.
Sets styles directly without creating keyframe animations.
Uses the animation history if available, otherwise falls back to builder.elements.
-}
reset : String -> AnimState -> AnimState
reset elementId (AnimState state) =
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
            }

        -- Try to get start values from animation history first
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

        -- Fallback to builder.elements if no history
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
        AnimState state

    else
        setStylesInstantly elementId NotStarted newElementConfig (AnimState state)


{-| Restart an animation from the beginning.
First resets to start position, then re-applies the original animation keyframes with a new name to force browser restart.
Uses the animation history if available, otherwise falls back to builder.elements.
-}
restartAnimation : String -> AnimState -> AnimState
restartAnimation elementId ((AnimState state) as animState) =
    let
        -- Try to get config from animation history first
        maybeFromHistory =
            Builder.getCurrentAnimation elementId state.builder
                |> Maybe.andThen (\entry -> Dict.get elementId entry.processedData.elements)

        -- Fallback to builder.elements
        maybeFromBuilder =
            Builder.getElementConfig elementId state.builder

        -- Increment restart counter for suffix
        currentCounter =
            Dict.get elementId state.restartCounters
                |> Maybe.withDefault 0

        newCounter =
            currentCounter + 1

        restartSuffix =
            "r" ++ String.fromInt newCounter

        -- Helper to apply restart with a given element animation
        applyRestart : ElementAnimation -> AnimState
        applyRestart elementAnimation =
            let
                -- First reset to start position (instantly)
                (AnimState resetStateData) =
                    reset elementId animState
            in
            AnimState
                { resetStateData
                    | elementAnimations = Dict.insert elementId elementAnimation resetStateData.elementAnimations
                    , elementStates = Dict.insert elementId NotStarted resetStateData.elementStates
                    , restartCounters = Dict.insert elementId newCounter resetStateData.restartCounters
                }
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
