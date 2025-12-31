module Anim.Internal.WAAPI exposing
    ( AnimState
    , allComplete
    , animate
    , anyRunning
    , builder
    , delay
    , duration
    , easing
    , encode
    , getBackgroundColorRange
    , getOpacityRange
    , getPositionRange
    , getRotateRange
    , getScaleRange
    , getSizeRange
    , init
    , isElementComplete
    , isElementRunning
    , speed
    , update
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.Properties.BackgroundColor as BackgroundColor exposing (Color)
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Properties.Position as Position exposing (Position)
import Anim.Internal.Properties.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Properties.Scale as Scale exposing (Scale)
import Anim.Internal.Properties.Size as Size exposing (Size)
import Anim.Internal.Timing.Easing as Easing exposing (Easing(..))
import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode



-- Build


type alias AnimBuilder =
    Builder.AnimBuilder


type alias ElementId =
    String


type alias ElementEndStates =
    { position : Maybe Position
    , rotate : Maybe Rotate
    , scale : Maybe Scale
    , backgroundColor : Maybe Color
    , opacity : Maybe Opacity
    , size : Maybe Size
    }


type alias ElementAnimation =
    { commands : Encode.Value
    , endStates : ElementEndStates
    , currentStates : ElementEndStates
    }


type AnimState
    = AnimState
        { elementAnimations : Dict ElementId ElementAnimation
        , isRunning : Bool
        , builder : AnimBuilder
        }


init : AnimState
init =
    AnimState
        { elementAnimations = Dict.empty
        , isRunning = False
        , builder = Builder.init
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



-- Execute Animation


animate : AnimState -> AnimBuilder -> ( AnimState, Encode.Value )
animate (AnimState state) builder_ =
    let
        -- Inject current animated states into builder before processing
        builderWithCurrentStates =
            Dict.foldl injectCurrentStatesForElement builder_ state.elementAnimations

        processedData =
            Builder.processAnimationData builderWithCurrentStates

        -- Create element animations from processed data
        newElementAnimations =
            processedData.elements
                |> Dict.map
                    (\elementId elementConfig ->
                        let
                            endStates =
                                extractElementEndStates elementConfig

                            -- Use current states from existing animation if available, otherwise use end states
                            currentStates =
                                Dict.get elementId state.elementAnimations
                                    |> Maybe.map .currentStates
                                    |> Maybe.withDefault endStates
                        in
                        { commands = encode processedData
                        , endStates = endStates
                        , currentStates = currentStates
                        }
                    )

        -- Merge with existing animations (new animations replace old ones for same elements)
        updatedElementAnimations =
            Dict.union newElementAnimations state.elementAnimations
    in
    ( AnimState
        { elementAnimations = updatedElementAnimations
        , isRunning = not (Dict.isEmpty newElementAnimations)
        , builder = Builder.markDirty builderWithCurrentStates
        }
    , encode processedData
    )


extractElementEndStates : Builder.ProcessedElementConfig -> ElementEndStates
extractElementEndStates elementConfig =
    let
        emptyElementEndStates =
            { position = Nothing
            , rotate = Nothing
            , scale = Nothing
            , backgroundColor = Nothing
            , opacity = Nothing
            , size = Nothing
            }

        extractPropertyEndState : Builder.ProcessedPropertyConfig -> ElementEndStates -> ElementEndStates
        extractPropertyEndState property state =
            case property of
                Builder.ProcessedPositionConfig config ->
                    { state | position = Just config.endAt }

                Builder.ProcessedRotateConfig config ->
                    { state | rotate = Just config.endAt }

                Builder.ProcessedScaleConfig config ->
                    { state | scale = Just config.endAt }

                Builder.ProcessedBackgroundColorConfig config ->
                    { state | backgroundColor = Just config.endAt }

                Builder.ProcessedOpacityConfig config ->
                    { state | opacity = Just config.endAt }

                Builder.ProcessedSizeConfig config ->
                    { state | size = Just config.endAt }
    in
    List.foldl extractPropertyEndState emptyElementEndStates elementConfig.properties


injectCurrentStatesForElement : ElementId -> ElementAnimation -> AnimBuilder -> AnimBuilder
injectCurrentStatesForElement elementId elementAnim baseBuilder =
    case Builder.getElementConfig elementId baseBuilder of
        Just elementConfig ->
            let
                updatedProperties =
                    List.map (injectCurrentStateIntoProperty elementAnim.currentStates) elementConfig.properties

                updatedElementConfig =
                    { elementConfig | properties = updatedProperties }
            in
            Builder.updateElementConfig elementId updatedElementConfig baseBuilder

        Nothing ->
            baseBuilder


injectCurrentStateIntoProperty : ElementEndStates -> Builder.PropertyConfig -> Builder.PropertyConfig
injectCurrentStateIntoProperty currentStates propertyConfig =
    case propertyConfig of
        Builder.PositionConfig config ->
            Builder.PositionConfig
                { config
                    | startAt =
                        case config.startAt of
                            Just _ ->
                                config.startAt

                            Nothing ->
                                currentStates.position
                }

        Builder.RotateConfig config ->
            Builder.RotateConfig
                { config
                    | startAt =
                        case config.startAt of
                            Just _ ->
                                config.startAt

                            Nothing ->
                                currentStates.rotate
                }

        Builder.ScaleConfig config ->
            Builder.ScaleConfig
                { config
                    | startAt =
                        case config.startAt of
                            Just _ ->
                                config.startAt

                            Nothing ->
                                currentStates.scale
                }

        Builder.OpacityConfig config ->
            Builder.OpacityConfig
                { config
                    | startAt =
                        case config.startAt of
                            Just _ ->
                                config.startAt

                            Nothing ->
                                currentStates.opacity
                }

        Builder.BackgroundColorConfig config ->
            Builder.BackgroundColorConfig
                { config
                    | startAt =
                        case config.startAt of
                            Just _ ->
                                config.startAt

                            Nothing ->
                                currentStates.backgroundColor
                }

        Builder.SizeConfig config ->
            Builder.SizeConfig
                { config
                    | startAt =
                        case config.startAt of
                            Just _ ->
                                config.startAt

                            Nothing ->
                                currentStates.size
                }



-- Update


update : Decode.Value -> AnimState -> AnimState
update jsonValue (AnimState state) =
    case Decode.decodeValue animationUpdateDecoder jsonValue of
        Ok animationUpdate ->
            let
                updatedAnimations =
                    Dict.update animationUpdate.elementId
                        (Maybe.map (updateElementAnimation animationUpdate))
                        state.elementAnimations
            in
            AnimState
                { state
                    | elementAnimations = updatedAnimations
                    , isRunning = not (Dict.isEmpty updatedAnimations)
                }

        Err _ ->
            -- Silently ignore decode errors since we control the data shape
            AnimState state


updateElementAnimation : AnimationUpdate -> ElementAnimation -> ElementAnimation
updateElementAnimation animUpdate elementAnimation =
    { elementAnimation
        | currentStates =
            { position = Just (Position.fromTriple ( animUpdate.x, animUpdate.y, animUpdate.z ))
            , rotate = Just (Rotate.fromTriple ( animUpdate.rotationX, animUpdate.rotationY, animUpdate.rotationZ ))
            , scale = Just (Scale.fromTriple ( animUpdate.scaleX, animUpdate.scaleY, animUpdate.scaleZ ))
            , opacity = Just (Opacity.fromFloat animUpdate.opacity)
            , backgroundColor = BackgroundColor.fromRgbString animUpdate.backgroundColor
            , size = Just (Size.fromTuple ( animUpdate.width, animUpdate.height ))
            }
    }



-- Query State


allComplete : AnimState -> Maybe Bool
allComplete (AnimState state) =
    if Dict.isEmpty state.elementAnimations then
        Nothing

    else
        Just (not state.isRunning)


anyRunning : AnimState -> Bool
anyRunning (AnimState state) =
    not (Dict.isEmpty state.elementAnimations) && state.isRunning


isElementComplete : String -> AnimState -> Maybe Bool
isElementComplete elementId (AnimState state) =
    if Dict.member elementId state.elementAnimations then
        Just (not state.isRunning)

    else
        Nothing


isElementRunning : String -> AnimState -> Bool
isElementRunning elementId (AnimState state) =
    Dict.member elementId state.elementAnimations && state.isRunning



-- Query Property Ranges (Start/End values)


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
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


getOpacityRange : String -> AnimState -> Maybe { start : Maybe Opacity, end : Opacity }
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
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


getPositionRange : String -> AnimState -> Maybe { start : Maybe Position, end : Position }
getPositionRange elementId (AnimState state) =
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
                                Builder.ProcessedPositionConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


getRotateRange : String -> AnimState -> Maybe { start : Maybe Rotate, end : Rotate }
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
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


getScaleRange : String -> AnimState -> Maybe { start : Maybe Scale, end : Scale }
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
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


getSizeRange : String -> AnimState -> Maybe { start : Maybe Size, end : Size }
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
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )



-- Decoders


type alias AnimationUpdate =
    { elementId : String
    , x : Float
    , y : Float
    , z : Float
    , opacity : Float
    , rotationX : Float
    , rotationY : Float
    , rotationZ : Float
    , scaleX : Float
    , scaleY : Float
    , scaleZ : Float
    , backgroundColor : String
    , width : Float
    , height : Float
    , isAnimating : Bool
    }


animationUpdateDecoder : Decoder AnimationUpdate
animationUpdateDecoder =
    Decode.succeed AnimationUpdate
        |> andMap (Decode.field "elementId" Decode.string)
        |> andMap (Decode.field "x" Decode.float)
        |> andMap (Decode.field "y" Decode.float)
        |> andMap (Decode.field "z" Decode.float)
        |> andMap (Decode.field "opacity" Decode.float)
        |> andMap (Decode.field "rotationX" Decode.float)
        |> andMap (Decode.field "rotationY" Decode.float)
        |> andMap (Decode.field "rotationZ" Decode.float)
        |> andMap (Decode.field "scaleX" Decode.float)
        |> andMap (Decode.field "scaleY" Decode.float)
        |> andMap (Decode.field "scaleZ" Decode.float)
        |> andMap (Decode.field "backgroundColor" Decode.string)
        |> andMap (Decode.field "width" Decode.float)
        |> andMap (Decode.field "height" Decode.float)
        |> andMap (Decode.field "isAnimating" Decode.bool)


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)



