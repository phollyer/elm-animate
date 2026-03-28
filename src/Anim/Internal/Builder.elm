module Anim.Internal.Builder exposing
    ( AnimBuilder
    , AnimationConfig
    , AnimationDirection(..)
    , AnimationHistory
    , AnimationHistoryEntry
    , AnimationId
    , CompositeKey
    , DefaultsConfig
    , ElementConfig
    , ElementEndStates
    , FreezeProperty(..)
    , IterationCount(..)
    , PlaybackConfig
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
    , getScrollContainer
    , getScrollTargets
    , getTargetElement
    , getTimeSpec
    , getTimeSpecWithDefault
    , getTransformOrder
    , init
    , initDefaults
    , initPlayback
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



-- ============================================================
-- TYPES
-- The core builder type, configuration records, property types,
-- and all supporting type aliases used throughout the module.
-- ============================================================


type AnimBuilder
    = AnimBuilder BuilderData



-- Configuration records


type alias BuilderData =
    { defaults : DefaultsConfig
    , animation : AnimGroupData
    , playback : PlaybackConfig
    , scroll : ScrollConfig
    , state : PersistentState
    }



-- Defaults Configuration


{-| Global timing, easing, delay, and transform order defaults.
-}
type alias DefaultsConfig =
    { globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Int
    , globalTransformOrder : Maybe (List TransformOrder)
    }


type TransformOrder
    = Translate
    | Rotate
    | Scale



-- Animation Group Data


type alias AnimGroupName =
    String


type alias ElementId =
    String


{-| Current animation group data cleared between animate calls.
-}
type alias AnimGroupData =
    { currentAnimGroup : Maybe AnimGroupName
    , animGroups : Dict AnimGroupName ElementConfig
    , targetElement : Maybe ElementId
    , frozenAxes : Dict String (List String)
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



-- Playback Configuration


{-| Playback configuration for iteration, direction, and discrete transitions.
-}
type alias PlaybackConfig =
    { iterationCount : IterationCount
    , animationDirection : AnimationDirection
    , discreteTransitions : Bool
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



-- Scroll Configuration


{-| Scroll engine configuration.
-}
type alias ScrollConfig =
    { scrollTargets : List ScrollTarget
    , scrollContainer : String
    }



-- Persistent State


{-| Unique identifier for animations.
-}
type alias AnimationId =
    Int


{-| Persistent state preserved across animate calls.
-}
type alias PersistentState =
    { animationHistories : Dict AnimGroupName AnimationHistory
    , nextAnimationId : AnimationId
    , animationBaselines : Dict AnimGroupName ElementEndStates
    , elementTargets : Dict AnimGroupName ElementEndStates
    }


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


type alias ProcessedAnimationData =
    { elements : Dict AnimGroupName ProcessedElementConfig
    , globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Int
    , iterationCount : IterationCount
    , animationDirection : AnimationDirection
    , globalTransformOrder : Maybe (List TransformOrder)
    }


type alias ProcessedElementConfig =
    { properties : List ProcessedPropertyConfig
    , targetElement : Maybe String -- WAAPI: DOM element ID (if different from animation key)
    }


type ProcessedPropertyConfig
    = ProcessedTranslateConfig (ProcessedAnimationConfig Translate)
    | ProcessedRotateConfig (ProcessedAnimationConfig Rotate)
    | ProcessedScaleConfig (ProcessedAnimationConfig Scale)
    | ProcessedBackgroundColorConfig (ProcessedAnimationConfig Color)
    | ProcessedFontColorConfig (ProcessedAnimationConfig Color)
    | ProcessedOpacityConfig (ProcessedAnimationConfig Opacity)
    | ProcessedSizeConfig (ProcessedAnimationConfig Size)


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


{-| Metadata for element animation history.
-}
type alias ElementHistoryMetadata =
    { totalAnimations : Int
    , lastExecutedId : Maybe AnimationId
    , createdAt : Int
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



-- ============================================================
-- INITIALIZATION
-- Constructing fresh builder instances and their sub-records.
-- ============================================================


init : AnimBuilder
init =
    AnimBuilder
        { defaults = initDefaults
        , animation = initAnimation
        , playback = initPlayback
        , scroll = initScroll
        , state = initState
        }


initDefaults : DefaultsConfig
initDefaults =
    { globalTiming = Nothing
    , globalEasing = Nothing
    , globalDelay = Nothing
    , globalTransformOrder = Nothing
    }


initAnimation : AnimGroupData
initAnimation =
    { currentAnimGroup = Nothing
    , animGroups = Dict.empty
    , targetElement = Nothing
    , frozenAxes = Dict.empty
    }


initPlayback : PlaybackConfig
initPlayback =
    { iterationCount = Once
    , animationDirection = Normal
    , discreteTransitions = False
    }


initScroll : ScrollConfig
initScroll =
    { scrollTargets = []
    , scrollContainer = "document"
    }


initState : PersistentState
initState =
    { animationHistories = Dict.empty
    , nextAnimationId = 1
    , animationBaselines = Dict.empty
    , elementTargets = Dict.empty
    }



-- ============================================================
-- BUILDER PIPELINE - DEFAULTS
-- Setting global timing, easing, delay, and transform order
-- that apply to all properties unless overridden per-property.
-- ============================================================


duration : Int -> AnimBuilder -> AnimBuilder
duration ms (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalTiming = Just (Duration ms) } }


speed : Float -> AnimBuilder -> AnimBuilder
speed value (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalTiming = Just (Speed value) } }


easing : Easing -> AnimBuilder -> AnimBuilder
easing easingValue (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalEasing = Just easingValue } }


delay : Int -> AnimBuilder -> AnimBuilder
delay ms (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data
            | defaults =
                { defs
                    | globalDelay =
                        Just <|
                            ms
                }
        }


transformOrder : List TransformOrder -> AnimBuilder -> AnimBuilder
transformOrder order (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder { data | defaults = { defs | globalTransformOrder = Just (normalizeTransformOrder order) } }


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



-- ============================================================
-- BUILDER PIPELINE - ELEMENT TARGETING
-- Selecting which element and animation group to configure.
-- Supports composite keys ("elementId:groupName") for sharing
-- animation group names across multiple elements.
-- ============================================================


for : String -> AnimBuilder -> AnimBuilder
for elementId (AnimBuilder data) =
    let
        anim =
            data.animation
    in
    AnimBuilder
        { data | animation = { anim | currentAnimGroup = Just elementId } }


{-| Set the target DOM element ID.
This creates composite keys ("elementId:groupName") enabling multiple elements
to share the same animation group names.
-}
setTargetElement : String -> AnimBuilder -> AnimBuilder
setTargetElement elementId (AnimBuilder data) =
    let
        anim =
            data.animation
    in
    AnimBuilder { data | animation = { anim | targetElement = Just elementId } }


{-| Get the current target element ID.
-}
getTargetElement : AnimBuilder -> Maybe String
getTargetElement (AnimBuilder data) =
    data.animation.targetElement



-- ============================================================
-- BUILDER PIPELINE - PLAYBACK
-- Iteration count, animation direction, and discrete
-- CSS transition support.
-- ============================================================


{-| Set the animation to repeat a specific number of times.

**Note:** This only works with CSS keyframe animations, not CSS transitions.

    CSS.animate model.animState <|
        (iterations 3 >> bounce)  -- Bounces 3 times

-}
iterations : Int -> AnimBuilder -> AnimBuilder
iterations count (AnimBuilder data) =
    let
        pb =
            data.playback
    in
    AnimBuilder { data | playback = { pb | iterationCount = Times count } }


{-| Set the animation to loop forever.

**Note:** This only works with CSS keyframe animations, not CSS transitions.

    CSS.animate model.animState <|
        (loopForever >> pulse)  -- Pulses continuously

-}
loopForever : AnimBuilder -> AnimBuilder
loopForever (AnimBuilder data) =
    let
        pb =
            data.playback
    in
    AnimBuilder { data | playback = { pb | iterationCount = Infinite } }


{-| Set the animation to alternate direction each iteration (ping-pong effect).

Combine with `loopForever` or `iterations` for continuous back-and-forth motion:

    CSS.animate model.animState <|
        (loopForever >> alternate >> rotate "element")  -- Rotates back and forth forever

-}
alternate : AnimBuilder -> AnimBuilder
alternate (AnimBuilder data) =
    let
        pb =
            data.playback
    in
    AnimBuilder { data | playback = { pb | animationDirection = Alternate } }


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
    let
        pb =
            data.playback
    in
    AnimBuilder { data | playback = { pb | discreteTransitions = True } }


{-| Check if discrete transitions are enabled for this animation.
-}
discreteTransitionsEnabled : AnimBuilder -> Bool
discreteTransitionsEnabled (AnimBuilder data) =
    data.playback.discreteTransitions


{-| Get the configured iteration count.
-}
getIterationCount : AnimBuilder -> IterationCount
getIterationCount (AnimBuilder data) =
    data.playback.iterationCount


{-| Get the configured animation direction.
-}
getAnimationDirection : AnimBuilder -> AnimationDirection
getAnimationDirection (AnimBuilder data) =
    data.playback.animationDirection



-- ============================================================
-- BUILDER PIPELINE - FREEZE AXES
-- Locking and unlocking specific transform axes at their
-- current baseline values during animation.
-- ============================================================


type FreezeProperty
    = FreezeTranslate
    | FreezeRotate
    | FreezeScale


{-| Freeze specific axes of the given properties at their current baseline values.
The axis names (e.g., ["x", "y"]) are added to the frozen set for each property.
-}
freezeAxes : List String -> List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeAxes axes properties (AnimBuilder data) =
    let
        propNames =
            List.map freezePropertyName properties

        anim =
            data.animation

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
                anim.frozenAxes
                propNames
    in
    AnimBuilder { data | animation = { anim | frozenAxes = newFrozenAxes } }


{-| Remove specific axes from the frozen set of the given properties.
-}
unfreezeAxes : List String -> List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeAxes axes properties (AnimBuilder data) =
    let
        propNames =
            List.map freezePropertyName properties

        anim =
            data.animation

        newFrozenAxes =
            List.foldl
                (\propName dict ->
                    Dict.update propName
                        (Maybe.map <|
                            List.filter (\a -> not (List.member a axes))
                        )
                        dict
                )
                anim.frozenAxes
                propNames
    in
    AnimBuilder { data | animation = { anim | frozenAxes = newFrozenAxes } }


{-| Get the list of frozen axes for a property. Returns [] if none are frozen.
-}
getFrozenAxes : String -> AnimBuilder -> List String
getFrozenAxes propName (AnimBuilder data) =
    Dict.get propName data.animation.frozenAxes |> Maybe.withDefault []


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



-- ============================================================
-- BUILDER PIPELINE - SCROLL
-- Scroll target elements and scroll container configuration.
-- ============================================================


addScrollTarget : ScrollTarget -> AnimBuilder -> AnimBuilder
addScrollTarget scrollTarget (AnimBuilder data) =
    let
        sc =
            data.scroll
    in
    AnimBuilder
        { data | scroll = { sc | scrollTargets = scrollTarget :: sc.scrollTargets } }


mapScrollTargets : (ScrollTarget -> ScrollTarget) -> AnimBuilder -> AnimBuilder
mapScrollTargets fn (AnimBuilder data) =
    let
        sc =
            data.scroll
    in
    AnimBuilder { data | scroll = { sc | scrollTargets = List.map fn sc.scrollTargets } }


setScrollContainer : String -> AnimBuilder -> AnimBuilder
setScrollContainer containerId (AnimBuilder data) =
    let
        sc =
            data.scroll
    in
    AnimBuilder { data | scroll = { sc | scrollContainer = containerId } }



-- ============================================================
-- QUERYING
-- Read-only access to builder configuration and state.
-- ============================================================


elements : AnimBuilder -> Dict AnimGroupName ElementConfig
elements (AnimBuilder data) =
    data.animation.animGroups


getCurrentElementConfig : AnimBuilder -> ElementConfig
getCurrentElementConfig (AnimBuilder data) =
    case data.animation.currentAnimGroup of
        Nothing ->
            { properties = [], targetElement = data.animation.targetElement }

        Just elementId ->
            Dict.get elementId data.animation.animGroups
                |> Maybe.withDefault { properties = [], targetElement = data.animation.targetElement }
                |> (\config -> { config | targetElement = data.animation.targetElement })


getElementConfig : String -> AnimBuilder -> Maybe ElementConfig
getElementConfig elementId (AnimBuilder data) =
    Dict.get elementId data.animation.animGroups


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
    case Dict.get key data.state.animationBaselines of
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
                    Dict.toList data.state.animationBaselines
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


getElementTarget : String -> AnimBuilder -> Maybe ElementEndStates
getElementTarget key (AnimBuilder data) =
    case Dict.get key data.state.elementTargets of
        Just target ->
            Just target

        Nothing ->
            let
                prefix =
                    key ++ ":"

                suffix =
                    ":" ++ key

                matches =
                    Dict.toList data.state.elementTargets
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


getTransformOrder : AnimBuilder -> Maybe (List TransformOrder)
getTransformOrder (AnimBuilder data) =
    data.defaults.globalTransformOrder


getTimeSpec : AnimBuilder -> Maybe TimeSpec
getTimeSpec (AnimBuilder data) =
    data.defaults.globalTiming


{-| Get TimeSpec with default fallback.
-}
getTimeSpecWithDefault : AnimBuilder -> TimeSpec
getTimeSpecWithDefault (AnimBuilder data) =
    data.defaults.globalTiming |> Maybe.withDefault (Duration 0)


getEasing : AnimBuilder -> Maybe Easing
getEasing (AnimBuilder data) =
    data.defaults.globalEasing


{-| Get Easing with default fallback.
-}
getEasingWithDefault : AnimBuilder -> Easing
getEasingWithDefault (AnimBuilder data) =
    data.defaults.globalEasing |> Maybe.withDefault QuintOut


getDelay : AnimBuilder -> Maybe Int
getDelay (AnimBuilder data) =
    data.defaults.globalDelay


{-| Get Delay with default fallback.
-}
getDelayWithDefault : AnimBuilder -> Int
getDelayWithDefault (AnimBuilder data) =
    data.defaults.globalDelay |> Maybe.withDefault 0


{-| Get scroll targets from the builder.
-}
getScrollTargets : AnimBuilder -> List ScrollTarget
getScrollTargets (AnimBuilder data) =
    data.scroll.scrollTargets


getScrollContainer : AnimBuilder -> String
getScrollContainer (AnimBuilder data) =
    data.scroll.scrollContainer



-- ============================================================
-- STATE MANAGEMENT
-- Injecting baselines, clearing transient data, merging end
-- states, and updating element configurations between cycles.
-- ============================================================


{-| Inject current animated states as baselines for the next animation.
This prevents mid-flight animation jumps by ensuring property builders copy from
current animated positions rather than old animation end positions.
-}
injectCurrentStates : Dict AnimGroupName { a | currentStates : ElementEndStates } -> AnimBuilder -> AnimBuilder
injectCurrentStates elementAnimations (AnimBuilder data) =
    let
        baselines =
            elementAnimations
                |> Dict.map
                    (\_ animation ->
                        animation.currentStates
                    )

        st =
            data.state
    in
    AnimBuilder { data | state = { st | animationBaselines = baselines } }


clearCurrentElement : AnimBuilder -> AnimBuilder
clearCurrentElement (AnimBuilder data) =
    let
        anim =
            data.animation
    in
    AnimBuilder { data | animation = { anim | currentAnimGroup = Nothing } }


clearAnimData : AnimBuilder -> AnimBuilder
clearAnimData (AnimBuilder data) =
    AnimBuilder { data | animation = initAnimation }


mergeEndStates : AnimBuilder -> AnimBuilder
mergeEndStates (AnimBuilder data) =
    let
        newTargets =
            Dict.map (\_ config -> extractEndStatesFromConfig config) data.animation.animGroups

        mergeBoth key new old =
            Dict.insert key (mergeElementEndStates old new)

        st =
            data.state

        mergedTargets =
            Dict.merge
                Dict.insert
                mergeBoth
                Dict.insert
                newTargets
                st.elementTargets
                Dict.empty
    in
    AnimBuilder { data | state = { st | elementTargets = mergedTargets } }


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
    case data.animation.currentAnimGroup of
        Nothing ->
            AnimBuilder data

        Just animKey ->
            let
                anim =
                    data.animation

                -- When forElement is used: composite key "elementId:groupName"
                -- Otherwise: use animation key (group name) as-is
                effectiveKey =
                    case anim.targetElement of
                        Just elementId ->
                            makeCompositeKey elementId animKey

                        Nothing ->
                            animKey

                -- Get types of new properties to avoid duplicates
                newPropertyTypes =
                    List.map propertyType config.properties

                -- Replace properties of same type (not just append) to avoid accumulation
                mergedConfig =
                    case Dict.get effectiveKey anim.animGroups of
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
                { data | animation = { anim | animGroups = Dict.insert effectiveKey mergedConfig anim.animGroups } }


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



-- ============================================================
-- PROCESSING
-- Resolving raw AnimBuilder configuration into engine-ready
-- ProcessedAnimationData with concrete timing, easing, and
-- delay values.
-- ============================================================


processAnimationData : AnimBuilder -> ProcessedAnimationData
processAnimationData (AnimBuilder data) =
    let
        processedElements =
            Dict.map (\_ elementConfig -> processElement data.defaults elementConfig) data.animation.animGroups
    in
    { elements = processedElements
    , globalTiming = data.defaults.globalTiming
    , globalEasing = data.defaults.globalEasing
    , globalDelay = data.defaults.globalDelay
    , iterationCount = data.playback.iterationCount
    , animationDirection = data.playback.animationDirection
    , globalTransformOrder = data.defaults.globalTransformOrder
    }


processElement : DefaultsConfig -> ElementConfig -> ProcessedElementConfig
processElement defaults elementConfig =
    { properties = List.filterMap (processProperty defaults) elementConfig.properties
    , targetElement = elementConfig.targetElement
    }


processStandardAnimation :
    { config : AnimationConfig a
    , globalData : DefaultsConfig
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


processProperty : DefaultsConfig -> PropertyConfig -> Maybe ProcessedPropertyConfig
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



-- ============================================================
-- TRANSFORM ORDERING
-- Assembling CSS transform strings with consistent ordering
-- across all animation engines (transitions, keyframes, WAAPI).
-- ============================================================


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



-- ============================================================
-- ANIMATION HISTORY & CONTROL
-- Tracking the animation timeline for each element and
-- supporting replay of previous animations by ID.
-- ============================================================


{-| Add a new animation to the element's history.
This function creates a new history entry and updates the element's animation timeline.
The previous current animation (if any) is moved to the history list.
-}
addAnimationToHistory : AnimGroupName -> ProcessedAnimationData -> Maybe String -> AnimBuilder -> ( AnimBuilder, AnimationId )
addAnimationToHistory elementId processedData maybeLabel (AnimBuilder data) =
    let
        st =
            data.state

        newAnimationId =
            st.nextAnimationId

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
            Dict.get elementId st.animationHistories
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

        updatedState =
            { st
                | animationHistories = Dict.insert elementId updatedHistory st.animationHistories
                , nextAnimationId = st.nextAnimationId + 1
            }
    in
    ( AnimBuilder { data | state = updatedState }, newAnimationId )


{-| Get the current (most recent) animation for an element.
-}
getCurrentAnimation : AnimGroupName -> AnimBuilder -> Maybe AnimationHistoryEntry
getCurrentAnimation elementId (AnimBuilder data) =
    Dict.get elementId data.state.animationHistories
        |> Maybe.andThen .current


{-| Get a specific animation by its ID for an element.
-}
getAnimationById : AnimGroupName -> AnimationId -> AnimBuilder -> Maybe AnimationHistoryEntry
getAnimationById elementId animId (AnimBuilder data) =
    Dict.get elementId data.state.animationHistories
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


{-| Restart the current animation for an element.
Returns the ProcessedAnimationData for the current animation, or Nothing if no current animation exists.
-}
restartCurrentAnimation : AnimGroupName -> AnimBuilder -> Maybe ProcessedAnimationData
restartCurrentAnimation elementId builder =
    getCurrentAnimation elementId builder
        |> Maybe.map .processedData


{-| Restart a specific animation by ID.
Returns the ProcessedAnimationData for the specified animation, or Nothing if the animation doesn't exist.
-}
restartAnimationById : AnimGroupName -> AnimationId -> AnimBuilder -> Maybe ProcessedAnimationData
restartAnimationById elementId animId builder =
    getAnimationById elementId animId builder
        |> Maybe.map .processedData



-- Composite Key


{-| A composite key combining element ID and group name, formatted as "elementId:groupName".
-}
type alias CompositeKey =
    String


{-| Create a composite key from element ID and group name.
-}
makeCompositeKey : ElementId -> AnimGroupName -> CompositeKey
makeCompositeKey elementId groupName =
    elementId ++ ":" ++ groupName


{-| Extract the element ID from a composite key.
If the key is not a composite key, returns the key itself.
-}
extractElementId : String -> String
extractElementId compositeKey =
    case String.split ":" compositeKey |> List.head of
        Just id ->
            id

        Nothing ->
            compositeKey


{-| Extract the group name from a composite key.
If the key is not a composite key, returns the key itself.
-}
extractGroupName : String -> String
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
