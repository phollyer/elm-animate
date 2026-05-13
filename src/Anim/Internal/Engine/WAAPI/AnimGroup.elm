module Anim.Internal.Engine.WAAPI.AnimGroup exposing
    ( AnimGroup
    , AnimationStatus(..)
    , PropertyState
    , addPropertyStates
    , bumpPropertyVersions
    , getAnimationDirection
    , getCurrentIteration
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
    , isRunning
    , setAnimationDirection
    , setCurrentIteration
    , setCurrentTranslateState
    , setDiscreteEntry
    , setDiscreteExit
    , setIterationCount
    , setProgress
    , setPropertyStates
    , setSnapshot
    , setStatus
    , setTransformOrder
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
        , currentTranslateState : Maybe { start : { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float }, durationMs : Float } -- Latest resize-updated translate bounds & duration; Nothing on a fresh `animate` call
        , animationDirection : Builder.AnimationDirection
        , discreteEntry : Dict String Builder.DiscreteEntryProperty
        , discreteExit : Dict String Builder.DiscreteExitProperty
        }


type alias PropertyState =
    { version : Int
    , status : AnimationStatus
    }


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



-- ============================================================
-- GETTERS
-- ============================================================


getAnimationDirection : AnimGroup -> Builder.AnimationDirection
getAnimationDirection (AnimGroup group) =
    group.animationDirection


getCurrentIteration : AnimGroup -> Int
getCurrentIteration (AnimGroup group) =
    group.currentIteration


getCurrentTranslateState : AnimGroup -> Maybe { start : { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float }, durationMs : Float }
getCurrentTranslateState (AnimGroup group) =
    group.currentTranslateState


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


setCurrentTranslateState : { start : { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float }, durationMs : Float } -> AnimGroup -> AnimGroup
setCurrentTranslateState newState (AnimGroup group) =
    AnimGroup { group | currentTranslateState = Just newState }


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
