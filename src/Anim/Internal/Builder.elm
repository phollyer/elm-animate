module Anim.Internal.Builder exposing
    ( AnimBuilder
    , AnimGroupConfig
    , AnimationConfig
    , AnimationDirection(..)
    , AnimationHistory
    , AnimationHistoryEntry
    , DefaultsConfig
    , FreezeProperty(..)
    , IterationCount(..)
    , PlaybackConfig
    , ProcessedAnimGroupConfig
    , ProcessedAnimationConfig
    , ProcessedAnimationData
    , ProcessedPropertyConfig(..)
    , PropertyConfig(..)
    , PropertyEndStates
    , TransformOrder(..)
    , TransformParts
    , addAnimationToHistory
    , addScrollTarget
    , allowDiscreteTransitions
    , alternate
    , animGroups
    , clearAnimData
    , clearCurrentElement
    , delay
    , discreteTransitionsEnabled
    , duration
    , easing
    , extractTransformsFromProcessed
    , extractTransformsFromProperty
    , for
    , freezeAxes
    , getAnimationDirection
    , getCurrentAnimation
    , getCurrentElementConfig
    , getDelay
    , getDelayWithDefault
    , getEasing
    , getEasingWithDefault
    , getElementBaseline
    , getElementConfig
    , getFrozenAxes
    , getIterationCount
    , getScrollContainer
    , getScrollTargets
    , getTargetValue
    , getTimeSpec
    , getTimeSpecWithDefault
    , getTransformOrder
    , init
    , initDefaults
    , initPlayback
    , injectCurrentStates
    , iterations
    , loopForever
    , mapScrollTargets
    , mergeEndStates
    , normalizeTransformOrder
    , process
    , processProperties
    , setScrollContainer
    , speed
    , transformOrder
    , transformOrderToString
    , unfreezeAxes
    , updateCurrentElement
    )

import Anim.Extra.Easing exposing (Easing(..))
import Anim.Internal.Engine.Scroll.ScrollTarget exposing (ScrollTarget)
import Anim.Internal.Extra.Color as Color exposing (Color)
import Anim.Internal.Property.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Anim.Internal.Property.Size as Size exposing (Size)
import Anim.Internal.Property.Translate as Translate exposing (Translate)
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


{-| Current animation group data cleared between animate calls.
-}
type alias AnimGroupData =
    { currentAnimGroup : Maybe AnimGroupName
    , animGroups : Dict AnimGroupName AnimGroupConfig
    , frozenAxes : Dict String (List String)
    }


