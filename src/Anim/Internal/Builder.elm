module Anim.Internal.Builder exposing
    ( AnimBuilder
    , AnimGroupConfig
    , AnimationConfig
    , AnimationDirection(..)
    , DefaultsConfig
    , DiscreteEntryProperty
    , DiscreteExitProperty
    , ForDocumentTimeline
    , ForKeyframeEngine
    , ForScrollTimeline
    , ForSubEngine
    , ForTransitionEngine
    , ForViewTimeline
    , ForWAAPIEngine
    , FreezeProperty(..)
    , Iterations(..)
    , PlaybackConfig
    , ProcessedAnimGroupConfig
    , ProcessedAnimationConfig
    , ProcessedAnimationData
    , ProcessedPropertyConfig(..)
    , PropertyConfig(..)
    , ScrollDrivenConfig
    , TransformParts
    , addAnimationToHistory
    , alternate
    , clearAnimData
    , clearClamp
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
    , getAnimTarget
    , getAnimationDirection
    , getBaseline
    , getClamp
    , getCurrentAnimGroupConfig
    , getCurrentAnimGroupName
    , getCurrentAnimationConfig
    , getDelay
    , getDelayWithDefault
    , getDiscreteEntryProperties
    , getDiscreteExitProperties
    , getEasing
    , getEasingWithDefault
    , getFrozenAxes
    , getIterations
    , getRuntimeBaseline
    , getScrollAxis
    , getScrollSource
    , getSpring
    , getTimeSpec
    , getTimeSpecWithDefault
    , getTransformOrder
    , getViewRangeEnd
    , getViewRangeStart
    , init
    , initDefaults
    , initPlayback
    , injectCurrentStates
    , injectRunningProperties
    , isPropertyRunning
    , iterations
    , loopForever
    , mergeBaselines
    , normalizeTransformOrder
    , process
    , processProperties
    , processedPropertyType
    , setAnimTarget
    , setClamp
    , setScrollAxis
    , setScrollSource
    , setViewRangeEnd
    , setViewRangeStart
    , speed
    , spring
    , transformOrder
    , transitionMode
    , unfreezeAxes
    , updateCurrentConfig
    )

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Extra.Color as Color exposing (Color)
import Anim.Internal.Property.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin exposing (PerspectiveOrigin)
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Anim.Internal.Property.Size as Size exposing (Size)
import Anim.Internal.Property.Skew as Skew exposing (Skew)
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Dict exposing (Dict)
import Motion.Easing exposing (Easing(..))
import Motion.Internal.Spring as SpringInt exposing (Spring)
import Set exposing (Set)
import Shared.Spring as SpringSolver
import Shared.TimeSpec as TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- TYPES
-- ============================================================


type AnimBuilder mode
    = AnimBuilder BuilderData



-- Available `mode`s


type alias ForScrollTimeline =
    { forScroll : () }


type alias ForViewTimeline =
    { forView : () }


type alias ForDocumentTimeline engine =
    { forDocument : ()
    , forEngine : engine
    }


type alias ForKeyframeEngine =
    { forKeyframe : () }


type alias ForSubEngine =
    { forSub : () }


type alias ForTransitionEngine =
    { forTransition : () }


type alias ForWAAPIEngine =
    { forWAAPI : () }



-- Configuration records


type alias BuilderData =
    { defaults : DefaultsConfig
    , animation : AnimGroupData
    , playback : PlaybackConfig
    , state : PersistentState
    , scrollDriven : ScrollDrivenConfig
    }



-- Defaults Configuration


{-| Global timing, easing, delay, and transform order defaults.
-}
type alias DefaultsConfig =
    { globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalSpring : Maybe Spring
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
    | PerspectiveOriginConfig (AnimationConfig PerspectiveOrigin)
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
    , spring : Maybe Spring
    , delay : Maybe Int
    }


