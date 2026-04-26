module Anim.Internal.Builder exposing
    ( AnimBuilder
    , AnimGroupConfig
    , AnimationConfig
    , AnimationDirection(..)
    , DefaultsConfig
    , DiscreteEntryProperty
    , DiscreteExitProperty
    , FreezeProperty(..)
    , Iterations(..)
    , PlaybackConfig
    , ProcessedAnimGroupConfig
    , ProcessedAnimationConfig
    , ProcessedAnimationData
    , ProcessedPropertyConfig(..)
    , PropertyConfig(..)
    , TransformParts
    , addAnimationToHistory
    , alternate
    , clearAnimData
    , delay
    , discreteEntry
    , discreteExit
    , discreteTransitionsEnabled
    , duration
    , easing
    , emptyTransformParts
    , extractTransformsFromProcessed
    , extractTransformsFromProperty
    , for
    , freezeAxes
    , getAnimGroupConfig
    , getAnimGroups
    , getAnimationDirection
    , getBaseline
    , getCurrentAnimationConfig
    , getCurrentElementConfig
    , getDelay
    , getDelayWithDefault
    , getDiscreteEntryProperties
    , getDiscreteExitProperties
    , getEasing
    , getEasingWithDefault
    , getFrozenAxes
    , getIterations
    , getRuntimeBaseline
    , getTimeSpec
    , getTimeSpecWithDefault
    , getTransformOrder
    , init
    , initDefaults
    , initPlayback
    , injectCurrentStates
    , iterations
    , loopForever
    , mergeBaselines
    , normalizeTransformOrder
    , process
    , processProperties
    , speed
    , transformOrder
    , unfreezeAxes
    , updateCurrentElement
    )

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Extra.Color as Color exposing (Color)
import Anim.Internal.PropertyBuilder.Opacity as Opacity exposing (Opacity)
import Anim.Internal.PropertyBuilder.Rotate as Rotate exposing (Rotate)
import Anim.Internal.PropertyBuilder.Scale as Scale exposing (Scale)
import Anim.Internal.PropertyBuilder.Size as Size exposing (Size)
import Anim.Internal.PropertyBuilder.Skew as Skew exposing (Skew)
import Anim.Internal.PropertyBuilder.Translate as Translate exposing (Translate)
import Anim.Internal.Timing.TimeSpec as TimeSpec exposing (TimeSpec(..))
import Dict exposing (Dict)
import Easing exposing (Easing(..))



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
    , state : PersistentState
    }



-- Defaults Configuration


{-| Global timing, easing, delay, and transform order defaults.
-}
type alias DefaultsConfig =
    { globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Int
    , globalTransformOrder : Maybe (List TransformProperty)
    }



-- Animation Group Data


type alias AnimGroupName =
    String


{-| Current animation group data cleared between animate calls.
-}
type alias AnimGroupData =
    { currentAnimGroup : Maybe AnimGroupName
    , animGroups : AnimGroups AnimGroupConfig
    , frozenAxes : Dict String (List String)
    }


type alias AnimGroupConfig =
    { properties : List PropertyConfig
    , transformOrder : Maybe (List TransformProperty)
    }


type alias ProcessedAnimGroupConfig =
    { properties : List ProcessedPropertyConfig
    , transformOrder : Maybe (List TransformProperty)
    }


type PropertyConfig
    = CustomPropertyConfig String String (AnimationConfig Float)
    | CustomColorPropertyConfig String (AnimationConfig Color)
    | OpacityConfig (AnimationConfig Opacity)
    | RotateConfig (AnimationConfig Rotate)
    | ScaleConfig (AnimationConfig Scale)
    | SizeConfig (AnimationConfig Size)
    | SkewConfig (AnimationConfig Skew)
    | TranslateConfig (AnimationConfig Translate)


type alias AnimationConfig targetProperty =
    { start : Maybe targetProperty
    , end : targetProperty
    , distance : Float
    , timing : Maybe TimeSpec
    , easing : Maybe Easing
    , delay : Maybe Int
    }


