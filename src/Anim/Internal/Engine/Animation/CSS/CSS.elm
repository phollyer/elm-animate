module Anim.Internal.Engine.Animation.CSS.CSS exposing
    ( AnimEvent(..)
    , AnimPlayState(..)
    , AnimState(..)
    , SourceEventData
    , allComplete
    , animGroupDataAttribute
    , anyRunning
    , delay
    , duration
    , easing
    , getBackgroundColorEnd
    , getBackgroundColorStart
    , getFontColorEnd
    , getFontColorStart
    , getOpacityEnd
    , getOpacityStart
    , getRotateEnd
    , getRotateStart
    , getScaleEnd
    , getScaleStart
    , getSizeEnd
    , getSizeStart
    , getTranslateEnd
    , getTranslateStart
    , handleEvent
    , isCancelled
    , isComplete
    , isPaused
    , isRunning
    , onEvent
    , onEventStopPropagation
    , simpleControl
    , speed
    )

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.BackgroundColor as BackgroundColor
import Anim.Internal.Builder.FontColor as FontColor
import Anim.Internal.Engine.Animation.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Animation.CSS.Styles exposing (Styles)
import Anim.Internal.Extra.Color exposing (Color(..))
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Html
import Html.Attributes
import Html.Events
import Json.Decode



-- Build


type alias AnimGroupName =
    String


type AnimState a
    = AnimState
        { animPlayStates : AnimGroups AnimPlayState
        , builder : AnimBuilder
        }
        (AnimGroups a)


duration : Int -> AnimBuilder -> AnimBuilder
duration =
    Builder.duration


speed : Float -> AnimBuilder -> AnimBuilder
speed =
    Builder.speed


easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Builder.easing


delay : Int -> AnimBuilder -> AnimBuilder
delay =
    Builder.delay


{-| Individual element animation lifecycle state.
-}
type AnimPlayState
    = NotStarted
    | Running
    | Paused
    | Complete
    | Cancelled



-- Update


{-| Animation lifecycle events.
-}
type AnimEvent
    = AnimationStarted AnimGroupName
    | AnimationEnded AnimGroupName
    | AnimationCancelled AnimGroupName
    | AnimationIteration AnimGroupName
    | TransitionStarted AnimGroupName
    | TransitionEnded AnimGroupName
    | TransitionRun AnimGroupName
    | TransitionCancelled AnimGroupName


{-| Handle animation lifecycle events to update element states.
-}
handleEvent : AnimEvent -> AnimState a -> AnimState a
handleEvent event (AnimState state animGroups) =
    let
        ( animGroup, playeState ) =
            case event of
                AnimationStarted id ->
                    ( id, Running )

                AnimationEnded id ->
                    ( id, Complete )

                AnimationCancelled id ->
                    ( id, Cancelled )

                AnimationIteration id ->
                    ( id, Running )

                TransitionStarted id ->
                    ( id, Running )

                TransitionEnded id ->
                    ( id, Complete )

                TransitionRun id ->
                    ( id, Running )

                TransitionCancelled id ->
                    ( id, Cancelled )
    in
    AnimState
        { state
            | animPlayStates = AnimGroups.insert animGroup playeState state.animPlayStates
        }
        animGroups


animGroupDataAttribute : AnimGroupName -> Html.Attribute msg
animGroupDataAttribute =
    Html.Attributes.attribute "data-anim-group"


onEvent : String -> (a -> msg) -> (AnimGroupName -> SourceEventData -> a) -> Html.Attribute msg
onEvent eventName toMsg msg =
    Html.Events.on eventName <|
        sourceEventDecoder (eventDataToMsg toMsg msg)


onEventStopPropagation : String -> (a -> msg) -> (AnimGroupName -> SourceEventData -> a) -> Html.Attribute msg
onEventStopPropagation eventName toMsg msg =
    Html.Events.stopPropagationOn eventName <|
        Json.Decode.map
            (\msg_ -> ( msg_, True ))
            (sourceEventDecoder (eventDataToMsg toMsg msg))


sourceEventDecoder : (AnimGroupName -> SourceEventData -> msg) -> Json.Decode.Decoder msg
sourceEventDecoder toMsg =
    Json.Decode.map3
        (\groupName targetId currentTargetId ->
            toMsg groupName <|
                SourceEventData targetId currentTargetId
        )
        animGroupNameDecoder
        targetIdDecoder
        currentTargetIdDecoder



-- Decoders


type alias SourceEventData =
    { targetId : Maybe String
    , currentTargetId : Maybe String
    }


eventDataToMsg : (animMsg -> msg) -> (AnimGroupName -> SourceEventData -> animMsg) -> AnimGroupName -> SourceEventData -> msg
eventDataToMsg toMsg toAnimMsg groupName sourceEventData =
    toMsg (toAnimMsg groupName sourceEventData)


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


animGroupNameDecoder : Json.Decode.Decoder String
animGroupNameDecoder =
    Json.Decode.at [ "target", "dataset", "animGroup" ] Json.Decode.string



