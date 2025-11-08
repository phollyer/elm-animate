module Anim.Internal.Builder exposing
    ( AnimBuilder
    , AnimationValue(..)
    , BuilderData
    , ElementAnimationState
    , ElementConfig
    , ProcessedAnimationData
    , ProcessedElementConfig
    , ProcessedPropertyConfig(..)
    , PropertyAnimationState
    , PropertyConfig(..)
    , State
    , UniversalPropertyData
    , delay
    , duration
    , easing
    , encode
    , for
    , getCurrentElement
    , init
    , processAnimationData
    , speed
    , updateCurrentElement
    , updateData
    )

import Anim.Internal.Properties.Color as Color exposing (Color, HSL, HSLA, Hex, RGB, RGBA)
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Properties.Position as Position exposing (Position)
import Anim.Internal.Properties.Rotation as Rotation exposing (Rotation)
import Anim.Internal.Properties.Scale as Scale exposing (Scale)
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing(..))
import Anim.Timing.TimeSpec as TimeSpec exposing (TimeSpec(..))
import Dict exposing (Dict)
import Json.Encode as Encode
import Scroll exposing (Config, Timing)


{-| State
-}
type State
    = State
        { elements : Dict String ElementAnimationState
        , isRunning : Bool
        }


type alias ElementAnimationState =
    { properties : List PropertyAnimationState
    , isComplete : Bool
    }


type alias PropertyAnimationState =
    { propertyType : String
    , startValue : AnimationValue
    , targetValue : AnimationValue
    , currentValue : AnimationValue
    , elapsed : Float -- milliseconds
    , delay : Delay
    , easing : Easing
    , timeSpec : TimeSpec
    , isComplete : Bool
    }


type AnimationValue
    = PositionAnimationValue Position
    | RotationAnimationValue Rotation
    | ScaleAnimationValue Scale
    | ColorAnimationValue Color
    | OpacityAnimationValue Opacity


type AnimBuilder
    = AnimBuilder BuilderData


type alias BuilderData =
    { globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Delay
    , currentElementId : ElementId
    , elements : Dict ElementId ElementConfig
    }


type alias ElementId =
    String


type alias ElementConfig =
    { properties : List PropertyConfig
    }


type PropertyConfig
    = PositionConfig Position UniversalPropertyData
    | RotateConfig Rotation UniversalPropertyData
    | ScaleConfig Scale UniversalPropertyData
    | ColorConfig Color UniversalPropertyData
    | OpacityConfig Opacity UniversalPropertyData


type alias UniversalPropertyData =
    { timing : Maybe TimeSpec
    , easing : Maybe Easing
    , delay : Maybe Delay
    }


init : String -> AnimBuilder
init elementId =
    AnimBuilder
        { globalTiming = Nothing
        , globalEasing = Nothing
        , globalDelay = Nothing
        , currentElementId = elementId
        , elements = Dict.empty
        }


for : String -> AnimBuilder -> AnimBuilder
for elementId (AnimBuilder data) =
    AnimBuilder
        { data | currentElementId = elementId }


duration : Int -> AnimBuilder -> AnimBuilder
duration ms (AnimBuilder data) =
    AnimBuilder
        { data | globalTiming = Just (Duration ms) }


speed : Float -> AnimBuilder -> AnimBuilder
speed value (AnimBuilder data) =
    AnimBuilder
        { data | globalTiming = Just (Speed value) }


easing : Easing -> AnimBuilder -> AnimBuilder
easing easingValue (AnimBuilder data) =
    AnimBuilder
        { data | globalEasing = Just easingValue }


delay : Int -> AnimBuilder -> AnimBuilder
delay ms (AnimBuilder data) =
    AnimBuilder
        { data
            | globalDelay =
                Just <|
                    Delay.fromInt ms
        }


{-| Get the current element configuration, creating one if it doesn't exist.
-}
getCurrentElement : AnimBuilder -> ElementConfig
getCurrentElement (AnimBuilder data) =
    Dict.get data.currentElementId data.elements
        |> Maybe.withDefault { properties = [] }


updateData : BuilderData -> AnimBuilder -> AnimBuilder
updateData newData (AnimBuilder _) =
    AnimBuilder newData


{-| Update the current element configuration.
-}
updateCurrentElement : ElementConfig -> AnimBuilder -> AnimBuilder
updateCurrentElement config (AnimBuilder data) =
    AnimBuilder
        { data
            | elements = Dict.insert data.currentElementId config data.elements
        }



{- PROCESSSING HELPERS

   Process animation data to resolve timing and easing values.
-}


{-| Process animation data to resolve timing and easing values.

This function applies global defaults to property-specific configurations
and returns processed animation data that can be used by different animation systems.

-}
processAnimationData : AnimBuilder -> ProcessedAnimationData
processAnimationData (AnimBuilder data) =
    let
        processedElements =
            Dict.map (processElement data) data.elements
    in
    { elements = processedElements
    , globalTiming = data.globalTiming
    , globalEasing = data.globalEasing
    , globalDelay = data.globalDelay
    }


type alias ProcessedAnimationData =
    { elements : Dict String ProcessedElementConfig
    , globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Delay
    }


type alias ProcessedElementConfig =
    { properties : List ProcessedPropertyConfig
    }