type ProcessedPropertyConfig
    = ProcessedCustomPropertyConfig String String (ProcessedAnimationConfig Float)
    | ProcessedCustomColorPropertyConfig String (ProcessedAnimationConfig Color)
    | ProcessedOpacityConfig (ProcessedAnimationConfig Opacity)
    | ProcessedRotateConfig (ProcessedAnimationConfig Rotate)
    | ProcessedScaleConfig (ProcessedAnimationConfig Scale)
    | ProcessedSizeConfig (ProcessedAnimationConfig Size)
    | ProcessedSkewConfig (ProcessedAnimationConfig Skew)
    | ProcessedTranslateConfig (ProcessedAnimationConfig Translate)


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


type alias ProcessedAnimationData =
    { groups : AnimGroups ProcessedAnimGroupConfig
    , globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalDelay : Maybe Int
    , iterations : Iterations
    , animationDirection : AnimationDirection
    }


{-| Persistent state preserved across animate calls.
-}
type alias PersistentState =
    { animationHistories : AnimGroups AnimationHistory
    , baselines : AnimGroups PropertyBaselines
    , runtimeBaselines : AnimGroups PropertyBaselines
    }


{-| Animation history for a single element.

  - current: The most recent animation (if any)
  - history: Previous animations (most recent first)

-}
type alias AnimationHistory =
    { current : ProcessedAnimGroupConfig
    , history : List ProcessedAnimGroupConfig -- Most recent first (head = previous)
    }



-- Playback Configuration


type alias DiscreteEntryProperty =
    String


{-| A discrete CSS property for exit keyframe animations.

  - `from` - The value to hold during the animation
  - `to` - The value to flip to at the final step (100%)

-}
type alias DiscreteExitProperty =
    { from : String
    , to : String
    }


{-| Playback configuration for iteration, direction, and discrete transitions.
-}
type alias PlaybackConfig =
    { iterations : Iterations
    , animationDirection : AnimationDirection
    , discreteTransitions : Bool
    , discreteEntryProperties : Dict String DiscreteEntryProperty
    , discreteExitProperties : Dict String DiscreteExitProperty
    }


{-| Specifies how many times an animation should repeat.

  - `Once` - Animation plays once and stops (default)
  - `Times n` - Animation repeats exactly n times
  - `Infinite` - Animation loops forever

-}
type Iterations
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
-- ============================================================
-- INITIALIZATION
-- Constructing fresh builder instances and their sub-records.
-- ============================================================


init : List (AnimBuilder -> AnimBuilder) -> AnimBuilder
init =
    List.foldl (\f b -> f b) <|
        AnimBuilder
            { defaults = initDefaults
            , animation = initAnimation
            , playback = initPlayback
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
    , animGroups = AnimGroups.init
    , frozenAxes = Dict.empty
    }


initPlayback : PlaybackConfig
initPlayback =
    { iterations = Once
    , animationDirection = Normal
    , discreteTransitions = False
    , discreteEntryProperties = Dict.empty
    , discreteExitProperties = Dict.empty
    }


initState : PersistentState
initState =
    { animationHistories = AnimGroups.init
    , baselines = AnimGroups.init
    , runtimeBaselines = AnimGroups.init
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


transformOrder : List TransformProperty -> AnimBuilder -> AnimBuilder
transformOrder order (AnimBuilder data) =
    let
        normalizedOrder =
            Just (normalizeTransformOrder order)

        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalTransformOrder = normalizedOrder } }


normalizeTransformOrder : List TransformProperty -> List TransformProperty
normalizeTransformOrder order =
    let
        removeDuplicates : List TransformProperty -> List TransformProperty -> List TransformProperty
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
            [ Translate, Rotate, Skew, Scale ]

        missing =
            List.filter (\t -> not (List.member t deduped)) defaultOrder
    in
    deduped ++ missing



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
getCurrentAnimationConfig : AnimGroupName -> AnimBuilder -> Maybe ProcessedAnimGroupConfig
getCurrentAnimationConfig animGroupName (AnimBuilder data) =
    AnimGroups.get animGroupName data.state.animationHistories
        |> Maybe.map .current



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
    AnimBuilder { data | playback = { pb | iterations = Times count } }


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
    AnimBuilder { data | playback = { pb | iterations = Infinite } }


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