-- Controls


simpleControl : AnimPlayState -> (Styles -> a) -> (List Builder.ProcessedPropertyConfig -> Styles) -> AnimGroupName -> AnimState a -> AnimState a
simpleControl playState setStyles buildStyles animGroupName ((AnimState { builder } _) as animState) =
    let
        builderFunc =
            case playState of
                Complete ->
                    buildStopProperties

                _ ->
                    buildResetProperties
    in
    case builderFunc animGroupName builder of
        [] ->
            animState

        properties ->
            let
                animGroup =
                    properties
                        |> Builder.processProperties Builder.initDefaults
                        |> buildStyles
                        |> setStyles
            in
            animState
                |> setPlayState animGroupName playState
                |> updateAnimGroup animGroupName animGroup


setPlayState : AnimGroupName -> AnimPlayState -> AnimState a -> AnimState a
setPlayState animGroupName animPlayState (AnimState state animGroups) =
    AnimState
        { state
            | animPlayStates =
                AnimGroups.insert animGroupName animPlayState state.animPlayStates
        }
        animGroups


updateAnimGroup : AnimGroupName -> a -> AnimState a -> AnimState a
updateAnimGroup animGroupName animGroup (AnimState state animGroups) =
    AnimState state <|
        AnimGroups.insert animGroupName animGroup animGroups



-- Query


{-| Check if any animations are currently running.
-}
anyRunning : AnimState a -> Maybe Bool
anyRunning (AnimState state _) =
    case AnimGroups.groups state.animPlayStates of
        [] ->
            Nothing

        playStates ->
            List.any (\playState -> playState == Running) playStates
                |> Just


{-| Check if all animations are complete.
-}
allComplete : AnimState a -> Maybe Bool
allComplete (AnimState state _) =
    if AnimGroups.isEmpty state.animPlayStates then
        Nothing

    else
        state.animPlayStates
            |> AnimGroups.groups
            |> List.all (\playState -> playState == Complete)
            |> Just


isRunning : AnimGroupName -> AnimState a -> Maybe Bool
isRunning animGroupName (AnimState state _) =
    AnimGroups.get animGroupName state.animPlayStates
        |> Maybe.map (\playState -> playState == Running)


isPaused : AnimGroupName -> AnimState a -> Maybe Bool
isPaused animGroupName (AnimState state _) =
    AnimGroups.get animGroupName state.animPlayStates
        |> Maybe.map (\playState -> playState == Paused)


isComplete : AnimGroupName -> AnimState a -> Maybe Bool
isComplete animGroupName (AnimState state _) =
    AnimGroups.get animGroupName state.animPlayStates
        |> Maybe.map
            (\playState ->
                case playState of
                    Complete ->
                        True

                    _ ->
                        False
            )


isCancelled : AnimGroupName -> AnimState a -> Maybe Bool
isCancelled animGroupName (AnimState state _) =
    AnimGroups.get animGroupName state.animPlayStates
        |> Maybe.map (\elementState -> elementState == Cancelled)


getBackgroundColorStart : AnimGroupName -> AnimState a -> Maybe Color
getBackgroundColorStart animGroupName =
    getBackgroundColorRange animGroupName
        >> Maybe.map
            (\{ start } ->
                case start of
                    Just startColor ->
                        startColor

                    Nothing ->
                        BackgroundColor.default
            )


getBackgroundColorEnd : AnimGroupName -> AnimState a -> Maybe Color
getBackgroundColorEnd animGroupName animState =
    getBackgroundColorRange animGroupName animState
        |> Maybe.map .end


{-| Get both start and end background colors for an element's animation.
Returns Nothing if the element has no background color animation.
-}
getBackgroundColorRange : AnimGroupName -> AnimState a -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange =
    getPropertyFromProcessed
        (\prop ->
            case prop of
                Builder.ProcessedBackgroundColorConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


getFontColorStart : AnimGroupName -> AnimState a -> Maybe Color
getFontColorStart animGroupName =
    getFontColorRange animGroupName
        >> Maybe.map
            (\{ start } ->
                case start of
                    Just startColor ->
                        startColor

                    Nothing ->
                        FontColor.default
            )


getFontColorEnd : AnimGroupName -> AnimState a -> Maybe Color
getFontColorEnd animGroupName animState =
    getFontColorRange animGroupName animState
        |> Maybe.map .end


{-| Get both start and end font colors for an element's animation.
Returns Nothing if the element has no font color animation.
-}
getFontColorRange : AnimGroupName -> AnimState a -> Maybe { start : Maybe Color, end : Color }
getFontColorRange =
    getPropertyFromProcessed
        (\prop ->
            case prop of
                Builder.ProcessedFontColorConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


getOpacityStart : AnimGroupName -> AnimState a -> Maybe Float
getOpacityStart animGroupName =
    getOpacityRange animGroupName
        >> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        1.0

                    Just startOpacity ->
                        Opacity.toFloat startOpacity
            )


getOpacityEnd : AnimGroupName -> AnimState a -> Maybe Float
getOpacityEnd animGroupName animState =
    getOpacityRange animGroupName animState
        |> Maybe.map (.end >> Opacity.toFloat)


{-| Get both start and end opacity for an element's animation.
Returns Nothing if the element has no opacity animation.
-}
getOpacityRange : AnimGroupName -> AnimState a -> Maybe { start : Maybe Opacity.Opacity, end : Opacity.Opacity }
getOpacityRange =
    getPropertyFromProcessed
        (\prop ->
            case prop of
                Builder.ProcessedOpacityConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


getRotateStart : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float, z : Float }
getRotateStart animGroupName =
    getRotateRange animGroupName
        >> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 0, y = 0, z = 0 }

                    Just startRotate ->
                        Rotate.toRecord startRotate
            )


