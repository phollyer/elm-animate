module Anim.Internal.CSS exposing
    ( AnimBuilder
    , AnimEvent(..)
    , AnimState(..)
    , ElementAnimation
    , ElementState(..)
    , KeyframeAnimation
    , SourceEventData
    , allComplete
    , anyRunning
    , builder
    , currentTargetIdDecoder
    , delay
    , duration
    , easing
    , elementIdDecoder
    , getBackgroundColorRange
    , getElementAnimation
    , getElementStyles
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
    , isComplete
    , isRunning
    , speed
    , targetIdDecoder
    )

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder
import Anim.Internal.Properties.Color exposing (Color(..))
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Properties.Translate exposing (Translate)
import Dict exposing (Dict)
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


builder : AnimState -> AnimBuilder
builder (AnimState state) =
    state.builder


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


getElementStyles : String -> AnimState -> List ( String, String )
getElementStyles elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.map .styles
        |> Maybe.withDefault []



-- Decoders


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