type ProcessedPropertyConfig
    = ProcessedPositionConfig
        { target : Position
        , timing : TimeSpec
        , easing : Easing
        , delay : Delay
        }
    | ProcessedRotateConfig
        { target : Rotation
        , timing : TimeSpec
        , easing : Easing
        , delay : Delay
        }
    | ProcessedScaleConfig
        { target : Scale
        , timing : TimeSpec
        , easing : Easing
        , delay : Delay
        }
    | ProcessedColorConfig
        { target : Color
        , timing : TimeSpec
        , easing : Easing
        , delay : Delay
        }
    | ProcessedOpacityConfig
        { target : Opacity
        , timing : TimeSpec
        , easing : Easing
        , delay : Delay
        }


processElement : BuilderData -> String -> ElementConfig -> ProcessedElementConfig
processElement globalData _ elementConfig =
    { properties = List.map (processProperty globalData) elementConfig.properties
    }


processProperty : BuilderData -> PropertyConfig -> ProcessedPropertyConfig
processProperty globalData property =
    case property of
        PositionConfig position config ->
            ProcessedPositionConfig
                { target = position
                , timing = resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)
                , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                }

        RotateConfig rotation config ->
            ProcessedRotateConfig
                { target = rotation
                , timing = resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)
                , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                }

        ScaleConfig scale config ->
            ProcessedScaleConfig
                { target = scale
                , timing = resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)
                , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                }

        ColorConfig color config ->
            ProcessedColorConfig
                { target = color
                , timing = resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)
                , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                }

        OpacityConfig opacity config ->
            ProcessedOpacityConfig
                { target = opacity
                , timing = resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)
                , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                }


resolveTimingWithDefault : Maybe TimeSpec -> Maybe TimeSpec -> TimeSpec -> TimeSpec
resolveTimingWithDefault local global default =
    case local of
        Just timing ->
            timing

        Nothing ->
            case global of
                Just timing ->
                    timing

                Nothing ->
                    default


resolveEasingWithDefault : Maybe Easing -> Maybe Easing -> Easing -> Easing
resolveEasingWithDefault local global default =
    case local of
        Just easing_ ->
            easing_

        Nothing ->
            case global of
                Just easing_ ->
                    easing_

                Nothing ->
                    default


resolveDelayWithDefault : Maybe Delay -> Maybe Delay -> Int -> Delay
resolveDelayWithDefault local global default =
    case local of
        Just delay_ ->
            delay_

        Nothing ->
            case global of
                Just delay_ ->
                    delay_

                Nothing ->
                    Delay.fromInt default



-- ENCODING FOR JAVASCRIPT


encode : ProcessedAnimationData -> Encode.Value
encode data =
    Encode.object
        [ ( "elements", Encode.dict identity encodeProcessedElementConfig data.elements )
        , ( "globalTiming", encodeMaybeProcessedTiming data.globalTiming )
        , ( "globalEasing", encodeMaybeProcessedEasing data.globalEasing )
        , ( "globalDelay", Delay.encodeMaybe data.globalDelay )
        ]


encodeProcessedElementConfig : ProcessedElementConfig -> Encode.Value
encodeProcessedElementConfig config =
    Encode.object
        [ ( "properties", Encode.list encodeProcessedPropertyConfig config.properties )
        ]


encodeProcessedPropertyConfig : ProcessedPropertyConfig -> Encode.Value
encodeProcessedPropertyConfig property =
    let
        encode : String -> (target -> Encode.Value) -> { target : target, timing : TimeSpec, easing : Easing, delay : Delay } -> Encode.Value
        encode type_ targetEncoder config =
            Encode.object <|
                [ ( "type", Encode.string type_ )
                , ( "target", targetEncoder config.target )
                , ( "timing", TimeSpec.encode config.timing )
                , ( "easing", Easing.encode config.easing )
                , ( "delay", Delay.encode config.delay )
                ]
    in
    case property of
        ProcessedPositionConfig config ->
            encode "position" Position.encode config

        ProcessedRotateConfig config ->
            encode "rotate" Rotation.encode config

        ProcessedScaleConfig config ->
            encode "scale" Scale.encode config

        ProcessedColorConfig config ->
            encode "color" Color.encode config

        ProcessedOpacityConfig config ->
            encode "opacity" Opacity.encode config


encodeMaybeProcessedTiming : Maybe TimeSpec -> Encode.Value
encodeMaybeProcessedTiming maybeTiming =
    case maybeTiming of
        Nothing ->
            Encode.null

        Just timing ->
            encodeProcessedTiming timing


encodeProcessedTiming : TimeSpec -> Encode.Value
encodeProcessedTiming timing =
    case timing of
        Duration ms ->
            Encode.object
                [ ( "type", Encode.string "duration" )
                , ( "value", Encode.int ms )
                ]

        Speed value ->
            Encode.object
                [ ( "type", Encode.string "speed" )
                , ( "value", Encode.float value )
                ]


encodeMaybeProcessedEasing : Maybe Easing -> Encode.Value
encodeMaybeProcessedEasing maybeEasing =
    case maybeEasing of
        Nothing ->
            Encode.null

        Just easing_ ->
            encodeProcessedEasing easing_


encodeProcessedEasing : Easing -> Encode.Value
encodeProcessedEasing easing_ =
    Easing.encode easing_


encodeMaybeInt : Maybe Int -> Encode.Value
encodeMaybeInt maybeInt =
    case maybeInt of
        Nothing ->
            Encode.null

        Just value ->
            Encode.int value