type ProcessedPropertyConfig
    = ProcessedCustomPropertyConfig String String (ProcessedAnimationConfig Float)
    | ProcessedCustomColorPropertyConfig String (ProcessedAnimationConfig Color)
    | ProcessedOpacityConfig (ProcessedAnimationConfig Opacity)
    | ProcessedPerspectiveOriginConfig (ProcessedAnimationConfig PerspectiveOrigin)
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
    , spring : Maybe Spring
    , delay : Int
    }


type alias ProcessedAnimationData =
    { groups : AnimGroups ProcessedAnimGroupConfig
    , globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalSpring : Maybe Spring
    , globalDelay : Maybe Int
    , iterations : Iterations
    , animationDirection : AnimationDirection
    }


{-| Persistent state preserved across animate calls.

`runningProperties` is the exception: it is populated only by the
engine-level `retarget` function and cleared by `clearAnimData` after
the pipeline runs. It tells per-property `continueFor` resolvers which
property animations were still running on each animGroup at the moment
`retarget` was invoked.

-}
type alias PersistentState =
    { animationHistories : AnimGroups AnimationHistory
    , baselines : AnimGroups PropertyBaselines
    , runtimeBaselines : AnimGroups PropertyBaselines
    , runningProperties : Dict AnimGroupName (Set String)
    , propertyClamps : Dict ( AnimGroupName, String, String ) ( Float, Float )
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



-- Scroll-Driven Animation Configuration


type alias ScrollDrivenConfig =
    { source : Maybe String
    , axis : Maybe String
    , viewRangeStart : Maybe String
    , viewRangeEnd : Maybe String
    , targets : AnimGroups String
    }



-- Constructing fresh builder instances and their sub-records.
-- ============================================================


init : List (AnimBuilder mode -> AnimBuilder mode) -> AnimBuilder mode
init =
    List.foldl (\f b -> f b) <|
        AnimBuilder
            { defaults = initDefaults
            , animation = initAnimation
            , playback = initPlayback
            , state = initState
            , scrollDriven = initScrollDrivenConfig
            }


initDefaults : DefaultsConfig
initDefaults =
    { globalTiming = Nothing
    , globalEasing = Nothing
    , globalSpring = Nothing
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
    , runningProperties = Dict.empty
    , propertyClamps = Dict.empty
    }


initScrollDrivenConfig : ScrollDrivenConfig
initScrollDrivenConfig =
    { source = Nothing
    , axis = Nothing
    , viewRangeStart = Nothing
    , viewRangeEnd = Nothing
    , targets = AnimGroups.init
    }



-- ============================================================
-- BUILDER PIPELINE - DEFAULTS
-- Setting global timing, easing, delay, and transform order
-- that apply to all properties unless overridden per-property.
-- ============================================================


duration : Int -> AnimBuilder mode -> AnimBuilder mode
duration ms (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalTiming = Just (Duration ms) } }


speed : Float -> AnimBuilder mode -> AnimBuilder mode
speed value (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalTiming = Just (Speed value) } }


easing : Easing -> AnimBuilder mode -> AnimBuilder mode
easing easingValue (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data
            | defaults =
                { defs
                    | globalEasing = Just easingValue
                    , globalSpring = Nothing
                }
        }


spring : Spring -> AnimBuilder mode -> AnimBuilder mode
spring springValue (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data
            | defaults =
                { defs
                    | globalSpring = Just springValue
                    , globalEasing = Nothing
                }
        }


delay : Int -> AnimBuilder mode -> AnimBuilder mode
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


transformOrder : List TransformProperty -> AnimBuilder mode -> AnimBuilder mode
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


for : String -> AnimBuilder mode -> AnimBuilder mode
for elementId (AnimBuilder data) =
    let
        anim =
            data.animation
    in
    AnimBuilder
        { data | animation = { anim | currentAnimGroup = Just elementId } }


