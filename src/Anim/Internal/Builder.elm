module Anim.Internal.Builder exposing
    ( AnimBuilder
    , AnimationConfig
    , ElementConfig
    , ProcessedElementConfig
    , ProcessedPropertyConfig(..)
    , PropertyConfig(..)
    , addScrollTarget
    , delay
    , duration
    , easing
    , elements
    , encode
    , for
    , getCurrentElementConfig
    , getDelay
    , getDelayWithDefault
    , getEasing
    , getEasingWithDefault
    , getElementConfig
    , getScrollContainer
    , getScrollTargets
    , getTimeSpec
    , getTimespec
    , init
    , mapScrollTargets
    , markDirty
    , processAnimationData
    , processElement
    , setScrollContainer
    , speed
    , updateCurrentElement
    )

import Anim.Internal.Properties.BackgroundColor as BackgroundColor exposing (Color)
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Properties.Position as Position exposing (Position, distance)
import Anim.Internal.Properties.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Properties.Scale as Scale exposing (Scale)
import Anim.Internal.Properties.ScrollTarget exposing (ScrollTarget)
import Anim.Internal.Properties.Size as Size exposing (Size)
import Anim.Internal.Timing.Easing as Easing exposing (Easing(..))
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Dict exposing (Dict)
import Json.Encode as Encode


type AnimBuilder
    = AnimBuilder BuilderData


type alias BuilderData =
    { globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Int
    , currentElementId : Maybe ElementId
    , elements : Dict ElementId ElementConfig
    , scrollTargets : List ScrollTarget
    , scrollContainer : String
    }


type alias ElementId =
    String


type alias ElementConfig =
    { properties : List PropertyConfig }


type PropertyConfig
    = PositionConfig (AnimationConfig Position)
    | RotateConfig (AnimationConfig Rotate)
    | ScaleConfig (AnimationConfig Scale)
      -- TODO: Need to consider how to handle all available color properties
    | BackgroundColorConfig (AnimationConfig Color)
    | OpacityConfig (AnimationConfig Opacity)
    | SizeConfig (AnimationConfig Size)


type ProcessedPropertyConfig
    = ProcessedPositionConfig (ProcessedAnimationConfig Position)
    | ProcessedRotateConfig (ProcessedAnimationConfig Rotate)
    | ProcessedScaleConfig (ProcessedAnimationConfig Scale)
    | ProcessedBackgroundColorConfig (ProcessedAnimationConfig Color)
    | ProcessedOpacityConfig (ProcessedAnimationConfig Opacity)
    | ProcessedSizeConfig (ProcessedAnimationConfig Size)


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
    , delay : Maybe Int
    , isDirty : Bool
    }


type alias ProcessedAnimationData =
    { elements : Dict ElementId ProcessedElementConfig
    , globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Int
    }


type alias ProcessedAnimationConfig targetProperty =
    { startAt : Maybe targetProperty
    , endAt : targetProperty
    , duration : Int
    , speed : Float
    , distance : Float
    , timing : TimeSpec
    , easing : Easing
    , delay : Int
    }


init : AnimBuilder
init =
    AnimBuilder
        { globalTiming = Nothing
        , globalEasing = Nothing
        , globalDelay = Nothing
        , currentElementId = Nothing
        , elements = Dict.empty
        , scrollTargets = []
        , scrollContainer = "document"
        }


markDirty : AnimBuilder -> AnimBuilder
markDirty (AnimBuilder data) =
    AnimBuilder
        { data
            | currentElementId = Nothing
            , elements = Dict.map (\_ el -> { el | properties = List.map markPropertyDirty el.properties }) data.elements
        }


markPropertyDirty : PropertyConfig -> PropertyConfig
markPropertyDirty property =
    case property of
        PositionConfig config ->
            PositionConfig { config | isDirty = True }

        RotateConfig config ->
            RotateConfig { config | isDirty = True }

        ScaleConfig config ->
            ScaleConfig { config | isDirty = True }

        BackgroundColorConfig config ->
            BackgroundColorConfig { config | isDirty = True }

        OpacityConfig config ->
            OpacityConfig { config | isDirty = True }

        SizeConfig config ->
            SizeConfig { config | isDirty = True }


