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
import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.BackgroundColor as BackgroundColor
import Anim.Internal.Builder.FontColor as FontColor
import Anim.Internal.Engine.Animation.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Animation.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Engine.Animation.PlayState as PlayState exposing (PlayState)
import Anim.Internal.Extra.Color exposing (Color(..))
import Anim.Internal.Property.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Anim.Internal.Property.Size as Size exposing (Size)
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Html
import Html.Events
import Json.Decode



{- ***** Model ***** -}


type AnimState a
    = AnimState
        { builder : AnimBuilder
        }
        (AnimGroups a)


type alias AnimGroupName =
    String


init : (AnimBuilder -> AnimGroupName -> Builder.AnimGroupConfig -> a) -> List (AnimBuilder -> AnimBuilder) -> AnimState a
init initGroup propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { builder = Builder.init []
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
                { builder =
                    builder
                        |> Builder.mergeBaselines
                        |> Builder.clearAnimData
                }
                (AnimGroups.map (initGroup builder) animGroups)



{- ***** TRIGGER ***** -}


animate :
    (PlayState -> a -> a)
    -> (Maybe (List TransformProperty) -> AnimBuilder -> AnimGroupName -> Builder.ProcessedAnimGroupConfig -> a)
    -> (AnimGroups Builder.ProcessedAnimGroupConfig -> AnimGroupName -> a -> AnimGroups a -> AnimGroups a)
    -> AnimState a
    -> (AnimBuilder -> AnimBuilder)
    -> AnimState a
animate setPlayState generateData insertData (AnimState state animGroups) transform =
    let
        builder =
            transform state.builder

        processedAnimData =
            Builder.process builder

        setAllRunning : AnimGroups a -> AnimGroups a
        setAllRunning groups =
            AnimGroups.map (\_ group -> setPlayState PlayState.Running group) groups
    in
    AnimState
        { builder =
            builder
                |> Builder.addAnimationToHistory processedAnimData
                |> Builder.mergeBaselines
                |> Builder.clearAnimData
        }
        (processedAnimData.groups
            |> AnimGroups.map (generateData processedAnimData.globalTransformOrder builder)
            |> AnimGroups.foldl (insertData processedAnimData.groups) animGroups
            |> setAllRunning
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


handleEvent : (PlayState -> a -> a) -> AnimEvent -> AnimState a -> AnimState a
handleEvent setPlayState event (AnimState state animGroups) =
    let
        ( animGroupName, playState ) =
            case event of
                AnimationStarted groupName ->
                    ( groupName, PlayState.Running )

                AnimationEnded groupName ->
                    ( groupName, PlayState.Complete )

                AnimationCancelled groupName ->
                    ( groupName, PlayState.Cancelled )

                AnimationIteration groupName ->
                    ( groupName, PlayState.Running )

                TransitionStarted groupName ->
                    ( groupName, PlayState.Running )

                TransitionEnded groupName ->
                    ( groupName, PlayState.Complete )

                TransitionRun groupName ->
                    ( groupName, PlayState.Running )

                TransitionCancelled groupName ->
                    ( groupName, PlayState.Cancelled )
    in
    AnimState state
        (AnimGroups.update animGroupName
            (Maybe.map (setPlayState playState))
            animGroups
        )



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


stop : (PlayState -> a -> a) -> (a -> Bool) -> (List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles) -> (Styles -> a) -> AnimGroupName -> AnimState a -> AnimState a
stop setPlayState getIsActive buildStyles setStyles animGroupName animState =
    case isActive getIsActive animGroupName animState of
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
            simpleControl (setPlayState PlayState.Complete) toStopProperty buildStyles setStyles animGroupName animState

        _ ->
            animState


reset : (PlayState -> a -> a) -> (List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles) -> (Styles -> a) -> AnimGroupName -> AnimState a -> AnimState a
reset setPlayState =
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
                , scale = toStartOr Scale.default
                , rotate = toStartOr Rotate.default
                , opacity = toStartOr Opacity.default
                , backgroundColor = toStartOr BackgroundColor.default
                , size = toStartOr Size.default
                , fontColor = toStartOr FontColor.default
                }
    in
    simpleControl (setPlayState PlayState.Reset) toResetProperty


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
    , scale : Builder.ProcessedAnimationConfig Scale -> Builder.ProcessedAnimationConfig Scale
    , rotate : Builder.ProcessedAnimationConfig Rotate -> Builder.ProcessedAnimationConfig Rotate
    , opacity : Builder.ProcessedAnimationConfig Opacity -> Builder.ProcessedAnimationConfig Opacity
    , backgroundColor : Builder.ProcessedAnimationConfig Color -> Builder.ProcessedAnimationConfig Color
    , size : Builder.ProcessedAnimationConfig Size -> Builder.ProcessedAnimationConfig Size
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
    (a -> a)
    -> (Builder.ProcessedPropertyConfig -> Builder.ProcessedPropertyConfig)
    -> (List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles)
    -> (Styles -> a)
    -> AnimGroupName
    -> AnimState a
    -> AnimState a
simpleControl setPlayState mapper buildStyles setStyles animGroupName ((AnimState state animGroups) as animState) =
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
                        |> setPlayState
            in
            AnimState state <|
                AnimGroups.insert animGroupName animGroup animGroups



{- ***** STATE QUERIES ***** -}


anyRunning : (a -> Bool) -> AnimState a -> Maybe Bool
anyRunning getIsRunning (AnimState _ animGroups) =
    case AnimGroups.groups animGroups of
        [] ->
            Nothing

        groups ->
            Just (List.any getIsRunning groups)


allComplete : (a -> Bool) -> AnimState a -> Maybe Bool
allComplete getIsComplete (AnimState _ animGroups) =
    case AnimGroups.groups animGroups of
        [] ->
            Nothing

        groups ->
            Just (List.all getIsComplete groups)


isActive : (a -> Bool) -> AnimGroupName -> AnimState a -> Maybe Bool
isActive getIsActive animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map getIsActive


isRunning : (a -> Bool) -> AnimGroupName -> AnimState a -> Maybe Bool
isRunning getIsRunning animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map getIsRunning


isPaused : (a -> Bool) -> AnimGroupName -> AnimState a -> Maybe Bool
isPaused getIsPaused animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map getIsPaused


isComplete : (a -> Bool) -> AnimGroupName -> AnimState a -> Maybe Bool
isComplete getIsComplete animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map getIsComplete


isCancelled : (a -> Bool) -> AnimGroupName -> AnimState a -> Maybe Bool
isCancelled getIsCancelled animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map getIsCancelled



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
    getPropertyConfig
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
    getPropertyConfig
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
    getPropertyConfig
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
    getPropertyConfig
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
    getPropertyConfig
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
    getPropertyConfig
        (\prop ->
            case prop of
                Builder.ProcessedSizeConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )



{- *** TRANSLATE *** -}


getTranslateStart : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedTranslateConfig config ->
                    Maybe.map Translate.toRecord config.start

                _ ->
                    Nothing
        )


getTranslateEnd : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    getPropertyConfig
        (\propConfig ->
            case propConfig of
                Builder.ProcessedTranslateConfig config ->
                    Just (Translate.toRecord config.end)

                _ ->
                    Nothing
        )


getTranslateRange : AnimGroupName -> AnimState a -> Maybe { start : Maybe Translate, end : Translate }
getTranslateRange =
    getPropertyConfig
        (\prop ->
            case prop of
                Builder.ProcessedTranslateConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


getPropertyConfig : (Builder.ProcessedPropertyConfig -> Maybe b) -> AnimGroupName -> AnimState a -> Maybe b
getPropertyConfig matcher animGroupName (AnimState state _) =
    Builder.getCurrentAnimation animGroupName state.builder
        |> Maybe.andThen (.properties >> List.filterMap matcher >> List.head)