{-| Get the current (most recent) animation for a group.
-}
getCurrentAnimationConfig : AnimGroupName -> AnimBuilder mode -> Maybe ProcessedAnimGroupConfig
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
iterations : Int -> AnimBuilder mode -> AnimBuilder mode
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
loopForever : AnimBuilder mode -> AnimBuilder mode
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
alternate : AnimBuilder mode -> AnimBuilder mode
alternate (AnimBuilder data) =
    let
        pb =
            data.playback
    in
    AnimBuilder { data | playback = { pb | animationDirection = Alternate } }


{-| Check if discrete transitions are enabled for this animation.
-}
discreteTransitionsEnabled : AnimBuilder mode -> Bool
discreteTransitionsEnabled (AnimBuilder data) =
    data.playback.discreteTransitions


{-| Add a discrete CSS property for entry animations.

The value is applied when the animation starts, ensuring the element is
immediately in the target state.

    discreteEntry "display" "block"

-}
discreteEntry : String -> String -> AnimBuilder mode -> AnimBuilder mode
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
discreteExit : String -> String -> String -> AnimBuilder mode -> AnimBuilder mode
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
getDiscreteEntryProperties : AnimBuilder mode -> Dict String String
getDiscreteEntryProperties (AnimBuilder data) =
    data.playback.discreteEntryProperties


{-| Get the discrete exit properties for keyframe animations.
-}
getDiscreteExitProperties : AnimBuilder mode -> Dict String DiscreteExitProperty
getDiscreteExitProperties (AnimBuilder data) =
    data.playback.discreteExitProperties


{-| Get the configured iteration count.
-}
getIterations : AnimBuilder mode -> Iterations
getIterations (AnimBuilder data) =
    data.playback.iterations


{-| Get the configured animation direction.
-}
getAnimationDirection : AnimBuilder mode -> AnimationDirection
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
freezeAxes : List String -> List FreezeProperty -> AnimBuilder mode -> AnimBuilder mode
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
unfreezeAxes : List String -> List FreezeProperty -> AnimBuilder mode -> AnimBuilder mode
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
getFrozenAxes : String -> AnimBuilder mode -> List String
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


getAnimGroups : AnimBuilder mode -> AnimGroups AnimGroupConfig
getAnimGroups (AnimBuilder data) =
    data.animation.animGroups


{-| The name of the animGroup the next pipeline step will configure, set
by `for` / `forContinuing`. `Nothing` before any `for` call.
-}
getCurrentAnimGroupName : AnimBuilder mode -> Maybe AnimGroupName
getCurrentAnimGroupName (AnimBuilder data) =
    data.animation.currentAnimGroup


getCurrentAnimGroupConfig : AnimBuilder mode -> AnimGroupConfig
getCurrentAnimGroupConfig (AnimBuilder data) =
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


getAnimGroupConfig : AnimGroupName -> AnimBuilder mode -> Maybe AnimGroupConfig
getAnimGroupConfig animGroupName (AnimBuilder data) =
    AnimGroups.get animGroupName data.animation.animGroups


{-| Get baseline states for a group.
Baselines reflect the last known property values - either animation targets
or runtime snapshots from active animations.
-}
getBaseline : String -> AnimBuilder mode -> Maybe PropertyBaselines
getBaseline key (AnimBuilder data) =
    AnimGroups.get key data.state.baselines


getRuntimeBaseline : String -> AnimBuilder mode -> Maybe PropertyBaselines
getRuntimeBaseline key (AnimBuilder data) =
    AnimGroups.get key data.state.runtimeBaselines


getTransformOrder : AnimGroupName -> AnimBuilder mode -> Maybe (List TransformProperty)
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


getTimeSpec : AnimBuilder mode -> Maybe TimeSpec
getTimeSpec (AnimBuilder data) =
    data.defaults.globalTiming


{-| Get TimeSpec with default fallback.
-}
getTimeSpecWithDefault : AnimBuilder mode -> TimeSpec
getTimeSpecWithDefault (AnimBuilder data) =
    data.defaults.globalTiming |> Maybe.withDefault (Duration 0)


getEasing : AnimBuilder mode -> Maybe Easing
getEasing (AnimBuilder data) =
    data.defaults.globalEasing


