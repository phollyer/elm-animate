module Anim.Internal.Engine.CSS.CSS exposing
    ( AnimEvent(..)
    , AnimState(..)
    , SourceEventData
    , allComplete
    , alternate
    , animate
    , anyRunning
    , attributes
    , delay
    , discreteEntry
    , discreteExit
    , duration
    , easing
    , getColorPropertyEnd
    , getColorPropertyRange
    , getColorPropertyStart
    , getOpacityEnd
    , getOpacityRange
    , getOpacityStart
    , getPerspectiveOriginEnd
    , getPerspectiveOriginRange
    , getPerspectiveOriginStart
    , getPropertyEnd
    , getPropertyRange
    , getPropertyStart
    , getRotateEnd
    , getRotateRange
    , getRotateStart
    , getScaleEnd
    , getScaleRange
    , getScaleStart
    , getSizeEnd
    , getSizeRange
    , getSizeStart
    , getSkewEnd
    , getSkewRange
    , getSkewStart
    , getTranslateEnd
    , getTranslateRange
    , getTranslateStart
    , handleEvent
    , init
    , isActive
    , isCancelled
    , isComplete
    , isPaused
    , isRunning
    , iterations
    , loopForever
    , onEvent
    , onEventStopPropagation
    , reset
    , speed
    , stop
    )

import Anim.Extra.Color as Color
import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.Property as Property
import Anim.Internal.Engine.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Engine.PlayState as PlayState exposing (PlayState)
import Anim.Internal.Extra.Color exposing (Color(..))
import Anim.Internal.Property.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin exposing (PerspectiveOrigin)
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Anim.Internal.Property.Size as Size exposing (Size)
import Anim.Internal.Property.Skew as Skew exposing (Skew)
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Easing exposing (Easing)
import Html
import Html.Events
import Json.Decode
import Shared.TimeSpec exposing (TimeSpec(..))


type alias AnimBuilder =
    Builder.AnimBuilder {}



-- ============================================================
-- TYPES
-- ============================================================


type AnimState a
    = AnimState { builder : AnimBuilder } (AnimGroups a)


type alias AnimGroupName =
    String



-- ============================================================
-- INITIALIZE
-- ============================================================


init : (AnimBuilder -> AnimGroupName -> Builder.AnimGroupConfig -> a) -> List (AnimBuilder -> AnimBuilder) -> AnimState a
init initGroup propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { builder = Builder.init [] }
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



-- ============================================================
-- TRIGGER
-- ============================================================


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
            |> AnimGroups.map (\animGroupName config -> generateData config.transformOrder builder animGroupName config)
            |> AnimGroups.foldl (insertData processedAnimData.groups) animGroups
            |> setAllRunning
        )



-- ============================================================
-- EVENTS
-- ============================================================


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



-- ============================================================
-- VIEW
-- ============================================================


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



-- ============================================================
-- EVENT LISTENERS
-- ============================================================


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



-- ============================================================
-- PLAYBACK
-- ============================================================


iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    Builder.iterations


loopForever : AnimBuilder -> AnimBuilder
loopForever =
    Builder.loopForever


alternate : AnimBuilder -> AnimBuilder
alternate =
    Builder.alternate



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> AnimBuilder -> AnimBuilder
delay =
    Builder.delay


duration : Int -> AnimBuilder -> AnimBuilder
duration =
    Builder.duration


speed : Float -> AnimBuilder -> AnimBuilder
speed =
    Builder.speed



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Builder.easing



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


