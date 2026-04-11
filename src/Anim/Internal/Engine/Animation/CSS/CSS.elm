module Anim.Internal.Engine.Animation.CSS.CSS exposing
    ( AnimEvent(..)
    , AnimPlayState(..)
    , AnimState(..)
    , SourceEventData
    , allComplete
    , animGroupDataAttribute
    , animate
    , anyRunning
    , attributes
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
    , init
    , isActive
    , isCancelled
    , isComplete
    , isPaused
    , isRunning
    , onEvent
    , onEventStopPropagation
    , reset
    , setPlayState
    , simpleControl
    , speed
    , stop
    , updateAnimGroup
    )

import Anim.Extra.Easing exposing (Easing)
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
import Html.Attributes
import Html.Events
import Json.Decode



{- ***** Model ***** -}


type AnimState a
    = AnimState
        { animPlayStates : PlayStates
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
                { animPlayStates = PlayStates.init
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
                { animPlayStates =
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
        { animPlayStates =
            PlayStates.union newPlayStates state.animPlayStates
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
            | animPlayStates =
                PlayStates.add animGroupName playState state.animPlayStates
        }
        animGroups



{- ***** VIEW ***** -}


attributes : List ( String, String ) -> (a -> Styles) -> AnimGroupName -> AnimState a -> List (Html.Attribute msg)
attributes attrs getStyles animGroupName (AnimState _ animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            []

        Just animGroup ->
            animGroupDataAttribute animGroupName
                :: (animGroup
                        |> getStyles
                        |> Styles.insertList attrs
                        |> Styles.toAttrs animGroupName
                   )



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
        animGroupNameDecoder
        targetIdDecoder
        currentTargetIdDecoder



-- Decoders


type alias SourceEventData =
    { targetId : Maybe String
    , currentTargetId : Maybe String
    }


eventDataToMsg : (animMsg -> msg) -> (AnimGroupName -> SourceEventData -> animMsg) -> AnimGroupName -> SourceEventData -> msg
eventDataToMsg toMsg toAnimMsg groupName =
    toMsg << toAnimMsg groupName


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



{- ***** CONTROL ***** -}


stop : (List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles) -> (Styles -> a) -> AnimGroupName -> AnimState a -> AnimState a
stop buildStyles setStyles animGroupName animState =
    case isActive animGroupName animState of
        Just True ->
            simpleControl PlayStates.Complete buildStopProperties buildStyles setStyles animGroupName animState

        _ ->
            animState


reset : (List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles) -> (Styles -> a) -> AnimGroupName -> AnimState a -> AnimState a
reset =
    simpleControl PlayStates.Reset buildResetProperties


simpleControl :
    PlayStates.State
    -> (AnimGroupName -> Builder.AnimBuilder -> List Builder.PropertyConfig)
    -> (List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles)
    -> (Styles -> a)
    -> AnimGroupName
    -> AnimState a
    -> AnimState a
simpleControl playState builderFunc buildStyles setStyles animGroupName ((AnimState { builder } _) as animState) =
    case builderFunc animGroupName builder of
        [] ->
            animState

        properties ->
            let
                animGroup =
                    properties
                        |> Builder.processProperties Builder.initDefaults
                        |> buildStyles
                            [ ( "animation", "none" )
                            , ( "transition", "none" )
                            ]
                        |> setStyles
            in
            animState
                |> setPlayState animGroupName playState
                |> updateAnimGroup animGroupName animGroup


setPlayState : AnimGroupName -> PlayStates.State -> AnimState a -> AnimState a
setPlayState animGroupName playState (AnimState state animGroups) =
    AnimState
        { state
            | animPlayStates =
                PlayStates.add animGroupName playState state.animPlayStates
        }
        animGroups


updateAnimGroup : AnimGroupName -> a -> AnimState a -> AnimState a
updateAnimGroup animGroupName animGroup (AnimState state animGroups) =
    AnimState state <|
        AnimGroups.insert animGroupName animGroup animGroups


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
    | Reset
    | Complete
    | Cancelled


animGroupDataAttribute : AnimGroupName -> Html.Attribute msg
animGroupDataAttribute =
    Html.Attributes.attribute "data-anim-group"



-- Query


{-| Check if any animations are currently running.
-}
anyRunning : AnimState a -> Maybe Bool
anyRunning (AnimState state _) =
    case PlayStates.list state.animPlayStates of
        [] ->
            Nothing

        _ ->
            Just <|
                PlayStates.any PlayStates.Running state.animPlayStates


{-| Check if all animations are complete.
-}
allComplete : AnimState a -> Maybe Bool
allComplete (AnimState state _) =
    PlayStates.allComplete state.animPlayStates


isActive : AnimGroupName -> AnimState a -> Maybe Bool
isActive animGroupName (AnimState state _) =
    PlayStates.isActive animGroupName state.animPlayStates


isRunning : AnimGroupName -> AnimState a -> Maybe Bool
isRunning animGroupName (AnimState state _) =
    PlayStates.isRunning animGroupName state.animPlayStates


isPaused : AnimGroupName -> AnimState a -> Maybe Bool
isPaused animGroupName (AnimState state _) =
    PlayStates.isPaused animGroupName state.animPlayStates


isComplete : AnimGroupName -> AnimState a -> Maybe Bool
isComplete animGroupName (AnimState state _) =
    PlayStates.isComplete animGroupName state.animPlayStates


isCancelled : AnimGroupName -> AnimState a -> Maybe Bool
isCancelled animGroupName (AnimState state _) =
    PlayStates.isCancelled animGroupName state.animPlayStates


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



-- stop/reset helpers


buildPropertiesWith : (Builder.ProcessedPropertyConfig -> Maybe Builder.PropertyConfig) -> AnimGroupName -> Builder.AnimBuilder -> List Builder.PropertyConfig
buildPropertiesWith mapper animGroupName builder_ =
    Builder.getCurrentAnimation animGroupName builder_
        |> Maybe.map (\config -> List.filterMap mapper config.properties)
        |> Maybe.withDefault []


toInstant : (a -> b) -> (Builder.AnimationConfig b -> Builder.PropertyConfig) -> a -> Maybe Builder.PropertyConfig
toInstant getValue wrapper config =
    Just (wrapper (makeInstantConfig (getValue config)))


startOr : a -> { b | start : Maybe a } -> a
startOr default config =
    Maybe.withDefault default config.start


buildStopProperties : AnimGroupName -> Builder.AnimBuilder -> List Builder.PropertyConfig
buildStopProperties =
    buildPropertiesWith
        (\prop ->
            case prop of
                Builder.ProcessedTranslateConfig config ->
                    toInstant .end Builder.TranslateConfig config

                Builder.ProcessedScaleConfig config ->
                    toInstant .end Builder.ScaleConfig config

                Builder.ProcessedRotateConfig config ->
                    toInstant .end Builder.RotateConfig config

                Builder.ProcessedOpacityConfig config ->
                    toInstant .end Builder.OpacityConfig config

                Builder.ProcessedBackgroundColorConfig config ->
                    toInstant .end Builder.BackgroundColorConfig config

                Builder.ProcessedSizeConfig config ->
                    toInstant .end Builder.SizeConfig config

                Builder.ProcessedFontColorConfig config ->
                    toInstant .end Builder.FontColorConfig config
        )


buildResetProperties : AnimGroupName -> Builder.AnimBuilder -> List Builder.PropertyConfig
buildResetProperties =
    buildPropertiesWith
        (\prop ->
            case prop of
                Builder.ProcessedTranslateConfig config ->
                    toInstant (startOr Translate.default) Builder.TranslateConfig config

                Builder.ProcessedScaleConfig config ->
                    toInstant (startOr (Scale.fromUniform 1.0)) Builder.ScaleConfig config

                Builder.ProcessedRotateConfig config ->
                    toInstant (startOr Rotate.default) Builder.RotateConfig config

                Builder.ProcessedOpacityConfig config ->
                    toInstant (startOr Opacity.default) Builder.OpacityConfig config

                Builder.ProcessedBackgroundColorConfig config ->
                    toInstant (startOr BackgroundColor.default) Builder.BackgroundColorConfig config

                Builder.ProcessedSizeConfig config ->
                    toInstant (startOr Size.default) Builder.SizeConfig config

                Builder.ProcessedFontColorConfig _ ->
                    Nothing
        )


makeInstantConfig : a -> Builder.AnimationConfig a
makeInstantConfig property =
    { start = Just property
    , end = property
    , distance = 0
    , timing = Just (Duration 0)
    , easing = Just Anim.Extra.Easing.Linear
    , delay = Nothing
    }