{-| Get the global default Spring (if any).
-}
getSpring : AnimBuilder mode -> Maybe Spring
getSpring (AnimBuilder data) =
    data.defaults.globalSpring


{-| Get Easing with default fallback.
-}
getEasingWithDefault : AnimBuilder mode -> Easing
getEasingWithDefault (AnimBuilder data) =
    data.defaults.globalEasing |> Maybe.withDefault QuintOut


getDelay : AnimBuilder mode -> Maybe Int
getDelay (AnimBuilder data) =
    data.defaults.globalDelay


{-| Get Delay with default fallback.
-}
getDelayWithDefault : AnimBuilder mode -> Int
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
injectCurrentStates : AnimGroups { a | propertySnapshot : PropertyBaselines } -> AnimBuilder mode -> AnimBuilder mode
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


{-| Inject the set of currently-running property keys per animGroup.

Engines call this from their `retarget` function to tell per-property
`continueFor` resolvers which property animations are still in flight.
The set is cleared by `clearAnimData` after the pipeline runs, so it
lives only for the duration of one pipeline invocation.

-}
injectRunningProperties : Dict AnimGroupName (Set String) -> AnimBuilder mode -> AnimBuilder mode
injectRunningProperties running (AnimBuilder data) =
    let
        state =
            data.state
    in
    AnimBuilder
        { data
            | state = { state | runningProperties = running }
        }


{-| True when the named property type is currently running on the given
animGroup, as reported by the most recent `injectRunningProperties` call.
-}
isPropertyRunning : AnimGroupName -> String -> AnimBuilder mode -> Bool
isPropertyRunning animGroupName propertyKey (AnimBuilder data) =
    Dict.get animGroupName data.state.runningProperties
        |> Maybe.map (Set.member propertyKey)
        |> Maybe.withDefault False


{-| Get a clamp range for a (animGroup, propertyKey, axis) triple, if any.
-}
getClamp : AnimGroupName -> String -> String -> AnimBuilder mode -> Maybe ( Float, Float )
getClamp animGroupName propertyKey axis (AnimBuilder data) =
    Dict.get ( animGroupName, propertyKey, axis ) data.state.propertyClamps


{-| Set a clamp range. Bounds are normalised so the smaller value becomes
the lower bound regardless of argument order.
-}
setClamp : AnimGroupName -> String -> String -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
setClamp animGroupName propertyKey axis lo hi (AnimBuilder data) =
    let
        state =
            data.state

        nextDict =
            Dict.insert ( animGroupName, propertyKey, axis ) (orderedRange lo hi) state.propertyClamps
    in
    AnimBuilder { data | state = { state | propertyClamps = nextDict } }


{-| Remove a clamp range for a (animGroup, propertyKey, axis) triple.
-}
clearClamp : AnimGroupName -> String -> String -> AnimBuilder mode -> AnimBuilder mode
clearClamp animGroupName propertyKey axis (AnimBuilder data) =
    let
        state =
            data.state

        nextDict =
            Dict.remove ( animGroupName, propertyKey, axis ) state.propertyClamps
    in
    AnimBuilder { data | state = { state | propertyClamps = nextDict } }


orderedRange : Float -> Float -> ( Float, Float )
orderedRange a b =
    if a <= b then
        ( a, b )

    else
        ( b, a )


clearAnimData : AnimBuilder mode -> AnimBuilder mode
clearAnimData (AnimBuilder data) =
    let
        pb =
            data.playback

        st =
            data.state
    in
    AnimBuilder
        { data
            | animation = initAnimation
            , playback =
                { pb
                    | discreteEntryProperties = Dict.empty
                    , discreteExitProperties = Dict.empty
                }
            , state = { st | runningProperties = Dict.empty }
        }