stop : (PlayState -> a -> a) -> (a -> Bool) -> (List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles) -> (Styles -> a) -> AnimGroupName -> AnimState a -> AnimState a
stop setPlayState getIsActive buildStyles setStyles animGroupName animState =
    case isActive getIsActive animGroupName animState of
        Just True ->
            let
                toStopProperty : Builder.ProcessedPropertyConfig -> Builder.ProcessedPropertyConfig
                toStopProperty =
                    mapProcessedProperty
                        { customProperty = \_ _ -> snapTo .end
                        , customColorProperty = \_ -> snapTo .end
                        , translate = snapTo .end
                        , scale = snapTo .end
                        , rotate = snapTo .end
                        , skew = snapTo .end
                        , opacity = snapTo .end
                        , perspectiveOrigin = snapTo .end
                        , size = snapTo .end
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
            snapTo <|
                .start
                    >> Maybe.withDefault default

        toResetProperty : Builder.ProcessedPropertyConfig -> Builder.ProcessedPropertyConfig
        toResetProperty =
            mapProcessedProperty
                { customProperty = \_ _ -> toStartOr 0
                , customColorProperty = \_ -> toStartOr Color.transparent
                , translate = toStartOr Translate.default
                , scale = toStartOr Scale.default
                , rotate = toStartOr Rotate.default
                , skew = toStartOr Skew.default
                , opacity = toStartOr Opacity.default
                , perspectiveOrigin = toStartOr PerspectiveOrigin.default
                , size = toStartOr Size.default
                }
    in
    simpleControl (setPlayState PlayState.Reset) toResetProperty


snapTo : (Builder.ProcessedAnimationConfig a -> a) -> Builder.ProcessedAnimationConfig a -> Builder.ProcessedAnimationConfig a
snapTo getValue config =
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
    { customProperty : String -> String -> Builder.ProcessedAnimationConfig Float -> Builder.ProcessedAnimationConfig Float
    , customColorProperty : String -> Builder.ProcessedAnimationConfig Color -> Builder.ProcessedAnimationConfig Color
    , translate : Builder.ProcessedAnimationConfig Translate -> Builder.ProcessedAnimationConfig Translate
    , scale : Builder.ProcessedAnimationConfig Scale -> Builder.ProcessedAnimationConfig Scale
    , rotate : Builder.ProcessedAnimationConfig Rotate -> Builder.ProcessedAnimationConfig Rotate
    , skew : Builder.ProcessedAnimationConfig Skew -> Builder.ProcessedAnimationConfig Skew
    , opacity : Builder.ProcessedAnimationConfig Opacity -> Builder.ProcessedAnimationConfig Opacity
    , perspectiveOrigin : Builder.ProcessedAnimationConfig PerspectiveOrigin -> Builder.ProcessedAnimationConfig PerspectiveOrigin
    , size : Builder.ProcessedAnimationConfig Size -> Builder.ProcessedAnimationConfig Size
    }
    -> Builder.ProcessedPropertyConfig
    -> Builder.ProcessedPropertyConfig
mapProcessedProperty transforms prop =
    case prop of
        Builder.ProcessedCustomPropertyConfig cssName unit config ->
            Builder.ProcessedCustomPropertyConfig cssName unit (transforms.customProperty cssName unit config)

        Builder.ProcessedCustomColorPropertyConfig cssName config ->
            Builder.ProcessedCustomColorPropertyConfig cssName (transforms.customColorProperty cssName config)

        Builder.ProcessedOpacityConfig config ->
            Builder.ProcessedOpacityConfig (transforms.opacity config)

        Builder.ProcessedPerspectiveOriginConfig config ->
            Builder.ProcessedPerspectiveOriginConfig (transforms.perspectiveOrigin config)

        Builder.ProcessedRotateConfig config ->
            Builder.ProcessedRotateConfig (transforms.rotate config)

        Builder.ProcessedScaleConfig config ->
            Builder.ProcessedScaleConfig (transforms.scale config)

        Builder.ProcessedSizeConfig config ->
            Builder.ProcessedSizeConfig (transforms.size config)

        Builder.ProcessedSkewConfig config ->
            Builder.ProcessedSkewConfig (transforms.skew config)

        Builder.ProcessedTranslateConfig config ->
            Builder.ProcessedTranslateConfig (transforms.translate config)


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
            state.builder
                |> Builder.getCurrentAnimationConfig animGroupName
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



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


discreteEntry : String -> String -> AnimBuilder -> AnimBuilder
discreteEntry =
    Builder.discreteEntry


discreteExit : String -> String -> String -> AnimBuilder -> AnimBuilder
discreteExit =
    Builder.discreteExit



-- ============================================================
-- STATE QUERIES
-- ============================================================


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



-- ============================================================
-- PROPERTY QUERIES
-- ============================================================


getBuilder : AnimState a -> Builder.AnimBuilder {}
getBuilder (AnimState state _) =
    state.builder



-- ============================
-- CUSTOM PROPERTY
-- ============================


getPropertyStart : AnimGroupName -> String -> AnimState a -> Maybe Float
getPropertyStart animGroupName cssName =
    getBuilder >> Property.getCustomPropertyStart animGroupName cssName


getPropertyEnd : AnimGroupName -> String -> AnimState a -> Maybe Float
getPropertyEnd animGroupName cssName =
    getBuilder >> Property.getCustomPropertyEnd animGroupName cssName


getPropertyRange : AnimGroupName -> String -> AnimState a -> Maybe { start : Maybe Float, end : Float }
getPropertyRange animGroupName cssName =
    getBuilder >> Property.getCustomPropertyRange animGroupName cssName



-- ============================
-- CUSTOM COLOR PROPERTY
-- ============================


getColorPropertyStart : AnimGroupName -> String -> AnimState a -> Maybe Color
getColorPropertyStart animGroupName cssName =
    getBuilder >> Property.getCustomColorPropertyStart animGroupName cssName


getColorPropertyEnd : AnimGroupName -> String -> AnimState a -> Maybe Color
getColorPropertyEnd animGroupName cssName =
    getBuilder >> Property.getCustomColorPropertyEnd animGroupName cssName


getColorPropertyRange : AnimGroupName -> String -> AnimState a -> Maybe { start : Maybe Color, end : Color }
getColorPropertyRange animGroupName cssName =
    getBuilder >> Property.getCustomColorPropertyRange animGroupName cssName



-- ============================
-- OPACITY
-- ============================


getOpacityStart : AnimGroupName -> AnimState a -> Maybe Float
getOpacityStart animGroupName =
    getBuilder >> Property.getOpacityStart animGroupName


getOpacityEnd : AnimGroupName -> AnimState a -> Maybe Float
getOpacityEnd animGroupName =
    getBuilder >> Property.getOpacityEnd animGroupName


getOpacityRange : AnimGroupName -> AnimState a -> Maybe { start : Maybe Float, end : Float }
getOpacityRange animGroupName =
    getBuilder >> Property.getOpacityRange animGroupName



-- ============================
-- PERSPECTIVE ORIGIN
-- ============================


getPerspectiveOriginStart : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float }
getPerspectiveOriginStart animGroupName =
    getBuilder >> Property.getPerspectiveOriginStart animGroupName