{-| Map a function over all scroll targets in the builder.
-}
mapScrollTargets : (ScrollTarget -> ScrollTarget) -> AnimBuilder -> AnimBuilder
mapScrollTargets fn (AnimBuilder data) =
    AnimBuilder { data | scrollTargets = List.map fn data.scrollTargets }


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
                    ms
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


{-| Get TimeSpec with default fallback.
-}
getTimeSpec : AnimBuilder -> TimeSpec
getTimeSpec (AnimBuilder data) =
    data.globalTiming |> Maybe.withDefault (Duration 400)


getEasing : AnimBuilder -> Maybe Easing
getEasing (AnimBuilder data) =
    data.globalEasing


{-| Get Easing with default fallback.
-}
getEasingWithDefault : AnimBuilder -> Easing
getEasingWithDefault (AnimBuilder data) =
    data.globalEasing |> Maybe.withDefault QuintOut


getDelay : AnimBuilder -> Maybe Int
getDelay (AnimBuilder data) =
    data.globalDelay


{-| Get Delay with default fallback.
-}
getDelayWithDefault : AnimBuilder -> Int
getDelayWithDefault (AnimBuilder data) =
    data.globalDelay |> Maybe.withDefault 0


{-| Get scroll targets from the builder.
-}
getScrollTargets : AnimBuilder -> List ScrollTarget
getScrollTargets (AnimBuilder data) =
    data.scrollTargets


{-| Add a scroll target to the builder.
-}
addScrollTarget : ScrollTarget -> AnimBuilder -> AnimBuilder
addScrollTarget scrollTarget (AnimBuilder data) =
    AnimBuilder
        { data | scrollTargets = scrollTarget :: data.scrollTargets }


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
            Dict.map (\_ elementConfig -> processElement data elementConfig) data.elements
    in
    { elements = processedElements
    , globalTiming = data.globalTiming
    , globalEasing = data.globalEasing
    , globalDelay = data.globalDelay
    }


processElement : BuilderData -> ElementConfig -> ProcessedElementConfig
processElement globalData elementConfig =
    { properties = List.filterMap (processProperty globalData) elementConfig.properties
    }