mergeBaselines : AnimBuilder mode -> AnimBuilder mode
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

        PerspectiveOriginConfig cfg ->
            PropertyBaselines.setPerspectiveOrigin cfg.end baselines

        SizeConfig cfg ->
            PropertyBaselines.setSize cfg.end baselines

        CustomPropertyConfig cssName unit cfg ->
            PropertyBaselines.setCustomProperty cssName cfg.end unit baselines

        CustomColorPropertyConfig cssName cfg ->
            PropertyBaselines.setCustomColorProperty cssName cfg.end baselines


updateCurrentConfig : AnimGroupConfig -> AnimBuilder mode -> AnimBuilder mode
updateCurrentConfig config (AnimBuilder data) =
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

        PerspectiveOriginConfig _ ->
            "perspectiveOrigin"

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


{-| Get the type tag of a ProcessedPropertyConfig. Mirrors `propertyType`
but for the post-process variant. The returned string matches the keys
used by `injectRunningProperties` / `isPropertyRunning`.
-}
processedPropertyType : ProcessedPropertyConfig -> String
processedPropertyType prop =
    case prop of
        ProcessedCustomPropertyConfig cssName _ _ ->
            "custom:" ++ cssName

        ProcessedCustomColorPropertyConfig cssName _ ->
            "customColor:" ++ cssName

        ProcessedOpacityConfig _ ->
            "opacity"

        ProcessedPerspectiveOriginConfig _ ->
            "perspectiveOrigin"

        ProcessedRotateConfig _ ->
            "rotate"

        ProcessedScaleConfig _ ->
            "scale"

        ProcessedSizeConfig _ ->
            "size"

        ProcessedSkewConfig _ ->
            "skew"

        ProcessedTranslateConfig _ ->
            "translate"



-- ============================================================
-- PROCESSING
-- Resolving raw AnimBuilder configuration into engine-ready
-- ProcessedAnimationData with concrete timing, easing, and
-- delay values.
-- ============================================================


process : AnimBuilder mode -> ProcessedAnimationData
process (AnimBuilder data) =
    { globalTiming = data.defaults.globalTiming
    , globalEasing = data.defaults.globalEasing
    , globalSpring = data.defaults.globalSpring
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
                    , defaultStart = Color.transparent
                    , distanceFn = Color.distance
                    , durationFn = Color.duration
                    , speedFn = Color.speed
                    , wrapper = ProcessedCustomColorPropertyConfig cssName
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

        PerspectiveOriginConfig config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , defaultStart = PerspectiveOrigin.default
                    , distanceFn = PerspectiveOrigin.distance
                    , durationFn = PerspectiveOrigin.duration
                    , speedFn = PerspectiveOrigin.speed
                    , wrapper = ProcessedPerspectiveOriginConfig
                    }

        RotateConfig config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , defaultStart = Rotate.default
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
                    , defaultStart = Scale.default
                    , distanceFn = Scale.distance
                    , durationFn = Scale.duration
                    , speedFn = Scale.speed
                    , wrapper = ProcessedScaleConfig
                    }

        SizeConfig config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , defaultStart = Size.default
                    , distanceFn = Size.distance
                    , durationFn = Size.duration
                    , speedFn = Size.speed
                    , wrapper = ProcessedSizeConfig
                    }

        SkewConfig config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , defaultStart = Skew.default
                    , distanceFn = Skew.distance
                    , durationFn = Skew.duration
                    , speedFn = Skew.speed
                    , wrapper = ProcessedSkewConfig
                    }

        TranslateConfig config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , defaultStart = Translate.default
                    , distanceFn = Translate.distance
                    , durationFn = Translate.duration
                    , speedFn = Translate.speed
                    , wrapper = ProcessedTranslateConfig
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

        rawDuration =
            durationFn distance_ resolvedTiming

        resolvedSpring =
            case config.spring of
                Just s ->
                    Just s

                Nothing ->
                    globalData.globalSpring

        duration_ =
            case resolvedSpring of
                Just s ->
                    SpringSolver.settleTimeMs
                        { spring = SpringInt.unwrap s
                        , from = 0
                        , to = 1
                        }

                Nothing ->
                    rawDuration

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
        , spring = resolvedSpring
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
addAnimationToHistory : ProcessedAnimationData -> AnimBuilder mode -> AnimBuilder mode
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