{-| Check if discrete transitions are enabled for this animation.
-}
discreteTransitionsEnabled : AnimBuilder -> Bool
discreteTransitionsEnabled (AnimBuilder data) =
    data.playback.discreteTransitions


{-| Add a discrete CSS property for entry animations.

The value is applied when the animation starts, ensuring the element is
immediately in the target state.

    discreteEntry "display" "block"

-}
discreteEntry : String -> String -> AnimBuilder -> AnimBuilder
discreteEntry propertyName value (AnimBuilder data) =
    let
        pb =
            data.playback
    in
    AnimBuilder
        { data
            | playback =
                { pb
                    | discreteTransitions = True
                    , discreteEntryProperties =
                        Dict.insert propertyName value pb.discreteEntryProperties
                }
        }


{-| Add a discrete CSS property for exit animations.

The `from` value is held during the animation and flips to the `to` value
when the animation ends.

    discreteExit "display" "block" "none"

-}
discreteExit : String -> String -> String -> AnimBuilder -> AnimBuilder
discreteExit propertyName from to (AnimBuilder data) =
    let
        pb =
            data.playback
    in
    AnimBuilder
        { data
            | playback =
                { pb
                    | discreteTransitions = True
                    , discreteExitProperties =
                        Dict.insert propertyName { from = from, to = to } pb.discreteExitProperties
                }
        }


{-| Get the discrete entry properties for keyframe animations.
-}
getDiscreteEntryProperties : AnimBuilder -> Dict String String
getDiscreteEntryProperties (AnimBuilder data) =
    data.playback.discreteEntryProperties


{-| Get the discrete exit properties for keyframe animations.
-}
getDiscreteExitProperties : AnimBuilder -> Dict String DiscreteExitProperty
getDiscreteExitProperties (AnimBuilder data) =
    data.playback.discreteExitProperties


{-| Get the configured iteration count.
-}
getIterations : AnimBuilder -> Iterations
getIterations (AnimBuilder data) =
    data.playback.iterations


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
    | FreexeSkew


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

        FreexeSkew ->
            "skew"



-- ============================================================
-- QUERYING
-- Read-only access to builder configuration and state.
-- ============================================================


getAnimGroups : AnimBuilder -> AnimGroups AnimGroupConfig
getAnimGroups (AnimBuilder data) =
    data.animation.animGroups


getCurrentElementConfig : AnimBuilder -> AnimGroupConfig
getCurrentElementConfig (AnimBuilder data) =
    case data.animation.currentAnimGroup of
        Nothing ->
            { properties = [], transformOrder = data.defaults.globalTransformOrder }

        Just animGroupName ->
            AnimGroups.get animGroupName data.animation.animGroups
                |> Maybe.map
                    (\config ->
                        { config
                            | transformOrder =
                                case data.defaults.globalTransformOrder of
                                    Just globalOrder ->
                                        Just globalOrder

                                    Nothing ->
                                        config.transformOrder
                        }
                    )
                |> Maybe.withDefault { properties = [], transformOrder = data.defaults.globalTransformOrder }


getAnimGroupConfig : AnimGroupName -> AnimBuilder -> Maybe AnimGroupConfig
getAnimGroupConfig animGroupName (AnimBuilder data) =
    AnimGroups.get animGroupName data.animation.animGroups


{-| Get baseline states for a group.
Baselines reflect the last known property values - either animation targets
or runtime snapshots from active animations.
-}
getBaseline : String -> AnimBuilder -> Maybe PropertyBaselines
getBaseline key (AnimBuilder data) =
    AnimGroups.get key data.state.baselines


