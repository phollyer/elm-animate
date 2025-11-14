module Anim.Internal.Builder exposing
    ( AnimBuilder
    , AnimationConfig
    , ElementConfig
    , PropertyConfig(..)
    , delay
    , duration
    , easing
    , elements
    , encode
    , for
    , getCurrentElementConfig
    , getDelay
    , getEasing
    , getElementConfig
    , getTimespec
    , init
    , processAnimationData
    , speed
    , updateCurrentElement
    )

import Anim.Internal.Properties.Color exposing (Color)
import Anim.Internal.Properties.Opacity exposing (Opacity)
import Anim.Internal.Properties.Position as Position exposing (Position, distance)
import Anim.Internal.Properties.Rotation as Rotation exposing (Rotation)
import Anim.Internal.Properties.Scale exposing (Scale)
import Anim.Internal.Timing.Delay as Delay exposing (Delay)
import Anim.Internal.Timing.Easing exposing (Easing(..))
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Dict exposing (Dict)
import Json.Encode as Encode


type AnimBuilder
    = AnimBuilder BuilderData


type alias BuilderData =
    { globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Delay
    , currentElementId : Maybe ElementId
    , elements : Dict ElementId ElementConfig
    }


type alias ElementId =
    String


type alias ElementConfig =
    { properties : List PropertyConfig }


type PropertyConfig
    = PositionConfig (AnimationConfig Position)
    | RotateConfig (AnimationConfig Rotation)
    | ScaleConfig (AnimationConfig Scale)
    | ColorConfig (AnimationConfig Color)
    | OpacityConfig (AnimationConfig Opacity)


type ProcessedPropertyConfig
    = ProcessedPositionConfig (ProcessedAnimationConfig Position)
    | ProcessedRotateConfig (ProcessedAnimationConfig Rotation)
    | ProcessedScaleConfig (ProcessedAnimationConfig Scale)
    | ProcessedColorConfig (ProcessedAnimationConfig Color)
    | ProcessedOpacityConfig (ProcessedAnimationConfig Opacity)


type alias ProcessedElementConfig =
    { properties : List ProcessedPropertyConfig }


type alias AnimationConfig targetProperty =
    { startAt : Maybe targetProperty
    , endAt : targetProperty
    , duration : Int
    , speed : Float
    , distance : Float
    , timing : Maybe TimeSpec
    , easing : Maybe Easing
    , delay : Maybe Delay
    }


type alias ProcessedAnimationData =
    { elements : Dict ElementId ProcessedElementConfig
    , globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Delay
    }


type alias ProcessedAnimationConfig targetProperty =
    { target : targetProperty
    , duration : Int
    , speed : Float
    , distance : Float
    , timing : TimeSpec
    , easing : Easing
    , delay : Delay
    }


init : AnimBuilder
init =
    AnimBuilder
        { globalTiming = Nothing
        , globalEasing = Nothing
        , globalDelay = Nothing
        , currentElementId = Nothing
        , elements = Dict.empty
        }


for : String -> AnimBuilder -> AnimBuilder
for elementId (AnimBuilder data) =
    AnimBuilder
        { data | currentElementId = Just elementId }


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


elements : AnimBuilder -> Dict ElementId ElementConfig
elements (AnimBuilder data) =
    data.elements


{-| Get the current element configuration, creating one if it doesn't exist.
-}
getCurrentElementConfig : AnimBuilder -> ElementConfig
getCurrentElementConfig (AnimBuilder data) =
    case data.currentElementId of
        Nothing ->
            { properties = [] }

        Just elementId ->
            Dict.get elementId data.elements
                |> Maybe.withDefault { properties = [] }


getElementConfig : String -> AnimBuilder -> Maybe ElementConfig
getElementConfig elementId (AnimBuilder data) =
    Dict.get elementId data.elements


getTimespec : AnimBuilder -> Maybe TimeSpec
getTimespec (AnimBuilder data) =
    data.globalTiming


getEasing : AnimBuilder -> Maybe Easing
getEasing (AnimBuilder data) =
    data.globalEasing


getDelay : AnimBuilder -> Maybe Delay
getDelay (AnimBuilder data) =
    data.globalDelay


{-| Update the current element configuration.
-}
updateCurrentElement : ElementConfig -> AnimBuilder -> AnimBuilder
updateCurrentElement config (AnimBuilder data) =
    case data.currentElementId of
        Nothing ->
            AnimBuilder data

        Just elementId ->
            AnimBuilder
                { data | elements = Dict.insert elementId config data.elements }



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


processElement : BuilderData -> String -> ElementConfig -> ProcessedElementConfig
processElement globalData _ elementConfig =
    { properties = List.map (processProperty globalData) elementConfig.properties
    }


processProperty : BuilderData -> PropertyConfig -> ProcessedPropertyConfig
processProperty globalData property =
    case property of
        PositionConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Position.fromTuple ( 0, 0 )

                distance =
                    Position.distance startAt config.endAt

                duration_ =
                    config.timing
                        |> Maybe.map (Position.duration distance)
                        |> Maybe.withDefault 0

                speed_ =
                    config.timing
                        |> Maybe.map (Position.speed distance duration_)
                        |> Maybe.withDefault 0
            in
            ProcessedPositionConfig
                { target = config.endAt
                , duration = round duration_
                , speed = speed_
                , distance = distance
                , timing = resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)
                , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                }

        RotateConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Rotation.fromFloat 0.0

                distance =
                    Rotation.distance startAt config.endAt

                duration_ =
                    config.timing
                        |> Maybe.map (Rotation.duration distance)
                        |> Maybe.withDefault 0

                speed_ =
                    config.timing
                        |> Maybe.map (Rotation.speed distance duration_)
                        |> Maybe.withDefault 0
            in
            ProcessedRotateConfig
                { target = config.endAt
                , duration = round duration_
                , speed = speed_
                , distance = distance
                , timing = resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)
                , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                }

        ScaleConfig config ->
            ProcessedScaleConfig
                { target = config.endAt
                , duration = 0 -- TODO: implement scale timing
                , speed = 0
                , distance = 0
                , timing = resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)
                , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                }

        ColorConfig config ->
            ProcessedColorConfig
                { target = config.endAt
                , duration = 0 -- TODO: implement color timing
                , speed = 0
                , distance = 0
                , timing = resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)
                , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                }

        OpacityConfig config ->
            ProcessedOpacityConfig
                { target = config.endAt
                , duration = 0 -- TODO: implement opacity timing
                , speed = 0
                , distance = 0
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
encode _ =
    Encode.object []



-- TODO: Complete encoding function for the Port module
-- maybe this should be moved to the Port module itself
{-
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
           encode_ : String -> (target -> Encode.Value) -> { target : target, timing : TimeSpec, easing : Easing, delay : Delay } -> Encode.Value
           encode_ type_ targetEncoder config =
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
               encode_ "position" Position.encode config.target

           ProcessedScaleConfig config ->
               encode_ "scale" Scale.encode config

           ProcessedColorConfig config ->
               encode_ "color" Color.encode config

           ProcessedOpacityConfig config ->
               encode_ "opacity" Opacity.encode config

           ProcessedRotateConfig config ->
               encode_ "rotate" Rotation.encode config


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

-}
