module Anim.Internal.Builder exposing
    ( AnimBuilder
    , AnimationConfig
    , AnimationHistory
    , AnimationHistoryEntry
    , AnimationId
    , ElementConfig
    , ElementEndStates
    , IterationCount(..)
    , ProcessedAnimationData
    , ProcessedElementConfig
    , ProcessedPropertyConfig(..)
    , PropertyConfig(..)
    , TransformParts
    , addAnimationToHistory
    , addScrollTarget
    , allowDiscreteTransitions
    , clearAnimationHistory
      -- Animation Control Functions
    , clearCurrentElement
    , delay
    , discreteTransitionsEnabled
    , duration
    , easing
    , elements
    , extractTransformsFromProcessed
    , extractTransformsFromProperty
    , for
    , getAllAnimationHistory
    , getAnimationById
    , getCurrentAnimation
    , getCurrentElementConfig
    , getDelay
    , getDelayWithDefault
    , getEasing
    , getEasingWithDefault
    , getElementBaseline
    , getElementConfig
    , getIterationCount
    , getPreviousAnimation
    , getScrollContainer
    , getScrollTargets
    , getTimeSpec
    , getTimespec
    , init
    , injectCurrentStates
    , iterations
    , loopForever
    , mapScrollTargets
    , markAnimationAsExecuted
    , markDirty
    , processAnimationData
    , processAnimationDataWithHistory
      -- NEW: Process and store in history
    , processElement
    , restartAnimationById
    , restartCurrentAnimation
    , restartPreviousAnimation
    , setScrollContainer
    , speed
    , updateAnimationHistoryTranslates
    , updateCurrentElement
    , updateElementConfig
      -- Animation History Management
    )

import Anim.Extra.Color exposing (Color)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Internal.Properties.Color as Color
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Properties.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Properties.Scale as Scale exposing (Scale)
import Anim.Internal.Properties.ScrollTarget exposing (ScrollTarget)
import Anim.Internal.Properties.Size as Size exposing (Size)
import Anim.Internal.Properties.Translate as Translate exposing (Translate)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Dict exposing (Dict)



-- TYPES


type AnimBuilder
    = AnimBuilder BuilderData


type alias ElementId =
    String


type alias BuilderData =
    { globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Int
    , currentElementId : Maybe ElementId
    , elements : Dict ElementId ElementConfig
    , scrollTargets : List ScrollTarget
    , scrollContainer : String
    , animationHistories : Dict ElementId AnimationHistory
    , nextAnimationId : AnimationId
    , elementBaselines : Dict ElementId ElementEndStates -- Current animated states used as baselines
    , discreteTransitions : Bool -- Whether to allow discrete CSS properties (display, visibility) to transition
    , iterationCount : IterationCount -- How many times the animation should repeat
    }


{-| Specifies how many times an animation should repeat.

  - `Once` - Animation plays once and stops (default)
  - `Times n` - Animation repeats exactly n times
  - `Infinite` - Animation loops forever

-}
type IterationCount
    = Once
    | Times Int
    | Infinite


{-| Animation history for a single element.

  - current: The most recent animation (if any)
  - history: Previous animations (most recent first)
  - metadata: Additional tracking information

-}
type alias AnimationHistory =
    { current : Maybe AnimationHistoryEntry
    , history : List AnimationHistoryEntry -- Most recent first (head = previous)
    , metadata : ElementHistoryMetadata
    }


{-| Individual animation entry in the history.
-}
type alias AnimationHistoryEntry =
    { id : AnimationId
    , processedData : ProcessedAnimationData
    , timestamp : Int -- Using Int for simplicity (could be Time.Posix)
    , label : Maybe String -- Optional user-provided label
    }


{-| Unique identifier for animations.
-}
type alias AnimationId =
    Int


{-| Metadata for element animation history.
-}
type alias ElementHistoryMetadata =
    { totalAnimations : Int
    , lastExecutedId : Maybe AnimationId
    , createdAt : Int
    }


type alias ElementConfig =
    { properties : List PropertyConfig }


