module Anim.Internal.CSS exposing
    ( AnimBuilder
    , AnimEvent(..)
    , AnimState(..)
    , ElementState(..)
    , SourceEventData
    , allComplete
    , anyRunning
    , buildResetProperties
    , buildStopProperties
    , builder
    , currentTargetIdDecoder
    , delay
    , duration
    , easing
    , elementData
    , getBackgroundColorRange
    , getOpacityRange
    , getRotateRange
    , getScaleRange
    , getSizeRange
    , getTranslateRange
    , handleEvent
    , isComplete
    , isRunning
    , speed
    , targetIdDecoder
    )

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.BackgroundColor as BackgroundColor
import Anim.Internal.Property.Color exposing (Color(..))
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Dict exposing (Dict)
import Json.Decode



-- Build


type alias AnimBuilder =
    Builder.AnimBuilder


type alias AnimGroupName =
    String


type AnimState a
    = AnimState
        { elementStates : Dict AnimGroupName ElementState
        , builder : AnimBuilder
        }
        (Dict AnimGroupName a)


builder : AnimState a -> AnimBuilder
builder (AnimState state _) =
    state.builder


elementData : AnimState a -> Dict AnimGroupName a
elementData (AnimState _ data) =
    data


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
handleEvent : AnimEvent -> AnimState a -> AnimState a
handleEvent event (AnimState state data) =
    let
        ( animGroupName, newElementState ) =
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
                Dict.insert animGroupName newElementState state.elementStates
        }
        data



-- Query


{-| Check if any animations are currently running.
-}
anyRunning : AnimState a -> Maybe Bool
anyRunning (AnimState state _) =
    case Dict.values state.elementStates of
        [] ->
            Nothing

        values ->
            List.any (\elementState -> elementState == Running) values
                |> Just


{-| Check if all animations are complete.
-}
allComplete : AnimState a -> Maybe Bool
allComplete (AnimState state _) =
    if Dict.isEmpty state.elementStates then
        Nothing

    else
        state.elementStates
            |> Dict.values
            |> List.all (\elementState -> elementState == Complete)
            |> Just


{-| Check if a specific element has any animations currently running.
-}
isRunning : String -> AnimState a -> Maybe Bool
isRunning animGroupName (AnimState state _) =
    Dict.get animGroupName state.elementStates
        |> Maybe.map (\elementState -> elementState == Running)


{-| Check if a specific element's animations have completed.
-}
isComplete : String -> AnimState a -> Maybe Bool
isComplete animGroupName (AnimState state _) =
    Dict.get animGroupName state.elementStates
        |> Maybe.map
            (\elementState ->
                case elementState of
                    Complete ->
                        True

                    _ ->
                        False
            )


getPropertyFromProcessed : (Builder.ProcessedPropertyConfig -> Maybe b) -> String -> AnimState a -> Maybe b
getPropertyFromProcessed extract animGroupName (AnimState state _) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get animGroupName processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap extract
                    |> List.head
            )