getRuntimeBaseline : String -> AnimBuilder -> Maybe PropertyBaselines
getRuntimeBaseline key (AnimBuilder data) =
    AnimGroups.get key data.state.runtimeBaselines


getTransformOrder : AnimGroupName -> AnimBuilder -> Maybe (List TransformProperty)
getTransformOrder animGroupName (AnimBuilder data) =
    AnimGroups.get animGroupName data.animation.animGroups
        |> Maybe.andThen .transformOrder
        |> orElse data.defaults.globalTransformOrder


orElse : Maybe a -> Maybe a -> Maybe a
orElse fallback primary =
    case primary of
        Just _ ->
            primary

        Nothing ->
            fallback


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



-- ============================================================
-- STATE MANAGEMENT
-- Injecting baselines, clearing transient data, merging end
-- states, and updating element configurations between cycles.
-- ============================================================


{-| Inject current animated states as baselines for the next animation.
This prevents mid-flight animation jumps by ensuring property builders copy from
current animated positions rather than old animation end positions.

Merges runtime snapshots into baselines rather than replacing them, so completed
groups' baselines are preserved.

-}
injectCurrentStates : AnimGroups { a | propertySnapshot : PropertyBaselines } -> AnimBuilder -> AnimBuilder
injectCurrentStates animGroups (AnimBuilder data) =
    let
        state =
            data.state

        runtimeSnapshots =
            AnimGroups.map
                (\_ animation -> animation.propertySnapshot)
                animGroups

        mergedRuntimeBaselines =
            AnimGroups.merge
                AnimGroups.insert
                (\key new old -> AnimGroups.insert key (PropertyBaselines.merge old new))
                AnimGroups.insert
                (AnimGroups.toDict runtimeSnapshots)
                (AnimGroups.toDict state.baselines)
                AnimGroups.init
    in
    AnimBuilder
        { data
            | state =
                { state | runtimeBaselines = mergedRuntimeBaselines }
        }


clearAnimData : AnimBuilder -> AnimBuilder
clearAnimData (AnimBuilder data) =
    let
        pb =
            data.playback
    in
    AnimBuilder
        { data
            | animation = initAnimation
            , playback =
                { pb
                    | discreteEntryProperties = Dict.empty
                    , discreteExitProperties = Dict.empty
                }
        }


mergeBaselines : AnimBuilder -> AnimBuilder
mergeBaselines (AnimBuilder ({ state, animation } as data)) =
    let
        newBaselines =
            animation.animGroups
                |> AnimGroups.map (\_ config -> extractBaselinesFromConfig config)

        mergeBoth key new old =
            AnimGroups.insert key (PropertyBaselines.merge old new)

        newState =
            { state
                | baselines =
                    AnimGroups.merge
                        AnimGroups.insert
                        mergeBoth
                        AnimGroups.insert
                        (AnimGroups.toDict newBaselines)
                        (AnimGroups.toDict state.baselines)
                        AnimGroups.init
            }
    in
    AnimBuilder { data | state = newState }


extractBaselinesFromConfig : AnimGroupConfig -> PropertyBaselines
extractBaselinesFromConfig elementConfig =
    List.foldl extractPropertyBaseline PropertyBaselines.empty elementConfig.properties