processProperty : BuilderData -> PropertyConfig -> Maybe ProcessedPropertyConfig
processProperty globalData property =
    case property of
        PositionConfig config ->
            if config.isDirty then
                -- Return static config to preserve visual state
                Just <|
                    ProcessedPositionConfig
                        { startAt = Just config.endAt
                        , endAt = config.endAt
                        , duration = 0 -- No animation, just maintain state
                        , speed = 0
                        , distance = 0
                        , timing = Duration 0
                        , easing = Linear
                        , delay = 0
                        }

            else
                let
                    startAt =
                        case config.startAt of
                            Just s ->
                                s

                            Nothing ->
                                Position.fromTuple ( 0.0, 0.0 )

                    distance =
                        Position.distance startAt config.endAt

                    resolvedTiming =
                        resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)

                    duration_ =
                        Position.duration distance resolvedTiming

                    speed_ =
                        Position.speed distance duration_ resolvedTiming
                in
                Just <|
                    ProcessedPositionConfig
                        { startAt = config.startAt
                        , endAt = config.endAt
                        , duration = round duration_
                        , speed = speed_
                        , distance = distance
                        , timing = resolvedTiming
                        , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                        , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                        }

        RotateConfig config ->
            if config.isDirty then
                -- Return static config to preserve visual state
                Just <|
                    ProcessedRotateConfig
                        { startAt = Just config.endAt
                        , endAt = config.endAt
                        , duration = 0 -- No animation, just maintain state
                        , speed = 0
                        , distance = 0
                        , timing = Duration 0
                        , easing = Linear
                        , delay = 0
                        }

            else
                let
                    startAt =
                        case config.startAt of
                            Just s ->
                                s

                            Nothing ->
                                Rotate.fromFloat 0.0

                    distance =
                        Rotate.distance startAt config.endAt

                    resolvedTiming =
                        resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)

                    duration_ =
                        Rotate.duration distance resolvedTiming

                    speed_ =
                        Rotate.speed distance duration_ resolvedTiming
                in
                Just <|
                    ProcessedRotateConfig
                        { startAt = config.startAt
                        , endAt = config.endAt
                        , duration = round duration_
                        , speed = speed_
                        , distance = distance
                        , timing = resolvedTiming
                        , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                        , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                        }

        ScaleConfig config ->
            if config.isDirty then
                -- Return static config to preserve visual state
                Just <|
                    ProcessedScaleConfig
                        { startAt = Just config.endAt
                        , endAt = config.endAt
                        , duration = 0 -- No animation, just maintain state
                        , speed = 0
                        , distance = 0
                        , timing = Duration 0
                        , easing = Linear
                        , delay = 0
                        }

            else
                let
                    startAt =
                        Maybe.withDefault (Scale.fromTuple ( 1.0, 1.0 )) config.startAt

                    distance =
                        Scale.distance startAt config.endAt

                    duration_ =
                        -- For scale, we need a way to calculate duration from timing
                        -- Let's use a simple approach based on timing spec
                        case resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000) of
                            Duration ms ->
                                toFloat ms

                            Speed _ ->
                                1000.0

                    -- Default 1 second for speed-based
                    speed_ =
                        if duration_ > 0 then
                            distance / (duration_ / 1000.0)

                        else
                            0.0
                in
                Just <|
                    ProcessedScaleConfig
                        { startAt = config.startAt
                        , endAt = config.endAt
                        , duration = round duration_
                        , speed = speed_
                        , distance = distance
                        , timing = resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)
                        , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                        , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                        }

        BackgroundColorConfig config ->
            if config.isDirty then
                -- Return static config to preserve visual state
                Just <|
                    ProcessedBackgroundColorConfig
                        { startAt = Just config.endAt
                        , endAt = config.endAt
                        , duration = 0 -- No animation, just maintain state
                        , speed = 0
                        , distance = 0
                        , timing = Duration 0
                        , easing = Linear
                        , delay = 0
                        }

            else
                let
                    startAt =
                        case config.startAt of
                            Just s ->
                                s

                            Nothing ->
                                BackgroundColor.rgb255 0 0 0

                    -- Default to black if no start color
                    distance =
                        BackgroundColor.distance startAt config.endAt

                    resolvedTiming =
                        resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)

                    duration_ =
                        BackgroundColor.duration distance resolvedTiming

                    speed_ =
                        BackgroundColor.speed distance duration_ resolvedTiming
                in
                Just <|
                    ProcessedBackgroundColorConfig
                        { startAt = config.startAt
                        , endAt = config.endAt
                        , duration = round duration_
                        , speed = speed_
                        , distance = distance
                        , timing = resolvedTiming
                        , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                        , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                        }

        OpacityConfig config ->
            if config.isDirty then
                -- Return static config to preserve visual state
                Just <|
                    ProcessedOpacityConfig
                        { startAt = Just config.endAt
                        , endAt = config.endAt
                        , duration = 0 -- No animation, just maintain state
                        , speed = 0
                        , distance = 0
                        , timing = Duration 0
                        , easing = Linear
                        , delay = 0
                        }

            else
                let
                    startAt =
                        case config.startAt of
                            Just s ->
                                s

                            Nothing ->
                                Opacity.fromFloat 1.0

                    distance =
                        Opacity.distance startAt config.endAt

                    resolvedTiming =
                        resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)

                    duration_ =
                        Opacity.duration distance resolvedTiming

                    speed_ =
                        Opacity.speed distance duration_ resolvedTiming
                in
                Just <|
                    ProcessedOpacityConfig
                        { startAt = config.startAt
                        , endAt = config.endAt
                        , duration = round duration_
                        , speed = speed_
                        , distance = distance
                        , timing = resolvedTiming
                        , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                        , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                        }

        SizeConfig config ->
            if config.isDirty then
                -- Return static config to preserve visual state
                Just <|
                    ProcessedSizeConfig
                        { startAt = Just config.endAt
                        , endAt = config.endAt
                        , duration = 0 -- No animation, just maintain state
                        , speed = 0
                        , distance = 0
                        , timing = Duration 0
                        , easing = Linear
                        , delay = 0
                        }

            else
                let
                    startAt =
                        case config.startAt of
                            Just s ->
                                s

                            Nothing ->
                                Size.fromTuple ( 100.0, 100.0 )

                    distance =
                        Size.distance startAt config.endAt

                    resolvedTiming =
                        resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)

                    duration_ =
                        Size.duration distance resolvedTiming

                    speed_ =
                        Size.speed distance duration_ resolvedTiming
                in
                Just <|
                    ProcessedSizeConfig
                        { startAt = config.startAt
                        , endAt = config.endAt
                        , duration = round duration_
                        , speed = speed_
                        , distance = distance
                        , timing = resolvedTiming
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


resolveDelayWithDefault : Maybe Int -> Maybe Int -> Int -> Int
resolveDelayWithDefault local global default =
    case local of
        Just delay_ ->
            delay_

        Nothing ->
            case global of
                Just delay_ ->
                    delay_

                Nothing ->
                    default



-- ENCODING FOR JAVASCRIPT


encode : ProcessedAnimationData -> Encode.Value
encode data =
    -- Create command strings for each element's animations
    -- Format: "elementId:targetX:targetY:duration:easing:axis"
    data.elements
        |> Dict.toList
        |> List.filterMap (createCommandString data)
        |> Encode.list Encode.string


createCommandString : ProcessedAnimationData -> ( String, ProcessedElementConfig ) -> Maybe String
createCommandString _ ( elementId, elementConfig ) =
    -- Create commands for all property types
    elementConfig.properties
        |> List.filterMap (extractPropertyCommand elementId)
        |> List.head


extractPropertyCommand : String -> ProcessedPropertyConfig -> Maybe String
extractPropertyCommand elementId property =
    case property of
        ProcessedPositionConfig config ->
            let
                ( targetX, targetY ) =
                    Position.toTuple config.endAt

                easingStr =
                    easingToJsString config.easing
            in
            Just
                (String.join ":"
                    [ "position"
                    , elementId
                    , String.fromFloat targetX
                    , String.fromFloat targetY
                    , String.fromInt config.duration
                    , easingStr
                    , "both"
                    ]
                )

        ProcessedScaleConfig config ->
            let
                easingStr =
                    easingToJsString config.easing

                ( targetX, targetY ) =
                    Scale.toTuple config.endAt
            in
            Just
                (String.join ":"
                    [ "scale"
                    , elementId
                    , String.fromFloat targetX
                    , String.fromFloat targetY
                    , String.fromInt config.duration
                    , easingStr
                    ]
                )

        ProcessedSizeConfig config ->
            let
                ( targetWidth, targetHeight ) =
                    Size.toTuple config.endAt

                easingStr =
                    easingToJsString config.easing
            in
            Just
                (String.join ":"
                    [ "size"
                    , elementId
                    , String.fromFloat targetWidth
                    , String.fromFloat targetHeight
                    , String.fromInt config.duration
                    , easingStr
                    ]
                )

        ProcessedRotateConfig config ->
            let
                easingStr =
                    easingToJsString config.easing
            in
            Just
                (String.join ":"
                    [ "rotation"
                    , elementId
                    , String.fromFloat (Rotate.toFloat config.endAt)
                    , String.fromInt config.duration
                    , easingStr
                    ]
                )

        ProcessedOpacityConfig config ->
            let
                easingStr =
                    easingToJsString config.easing
            in
            Just
                (String.join ":"
                    [ "opacity"
                    , elementId
                    , String.fromFloat (Opacity.toFloat config.endAt)
                    , String.fromInt config.duration
                    , easingStr
                    ]
                )

        ProcessedBackgroundColorConfig config ->
            let
                easingStr =
                    easingToJsString config.easing

                colorStr =
                    BackgroundColor.toString config.endAt
            in
            Just
                (String.join ":"
                    [ "color"
                    , elementId
                    , colorStr
                    , String.fromInt config.duration
                    , easingStr
                    ]
                )


easingToJsString : Easing -> String
easingToJsString easingValue =
    -- Use the proper Web Animations API conversion
    Easing.toWebAnimations easingValue



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
               encode_ "color" BackgroundColor.encode config

           ProcessedOpacityConfig config ->
               encode_ "opacity" Opacity.encode config

           ProcessedRotateConfig config ->
               encode_ "rotate" Rotate.encode config


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


{-| Set the scroll container for scroll animations.
-}
setScrollContainer : String -> AnimBuilder -> AnimBuilder
setScrollContainer containerId (AnimBuilder data) =
    AnimBuilder { data | scrollContainer = containerId }


{-| Get the scroll container for scroll animations.
-}
getScrollContainer : AnimBuilder -> String
getScrollContainer (AnimBuilder data) =
    data.scrollContainer