type PropertyConfig
    = TranslateConfig (AnimationConfig Translate)
    | RotateConfig (AnimationConfig Rotate)
    | ScaleConfig (AnimationConfig Scale)
    | BackgroundColorConfig (AnimationConfig Color)
    | FontColorConfig (AnimationConfig Color)
    | OpacityConfig (AnimationConfig Opacity)
    | SizeConfig (AnimationConfig Size)


type ProcessedPropertyConfig
    = ProcessedTranslateConfig (ProcessedAnimationConfig Translate)
    | ProcessedRotateConfig (ProcessedAnimationConfig Rotate)
    | ProcessedScaleConfig (ProcessedAnimationConfig Scale)
    | ProcessedBackgroundColorConfig (ProcessedAnimationConfig Color)
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
    , isDirty : Bool
    }


type alias ProcessedAnimationData =
    { elements : Dict ElementId ProcessedElementConfig
    , globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Int
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
    }


{-| Current animated states for an element, used as baselines for new animations.
Updated from JavaScript during animation playback.
-}
type alias ElementEndStates =
    { translate : Maybe Translate
    , rotate : Maybe Rotate
    , scale : Maybe Scale
    , backgroundColor : Maybe Color
    , fontColor : Maybe Color
    , opacity : Maybe Opacity
    , size : Maybe Size
    }



-- BUILD


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
        , animationHistories = Dict.empty -- NEW: Initialize empty animation histories
        , nextAnimationId = 1 -- NEW: Start animation IDs from 1
        , elementBaselines = Dict.empty -- NEW: Initialize empty baselines
        , discreteTransitions = False -- Disabled by default
        , iterationCount = Once -- Default: play once
        }


{-| Inject current animated states as baselines for the next animation.
This prevents mid-flight animation jumps by ensuring property builders copy from
current animated positions rather than old animation end positions.
-}
injectCurrentStates : Dict ElementId { a | currentStates : ElementEndStates } -> AnimBuilder -> AnimBuilder
injectCurrentStates elementAnimations (AnimBuilder data) =
    let
        baselines =
            elementAnimations
                |> Dict.map
                    (\_ animation ->
                        animation.currentStates
                    )
    in
    AnimBuilder { data | elementBaselines = baselines }


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


{-| Enable discrete CSS property transitions via `transition-behavior: allow-discrete`.

This allows properties like `display`, `visibility`, and `content-visibility` to participate
in transitions, enabling smoother entry/exit animations.

**Example:**

    CSS.animate model.animState <|
        (allowDiscreteTransitions >> fadeIn >> slideIn)

**Browser support:** The `transition-behavior` property is supported in modern browsers
(Chrome 117+, Firefox 129+, Safari 17.4+).

-}
allowDiscreteTransitions : AnimBuilder -> AnimBuilder
allowDiscreteTransitions (AnimBuilder data) =
    AnimBuilder { data | discreteTransitions = True }


{-| Check if discrete transitions are enabled for this animation.
-}
discreteTransitionsEnabled : AnimBuilder -> Bool
discreteTransitionsEnabled (AnimBuilder data) =
    data.discreteTransitions


{-| Set the animation to repeat a specific number of times.

**Note:** This only works with CSS keyframe animations, not CSS transitions.

    CSS.animate model.animState <|
        (iterations 3 >> bounce)  -- Bounces 3 times

-}
iterations : Int -> AnimBuilder -> AnimBuilder
iterations count (AnimBuilder data) =
    AnimBuilder { data | iterationCount = Times count }


{-| Set the animation to loop forever.

**Note:** This only works with CSS keyframe animations, not CSS transitions.

    CSS.animate model.animState <|
        (loopForever >> pulse)  -- Pulses continuously

-}
loopForever : AnimBuilder -> AnimBuilder
loopForever (AnimBuilder data) =
    AnimBuilder { data | iterationCount = Infinite }


{-| Get the configured iteration count.
-}
getIterationCount : AnimBuilder -> IterationCount
getIterationCount (AnimBuilder data) =
    data.iterationCount



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


{-| Get baseline states for an element (current animated values from JavaScript).
-}
getElementBaseline : String -> AnimBuilder -> Maybe ElementEndStates
getElementBaseline elementId (AnimBuilder data) =
    Dict.get elementId data.elementBaselines


getTimespec : AnimBuilder -> Maybe TimeSpec
getTimespec (AnimBuilder data) =
    data.globalTiming


