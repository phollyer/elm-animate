module Anim.Internal.Builder exposing
    ( AnimBuilder
    , AnimationConfig
    , ElementConfig
    , ProcessedAnimationData
    , ProcessedElementConfig
    , ProcessedPropertyConfig(..)
    , PropertyConfig(..)
    , TransformParts
    , addScrollTarget
    , delay
    , duration
    , easing
    , elements
    , extractTransformsFromProcessed
    , extractTransformsFromProperty
    , for
    , getCurrentElementConfig
    , getDelay
    , getDelayWithDefault
    , getEasing
    , getEasingWithDefault
    , getElementConfig
    , getPerspective
    , getPerspectiveWithDefault
    , getScrollContainer
    , getScrollTargets
    , getTimeSpec
    , getTimespec
    , init
    , mapScrollTargets
    , markDirty
    , perspective
    , processAnimationData
    , processElement
    , setScrollContainer
    , speed
    , updateCurrentElement
    , updateElementConfig
    )

import Anim.Internal.Properties.BackgroundColor as BackgroundColor exposing (Color)
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Properties.Position as Position exposing (Position, distance)
import Anim.Internal.Properties.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Properties.Scale as Scale exposing (Scale)
import Anim.Internal.Properties.ScrollTarget exposing (ScrollTarget)
import Anim.Internal.Properties.Size as Size exposing (Size)
import Anim.Internal.Timing.Easing exposing (Easing(..))
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Dict exposing (Dict)


type AnimBuilder
    = AnimBuilder BuilderData


type alias ElementId =
    String


type alias BuilderData =
    { globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Int
    , globalPerspective : Maybe { containerId : String, value : Float }
    , currentElementId : Maybe ElementId
    , elements : Dict ElementId ElementConfig
    , scrollTargets : List ScrollTarget
    , scrollContainer : String
    }


type alias ElementConfig =
    { properties : List PropertyConfig }


type PropertyConfig
    = PositionConfig (AnimationConfig Position)
    | RotateConfig (AnimationConfig Rotate)
    | ScaleConfig (AnimationConfig Scale)
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
    { start : Maybe targetProperty
    , end : targetProperty
    , duration : Int
    , speed : Float
    , distance : Float
    , timing : Maybe TimeSpec
    , easing : Maybe Easing
    , delay : Maybe Int
    , perspective : Maybe { containerId : String, value : Float }
    , isDirty : Bool
    }


type alias ProcessedAnimationData =
    { elements : Dict ElementId ProcessedElementConfig
    , globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Int
    , globalPerspective : Maybe { containerId : String, value : Float }
    }


type alias ProcessedAnimationConfig targetProperty =
    { start : Maybe targetProperty
    , end : targetProperty
    , duration : Int
    , speed : Float
    , distance : Float
    , timing : TimeSpec
    , easing : Easing
    , delay : Int
    , perspective : Maybe { containerId : String, value : Float }
    }