getPerspectiveOriginEnd : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float }
getPerspectiveOriginEnd animGroupName =
    getBuilder >> Property.getPerspectiveOriginEnd animGroupName


getPerspectiveOriginRange : AnimGroupName -> AnimState a -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getPerspectiveOriginRange animGroupName =
    getBuilder >> Property.getPerspectiveOriginRange animGroupName



-- ============================
-- ROTATE
-- ============================


getRotateStart : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float, z : Float }
getRotateStart animGroupName =
    getBuilder >> Property.getRotateStart animGroupName


getRotateEnd : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd animGroupName =
    getBuilder >> Property.getRotateEnd animGroupName


getRotateRange : AnimGroupName -> AnimState a -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange animGroupName =
    getBuilder >> Property.getRotateRange animGroupName



-- ============================
-- SCALE
-- ============================


getScaleStart : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float, z : Float }
getScaleStart animGroupName =
    getBuilder >> Property.getScaleStart animGroupName


getScaleEnd : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd animGroupName =
    getBuilder >> Property.getScaleEnd animGroupName


getScaleRange : AnimGroupName -> AnimState a -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange animGroupName =
    getBuilder >> Property.getScaleRange animGroupName



-- ============================
-- SIZE
-- ============================


getSizeStart : AnimGroupName -> AnimState a -> Maybe { width : Float, height : Float }
getSizeStart animGroupName =
    getBuilder >> Property.getSizeStart animGroupName


getSizeEnd : AnimGroupName -> AnimState a -> Maybe { width : Float, height : Float }
getSizeEnd animGroupName =
    getBuilder >> Property.getSizeEnd animGroupName


getSizeRange : AnimGroupName -> AnimState a -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange animGroupName =
    getBuilder >> Property.getSizeRange animGroupName



-- ============================
-- SKEW
-- ============================


getSkewStart : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float }
getSkewStart animGroupName =
    getBuilder >> Property.getSkewStart animGroupName


getSkewEnd : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float }
getSkewEnd animGroupName =
    getBuilder >> Property.getSkewEnd animGroupName


getSkewRange : AnimGroupName -> AnimState a -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getSkewRange animGroupName =
    getBuilder >> Property.getSkewRange animGroupName



-- ============================
-- TRANSLATE
-- ============================


getTranslateStart : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart animGroupName =
    getBuilder >> Property.getTranslateStart animGroupName


getTranslateEnd : AnimGroupName -> AnimState a -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd animGroupName =
    getBuilder >> Property.getTranslateEnd animGroupName


getTranslateRange : AnimGroupName -> AnimState a -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange animGroupName =
    getBuilder >> Property.getTranslateRange animGroupName