type alias AnimGroupConfig =
    { properties : List PropertyConfig
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


{-| Persistent state preserved across animate calls.
-}
type alias PersistentState =
    { animationHistories : Dict AnimGroupName AnimationHistory
    , animationBaselines : Dict AnimGroupName PropertyEndStates
    , endStates : Dict AnimGroupName PropertyEndStates
    }


{-| Animation history for a single element.

  - current: The most recent animation (if any)
  - history: Previous animations (most recent first)

-}
type alias AnimationHistory =
    { current : Maybe AnimationHistoryEntry
    , history : List AnimationHistoryEntry -- Most recent first (head = previous)
    }


{-| Individual animation entry in the history.
-}
type alias AnimationHistoryEntry =
    ProcessedAnimationData


type alias ProcessedAnimationData =
    { groups : Dict AnimGroupName ProcessedAnimGroupConfig
    , globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Int
    , iterationCount : IterationCount
    , animationDirection : AnimationDirection
    , globalTransformOrder : Maybe (List TransformOrder)
    }


type alias ProcessedAnimGroupConfig =
    { properties : List ProcessedPropertyConfig
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


{-| Current animated states for a group, used as baselines for new animations.
Updated from JavaScript during animation playback.
-}
type alias PropertyEndStates =
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
    , animationBaselines = Dict.empty
    , endStates = Dict.empty
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


transformOrderToString : TransformOrder -> String
transformOrderToString order =
    case order of
        Translate ->
            "translate"

        Rotate ->
            "rotate"

        Scale ->
            "scale"



-- ============================================================
-- ANIMATION TARGETING
-- Selecting which animation group to configure.
-- ============================================================


for : String -> AnimBuilder -> AnimBuilder
for elementId (AnimBuilder data) =
    let
        anim =
            data.animation
    in
    AnimBuilder
        { data | animation = { anim | currentAnimGroup = Just elementId } }


{-| Get the current (most recent) animation for a group.
-}
getCurrentAnimation : AnimGroupName -> AnimBuilder -> Maybe AnimationHistoryEntry
getCurrentAnimation animGroupName (AnimBuilder data) =
    Dict.get animGroupName data.state.animationHistories
        |> Maybe.andThen .current



-- ============================================================
-- PLAYBACK
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


animGroups : AnimBuilder -> Dict AnimGroupName AnimGroupConfig
animGroups (AnimBuilder data) =
    data.animation.animGroups


getCurrentElementConfig : AnimBuilder -> AnimGroupConfig
getCurrentElementConfig (AnimBuilder data) =
    case data.animation.currentAnimGroup of
        Nothing ->
            { properties = [] }

        Just elementId ->
            Dict.get elementId data.animation.animGroups
                |> Maybe.withDefault { properties = [] }


getElementConfig : String -> AnimBuilder -> Maybe AnimGroupConfig
getElementConfig elementId (AnimBuilder data) =
    Dict.get elementId data.animation.animGroups


{-| Get baseline states for a group (current animated values from JavaScript).
Searches for:

1.  Exact match
2.  Composite keys that start with "key:" (when key is element ID)
3.  Composite keys that end with ":key" (when key is animation group)

If multiple matches exist, merges them with later matches taking precedence.

-}
getElementBaseline : String -> AnimBuilder -> Maybe PropertyEndStates
getElementBaseline key (AnimBuilder data) =
    Dict.get key data.state.animationBaselines


getTargetValue : String -> AnimBuilder -> Maybe PropertyEndStates
getTargetValue key (AnimBuilder data) =
    Dict.get key data.state.endStates


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
injectCurrentStates : Dict AnimGroupName { a | currentStates : PropertyEndStates } -> AnimBuilder -> AnimBuilder
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
mergeEndStates (AnimBuilder ({ state, animation } as data)) =
    let
        newEndStates =
            Dict.map (\_ config -> extractEndStatesFromConfig config) animation.animGroups

        mergeBoth key new old =
            Dict.insert key (mergePropertyEndStates old new)

        newState =
            { state
                | endStates =
                    Dict.merge
                        Dict.insert
                        mergeBoth
                        Dict.insert
                        newEndStates
                        state.endStates
                        Dict.empty
            }
    in
    AnimBuilder { data | state = newState }


{-| Merge two PropertyEndStates, with the second taking precedence for non-Nothing values.

This preserves existing baseline values for properties not included in the new configuration,
while updating any properties that are being reconfigured.

-}
mergePropertyEndStates : PropertyEndStates -> PropertyEndStates -> PropertyEndStates
mergePropertyEndStates a b =
    let
        merge : (PropertyEndStates -> Maybe a) -> Maybe a
        merge field =
            field b
                |> Maybe.map Just
                |> Maybe.withDefault (field a)
    in
    { translate = merge .translate
    , rotate = merge .rotate
    , scale = merge .scale
    , opacity = merge .opacity
    , backgroundColor = merge .backgroundColor
    , fontColor = merge .fontColor
    , size = merge .size
    }


extractEndStatesFromConfig : AnimGroupConfig -> PropertyEndStates
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


extractPropertyEndState : PropertyConfig -> PropertyEndStates -> PropertyEndStates
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


updateCurrentElement : AnimGroupConfig -> AnimBuilder -> AnimBuilder
updateCurrentElement config (AnimBuilder data) =
    case data.animation.currentAnimGroup of
        Nothing ->
            AnimBuilder data

        Just animKey ->
            let
                anim =
                    data.animation

                -- Get types of new properties to avoid duplicates
                newPropertyTypes =
                    List.map propertyType config.properties

                -- Replace properties of same type (not just append) to avoid accumulation
                mergedConfig =
                    case Dict.get animKey anim.animGroups of
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
                { data | animation = { anim | animGroups = Dict.insert animKey mergedConfig anim.animGroups } }


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


process : AnimBuilder -> ProcessedAnimationData
process (AnimBuilder data) =
    { globalTiming = data.defaults.globalTiming
    , globalEasing = data.defaults.globalEasing
    , globalDelay = data.defaults.globalDelay
    , iterationCount = data.playback.iterationCount
    , animationDirection = data.playback.animationDirection
    , globalTransformOrder = data.defaults.globalTransformOrder
    , groups =
        Dict.map
            (\_ { properties } ->
                { properties = processProperties data.defaults properties }
            )
            data.animation.animGroups
    }


processProperties : DefaultsConfig -> List PropertyConfig -> List ProcessedPropertyConfig
processProperties defaults =
    List.filterMap (processProperty defaults)


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
addAnimationToHistory : ProcessedAnimationData -> AnimBuilder -> AnimBuilder
addAnimationToHistory processedData (AnimBuilder data) =
    Dict.foldl
        (\animGroupName _ (AnimBuilder accData) ->
            let
                state =
                    accData.state

                -- Get existing history for this element or create new one
                existingHistory =
                    Dict.get animGroupName state.animationHistories
                        |> Maybe.withDefault
                            { current = Nothing
                            , history = []
                            }

                -- Update history: move current to history list, set new as current
                updatedHistory =
                    case existingHistory.current of
                        Nothing ->
                            -- No previous animation, just set as current
                            { existingHistory
                                | current = Just processedData
                            }

                        Just previousCurrent ->
                            -- Move current to history, set new as current
                            { existingHistory
                                | current = Just processedData
                                , history = previousCurrent :: existingHistory.history
                            }
            in
            AnimBuilder
                { accData
                    | state =
                        { state
                            | animationHistories =
                                Dict.insert
                                    animGroupName
                                    updatedHistory
                                    state.animationHistories
                        }
                }
        )
        (AnimBuilder data)
        processedData.groups