{-| Get both start and end translates for an element's animation.
Returns Nothing if the element has no translate animation.
-}
getTranslateRange : String -> AnimState a -> Maybe { start : Maybe Translate, end : Translate }
getTranslateRange =
    getPropertyFromProcessed
        (\prop ->
            case prop of
                Builder.ProcessedTranslateConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


{-| Get both start and end scales for an element's animation.
Returns Nothing if the element has no scale animation.
-}
getScaleRange : String -> AnimState a -> Maybe { start : Maybe Scale.Scale, end : Scale.Scale }
getScaleRange =
    getPropertyFromProcessed
        (\prop ->
            case prop of
                Builder.ProcessedScaleConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


{-| Get both start and end rotations for an element's animation.
Returns Nothing if the element has no rotate animation.
-}
getRotateRange : String -> AnimState a -> Maybe { start : Maybe Rotate.Rotate, end : Rotate.Rotate }
getRotateRange =
    getPropertyFromProcessed
        (\prop ->
            case prop of
                Builder.ProcessedRotateConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


{-| Get both start and end background colors for an element's animation.
Returns Nothing if the element has no background color animation.
-}
getBackgroundColorRange : String -> AnimState a -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange =
    getPropertyFromProcessed
        (\prop ->
            case prop of
                Builder.ProcessedBackgroundColorConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


{-| Get both start and end opacity for an element's animation.
Returns Nothing if the element has no opacity animation.
-}
getOpacityRange : String -> AnimState a -> Maybe { start : Maybe Opacity.Opacity, end : Opacity.Opacity }
getOpacityRange =
    getPropertyFromProcessed
        (\prop ->
            case prop of
                Builder.ProcessedOpacityConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


{-| Get both start and end sizes for an element's animation.
Returns Nothing if the element has no size animation.
-}
getSizeRange : String -> AnimState a -> Maybe { start : Maybe Size.Size, end : Size.Size }
getSizeRange =
    getPropertyFromProcessed
        (\prop ->
            case prop of
                Builder.ProcessedSizeConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )



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



-- Shared stop/reset helpers


makeInstantConfig : a -> Builder.AnimationConfig a
makeInstantConfig value =
    { start = Just value
    , end = value
    , distance = 0
    , timing = Just (Duration 0)
    , easing = Just Anim.Extra.Easing.Linear
    , delay = Nothing
    }


buildStopProperties : String -> Builder.AnimBuilder -> List Builder.PropertyConfig
buildStopProperties animGroupName builder_ =
    Builder.getCurrentAnimation animGroupName builder_
        |> Maybe.andThen (\entry -> Dict.get animGroupName entry.processedData.elements)
        |> Maybe.map
            (\processedElementConfig ->
                processedElementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedTranslateConfig config ->
                                    Just <| Builder.TranslateConfig (makeInstantConfig config.end)

                                Builder.ProcessedScaleConfig config ->
                                    Just <| Builder.ScaleConfig (makeInstantConfig config.end)

                                Builder.ProcessedRotateConfig config ->
                                    Just <| Builder.RotateConfig (makeInstantConfig config.end)

                                Builder.ProcessedOpacityConfig config ->
                                    Just <| Builder.OpacityConfig (makeInstantConfig config.end)

                                Builder.ProcessedBackgroundColorConfig config ->
                                    Just <| Builder.BackgroundColorConfig (makeInstantConfig config.end)

                                Builder.ProcessedSizeConfig config ->
                                    Just <| Builder.SizeConfig (makeInstantConfig config.end)

                                Builder.ProcessedFontColorConfig config ->
                                    Just <| Builder.FontColorConfig (makeInstantConfig config.end)
                        )
            )
        |> Maybe.withDefault []


buildResetProperties : String -> Builder.AnimBuilder -> List Builder.PropertyConfig
buildResetProperties animGroupName builder_ =
    Builder.getCurrentAnimation animGroupName builder_
        |> Maybe.andThen (\entry -> Dict.get animGroupName entry.processedData.elements)
        |> Maybe.map
            (\processedElementConfig ->
                processedElementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedTranslateConfig config ->
                                    Just <|
                                        Builder.TranslateConfig
                                            (makeInstantConfig (Maybe.withDefault Translate.default config.start))

                                Builder.ProcessedScaleConfig config ->
                                    Just <|
                                        Builder.ScaleConfig
                                            (makeInstantConfig (Maybe.withDefault (Scale.fromUniform 1.0) config.start))

                                Builder.ProcessedRotateConfig config ->
                                    Just <|
                                        Builder.RotateConfig
                                            (makeInstantConfig (Maybe.withDefault Rotate.default config.start))

                                Builder.ProcessedOpacityConfig config ->
                                    Just <|
                                        Builder.OpacityConfig
                                            (makeInstantConfig (Maybe.withDefault Opacity.default config.start))

                                Builder.ProcessedBackgroundColorConfig config ->
                                    Just <|
                                        Builder.BackgroundColorConfig
                                            (makeInstantConfig (Maybe.withDefault BackgroundColor.default config.start))

                                Builder.ProcessedSizeConfig config ->
                                    Just <|
                                        Builder.SizeConfig
                                            (makeInstantConfig (Maybe.withDefault Size.default config.start))

                                Builder.ProcessedFontColorConfig _ ->
                                    Nothing
                        )
            )
        |> Maybe.withDefault []