{-| Get TimeSpec with default fallback.
-}
getTimeSpec : AnimBuilder -> TimeSpec
getTimeSpec (AnimBuilder data) =
    data.globalTiming |> Maybe.withDefault (Duration 0)


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


getScrollContainer : AnimBuilder -> String
getScrollContainer (AnimBuilder data) =
    data.scrollContainer



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
        TranslateConfig config ->
            TranslateConfig { config | isDirty = True }

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


{-| Process animation data and automatically add to history for all animated elements.
This is the new preferred way to process animations as it maintains proper history tracking.
Returns (updatedBuilder, processedData, animationIds) where animationIds maps elementId to AnimationId.
-}
processAnimationDataWithHistory : Maybe String -> AnimBuilder -> ( AnimBuilder, ProcessedAnimationData, Dict ElementId AnimationId )
processAnimationDataWithHistory maybeLabel builder =
    let
        -- First process the animation data normally
        processedData =
            processAnimationData builder

        -- Get all element IDs that have animations
        animatedElementIds =
            Dict.keys processedData.elements

        -- Add each element's animation to history
        ( updatedBuilder, animationIds ) =
            List.foldl
                (\elementId ( currentBuilder, idDict ) ->
                    let
                        ( newBuilder, animId ) =
                            addAnimationToHistory elementId processedData maybeLabel currentBuilder
                    in
                    ( newBuilder, Dict.insert elementId animId idDict )
                )
                ( builder, Dict.empty )
                animatedElementIds
    in
    ( updatedBuilder, processedData, animationIds )


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


createDirtyConfig :
    { end : a
    , wrapper : ProcessedAnimationConfig a -> ProcessedPropertyConfig
    }
    -> ProcessedPropertyConfig
createDirtyConfig { end, wrapper } =
    wrapper
        { start = Just end
        , end = end
        , duration = 0
        , speed = 0
        , distance = 0
        , timing = Duration 0
        , easing = Linear
        , delay = 0
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
            resolveTimingWithDefault config.timing globalData.globalTiming (Duration 0)

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
        }