getRotateEnd : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd animGroupName =
    getRotateRange animGroupName
        >> Maybe.map (.end >> Rotate.toRecord)


{-| Get both start and end rotations for an element's animation.
Returns Nothing if the element has no rotate animation.
-}
getRotateRange : AnimGroupName -> AnimState a -> Maybe { start : Maybe Rotate.Rotate, end : Rotate.Rotate }
getRotateRange =
    getPropertyFromProcessed
        (\prop ->
            case prop of
                Builder.ProcessedRotateConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


getScaleStart : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float, z : Float }
getScaleStart animGroupName =
    getScaleRange animGroupName
        >> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 1, y = 1, z = 1 }

                    Just startScale ->
                        Scale.toRecord startScale
            )


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd animGroupName =
    getScaleRange animGroupName
        >> Maybe.map (.end >> Scale.toRecord)


{-| Get both start and end scales for an element's animation.
Returns Nothing if the element has no scale animation.
-}
getScaleRange : AnimGroupName -> AnimState a -> Maybe { start : Maybe Scale.Scale, end : Scale.Scale }
getScaleRange =
    getPropertyFromProcessed
        (\prop ->
            case prop of
                Builder.ProcessedScaleConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


getSizeStart : AnimGroupName -> AnimState a -> Maybe { width : Float, height : Float }
getSizeStart animGroupName =
    getSizeRange animGroupName
        >> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { width = 0, height = 0 }

                    Just startSize ->
                        Size.toRecord startSize
            )


getSizeEnd : AnimGroupName -> AnimState a -> Maybe { width : Float, height : Float }
getSizeEnd animGroupName animState =
    getSizeRange animGroupName animState
        |> Maybe.map (.end >> Size.toRecord)


{-| Get both start and end sizes for an element's animation.
Returns Nothing if the element has no size animation.
-}
getSizeRange : AnimGroupName -> AnimState a -> Maybe { start : Maybe Size.Size, end : Size.Size }
getSizeRange =
    getPropertyFromProcessed
        (\prop ->
            case prop of
                Builder.ProcessedSizeConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


getTranslateStart : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart animGroupName =
    getTranslateRange animGroupName
        >> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 0, y = 0, z = 0 }

                    Just startPos ->
                        Translate.toRecord startPos
            )


getTranslateEnd : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd animGroupName =
    getTranslateRange animGroupName
        >> Maybe.map (.end >> Translate.toRecord)


getTranslateRange : AnimGroupName -> AnimState a -> Maybe { start : Maybe Translate, end : Translate }
getTranslateRange =
    getPropertyFromProcessed
        (\prop ->
            case prop of
                Builder.ProcessedTranslateConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


getPropertyFromProcessed : (Builder.ProcessedPropertyConfig -> Maybe b) -> AnimGroupName -> AnimState a -> Maybe b
getPropertyFromProcessed extract animGroupName (AnimState state _) =
    let
        processedData =
            Builder.process state.builder
    in
    AnimGroups.get animGroupName processedData.groups
        |> Maybe.andThen
            (\{ properties } ->
                properties
                    |> List.filterMap extract
                    |> List.head
            )



-- Shared stop/reset helpers


buildStopProperties : AnimGroupName -> Builder.AnimBuilder -> List Builder.PropertyConfig
buildStopProperties animGroupName builder_ =
    Builder.getCurrentAnimation animGroupName builder_
        |> Maybe.map
            (\processedElementConfig ->
                processedElementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedTranslateConfig config ->
                                    Just <|
                                        Builder.TranslateConfig
                                            (makeInstantConfig config.end)

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


buildResetProperties : AnimGroupName -> Builder.AnimBuilder -> List Builder.PropertyConfig
buildResetProperties animGroupName builder_ =
    Builder.getCurrentAnimation animGroupName builder_
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


makeInstantConfig : a -> Builder.AnimationConfig a
makeInstantConfig value =
    { start = Just value
    , end = value
    , distance = 0
    , timing = Just (Duration 0)
    , easing = Just Anim.Extra.Easing.Linear
    , delay = Nothing
    }