-- Encoders


encode : Builder.ProcessedAnimationData -> Encode.Value
encode data =
    Encode.object
        [ ( "elements", Encode.dict identity encodeProcessedElementConfig data.elements )
        , ( "globalPerspective", encodeMaybePerspective data.globalPerspective )
        ]


encodeMaybePerspective : Maybe { containerId : String, value : Float } -> Encode.Value
encodeMaybePerspective maybePerspective =
    case maybePerspective of
        Nothing ->
            Encode.null

        Just perspectiveData ->
            Encode.object
                [ ( "containerId", Encode.string perspectiveData.containerId )
                , ( "value", Encode.float perspectiveData.value )
                ]


encodeProcessedElementConfig : Builder.ProcessedElementConfig -> Encode.Value
encodeProcessedElementConfig config =
    Encode.object
        [ ( "properties", Encode.list encodeProcessedPropertyConfig config.properties )
        ]


encodeProcessedPropertyConfig : Builder.ProcessedPropertyConfig -> Encode.Value
encodeProcessedPropertyConfig property =
    case property of
        Builder.ProcessedPositionConfig config ->
            let
                ( endX, endY, endZ ) =
                    Position.toTriple config.endAt

                ( startX, startY, startZ ) =
                    config.startAt
                        |> Maybe.map Position.toTriple
                        |> Maybe.withDefault ( 0, 0, 0 )
            in
            Encode.object
                [ ( "type", Encode.string "position" )
                , ( "x", Encode.float endX )
                , ( "y", Encode.float endY )
                , ( "z", Encode.float endZ )
                , ( "startX", Encode.float startX )
                , ( "startY", Encode.float startY )
                , ( "startZ", Encode.float startZ )
                , ( "duration", Encode.int config.duration )
                , ( "easing", Encode.string (easingToJsString config.easing) )
                , ( "perspective", encodeMaybePerspective config.perspective )
                ]

        Builder.ProcessedScaleConfig config ->
            let
                ( endX, endY, endZ ) =
                    Scale.toTriple config.endAt

                ( startX, startY, startZ ) =
                    config.startAt
                        |> Maybe.map Scale.toTriple
                        |> Maybe.withDefault ( 1, 1, 1 )
            in
            Encode.object
                [ ( "type", Encode.string "scale" )
                , ( "x", Encode.float endX )
                , ( "y", Encode.float endY )
                , ( "z", Encode.float endZ )
                , ( "startX", Encode.float startX )
                , ( "startY", Encode.float startY )
                , ( "startZ", Encode.float startZ )
                , ( "duration", Encode.int config.duration )
                , ( "easing", Encode.string (easingToJsString config.easing) )
                , ( "perspective", encodeMaybePerspective config.perspective )
                ]

        Builder.ProcessedRotateConfig config ->
            let
                ( endX, endY, endZ ) =
                    Rotate.toTriple config.endAt

                ( startX, startY, startZ ) =
                    config.startAt
                        |> Maybe.map Rotate.toTriple
                        |> Maybe.withDefault ( 0, 0, 0 )
            in
            Encode.object
                [ ( "type", Encode.string "rotate" )
                , ( "x", Encode.float endX )
                , ( "y", Encode.float endY )
                , ( "z", Encode.float endZ )
                , ( "startX", Encode.float startX )
                , ( "startY", Encode.float startY )
                , ( "startZ", Encode.float startZ )
                , ( "duration", Encode.int config.duration )
                , ( "easing", Encode.string (easingToJsString config.easing) )
                , ( "perspective", encodeMaybePerspective config.perspective )
                ]

        Builder.ProcessedSizeConfig config ->
            let
                ( width, height ) =
                    Size.toTuple config.endAt
            in
            Encode.object
                [ ( "type", Encode.string "size" )
                , ( "width", Encode.float width )
                , ( "height", Encode.float height )
                , ( "duration", Encode.int config.duration )
                , ( "easing", Encode.string (easingToJsString config.easing) )
                ]

        Builder.ProcessedOpacityConfig config ->
            let
                startValue =
                    config.startAt
                        |> Maybe.map Opacity.toFloat
                        |> Maybe.withDefault 1.0
            in
            Encode.object
                [ ( "type", Encode.string "opacity" )
                , ( "value", Encode.float (Opacity.toFloat config.endAt) )
                , ( "startValue", Encode.float startValue )
                , ( "duration", Encode.int config.duration )
                , ( "easing", Encode.string (easingToJsString config.easing) )
                ]

        Builder.ProcessedBackgroundColorConfig config ->
            let
                startColor =
                    config.startAt
                        |> Maybe.map BackgroundColor.toString
                        |> Maybe.withDefault "rgba(255, 255, 255, 1)"
            in
            Encode.object
                [ ( "type", Encode.string "backgroundColor" )
                , ( "color", Encode.string (BackgroundColor.toString config.endAt) )
                , ( "startColor", Encode.string startColor )
                , ( "duration", Encode.int config.duration )
                , ( "easing", Encode.string (easingToJsString config.easing) )
                ]


easingToJsString : Easing -> String
easingToJsString easingValue =
    Easing.toWebAnimations easingValue
