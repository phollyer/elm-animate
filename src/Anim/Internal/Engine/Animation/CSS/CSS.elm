module Anim.Internal.Engine.Animation.CSS.CSS exposing
    ( AnimEvent(..)
    , AnimState(..)
    , SourceEventData
    , allComplete
    , animate
    , anyRunning
    , attributes
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
    , init
    , isActive
    , isCancelled
    , isComplete
    , isPaused
    , isRunning
    , onEvent
    , onEventStopPropagation
    , reset
    , stop
    )

import Anim.Extra.Easing as Easing
import Anim.Extra.TransformOrder exposing (TransformOrder)
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.BackgroundColor as BackgroundColor
import Anim.Internal.Builder.FontColor as FontColor
import Anim.Internal.Engine.Animation.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Animation.CSS.PlayStates as PlayStates exposing (PlayStates)
import Anim.Internal.Engine.Animation.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Extra.Color exposing (Color(..))
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Html
import Html.Events
import Json.Decode



{- ***** Model ***** -}


type AnimState a
    = AnimState
        { playStates : PlayStates
        , builder : AnimBuilder
        }
        (AnimGroups a)


type alias AnimGroupName =
    String


init : (AnimBuilder -> AnimGroupName -> Builder.AnimGroupConfig -> a) -> List (AnimBuilder -> AnimBuilder) -> AnimState a
init toData propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { playStates = PlayStates.init
                , builder = Builder.init []
                }
                AnimGroups.init

        _ ->
            let
                builder =
                    Builder.init propertyInitializers

                animGroups =
                    Builder.getAnimGroups builder
            in
            AnimState
                { playStates =
                    animGroups
                        |> AnimGroups.names
                        |> PlayStates.fromNames
                , builder =
                    builder
                        |> Builder.mergeEndStates
                        |> Builder.clearAnimData
                }
                (AnimGroups.map (toData builder) animGroups)



{- ***** TRIGGER ***** -}


animate :
    (Maybe (List TransformOrder) -> AnimBuilder -> AnimGroupName -> Builder.ProcessedAnimGroupConfig -> a)
    -> (AnimGroups Builder.ProcessedAnimGroupConfig -> AnimGroupName -> a -> AnimGroups a -> AnimGroups a)
    -> AnimState a
    -> (AnimBuilder -> AnimBuilder)
    -> AnimState a
animate generateData insertData (AnimState state animGroups) transform =
    let
        builder =
            transform state.builder

        processedAnimData =
            Builder.process builder

        newPlayStates =
            animGroups
                |> AnimGroups.names
                |> PlayStates.fromNames
                |> PlayStates.setAll PlayStates.Running
    in
    AnimState
        { playStates =
            PlayStates.union newPlayStates state.playStates
        , builder =
            builder
                |> Builder.addAnimationToHistory processedAnimData
                |> Builder.mergeEndStates
                |> Builder.clearAnimData
        }
        (processedAnimData.groups
            |> AnimGroups.map (generateData processedAnimData.globalTransformOrder builder)
            |> AnimGroups.foldl (insertData processedAnimData.groups) animGroups
        )



{- ***** UPDATE ***** -}


type AnimEvent
    = AnimationStarted AnimGroupName
    | AnimationEnded AnimGroupName
    | AnimationCancelled AnimGroupName
    | AnimationIteration AnimGroupName
    | TransitionStarted AnimGroupName
    | TransitionEnded AnimGroupName
    | TransitionRun AnimGroupName
    | TransitionCancelled AnimGroupName


handleEvent : AnimEvent -> AnimState a -> AnimState a
handleEvent event (AnimState state animGroups) =
    let
        ( animGroupName, playState ) =
            case event of
                AnimationStarted groupName ->
                    ( groupName, PlayStates.Running )

                AnimationEnded groupName ->
                    ( groupName, PlayStates.Complete )

                AnimationCancelled groupName ->
                    ( groupName, PlayStates.Cancelled )

                AnimationIteration groupName ->
                    ( groupName, PlayStates.Running )

                TransitionStarted groupName ->
                    ( groupName, PlayStates.Running )

                TransitionEnded groupName ->
                    ( groupName, PlayStates.Complete )

                TransitionRun groupName ->
                    ( groupName, PlayStates.Running )

                TransitionCancelled groupName ->
                    ( groupName, PlayStates.Cancelled )
    in
    AnimState
        { state
            | playStates =
                PlayStates.add animGroupName playState state.playStates
        }
        animGroups



