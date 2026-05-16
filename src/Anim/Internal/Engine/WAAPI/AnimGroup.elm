module Anim.Internal.Engine.WAAPI.AnimGroup exposing
    ( AnimGroup
    , AnimationStatus(..)
    , AxisProportion
    , PropertyState
    , ResizeAxisState
    , Vec3
    , addPropertyStates
    , bumpPropertyVersions
    , emptyProportion
    , getAnimationDirection
    , getCurrentIteration
    , getCurrentScaleState
    , getCurrentTranslateState
    , getDiscreteEntry
    , getDiscreteExit
    , getIterations
    , getProgress
    , getPropertySnapshot
    , getPropertyStates
    , getTransformOrder
    , init
    , isComplete
    , isPaused
    , isRunning
    , setAnimationDirection
    , setCurrentIteration
    , setCurrentScaleState
    , setCurrentTranslateState
    , setDiscreteEntry
    , setDiscreteExit
    , setIterationCount
    , setProgress
    , setPropertyStates
    , setScaleProportion
    , setSnapshot
    , setStatus
    , setTransformOrder
    , setTranslateProportion
    )

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty(..))
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups exposing (AnimGroups)
import Dict exposing (Dict)



-- ============================================================
-- TYPES
-- ============================================================


type AnimGroup
    = AnimGroup
        { propertySnapshot : PropertyBaselines
        , propertyStates : AnimGroups PropertyState -- Tracks version and status per property type ("position", "opacity", etc.)
        , transformOrder : List TransformProperty -- Order to apply transforms (default: Translate → Rotate → Scale)
        , progress : Float -- Current animation progress (0.0 to 1.0)
        , iterations : Builder.Iterations
        , currentIteration : Int -- Latest iteration index reported by WAAPI (0 = first leg)
        , currentTranslateState : Maybe ResizeAxisState -- Latest resize-updated translate bounds, duration & per-axis proportion snapshot; Nothing on a fresh `animate` call
        , currentScaleState : Maybe ResizeAxisState -- Latest resize-updated scale bounds, duration & per-axis proportion snapshot; Nothing on a fresh `animate` call
        , animationDirection : Builder.AnimationDirection
        , discreteEntry : Dict String Builder.DiscreteEntryProperty
        , discreteExit : Dict String Builder.DiscreteExitProperty
        }


type alias PropertyState =
    { version : Int
    , status : AnimationStatus
    }


type alias Vec3 =
    { x : Float, y : Float, z : Float }


{-| Per-axis forward-axis proportion snapshot (0 = at `b.min`, 1 = at
`b.max`, regardless of animation direction). `Nothing` on an axis means
no snapshot exists yet — the resize handler falls back to the legacy
absolute-pixel `(oldCurrent - oldMin) / oldRange` derivation for that
axis.
-}
type alias AxisProportion =
    { x : Maybe Float, y : Maybe Float, z : Maybe Float }


{-| Resize-aware leg state shared by translate and scale. `proportion`
is the single source of truth for "where on the leg are we" across
resize round-trips; `start`/`end`/`durationMs` are the resize-rebased
leg endpoints and timing used to feed WAAPI on the next resize.
-}
type alias ResizeAxisState =
    { start : Vec3
    , end : Vec3
    , durationMs : Float
    , proportion : AxisProportion
    }


emptyProportion : AxisProportion
emptyProportion =
    { x = Nothing, y = Nothing, z = Nothing }


type AnimationStatus
    = NotStarted
    | Running
    | Paused
    | Complete



-- ============================================================
-- INITIALIZE
-- ============================================================


init : AnimGroup
init =
    AnimGroup
        { propertySnapshot = PropertyBaselines.empty
        , propertyStates = AnimGroups.init
        , transformOrder = TransformProperty.default
        , progress = 0
        , iterations = Builder.Once
        , currentIteration = 0
        , currentTranslateState = Nothing
        , currentScaleState = Nothing
        , animationDirection = Builder.Normal
        , discreteEntry = Dict.empty
        , discreteExit = Dict.empty
        }



-- ============================================================
-- QUERIES
-- ============================================================


isRunning : AnimGroup -> Bool
isRunning =
    getPropertyStates
        >> AnimGroups.groups
        >> List.any (\prop -> prop.status == Running)


isComplete : AnimGroup -> Bool
isComplete =
    getPropertyStates
        >> AnimGroups.groups
        >> List.all (\prop -> prop.status == Complete)


isPaused : AnimGroup -> Bool
isPaused =
    getPropertyStates
        >> AnimGroups.groups
        >> List.any (\prop -> prop.status == Paused)



-- ============================================================
-- GETTERS
-- ============================================================


getAnimationDirection : AnimGroup -> Builder.AnimationDirection
getAnimationDirection (AnimGroup group) =
    group.animationDirection


getCurrentIteration : AnimGroup -> Int
getCurrentIteration (AnimGroup group) =
    group.currentIteration


getCurrentTranslateState : AnimGroup -> Maybe ResizeAxisState
getCurrentTranslateState (AnimGroup group) =
    group.currentTranslateState


getCurrentScaleState : AnimGroup -> Maybe ResizeAxisState
getCurrentScaleState (AnimGroup group) =
    group.currentScaleState


