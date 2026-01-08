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
    , clearCurrentElement
    , computeAndCachePerspectiveStyles
    , computePerspectiveStyles
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
    , getPerspectiveStylesCache
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

import Anim.Easing exposing (Easing(..))
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Color as TextColor exposing (Color)
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Properties.Position as Position exposing (Position)
import Anim.Internal.Properties.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Properties.Scale as Scale exposing (Scale)
import Anim.Internal.Properties.ScrollTarget exposing (ScrollTarget)
import Anim.Internal.Properties.Size as Size exposing (Size)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Dict exposing (Dict)


type alias BackgroundColor =
    BackgroundColor.Color



-- TYPES


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
    , perspectiveStylesCache : Maybe (Dict String (List { attribute : String, value : String }))
    }


type alias ElementConfig =
    { properties : List PropertyConfig }


type PropertyConfig
    = PositionConfig (AnimationConfig Position)
    | RotateConfig (AnimationConfig Rotate)
    | ScaleConfig (AnimationConfig Scale)
    | BackgroundColorConfig (AnimationConfig BackgroundColor)
    | FontColorConfig (AnimationConfig Color)
    | OpacityConfig (AnimationConfig Opacity)
    | SizeConfig (AnimationConfig Size)


type ProcessedPropertyConfig
    = ProcessedPositionConfig (ProcessedAnimationConfig Position)
    | ProcessedRotateConfig (ProcessedAnimationConfig Rotate)
    | ProcessedScaleConfig (ProcessedAnimationConfig Scale)
    | ProcessedBackgroundColorConfig (ProcessedAnimationConfig BackgroundColor)
    | ProcessedFontColorConfig (ProcessedAnimationConfig Color)
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



-- BUILD


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
        , perspectiveStylesCache = Nothing
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
                    ms
        }


perspective : String -> Float -> AnimBuilder -> AnimBuilder
perspective containerId value (AnimBuilder data) =
    AnimBuilder
        { data
            | globalPerspective = Just { containerId = containerId, value = value }
        }



-- QUERY BUILDER


elements : AnimBuilder -> Dict ElementId ElementConfig
elements (AnimBuilder data) =
    data.elements


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


getScrollContainer : AnimBuilder -> String
getScrollContainer (AnimBuilder data) =
    data.scrollContainer


{-| Get cached perspective styles from builder.
-}
getPerspectiveStylesCache : AnimBuilder -> Maybe (Dict String (List { attribute : String, value : String }))
getPerspectiveStylesCache (AnimBuilder data) =
    data.perspectiveStylesCache



-- UPDATE BUILDER


clearCurrentElement : AnimBuilder -> AnimBuilder
clearCurrentElement (AnimBuilder data) =
    AnimBuilder { data | currentElementId = Nothing }


updateElementConfig : String -> ElementConfig -> AnimBuilder -> AnimBuilder
updateElementConfig elementId elementConfig (AnimBuilder data) =
    AnimBuilder
        { data | elements = Dict.insert elementId elementConfig data.elements }


updateCurrentElement : ElementConfig -> AnimBuilder -> AnimBuilder
updateCurrentElement config (AnimBuilder data) =
    case data.currentElementId of
        Nothing ->
            AnimBuilder data

        Just elementId ->
            AnimBuilder
                { data | elements = Dict.insert elementId config data.elements }


