module Anim.Internal.Builder exposing
    ( AnimBuilder
    , AnimationConfig
    , AnimationDirection(..)
    , AnimationHistory
    , AnimationHistoryEntry
    , AnimationId
    , CompositeKey
    , ElementConfig
    , ElementEndStates
    , FreezeProperty(..)
    , IterationCount(..)
    , ProcessedAnimationData
    , ProcessedElementConfig
    , ProcessedPropertyConfig(..)
    , PropertyConfig(..)
    , TransformOrder(..)
    , TransformParts
    , addAnimationToHistory
    , addScrollTarget
    , allowDiscreteTransitions
    , alternate
    , clearAnimData
    , clearCurrentElement
    , delay
    , discreteTransitionsEnabled
    , duration
    , easing
    , elements
    , extractElementId
    , extractGroupName
    , extractTransformsFromProcessed
    , extractTransformsFromProperty
    , for
    , freezeAxes
    , getAnimationById
    , getAnimationDirection
    , getCurrentAnimation
    , getCurrentElementConfig
    , getDelay
    , getDelayWithDefault
    , getEasing
    , getEasingWithDefault
    , getElementBaseline
    , getElementConfig
    , getElementTarget
    , getFrozenAxes
    , getIterationCount
    , getPreviousAnimation
    , getScrollContainer
    , getScrollTargets
    , getTargetElement
    , getTimeSpec
    , getTimespec
    , getTransformOrder
    , init
    , injectCurrentStates
    , isCompositeKey
    , iterations
    , loopForever
    , makeCompositeKey
    , mapScrollTargets
    , mergeEndStates
    , normalizeTransformOrder
    , processAnimationData
    , processElement
    , restartAnimationById
    , restartCurrentAnimation
    , restartPreviousAnimation
    , setScrollContainer
    , setTargetElement
    , speed
    , transformOrder
    , unfreezeAxes
    , updateCurrentElement
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


{-| A composite key combining element ID and group name, formatted as "elementId:groupName".
Used by WAAPI to track multiple animation groups per DOM element.
-}
type alias CompositeKey =
    String


{-| Create a composite key from element ID and group name.
-}
makeCompositeKey : ElementId -> String -> CompositeKey
makeCompositeKey elementId groupName =
    elementId ++ ":" ++ groupName


{-| Extract the element ID from a composite key.
If the key is not a composite key, returns the key itself.
-}
extractElementId : CompositeKey -> ElementId
extractElementId compositeKey =
    case String.split ":" compositeKey |> List.head of
        Just id ->
            id

        Nothing ->
            compositeKey


{-| Extract the group name from a composite key.
If the key is not a composite key (no colon), returns the key itself as the group name.
-}
extractGroupName : CompositeKey -> String
extractGroupName compositeKey =
    case String.split ":" compositeKey of
        [ _, groupName ] ->
            groupName

        _ ->
            compositeKey


{-| Check if a key is a composite key (contains a colon separator).
-}
isCompositeKey : String -> Bool
isCompositeKey key =
    String.contains ":" key


type TransformOrder
    = Translate
    | Rotate
    | Scale


type FreezeProperty
    = FreezeTranslate
    | FreezeRotate
    | FreezeScale


type alias BuilderData =
    { globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Int
    , globalTransformOrder : Maybe (List TransformOrder)
    , currentElementId : Maybe ElementId
    , elements : Dict ElementId ElementConfig
    , scrollTargets : List ScrollTarget
    , scrollContainer : String
    , animationHistories : Dict ElementId AnimationHistory
    , nextAnimationId : AnimationId
    , elementBaselines : Dict ElementId ElementEndStates -- Current animated states used as baselines
    , elementTargets : Dict ElementId ElementEndStates -- Previous animation end targets for unspecified axis resolution
    , discreteTransitions : Bool -- Whether to allow discrete CSS properties (display, visibility) to transition
    , iterationCount : IterationCount -- How many times the animation should repeat
    , animationDirection : AnimationDirection -- Direction the animation plays (normal, alternate)
    , targetElement : Maybe ElementId -- Target DOM element ID for composite keys (used by WAAPI and Sub engines)
    , frozenAxes : Dict String (List String) -- Per-property frozen axis names (e.g., { "translate" -> ["x", "y"] })
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


{-| Specifies the direction an animation should play.

  - `Normal` - Animation plays forwards each iteration (default)
  - `Alternate` - Animation alternates direction each iteration (ping-pong)

-}
type AnimationDirection
    = Normal
    | Alternate


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
    { properties : List PropertyConfig
    , targetElement : Maybe String -- WAAPI: DOM element ID (if different from animation key)
    }


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
    { properties : List ProcessedPropertyConfig
    , targetElement : Maybe String -- WAAPI: DOM element ID (if different from animation key)
    }


type alias AnimationConfig targetProperty =
    { start : Maybe targetProperty
    , end : targetProperty
    , duration : Int
    , speed : Float
    , distance : Float
    , timing : Maybe TimeSpec
    , easing : Maybe Easing
    , delay : Maybe Int
    }


type alias ProcessedAnimationData =
    { elements : Dict ElementId ProcessedElementConfig
    , globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Int
    , iterationCount : IterationCount
    , animationDirection : AnimationDirection
    , globalTransformOrder : Maybe (List TransformOrder)
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
        , globalTransformOrder = Nothing
        , currentElementId = Nothing
        , elements = Dict.empty
        , scrollTargets = []
        , scrollContainer = "document"
        , animationHistories = Dict.empty -- NEW: Initialize empty animation histories
        , nextAnimationId = 1 -- NEW: Start animation IDs from 1
        , elementBaselines = Dict.empty -- NEW: Initialize empty baselines
        , elementTargets = Dict.empty
        , discreteTransitions = False -- Disabled by default
        , iterationCount = Once -- Default: play once
        , animationDirection = Normal -- Default: play forwards
        , targetElement = Nothing
        , frozenAxes = Dict.empty
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


{-| Freeze specific axes of the given properties at their current baseline values.
The axis names (e.g., ["x", "y"]) are added to the frozen set for each property.
-}
freezeAxes : List String -> List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeAxes axes properties (AnimBuilder data) =
    let
        propNames =
            List.map freezePropertyName properties

        newFrozenAxes =
            List.foldl
                (\propName dict ->
                    Dict.update propName
                        (\maybeAxes ->
                            case maybeAxes of
                                Just existing ->
                                    Just (List.foldl addIfMissing existing axes)

                                Nothing ->
                                    Just axes
                        )
                        dict
                )
                data.frozenAxes
                propNames
    in
    AnimBuilder { data | frozenAxes = newFrozenAxes }


{-| Remove specific axes from the frozen set of the given properties.
-}
unfreezeAxes : List String -> List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeAxes axes properties (AnimBuilder data) =
    let
        propNames =
            List.map freezePropertyName properties

        newFrozenAxes =
            List.foldl
                (\propName dict ->
                    Dict.update propName
                        (Maybe.map <|
                            List.filter (\a -> not (List.member a axes))
                        )
                        dict
                )
                data.frozenAxes
                propNames
    in
    AnimBuilder { data | frozenAxes = newFrozenAxes }


{-| Get the list of frozen axes for a property. Returns [] if none are frozen.
-}
getFrozenAxes : String -> AnimBuilder -> List String
getFrozenAxes propName (AnimBuilder data) =
    Dict.get propName data.frozenAxes |> Maybe.withDefault []


addIfMissing : a -> List a -> List a
addIfMissing item list =
    if List.member item list then
        list

    else
        item :: list


freezePropertyName : FreezeProperty -> String
freezePropertyName prop =
    case prop of
        FreezeTranslate ->
            "translate"

        FreezeRotate ->
            "rotate"

        FreezeScale ->
            "scale"


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


transformOrder : List TransformOrder -> AnimBuilder -> AnimBuilder
transformOrder order (AnimBuilder data) =
    AnimBuilder { data | globalTransformOrder = Just (normalizeTransformOrder order) }


getTransformOrder : AnimBuilder -> Maybe (List TransformOrder)
getTransformOrder (AnimBuilder data) =
    data.globalTransformOrder


normalizeTransformOrder : List TransformOrder -> List TransformOrder
normalizeTransformOrder order =
    let
        removeDuplicates : List TransformOrder -> List TransformOrder -> List TransformOrder
        removeDuplicates seen remaining =
            case remaining of
                [] ->
                    List.reverse seen

                x :: xs ->
                    if List.member x seen then
                        removeDuplicates seen xs

                    else
                        removeDuplicates (x :: seen) xs

        deduped =
            removeDuplicates [] order

        defaultOrder =
            [ Translate, Rotate, Scale ]

        missing =
            List.filter (\t -> not (List.member t deduped)) defaultOrder
    in
    deduped ++ missing


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


{-| Set the animation to alternate direction each iteration (ping-pong effect).

Combine with `loopForever` or `iterations` for continuous back-and-forth motion:

    CSS.animate model.animState <|
        (loopForever >> alternate >> rotate "element")  -- Rotates back and forth forever

-}
alternate : AnimBuilder -> AnimBuilder
alternate (AnimBuilder data) =
    AnimBuilder { data | animationDirection = Alternate }


{-| Get the configured iteration count.
-}
getIterationCount : AnimBuilder -> IterationCount
getIterationCount (AnimBuilder data) =
    data.iterationCount


{-| Get the configured animation direction.
-}
getAnimationDirection : AnimBuilder -> AnimationDirection
getAnimationDirection (AnimBuilder data) =
    data.animationDirection



-- QUERY BUILDER


elements : AnimBuilder -> Dict ElementId ElementConfig
elements (AnimBuilder data) =
    data.elements


getCurrentElementConfig : AnimBuilder -> ElementConfig
getCurrentElementConfig (AnimBuilder data) =
    case data.currentElementId of
        Nothing ->
            { properties = [], targetElement = data.targetElement }

        Just elementId ->
            Dict.get elementId data.elements
                |> Maybe.withDefault { properties = [], targetElement = data.targetElement }
                |> (\config -> { config | targetElement = data.targetElement })


getElementConfig : String -> AnimBuilder -> Maybe ElementConfig
getElementConfig elementId (AnimBuilder data) =
    Dict.get elementId data.elements


{-| Get baseline states for an element (current animated values from JavaScript).
Searches for:

1.  Exact match
2.  Composite keys that start with "key:" (when key is element ID)
3.  Composite keys that end with ":key" (when key is animation group)

If multiple matches exist, merges them with later matches taking precedence.

-}
getElementBaseline : String -> AnimBuilder -> Maybe ElementEndStates
getElementBaseline key (AnimBuilder data) =
    -- First try exact match
    case Dict.get key data.elementBaselines of
        Just baseline ->
            Just baseline

        Nothing ->
            -- Search for composite key matches
            let
                prefix =
                    key ++ ":"

                suffix =
                    ":" ++ key

                -- Find all matching baselines
                matches =
                    Dict.toList data.elementBaselines
                        |> List.filter
                            (\( k, _ ) ->
                                String.startsWith prefix k || String.endsWith suffix k
                            )
            in
            case matches of
                [] ->
                    Nothing

                [ ( _, baseline ) ] ->
                    Just baseline

                first :: rest ->
                    -- Merge multiple matches
                    Just <|
                        List.foldl
                            (\( _, baseline ) acc -> mergeElementEndStates acc baseline)
                            (Tuple.second first)
                            rest


{-| Merge two ElementEndStates, with the second taking precedence for non-Nothing values.
-}
mergeElementEndStates : ElementEndStates -> ElementEndStates -> ElementEndStates
mergeElementEndStates a b =
    { translate = Maybe.map Just b.translate |> Maybe.withDefault a.translate
    , rotate = Maybe.map Just b.rotate |> Maybe.withDefault a.rotate
    , scale = Maybe.map Just b.scale |> Maybe.withDefault a.scale
    , opacity = Maybe.map Just b.opacity |> Maybe.withDefault a.opacity
    , backgroundColor = Maybe.map Just b.backgroundColor |> Maybe.withDefault a.backgroundColor
    , fontColor = Maybe.map Just b.fontColor |> Maybe.withDefault a.fontColor
    , size = Maybe.map Just b.size |> Maybe.withDefault a.size
    }


getElementTarget : String -> AnimBuilder -> Maybe ElementEndStates
getElementTarget key (AnimBuilder data) =
    case Dict.get key data.elementTargets of
        Just target ->
            Just target

        Nothing ->
            let
                prefix =
                    key ++ ":"

                suffix =
                    ":" ++ key

                matches =
                    Dict.toList data.elementTargets
                        |> List.filter
                            (\( k, _ ) ->
                                String.startsWith prefix k || String.endsWith suffix k
                            )
            in
            case matches of
                [] ->
                    Nothing

                [ ( _, target ) ] ->
                    Just target

                first :: rest ->
                    Just <|
                        List.foldl
                            (\( _, target ) acc -> mergeElementEndStates acc target)
                            (Tuple.second first)
                            rest


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


clearAnimData : AnimBuilder -> AnimBuilder
clearAnimData (AnimBuilder data) =
    AnimBuilder { data | elements = Dict.empty, currentElementId = Nothing, frozenAxes = Dict.empty, targetElement = Nothing }


mergeEndStates : AnimBuilder -> AnimBuilder
mergeEndStates (AnimBuilder data) =
    let
        newTargets =
            Dict.map (\_ config -> extractEndStatesFromConfig config) data.elements

        mergeBoth key new old =
            Dict.insert key (mergeElementEndStates old new)

        mergedTargets =
            Dict.merge
                Dict.insert
                mergeBoth
                Dict.insert
                newTargets
                data.elementTargets
                Dict.empty
    in
    AnimBuilder { data | elementTargets = mergedTargets }


extractEndStatesFromConfig : ElementConfig -> ElementEndStates
extractEndStatesFromConfig elementConfig =
    List.foldl extractPropertyEndState
        { translate = Nothing
        , rotate = Nothing
        , scale = Nothing
        , backgroundColor = Nothing
        , fontColor = Nothing
        , opacity = Nothing
        , size = Nothing
        }
        elementConfig.properties


extractPropertyEndState : PropertyConfig -> ElementEndStates -> ElementEndStates
extractPropertyEndState propConfig states =
    case propConfig of
        TranslateConfig cfg ->
            { states | translate = Just cfg.end }

        RotateConfig cfg ->
            { states | rotate = Just cfg.end }

        ScaleConfig cfg ->
            { states | scale = Just cfg.end }

        BackgroundColorConfig cfg ->
            { states | backgroundColor = Just cfg.end }

        FontColorConfig cfg ->
            { states | fontColor = Just cfg.end }

        OpacityConfig cfg ->
            { states | opacity = Just cfg.end }

        SizeConfig cfg ->
            { states | size = Just cfg.end }


updateCurrentElement : ElementConfig -> AnimBuilder -> AnimBuilder
updateCurrentElement config (AnimBuilder data) =
    case data.currentElementId of
        Nothing ->
            AnimBuilder data

        Just animKey ->
            let
                -- When forElement is used: composite key "elementId:groupName"
                -- Otherwise: use animation key (group name) as-is
                effectiveKey =
                    case data.targetElement of
                        Just elementId ->
                            makeCompositeKey elementId animKey

                        Nothing ->
                            animKey

                -- Get types of new properties to avoid duplicates
                newPropertyTypes =
                    List.map propertyType config.properties

                -- Replace properties of same type (not just append) to avoid accumulation
                mergedConfig =
                    case Dict.get effectiveKey data.elements of
                        Just existing ->
                            let
                                -- Filter out existing properties that would be replaced by new ones
                                filteredExisting =
                                    existing.properties
                                        |> List.filter
                                            (\p -> not (List.member (propertyType p) newPropertyTypes))
                            in
                            { existing | properties = filteredExisting ++ config.properties }

                        Nothing ->
                            config
            in
            AnimBuilder
                { data | elements = Dict.insert effectiveKey mergedConfig data.elements }


{-| Get the type tag of a PropertyConfig for comparison.
-}
propertyType : PropertyConfig -> String
propertyType prop =
    case prop of
        TranslateConfig _ ->
            "translate"

        RotateConfig _ ->
            "rotate"

        ScaleConfig _ ->
            "scale"

        BackgroundColorConfig _ ->
            "backgroundColor"

        FontColorConfig _ ->
            "fontColor"

        OpacityConfig _ ->
            "opacity"

        SizeConfig _ ->
            "size"


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


{-| Set the target DOM element ID.
This creates composite keys ("elementId:groupName") enabling multiple elements
to share the same animation group names.
-}
setTargetElement : String -> AnimBuilder -> AnimBuilder
setTargetElement elementId (AnimBuilder data) =
    AnimBuilder { data | targetElement = Just elementId }


{-| Get the current target element ID.
-}
getTargetElement : AnimBuilder -> Maybe String
getTargetElement (AnimBuilder data) =
    data.targetElement



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
    , iterationCount = data.iterationCount
    , animationDirection = data.animationDirection
    , globalTransformOrder = data.globalTransformOrder
    }


processElement : BuilderData -> ElementConfig -> ProcessedElementConfig
processElement globalData elementConfig =
    { properties = List.filterMap (processProperty globalData) elementConfig.properties
    , targetElement = elementConfig.targetElement
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
            { acc | translate = Translate.toCssString config.end }

        ProcessedRotateConfig config ->
            { acc | rotate = Rotate.toCssString config.end }

        ProcessedScaleConfig config ->
            { acc | scale = Scale.toCssString config.end }

        _ ->
            acc


{-| Collect transform from PropertyConfig.
-}
collectPropertyTransform : PropertyConfig -> TransformParts -> TransformParts
collectPropertyTransform property acc =
    case property of
        TranslateConfig config ->
            { acc | translate = Translate.toCssString config.end }

        RotateConfig config ->
            { acc | rotate = Rotate.toCssString config.end }

        ScaleConfig config ->
            { acc | scale = Scale.toCssString config.end }

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