-- ============================================================
-- SCROLL-DRIVEN ANIMATION
-- Setters and getters for scroll/view timeline configuration.
-- ============================================================


{-| Set the scroll source element ID, transitioning the builder into scroll mode.
The `newMode` type parameter is left open so callers can specialise it to a phantom
mode record (e.g. `{ isScrollBased : () }`).
-}
setScrollSource : String -> AnimBuilder mode -> AnimBuilder newMode
setScrollSource source (AnimBuilder data) =
    let
        sd =
            data.scrollDriven
    in
    AnimBuilder { data | scrollDriven = { sd | source = Just source } }


{-| Set the scroll/view axis ("block" or "inline") without changing the phantom mode.
-}
setScrollAxis : String -> AnimBuilder mode -> AnimBuilder mode
setScrollAxis axisStr (AnimBuilder data) =
    let
        sd =
            data.scrollDriven
    in
    AnimBuilder { data | scrollDriven = { sd | axis = Just axisStr } }


{-| Set the target selector key for the current animation group.
For timeline engines this decouples animation group names from DOM lookup ids.
-}
setAnimTarget : String -> AnimBuilder mode -> AnimBuilder mode
setAnimTarget targetId (AnimBuilder data) =
    case data.animation.currentAnimGroup of
        Nothing ->
            AnimBuilder data

        Just animGroupName ->
            let
                sd =
                    data.scrollDriven
            in
            AnimBuilder
                { data
                    | scrollDriven =
                        { sd
                            | targets =
                                AnimGroups.insert animGroupName targetId sd.targets
                        }
                }


{-| Transition the builder into view mode without storing any data.
The `newMode` type parameter is left open so callers can specialise it to a phantom
mode record (e.g. `{ isViewBased : () }`).
-}
transitionMode : AnimBuilder mode -> AnimBuilder newMode
transitionMode (AnimBuilder data) =
    AnimBuilder data


{-| Set the ViewTimeline rangeStart value without changing the phantom mode.
-}
setViewRangeStart : String -> AnimBuilder mode -> AnimBuilder mode
setViewRangeStart range (AnimBuilder data) =
    let
        sd =
            data.scrollDriven
    in
    AnimBuilder { data | scrollDriven = { sd | viewRangeStart = Just range } }


{-| Set the ViewTimeline rangeEnd value without changing the phantom mode.
-}
setViewRangeEnd : String -> AnimBuilder mode -> AnimBuilder mode
setViewRangeEnd range (AnimBuilder data) =
    let
        sd =
            data.scrollDriven
    in
    AnimBuilder { data | scrollDriven = { sd | viewRangeEnd = Just range } }


{-| Get the scroll source element ID (for ScrollTimeline).
-}
getScrollSource : AnimBuilder mode -> Maybe String
getScrollSource (AnimBuilder data) =
    data.scrollDriven.source


{-| Get the timeline target id for an animation group, if explicitly set.
-}
getAnimTarget : AnimGroupName -> AnimBuilder mode -> Maybe String
getAnimTarget animGroupName (AnimBuilder data) =
    AnimGroups.get animGroupName data.scrollDriven.targets


{-| Get the scroll/view axis string ("block" or "inline").
-}
getScrollAxis : AnimBuilder mode -> Maybe String
getScrollAxis (AnimBuilder data) =
    data.scrollDriven.axis


{-| Get the ViewTimeline rangeStart value.
-}
getViewRangeStart : AnimBuilder mode -> Maybe String
getViewRangeStart (AnimBuilder data) =
    data.scrollDriven.viewRangeStart


{-| Get the ViewTimeline rangeEnd value.
-}
getViewRangeEnd : AnimBuilder mode -> Maybe String
getViewRangeEnd (AnimBuilder data) =
    data.scrollDriven.viewRangeEnd