processProperty : BuilderData -> PropertyConfig -> Maybe ProcessedPropertyConfig
processProperty globalData property =
    case property of
        TranslateConfig config ->
            if config.isDirty then
                Just <|
                    createDirtyConfig
                        { end = config.end
                        , wrapper = ProcessedTranslateConfig
                        }

            else
                Just <|
                    processStandardAnimation
                        { config = config
                        , globalData = globalData
                        , defaultStart = Translate.fromTuple ( 0.0, 0.0 )
                        , distanceFn = Translate.distance
                        , durationFn = Translate.duration
                        , speedFn = Translate.speed
                        , wrapper = ProcessedTranslateConfig
                        }

        RotateConfig config ->
            if config.isDirty then
                Just <|
                    createDirtyConfig
                        { end = config.end
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
                        , wrapper = ProcessedBackgroundColorConfig
                        }

            else
                Just <|
                    processStandardAnimation
                        { config = config
                        , globalData = globalData
                        , defaultStart = Color.fromRGB { r = 0, g = 0, b = 0 }
                        , distanceFn = Color.distance
                        , durationFn = Color.duration
                        , speedFn = Color.speed
                        , wrapper = ProcessedBackgroundColorConfig
                        }

        FontColorConfig config ->
            if config.isDirty then
                Just <|
                    createDirtyConfig
                        { end = config.end
                        , wrapper = ProcessedFontColorConfig
                        }

            else
                Just <|
                    processStandardAnimation
                        { config = config
                        , globalData = globalData
                        , defaultStart = Color.fromRGB { r = 0, g = 0, b = 0 }
                        , distanceFn = Color.distance
                        , durationFn = Color.duration
                        , speedFn = Color.speed
                        , wrapper = ProcessedFontColorConfig
                        }

        OpacityConfig config ->
            if config.isDirty then
                Just <|
                    createDirtyConfig
                        { end = config.end
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



-- TRANSFORM ORDERING
--
--
-- Shared logic for consistent transform ordering across engines


type alias TransformParts =
    { translate : String
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
    { translate = ""
    , rotate = ""
    , scale = ""
    }


{-| Collect transform from ProcessedPropertyConfig.
-}
collectProcessedTransform : ProcessedPropertyConfig -> TransformParts -> TransformParts
collectProcessedTransform property acc =
    case property of
        ProcessedTranslateConfig config ->
            { acc | translate = "translate3d(" ++ Translate.toCssString config.end ++ ")" }

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
        TranslateConfig config ->
            if config.isDirty then
                acc

            else
                { acc | translate = "translate3d(" ++ Translate.toCssString config.end ++ ")" }

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



-- ANIMATION HISTORY MANAGEMENT


{-| Add a new animation to the element's history.
This function creates a new history entry and updates the element's animation timeline.
The previous current animation (if any) is moved to the history list.
-}
addAnimationToHistory : ElementId -> ProcessedAnimationData -> Maybe String -> AnimBuilder -> ( AnimBuilder, AnimationId )
addAnimationToHistory elementId processedData maybeLabel (AnimBuilder data) =
    let
        newAnimationId =
            data.nextAnimationId

        currentTimestamp =
            0

        -- TODO: Could integrate with Time.now in the future
        -- Create the new animation entry
        newEntry =
            { id = newAnimationId
            , processedData = processedData
            , timestamp = currentTimestamp
            , label = maybeLabel
            }

        -- Get existing history for this element or create new one
        existingHistory =
            Dict.get elementId data.animationHistories
                |> Maybe.withDefault (createEmptyHistory currentTimestamp)

        -- Update history: move current to history list, set new as current
        updatedHistory =
            case existingHistory.current of
                Nothing ->
                    -- No previous animation, just set as current
                    { existingHistory
                        | current = Just newEntry
                        , metadata =
                            { totalAnimations = existingHistory.metadata.totalAnimations + 1
                            , lastExecutedId = existingHistory.metadata.lastExecutedId
                            , createdAt = existingHistory.metadata.createdAt
                            }
                    }

                Just previousCurrent ->
                    -- Move current to history, set new as current
                    { existingHistory
                        | current = Just newEntry
                        , history = previousCurrent :: existingHistory.history
                        , metadata =
                            { totalAnimations = existingHistory.metadata.totalAnimations + 1
                            , lastExecutedId = existingHistory.metadata.lastExecutedId
                            , createdAt = existingHistory.metadata.createdAt
                            }
                    }

        -- Update the builder with new history and incremented ID counter
        updatedData =
            { data
                | animationHistories = Dict.insert elementId updatedHistory data.animationHistories
                , nextAnimationId = data.nextAnimationId + 1
            }
    in
    ( AnimBuilder updatedData, newAnimationId )


{-| Get the current (most recent) animation for an element.
-}
getCurrentAnimation : ElementId -> AnimBuilder -> Maybe AnimationHistoryEntry
getCurrentAnimation elementId (AnimBuilder data) =
    Dict.get elementId data.animationHistories
        |> Maybe.andThen .current


{-| Get the previous animation for an element.
-}
getPreviousAnimation : ElementId -> AnimBuilder -> Maybe AnimationHistoryEntry
getPreviousAnimation elementId (AnimBuilder data) =
    Dict.get elementId data.animationHistories
        |> Maybe.andThen (.history >> List.head)


{-| Get a specific animation by its ID for an element.
-}
getAnimationById : ElementId -> AnimationId -> AnimBuilder -> Maybe AnimationHistoryEntry
getAnimationById elementId animId (AnimBuilder data) =
    Dict.get elementId data.animationHistories
        |> Maybe.andThen
            (\history ->
                -- Check current animation first
                case history.current of
                    Just current ->
                        if current.id == animId then
                            Just current

                        else
                            -- Search through history
                            List.filter (.id >> (==) animId) history.history
                                |> List.head

                    Nothing ->
                        -- Only search history
                        List.filter (.id >> (==) animId) history.history
                            |> List.head
            )


{-| Get the complete animation history for an element.
Returns (current, history) tuple where history is most recent first.
-}
getAllAnimationHistory : ElementId -> AnimBuilder -> Maybe ( Maybe AnimationHistoryEntry, List AnimationHistoryEntry )
getAllAnimationHistory elementId (AnimBuilder data) =
    Dict.get elementId data.animationHistories
        |> Maybe.map (\history -> ( history.current, history.history ))


{-| Clear animation history for an element.
-}
clearAnimationHistory : ElementId -> AnimBuilder -> AnimBuilder
clearAnimationHistory elementId (AnimBuilder data) =
    AnimBuilder { data | animationHistories = Dict.remove elementId data.animationHistories }


{-| Create an empty animation history for an element.
-}
createEmptyHistory : Int -> AnimationHistory
createEmptyHistory timestamp =
    { current = Nothing
    , history = []
    , metadata =
        { totalAnimations = 0
        , lastExecutedId = Nothing
        , createdAt = timestamp
        }
    }



-- ANIMATION CONTROL FUNCTIONS


{-| Restart the current animation for an element.
Returns the ProcessedAnimationData for the current animation, or Nothing if no current animation exists.
-}
restartCurrentAnimation : ElementId -> AnimBuilder -> Maybe ProcessedAnimationData
restartCurrentAnimation elementId builder =
    getCurrentAnimation elementId builder
        |> Maybe.map .processedData


{-| Restart the previous animation for an element.
Returns the ProcessedAnimationData for the previous animation, or Nothing if no previous animation exists.
-}
restartPreviousAnimation : ElementId -> AnimBuilder -> Maybe ProcessedAnimationData
restartPreviousAnimation elementId builder =
    getPreviousAnimation elementId builder
        |> Maybe.map .processedData


{-| Restart a specific animation by ID.
Returns the ProcessedAnimationData for the specified animation, or Nothing if the animation doesn't exist.
-}
restartAnimationById : ElementId -> AnimationId -> AnimBuilder -> Maybe ProcessedAnimationData
restartAnimationById elementId animId builder =
    getAnimationById elementId animId builder
        |> Maybe.map .processedData


{-| Mark an animation as executed and update the metadata.
This should be called by engines when they actually start executing an animation.
-}
markAnimationAsExecuted : ElementId -> AnimationId -> AnimBuilder -> AnimBuilder
markAnimationAsExecuted elementId animId (AnimBuilder data) =
    let
        updatedHistories =
            Dict.update elementId
                (Maybe.map
                    (\history ->
                        { history
                            | metadata =
                                { totalAnimations = history.metadata.totalAnimations
                                , lastExecutedId = Just animId
                                , createdAt = history.metadata.createdAt
                                }
                        }
                    )
                )
                data.animationHistories
    in
    AnimBuilder { data | animationHistories = updatedHistories }


{-| Update animation history translates for an element after container resize.
Updates both start and end translates in the current animation's ProcessedAnimationData.
-}
updateAnimationHistoryTranslates : ElementId -> Translate -> AnimBuilder -> AnimBuilder
updateAnimationHistoryTranslates elementId newTranslate (AnimBuilder data) =
    let
        updatedHistories =
            Dict.update elementId
                (Maybe.map
                    (\history ->
                        case history.current of
                            Just currentAnim ->
                                let
                                    updatedProcessedData =
                                        updateProcessedDataTranslate elementId newTranslate currentAnim.processedData

                                    updatedCurrent =
                                        { currentAnim | processedData = updatedProcessedData }
                                in
                                { history | current = Just updatedCurrent }

                            Nothing ->
                                history
                    )
                )
                data.animationHistories
    in
    AnimBuilder { data | animationHistories = updatedHistories }


{-| Helper to update translate in ProcessedAnimationData
-}
updateProcessedDataTranslate : ElementId -> Translate -> ProcessedAnimationData -> ProcessedAnimationData
updateProcessedDataTranslate elementId newTranslate processedData =
    let
        updatedElements =
            Dict.update elementId
                (Maybe.map
                    (\elementConfig ->
                        { elementConfig
                            | properties =
                                List.map
                                    (\prop ->
                                        case prop of
                                            ProcessedTranslateConfig config ->
                                                ProcessedTranslateConfig
                                                    { config
                                                        | start = Just newTranslate
                                                        , end = newTranslate
                                                    }

                                            _ ->
                                                prop
                                    )
                                    elementConfig.properties
                        }
                    )
                )
                processedData.elements
    in
    { processedData | elements = updatedElements }