markDirty : AnimBuilder -> AnimBuilder
markDirty (AnimBuilder data) =
    AnimBuilder
        { data
            | elements =
                Dict.map
                    (\_ el ->
                        { el
                            | properties =
                                List.map markPropertyDirty el.properties
                        }
                    )
                    data.elements
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

        FontColorConfig config ->
            FontColorConfig { config | isDirty = True }

        OpacityConfig config ->
            OpacityConfig { config | isDirty = True }

        SizeConfig config ->
            SizeConfig { config | isDirty = True }


mapScrollTargets : (ScrollTarget -> ScrollTarget) -> AnimBuilder -> AnimBuilder
mapScrollTargets fn (AnimBuilder data) =
    AnimBuilder { data | scrollTargets = List.map fn data.scrollTargets }


addScrollTarget : ScrollTarget -> AnimBuilder -> AnimBuilder
addScrollTarget scrollTarget (AnimBuilder data) =
    AnimBuilder
        { data | scrollTargets = scrollTarget :: data.scrollTargets }


setScrollContainer : String -> AnimBuilder -> AnimBuilder
setScrollContainer containerId (AnimBuilder data) =
    AnimBuilder { data | scrollContainer = containerId }



-- PROCESSING
--
--
-- Process animation data to resolve timing and easing values


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


createDirtyConfig :
    { end : a
    , propPerspective : Maybe { containerId : String, value : Float }
    , globalPerspective : Maybe { containerId : String, value : Float }
    , wrapper : ProcessedAnimationConfig a -> ProcessedPropertyConfig
    }
    -> ProcessedPropertyConfig
createDirtyConfig { end, propPerspective, globalPerspective, wrapper } =
    wrapper
        { start = Just end
        , end = end
        , duration = 0
        , speed = 0
        , distance = 0
        , timing = Duration 0
        , easing = Linear
        , delay = 0
        , perspective = resolvePerspective propPerspective globalPerspective
        }


processStandardAnimation :
    { config : AnimationConfig a
    , globalData : BuilderData
    , defaultStart : a
    , distanceFn : a -> a -> Float
    , durationFn : Float -> TimeSpec -> Float
    , speedFn : Float -> Float -> TimeSpec -> Float
    , wrapper : ProcessedAnimationConfig a -> ProcessedPropertyConfig
    }
    -> ProcessedPropertyConfig
processStandardAnimation { config, globalData, defaultStart, distanceFn, durationFn, speedFn, wrapper } =
    let
        start =
            Maybe.withDefault defaultStart config.start

        distance_ =
            distanceFn start config.end

        resolvedTiming =
            resolveTimingWithDefault config.timing globalData.globalTiming (Duration 1000)

        duration_ =
            durationFn distance_ resolvedTiming

        speed_ =
            speedFn distance_ duration_ resolvedTiming
    in
    wrapper
        { start = config.start
        , end = config.end
        , duration = round duration_
        , speed = speed_
        , distance = distance_
        , timing = resolvedTiming
        , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
        , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
        , perspective = resolvePerspective config.perspective globalData.globalPerspective
        }


processProperty : BuilderData -> PropertyConfig -> Maybe ProcessedPropertyConfig
processProperty globalData property =
    case property of
        PositionConfig config ->
            if config.isDirty then
                Just <|
                    createDirtyConfig
                        { end = config.end
                        , propPerspective = config.perspective
                        , globalPerspective = globalData.globalPerspective
                        , wrapper = ProcessedPositionConfig
                        }

            else
                Just <|
                    processStandardAnimation
                        { config = config
                        , globalData = globalData
                        , defaultStart = Position.fromTuple ( 0.0, 0.0 )
                        , distanceFn = Position.distance
                        , durationFn = Position.duration
                        , speedFn = Position.speed
                        , wrapper = ProcessedPositionConfig
                        }

        RotateConfig config ->
            if config.isDirty then
                Just <|
                    createDirtyConfig
                        { end = config.end
                        , propPerspective = config.perspective
                        , globalPerspective = globalData.globalPerspective
                        , wrapper = ProcessedRotateConfig
                        }

            else
                Just <|
                    processStandardAnimation
                        { config = config
                        , globalData = globalData
                        , defaultStart = Rotate.fromFloat 0.0
                        , distanceFn = Rotate.distance
                        , durationFn = Rotate.duration
                        , speedFn = Rotate.speed
                        , wrapper = ProcessedRotateConfig
                        }

        ScaleConfig config ->
            if config.isDirty then
                Just <|
                    createDirtyConfig
                        { end = config.end
                        , propPerspective = config.perspective
                        , globalPerspective = globalData.globalPerspective
                        , wrapper = ProcessedScaleConfig
                        }

            else
                Just <|
                    processStandardAnimation
                        { config = config
                        , globalData = globalData
                        , defaultStart = Scale.fromTuple ( 1.0, 1.0 )
                        , distanceFn = Scale.distance
                        , durationFn = Scale.duration
                        , speedFn = Scale.speed
                        , wrapper = ProcessedScaleConfig
                        }

        BackgroundColorConfig config ->
            if config.isDirty then
                Just <|
                    createDirtyConfig
                        { end = config.end
                        , propPerspective = Nothing
                        , globalPerspective = Nothing
                        , wrapper = ProcessedBackgroundColorConfig
                        }

            else
                Just <|
                    processStandardAnimation
                        { config = config
                        , globalData = globalData
                        , defaultStart = BackgroundColor.rgb255 0 0 0
                        , distanceFn = BackgroundColor.distance
                        , durationFn = BackgroundColor.duration
                        , speedFn = BackgroundColor.speed
                        , wrapper = ProcessedBackgroundColorConfig
                        }

        FontColorConfig config ->
            if config.isDirty then
                Just <|
                    createDirtyConfig
                        { end = config.end
                        , propPerspective = Nothing
                        , globalPerspective = Nothing
                        , wrapper = ProcessedFontColorConfig
                        }

            else
                Just <|
                    processStandardAnimation
                        { config = config
                        , globalData = globalData
                        , defaultStart = TextColor.rgb255 0 0 0
                        , distanceFn = TextColor.distance
                        , durationFn = TextColor.duration
                        , speedFn = TextColor.speed
                        , wrapper = ProcessedFontColorConfig
                        }

        OpacityConfig config ->
            if config.isDirty then
                Just <|
                    createDirtyConfig
                        { end = config.end
                        , propPerspective = Nothing
                        , globalPerspective = Nothing
                        , wrapper = ProcessedOpacityConfig
                        }

            else
                Just <|
                    processStandardAnimation
                        { config = config
                        , globalData = globalData
                        , defaultStart = Opacity.fromFloat 1.0
                        , distanceFn = Opacity.distance
                        , durationFn = Opacity.duration
                        , speedFn = Opacity.speed
                        , wrapper = ProcessedOpacityConfig
                        }

        SizeConfig config ->
            if config.isDirty then
                Just <|
                    createDirtyConfig
                        { end = config.end
                        , propPerspective = Nothing
                        , globalPerspective = Nothing
                        , wrapper = ProcessedSizeConfig
                        }

            else
                Just <|
                    processStandardAnimation
                        { config = config
                        , globalData = globalData
                        , defaultStart = Size.fromTuple ( 100.0, 100.0 )
                        , distanceFn = Size.distance
                        , durationFn = Size.duration
                        , speedFn = Size.speed
                        , wrapper = ProcessedSizeConfig
                        }


{-| Generic resolver for optional values with local, global, and default fallback.
-}
resolveMaybeWithDefault : Maybe a -> Maybe a -> a -> a
resolveMaybeWithDefault local global default =
    case ( local, global ) of
        ( Just value, _ ) ->
            value

        ( Nothing, Just value ) ->
            value

        ( Nothing, Nothing ) ->
            default


resolveTimingWithDefault : Maybe TimeSpec -> Maybe TimeSpec -> TimeSpec -> TimeSpec
resolveTimingWithDefault =
    resolveMaybeWithDefault


resolveEasingWithDefault : Maybe Easing -> Maybe Easing -> Easing -> Easing
resolveEasingWithDefault =
    resolveMaybeWithDefault


resolveDelayWithDefault : Maybe Int -> Maybe Int -> Int -> Int
resolveDelayWithDefault =
    resolveMaybeWithDefault


{-| Resolve perspective with Nothing as the ultimate fallback.
Perspective is special because Nothing is a valid final value (no perspective).
-}
resolvePerspective : Maybe a -> Maybe a -> Maybe a
resolvePerspective local global =
    case local of
        Just value ->
            Just value

        Nothing ->
            global



-- TRANSFORM ORDERING
--
--
-- Shared logic for consistent transform ordering across engines


type alias TransformParts =
    { position : String
    , rotate : String
    , scale : String
    }


{-| Extract transforms from ProcessedPropertyConfig list in correct order.
-}
extractTransformsFromProcessed : List ProcessedPropertyConfig -> TransformParts
extractTransformsFromProcessed properties =
    List.foldl collectProcessedTransform emptyTransformParts properties


{-| Extract transforms from PropertyConfig list in correct order.
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



-- PERSPECTIVE STYLES
--
--
-- Pre-computed perspective styles for all containers


{-| Extract perspective from a processed property config.
-}
extractPerspectiveFromProperty : ProcessedPropertyConfig -> Maybe { containerId : String, value : Float }
extractPerspectiveFromProperty property =
    case property of
        ProcessedPositionConfig config ->
            config.perspective

        ProcessedRotateConfig config ->
            config.perspective

        ProcessedScaleConfig config ->
            config.perspective

        _ ->
            Nothing


computePerspectiveStyles : ProcessedAnimationData -> Dict String (List { attribute : String, value : String })
computePerspectiveStyles processedData =
    let
        -- Get all unique container IDs from properties
        propertyContainerIds =
            processedData.elements
                |> Dict.values
                |> List.concatMap .properties
                |> List.filterMap extractPerspectiveFromProperty
                |> List.map .containerId

        -- Get global perspective container ID if present
        maybeGlobalContainerId =
            processedData.globalPerspective
                |> Maybe.map .containerId

        allContainerIds =
            case maybeGlobalContainerId of
                Just globalId ->
                    if List.member globalId propertyContainerIds then
                        propertyContainerIds

                    else
                        propertyContainerIds ++ [ globalId ]

                Nothing ->
                    propertyContainerIds
    in
    -- For each container ID, compute the perspective value and styles
    allContainerIds
        |> List.filterMap
            (\containerId ->
                let
                    -- Check property-level perspective first
                    propertyPerspective =
                        processedData.elements
                            |> Dict.values
                            |> List.concatMap .properties
                            |> List.filterMap extractPerspectiveFromProperty
                            |> List.filter (\p -> p.containerId == containerId)
                            |> List.head
                            |> Maybe.map .value

                    maybePerspectiveValue =
                        case propertyPerspective of
                            Just value ->
                                Just value

                            Nothing ->
                                -- Fall back to global perspective
                                processedData.globalPerspective
                                    |> Maybe.andThen
                                        (\p ->
                                            if p.containerId == containerId then
                                                Just p.value

                                            else
                                                Nothing
                                        )
                in
                Maybe.map
                    (\value ->
                        ( containerId
                        , [ { attribute = "perspective", value = String.fromFloat value ++ "px" }
                          , { attribute = "transform-style", value = "preserve-3d" }
                          , { attribute = "data-perspective-source", value = "elm" }
                          ]
                        )
                    )
                    maybePerspectiveValue
            )
        |> Dict.fromList


{-| Compute and cache perspective styles on the builder.
This should be called by each engine's animate function before creating AnimState.
-}
computeAndCachePerspectiveStyles : AnimBuilder -> AnimBuilder
computeAndCachePerspectiveStyles ((AnimBuilder data) as builder) =
    case data.perspectiveStylesCache of
        Just _ ->
            -- Already cached
            builder

        Nothing ->
            let
                processedData =
                    processAnimationData builder

                cache =
                    computePerspectiveStyles processedData
            in
            AnimBuilder { data | perspectiveStylesCache = Just cache }