extractPropertyBaseline : PropertyConfig -> PropertyBaselines -> PropertyBaselines
extractPropertyBaseline propConfig baselines =
    case propConfig of
        TranslateConfig cfg ->
            PropertyBaselines.setTranslate cfg.end baselines

        RotateConfig cfg ->
            PropertyBaselines.setRotate cfg.end baselines

        ScaleConfig cfg ->
            PropertyBaselines.setScale cfg.end baselines

        SkewConfig cfg ->
            PropertyBaselines.setSkew cfg.end baselines

        OpacityConfig cfg ->
            PropertyBaselines.setOpacity cfg.end baselines

        SizeConfig cfg ->
            PropertyBaselines.setSize cfg.end baselines

        CustomPropertyConfig cssName unit cfg ->
            PropertyBaselines.setCustomProperty cssName cfg.end unit baselines

        CustomColorPropertyConfig cssName cfg ->
            PropertyBaselines.setCustomColorProperty cssName cfg.end baselines


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
                    case AnimGroups.get animKey anim.animGroups of
                        Just existing ->
                            let
                                -- Filter out existing properties that would be replaced by new ones
                                filteredExisting =
                                    existing.properties
                                        |> List.filter
                                            (\p -> not (List.member (propertyType p) newPropertyTypes))

                                mergedOrder =
                                    case config.transformOrder of
                                        Just _ ->
                                            config.transformOrder

                                        Nothing ->
                                            existing.transformOrder
                            in
                            { existing
                                | properties = filteredExisting ++ config.properties
                                , transformOrder = mergedOrder
                            }

                        Nothing ->
                            config
            in
            AnimBuilder
                { data | animation = { anim | animGroups = AnimGroups.insert animKey mergedConfig anim.animGroups } }


{-| Get the type tag of a PropertyConfig for comparison.
-}
propertyType : PropertyConfig -> String
propertyType prop =
    case prop of
        CustomPropertyConfig cssName _ _ ->
            "custom:" ++ cssName

        CustomColorPropertyConfig cssName _ ->
            "customColor:" ++ cssName

        OpacityConfig _ ->
            "opacity"

        RotateConfig _ ->
            "rotate"

        ScaleConfig _ ->
            "scale"

        SizeConfig _ ->
            "size"

        SkewConfig _ ->
            "skew"

        TranslateConfig _ ->
            "translate"



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
    , iterations = data.playback.iterations
    , animationDirection = data.playback.animationDirection
    , groups =
        AnimGroups.map
            (\_ group ->
                { properties = processProperties data.defaults group.properties
                , transformOrder =
                    case group.transformOrder of
                        Just _ ->
                            group.transformOrder

                        Nothing ->
                            data.defaults.globalTransformOrder
                }
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

        SkewConfig config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , defaultStart = Skew.fromTuple ( 0.0, 0.0 )
                    , distanceFn = Skew.distance
                    , durationFn = Skew.duration
                    , speedFn = Skew.speed
                    , wrapper = ProcessedSkewConfig
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

        CustomPropertyConfig cssName unit config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , defaultStart = 0
                    , distanceFn = \a b -> abs (b - a)
                    , durationFn = TimeSpec.duration
                    , speedFn = TimeSpec.speed
                    , wrapper = ProcessedCustomPropertyConfig cssName unit
                    }

        CustomColorPropertyConfig cssName config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , defaultStart = Color.fromRGB { r = 0, g = 0, b = 0 }
                    , distanceFn = Color.distance
                    , durationFn = Color.duration
                    , speedFn = Color.speed
                    , wrapper = ProcessedCustomColorPropertyConfig cssName
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
    , skew : String
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
    , skew = ""
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

        ProcessedSkewConfig config ->
            { acc | skew = Skew.toCssString config.end }

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

        SkewConfig config ->
            { acc | skew = Skew.toCssString config.end }

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
    AnimGroups.foldl
        (\animGroupName groupConfig (AnimBuilder accData) ->
            let
                state =
                    accData.state

                -- Get existing history for this element
                existingHistory =
                    AnimGroups.get animGroupName state.animationHistories

                -- Update history: move current to history list, set new as current
                updatedHistory =
                    case existingHistory of
                        Nothing ->
                            { current = groupConfig
                            , history = []
                            }

                        Just existing ->
                            { current = groupConfig
                            , history = existing.current :: existing.history
                            }
            in
            AnimBuilder
                { accData
                    | state =
                        { state
                            | animationHistories =
                                AnimGroups.insert
                                    animGroupName
                                    updatedHistory
                                    state.animationHistories
                        }
                }
        )
        (AnimBuilder data)
        processedData.groups