getDiscreteEntry : AnimGroup -> Dict String Builder.DiscreteEntryProperty
getDiscreteEntry (AnimGroup group) =
    group.discreteEntry


getDiscreteExit : AnimGroup -> Dict String Builder.DiscreteExitProperty
getDiscreteExit (AnimGroup group) =
    group.discreteExit


getIterations : AnimGroup -> Builder.Iterations
getIterations (AnimGroup group) =
    group.iterations


getProgress : AnimGroup -> Float
getProgress (AnimGroup group) =
    group.progress


getPropertySnapshot : AnimGroup -> PropertyBaselines
getPropertySnapshot (AnimGroup group) =
    group.propertySnapshot


getPropertyStates : AnimGroup -> AnimGroups PropertyState
getPropertyStates (AnimGroup group) =
    group.propertyStates


getTransformOrder : AnimGroup -> List TransformProperty
getTransformOrder (AnimGroup group) =
    group.transformOrder



-- ============================================================
-- SETTERS
-- ============================================================


setAnimationDirection : Builder.AnimationDirection -> AnimGroup -> AnimGroup
setAnimationDirection direction (AnimGroup group) =
    AnimGroup { group | animationDirection = direction }


setCurrentIteration : Int -> AnimGroup -> AnimGroup
setCurrentIteration currentIteration (AnimGroup group) =
    AnimGroup { group | currentIteration = currentIteration }


setCurrentTranslateState : ResizeAxisState -> AnimGroup -> AnimGroup
setCurrentTranslateState newState (AnimGroup group) =
    AnimGroup { group | currentTranslateState = Just newState }


setCurrentScaleState : ResizeAxisState -> AnimGroup -> AnimGroup
setCurrentScaleState newState (AnimGroup group) =
    AnimGroup { group | currentScaleState = Just newState }


{-| Update _only_ the per-axis proportion snapshot of the cached
translate state, leaving `start`/`end`/`durationMs` untouched. A no-op
if no translate state has been cached yet (animation hasn't reported a
first frame).
-}
setTranslateProportion : AxisProportion -> AnimGroup -> AnimGroup
setTranslateProportion proportion (AnimGroup group) =
    case group.currentTranslateState of
        Just state ->
            AnimGroup
                { group | currentTranslateState = Just { state | proportion = proportion } }

        Nothing ->
            AnimGroup group


{-| Update _only_ the per-axis proportion snapshot of the cached scale
state, leaving `start`/`end`/`durationMs` untouched. A no-op if no
scale state has been cached yet.
-}
setScaleProportion : AxisProportion -> AnimGroup -> AnimGroup
setScaleProportion proportion (AnimGroup group) =
    case group.currentScaleState of
        Just state ->
            AnimGroup
                { group | currentScaleState = Just { state | proportion = proportion } }

        Nothing ->
            AnimGroup group


setDiscreteEntry : Dict String Builder.DiscreteEntryProperty -> AnimGroup -> AnimGroup
setDiscreteEntry entry (AnimGroup group) =
    AnimGroup { group | discreteEntry = entry }


setDiscreteExit : Dict String Builder.DiscreteExitProperty -> AnimGroup -> AnimGroup
setDiscreteExit exit (AnimGroup group) =
    AnimGroup { group | discreteExit = exit }


setIterationCount : Builder.Iterations -> AnimGroup -> AnimGroup
setIterationCount iterations (AnimGroup group) =
    AnimGroup { group | iterations = iterations }


setProgress : Float -> AnimGroup -> AnimGroup
setProgress progress (AnimGroup group) =
    AnimGroup { group | progress = progress }


setPropertyStates : AnimGroups PropertyState -> AnimGroup -> AnimGroup
setPropertyStates propertyStates (AnimGroup group) =
    AnimGroup { group | propertyStates = propertyStates }


setSnapshot : PropertyBaselines -> AnimGroup -> AnimGroup
setSnapshot snapshot (AnimGroup group) =
    AnimGroup { group | propertySnapshot = snapshot }


setStatus : AnimationStatus -> AnimGroup -> AnimGroup
setStatus newStatus (AnimGroup group) =
    AnimGroup
        { group
            | propertyStates =
                AnimGroups.map
                    (\_ propAnim -> { propAnim | status = newStatus })
                    group.propertyStates
        }


setTransformOrder : List TransformProperty -> AnimGroup -> AnimGroup
setTransformOrder order (AnimGroup group) =
    AnimGroup { group | transformOrder = order }



-- ============================================================
-- HELPERS
-- ============================================================


addPropertyStates : AnimGroup -> AnimGroup -> AnimGroup
addPropertyStates (AnimGroup newGroup) (AnimGroup existingGroup) =
    AnimGroup
        { newGroup
            | propertyStates = AnimGroups.union newGroup.propertyStates existingGroup.propertyStates
        }


bumpPropertyVersions : List String -> AnimGroup -> AnimGroup
bumpPropertyVersions props (AnimGroup group) =
    AnimGroup
        { group
            | propertyStates =
                AnimGroups.map
                    (\propType propAnim ->
                        if List.member propType props then
                            { propAnim
                                | version = propAnim.version + 1
                                , status = NotStarted
                            }

                        else
                            propAnim
                    )
                    group.propertyStates
        }