init : AnimBuilder
init =
    AnimBuilder
        { globalTiming = Nothing
        , globalEasing = Nothing
        , globalDelay = Nothing
        , globalPerspective = Nothing
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


perspective : String -> Float -> AnimBuilder -> AnimBuilder
perspective containerId value (AnimBuilder data) =
    AnimBuilder
        { data
            | globalPerspective = Just { containerId = containerId, value = value }
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


updateElementConfig : String -> ElementConfig -> AnimBuilder -> AnimBuilder
updateElementConfig elementId elementConfig (AnimBuilder data) =
    AnimBuilder
        { data | elements = Dict.insert elementId elementConfig data.elements }


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


{-| Get global perspective setting.
-}
getPerspective : AnimBuilder -> Maybe { containerId : String, value : Float }
getPerspective (AnimBuilder data) =
    data.globalPerspective


{-| Get perspective with default fallback.
-}
getPerspectiveWithDefault : AnimBuilder -> Maybe { containerId : String, value : Float }
getPerspectiveWithDefault (AnimBuilder data) =
    data.globalPerspective


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
    , globalPerspective = data.globalPerspective
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
                -- Send dirty properties with duration=0 to preserve their state
                Just <|
                    ProcessedPositionConfig
                        { start = Just config.end
                        , end = config.end
                        , duration = 0
                        , speed = 0
                        , distance = 0
                        , timing = Duration 0
                        , easing = Linear
                        , delay = 0
                        , perspective = resolvePerspectiveWithDefault config.perspective globalData.globalPerspective Nothing
                        }

            else
                let
                    start =
                        case config.start of
                            Just s ->
                                s

                            Nothing ->
                                Position.fromTuple ( 0.0, 0.0 )

                    distance =
                        Position.distance start config.end

                    resolvedTiming =
                        resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)

                    duration_ =
                        Position.duration distance resolvedTiming

                    speed_ =
                        Position.speed distance duration_ resolvedTiming
                in
                Just <|
                    ProcessedPositionConfig
                        { start = config.start
                        , end = config.end
                        , duration = round duration_
                        , speed = speed_
                        , distance = distance
                        , timing = resolvedTiming
                        , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                        , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                        , perspective = resolvePerspectiveWithDefault config.perspective globalData.globalPerspective Nothing
                        }

        RotateConfig config ->
            if config.isDirty then
                -- Send dirty properties with duration=0 to preserve their state
                Just <|
                    ProcessedRotateConfig
                        { start = Just config.end
                        , end = config.end
                        , duration = 0
                        , speed = 0
                        , distance = 0
                        , timing = Duration 0
                        , easing = Linear
                        , delay = 0
                        , perspective = resolvePerspectiveWithDefault config.perspective globalData.globalPerspective Nothing
                        }

            else
                let
                    start =
                        case config.start of
                            Just s ->
                                s

                            Nothing ->
                                Rotate.fromFloat 0.0

                    distance =
                        Rotate.distance start config.end

                    resolvedTiming =
                        resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)

                    duration_ =
                        Rotate.duration distance resolvedTiming

                    speed_ =
                        Rotate.speed distance duration_ resolvedTiming
                in
                Just <|
                    ProcessedRotateConfig
                        { start = config.start
                        , end = config.end
                        , duration = round duration_
                        , speed = speed_
                        , distance = distance
                        , timing = resolvedTiming
                        , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                        , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                        , perspective = resolvePerspectiveWithDefault config.perspective globalData.globalPerspective Nothing
                        }

        ScaleConfig config ->
            if config.isDirty then
                -- Send dirty properties with duration=0 to preserve their state
                Just <|
                    ProcessedScaleConfig
                        { start = Just config.end
                        , end = config.end
                        , duration = 0
                        , speed = 0
                        , distance = 0
                        , timing = Duration 0
                        , easing = Linear
                        , delay = 0
                        , perspective = resolvePerspectiveWithDefault config.perspective globalData.globalPerspective Nothing
                        }

            else
                let
                    start =
                        Maybe.withDefault (Scale.fromTuple ( 1.0, 1.0 )) config.start

                    distance =
                        Scale.distance start config.end

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
                        { start = config.start
                        , end = config.end
                        , duration = round duration_
                        , speed = speed_
                        , distance = distance
                        , timing = resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)
                        , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                        , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                        , perspective = resolvePerspectiveWithDefault config.perspective globalData.globalPerspective Nothing
                        }

        BackgroundColorConfig config ->
            if config.isDirty then
                -- Return static config to preserve visual state
                Just <|
                    ProcessedBackgroundColorConfig
                        { start = Just config.end
                        , end = config.end
                        , duration = 0 -- No animation, just maintain state
                        , speed = 0
                        , distance = 0
                        , timing = Duration 0
                        , easing = Linear
                        , delay = 0
                        , perspective = Nothing
                        }

            else
                let
                    start =
                        case config.start of
                            Just s ->
                                s

                            Nothing ->
                                BackgroundColor.rgb255 0 0 0

                    -- Default to black if no start color
                    distance =
                        BackgroundColor.distance start config.end

                    resolvedTiming =
                        resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)

                    duration_ =
                        BackgroundColor.duration distance resolvedTiming

                    speed_ =
                        BackgroundColor.speed distance duration_ resolvedTiming
                in
                Just <|
                    ProcessedBackgroundColorConfig
                        { start = config.start
                        , end = config.end
                        , duration = round duration_
                        , speed = speed_
                        , distance = distance
                        , timing = resolvedTiming
                        , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                        , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                        , perspective = Nothing
                        }

        OpacityConfig config ->
            if config.isDirty then
                -- Return static config to preserve visual state
                Just <|
                    ProcessedOpacityConfig
                        { start = Just config.end
                        , end = config.end
                        , duration = 0 -- No animation, just maintain state
                        , speed = 0
                        , distance = 0
                        , timing = Duration 0
                        , easing = Linear
                        , delay = 0
                        , perspective = Nothing
                        }

            else
                let
                    start =
                        case config.start of
                            Just s ->
                                s

                            Nothing ->
                                Opacity.fromFloat 1.0

                    distance =
                        Opacity.distance start config.end

                    resolvedTiming =
                        resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)

                    duration_ =
                        Opacity.duration distance resolvedTiming

                    speed_ =
                        Opacity.speed distance duration_ resolvedTiming
                in
                Just <|
                    ProcessedOpacityConfig
                        { start = config.start
                        , end = config.end
                        , duration = round duration_
                        , speed = speed_
                        , distance = distance
                        , timing = resolvedTiming
                        , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                        , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                        , perspective = Nothing
                        }

        SizeConfig config ->
            if config.isDirty then
                -- Return static config to preserve visual state
                Just <|
                    ProcessedSizeConfig
                        { start = Just config.end
                        , end = config.end
                        , duration = 0 -- No animation, just maintain state
                        , speed = 0
                        , distance = 0
                        , timing = Duration 0
                        , easing = Linear
                        , delay = 0
                        , perspective = Nothing
                        }

            else
                let
                    start =
                        case config.start of
                            Just s ->
                                s

                            Nothing ->
                                Size.fromTuple ( 100.0, 100.0 )

                    distance =
                        Size.distance start config.end

                    resolvedTiming =
                        resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)

                    duration_ =
                        Size.duration distance resolvedTiming

                    speed_ =
                        Size.speed distance duration_ resolvedTiming
                in
                Just <|
                    ProcessedSizeConfig
                        { start = config.start
                        , end = config.end
                        , duration = round duration_
                        , speed = speed_
                        , distance = distance
                        , timing = resolvedTiming
                        , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
                        , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
                        , perspective = Nothing
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


resolvePerspectiveWithDefault : Maybe { containerId : String, value : Float } -> Maybe { containerId : String, value : Float } -> Maybe { containerId : String, value : Float } -> Maybe { containerId : String, value : Float }
resolvePerspectiveWithDefault local global default =
    case local of
        Just perspective_ ->
            Just perspective_

        Nothing ->
            case global of
                Just perspective_ ->
                    Just perspective_

                Nothing ->
                    default



-- ENCODING FOR JAVASCRIPT


setScrollContainer : String -> AnimBuilder -> AnimBuilder
setScrollContainer containerId (AnimBuilder data) =
    AnimBuilder { data | scrollContainer = containerId }


getScrollContainer : AnimBuilder -> String
getScrollContainer (AnimBuilder data) =
    data.scrollContainer



-- TRANSFORM ORDERING
-- Shared logic for consistent transform ordering across CSS and Sub engines


{-| Record to hold transform parts in the correct order.
-}
type alias TransformParts =
    { position : String
    , rotate : String
    , scale : String
    }


{-| Extract transforms from ProcessedPropertyConfig list in correct order.
Used by Sub engine.
-}
extractTransformsFromProcessed : List ProcessedPropertyConfig -> TransformParts
extractTransformsFromProcessed properties =
    List.foldl collectProcessedTransform emptyTransformParts properties


{-| Extract transforms from PropertyConfig list in correct order.
Used by CSS engine.
-}
extractTransformsFromProperty : List PropertyConfig -> TransformParts
extractTransformsFromProperty properties =
    List.foldl collectPropertyTransform emptyTransformParts properties


emptyTransformParts : TransformParts
emptyTransformParts =
    { position = ""
    , rotate = ""
    , scale = ""
    }


{-| Collect transform from ProcessedPropertyConfig.
-}
collectProcessedTransform : ProcessedPropertyConfig -> TransformParts -> TransformParts
collectProcessedTransform property acc =
    case property of
        ProcessedPositionConfig config ->
            { acc | position = "translate3d(" ++ Position.toCssString config.end ++ ")" }

        ProcessedRotateConfig config ->
            { acc | rotate = Rotate.to3DCssString config.end }

        ProcessedScaleConfig config ->
            let
                ( x, y ) =
                    Scale.toTuple config.end
            in
            { acc | scale = "scale(" ++ String.fromFloat x ++ ", " ++ String.fromFloat y ++ ")" }

        _ ->
            acc


{-| Collect transform from PropertyConfig (skips dirty properties).
-}
collectPropertyTransform : PropertyConfig -> TransformParts -> TransformParts
collectPropertyTransform property acc =
    case property of
        PositionConfig config ->
            if config.isDirty then
                acc

            else
                { acc | position = "translate3d(" ++ Position.toCssString config.end ++ ")" }

        RotateConfig config ->
            if config.isDirty then
                acc

            else
                { acc | rotate = Rotate.to3DCssString config.end }

        ScaleConfig config ->
            if config.isDirty then
                acc

            else
                { acc | scale = Scale.to3DCssString config.end }

        _ ->
            acc