{- ***** VIEW ***** -}


attributes : List ( String, String ) -> (a -> Styles) -> AnimGroupName -> AnimState a -> List (Html.Attribute msg)
attributes attrs getStyles animGroupName (AnimState _ animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            []

        Just animGroup ->
            animGroup
                |> getStyles
                |> Styles.insertList attrs
                |> Styles.toAttrs animGroupName



{- ***** EVENT HANDLERS ***** -}


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
        (Json.Decode.at [ "target", "dataset", "animGroupName" ] Json.Decode.string)
        (elementIdDecoder [ "target", "id" ])
        (elementIdDecoder [ "currentTarget", "id" ])



-- Decoders


type alias SourceEventData =
    { targetId : Maybe String
    , currentTargetId : Maybe String
    }


eventDataToMsg : (animMsg -> msg) -> (AnimGroupName -> SourceEventData -> animMsg) -> AnimGroupName -> SourceEventData -> msg
eventDataToMsg toMsg toAnimMsg groupName =
    toMsg << toAnimMsg groupName


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



{- ***** CONTROL ***** -}


stop : (List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles) -> (Styles -> a) -> AnimGroupName -> AnimState a -> AnimState a
stop buildStyles setStyles animGroupName animState =
    case isActive animGroupName animState of
        Just True ->
            let
                toEndValue : Builder.ProcessedAnimationConfig b -> Builder.ProcessedAnimationConfig b
                toEndValue =
                    toInstantProcessed .end

                toStopProperty : Builder.ProcessedPropertyConfig -> Builder.ProcessedPropertyConfig
                toStopProperty =
                    mapProcessedProperty
                        { translate = toEndValue
                        , scale = toEndValue
                        , rotate = toEndValue
                        , opacity = toEndValue
                        , backgroundColor = toEndValue
                        , size = toEndValue
                        , fontColor = toEndValue
                        }
            in
            simpleControl PlayStates.Complete toStopProperty buildStyles setStyles animGroupName animState

        _ ->
            animState


reset : (List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles) -> (Styles -> a) -> AnimGroupName -> AnimState a -> AnimState a
reset =
    let
        toStartOr : b -> Builder.ProcessedAnimationConfig b -> Builder.ProcessedAnimationConfig b
        toStartOr default =
            toInstantProcessed
                (\config ->
                    case config.start of
                        Just s ->
                            s

                        Nothing ->
                            default
                )

        toResetProperty : Builder.ProcessedPropertyConfig -> Builder.ProcessedPropertyConfig
        toResetProperty =
            mapProcessedProperty
                { translate = toStartOr Translate.default
                , scale = toStartOr (Scale.fromUniform 1.0)
                , rotate = toStartOr Rotate.default
                , opacity = toStartOr Opacity.default
                , backgroundColor = toStartOr BackgroundColor.default
                , size = toStartOr Size.default
                , fontColor = toStartOr FontColor.default
                }
    in
    simpleControl PlayStates.Reset toResetProperty


toInstantProcessed : (Builder.ProcessedAnimationConfig a -> a) -> Builder.ProcessedAnimationConfig a -> Builder.ProcessedAnimationConfig a
toInstantProcessed getValue config =
    let
        value =
            getValue config
    in
    { config
        | start = Just value
        , end = value
        , distance = 0
        , timing = Duration 0
        , easing = Easing.Linear
        , delay = 0
    }


mapProcessedProperty :
    { translate : Builder.ProcessedAnimationConfig Translate -> Builder.ProcessedAnimationConfig Translate
    , scale : Builder.ProcessedAnimationConfig Scale.Scale -> Builder.ProcessedAnimationConfig Scale.Scale
    , rotate : Builder.ProcessedAnimationConfig Rotate.Rotate -> Builder.ProcessedAnimationConfig Rotate.Rotate
    , opacity : Builder.ProcessedAnimationConfig Opacity.Opacity -> Builder.ProcessedAnimationConfig Opacity.Opacity
    , backgroundColor : Builder.ProcessedAnimationConfig Color -> Builder.ProcessedAnimationConfig Color
    , size : Builder.ProcessedAnimationConfig Size.Size -> Builder.ProcessedAnimationConfig Size.Size
    , fontColor : Builder.ProcessedAnimationConfig Color -> Builder.ProcessedAnimationConfig Color
    }
    -> Builder.ProcessedPropertyConfig
    -> Builder.ProcessedPropertyConfig
mapProcessedProperty transforms prop =
    case prop of
        Builder.ProcessedTranslateConfig config ->
            Builder.ProcessedTranslateConfig (transforms.translate config)

        Builder.ProcessedScaleConfig config ->
            Builder.ProcessedScaleConfig (transforms.scale config)

        Builder.ProcessedRotateConfig config ->
            Builder.ProcessedRotateConfig (transforms.rotate config)

        Builder.ProcessedOpacityConfig config ->
            Builder.ProcessedOpacityConfig (transforms.opacity config)

        Builder.ProcessedBackgroundColorConfig config ->
            Builder.ProcessedBackgroundColorConfig (transforms.backgroundColor config)

        Builder.ProcessedSizeConfig config ->
            Builder.ProcessedSizeConfig (transforms.size config)

        Builder.ProcessedFontColorConfig config ->
            Builder.ProcessedFontColorConfig (transforms.fontColor config)


simpleControl :
    PlayStates.State
    -> (Builder.ProcessedPropertyConfig -> Builder.ProcessedPropertyConfig)
    -> (List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles)
    -> (Styles -> a)
    -> AnimGroupName
    -> AnimState a
    -> AnimState a
simpleControl playState mapper buildStyles setStyles animGroupName ((AnimState state animGroups) as animState) =
    let
        getProcessedProperties : List Builder.ProcessedPropertyConfig
        getProcessedProperties =
            Builder.getCurrentAnimation animGroupName state.builder
                |> Maybe.map .properties
                |> Maybe.withDefault []
    in
    case getProcessedProperties of
        [] ->
            animState

        properties ->
            let
                animGroup =
                    properties
                        |> List.map mapper
                        |> buildStyles
                            [ ( "animation", "none" )
                            , ( "transition", "none" )
                            ]
                        |> setStyles
            in
            AnimState
                { state
                    | playStates =
                        PlayStates.add animGroupName playState state.playStates
                }
            <|
                AnimGroups.insert animGroupName animGroup animGroups



{- ***** STATE QUERIES ***** -}


anyRunning : AnimState a -> Maybe Bool
anyRunning (AnimState { playStates } _) =
    PlayStates.anyRunning PlayStates.Running playStates


allComplete : AnimState a -> Maybe Bool
allComplete (AnimState { playStates } _) =
    PlayStates.allComplete playStates


isActive : AnimGroupName -> AnimState a -> Maybe Bool
isActive animGroupName (AnimState { playStates } _) =
    PlayStates.isActive animGroupName playStates


isRunning : AnimGroupName -> AnimState a -> Maybe Bool
isRunning animGroupName (AnimState { playStates } _) =
    PlayStates.isRunning animGroupName playStates


isPaused : AnimGroupName -> AnimState a -> Maybe Bool
isPaused animGroupName (AnimState { playStates } _) =
    PlayStates.isPaused animGroupName playStates


isComplete : AnimGroupName -> AnimState a -> Maybe Bool
isComplete animGroupName (AnimState { playStates } _) =
    PlayStates.isComplete animGroupName playStates


isCancelled : AnimGroupName -> AnimState a -> Maybe Bool
isCancelled animGroupName (AnimState { playStates } _) =
    PlayStates.isCancelled animGroupName playStates



{- ***** PROPERTY QUERIES ***** -}
--
--
--
{- *** BACKGROUND COLOR *** -}


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
getBackgroundColorEnd animGroupName =
    getBackgroundColorRange animGroupName
        >> Maybe.map .end


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



{- *** FONT COLOR *** -}


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



{- *** OPACITY *** -}


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



{- *** ROTATE *** -}


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



{- *** SCALE *** -}


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


getScaleEnd : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd animGroupName =
    getScaleRange animGroupName
        >> Maybe.map (.end >> Scale.toRecord)


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



{- *** SIZE *** -}


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
getSizeEnd animGroupName =
    getSizeRange animGroupName
        >> Maybe.map (.end >> Size.toRecord)


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



{- *** TRANSLATE *** -}


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
