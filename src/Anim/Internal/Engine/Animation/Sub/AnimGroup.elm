module Anim.Internal.Engine.Animation.Sub.AnimGroup exposing
    ( AnimGroup
    , addAnimation
    , getAnimations
    , getCurrentIteration
    , getDiscreteEntry
    , getDiscreteExit
    , getIterations
    , getTransformOrder
    , init
    , isComplete
    , isPaused
    , isRunning
    , setAnimations
    , setCurrentIteration
    , setDiscreteEntry
    , setDiscreteExit
    , setIsComplete
    , setIsPaused
    , setIterationCount
    , setTransformOrder
    )

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty)
import Anim.Internal.Builder exposing (DiscreteExitProperty, Iterations(..))
import Anim.Internal.Engine.Animation.Sub.Animations as Animations exposing (Animations)
import Dict exposing (Dict)


type AnimGroup
    = AnimGroup
        { animations : Animations
        , isComplete : Bool
        , isPaused : Bool
        , transformOrder : List TransformProperty
        , iterations : Iterations
        , currentIteration : Int
        , discreteEntry : Dict String String
        , discreteExit : Dict String DiscreteExitProperty
        }


init : AnimGroup
init =
    AnimGroup
        { animations = Animations.init
        , isComplete = False
        , isPaused = False
        , transformOrder = TransformProperty.default
        , iterations = Once
        , currentIteration = 0
        , discreteEntry = Dict.empty
        , discreteExit = Dict.empty
        }


addAnimation : Animations -> AnimGroup -> AnimGroup
addAnimation additional (AnimGroup group) =
    AnimGroup { group | animations = Animations.add additional group.animations }


getAnimations : AnimGroup -> Animations
getAnimations (AnimGroup group) =
    group.animations


getCurrentIteration : AnimGroup -> Int
getCurrentIteration (AnimGroup group) =
    group.currentIteration


getDiscreteEntry : AnimGroup -> Dict String String
getDiscreteEntry (AnimGroup group) =
    group.discreteEntry


getDiscreteExit : AnimGroup -> Dict String DiscreteExitProperty
getDiscreteExit (AnimGroup group) =
    group.discreteExit


getIterations : AnimGroup -> Iterations
getIterations (AnimGroup group) =
    group.iterations


getTransformOrder : AnimGroup -> List TransformProperty
getTransformOrder (AnimGroup group) =
    group.transformOrder


isComplete : AnimGroup -> Bool
isComplete (AnimGroup group) =
    group.isComplete


isPaused : AnimGroup -> Bool
isPaused (AnimGroup group) =
    group.isPaused


isRunning : AnimGroup -> Bool
isRunning (AnimGroup group) =
    not group.isComplete && not group.isPaused


setCurrentIteration : Int -> AnimGroup -> AnimGroup
setCurrentIteration currentIteration (AnimGroup group) =
    AnimGroup { group | currentIteration = currentIteration }


setIsComplete : Bool -> AnimGroup -> AnimGroup
setIsComplete complete (AnimGroup group) =
    AnimGroup { group | isComplete = complete }


setIsPaused : Bool -> AnimGroup -> AnimGroup
setIsPaused paused (AnimGroup group) =
    AnimGroup { group | isPaused = paused }


setIterationCount : Iterations -> AnimGroup -> AnimGroup
setIterationCount iterationCount (AnimGroup group) =
    AnimGroup { group | iterations = iterationCount }


setAnimations : Animations -> AnimGroup -> AnimGroup
setAnimations animations (AnimGroup group) =
    AnimGroup { group | animations = animations }


setTransformOrder : List TransformProperty -> AnimGroup -> AnimGroup
setTransformOrder transformOrder (AnimGroup group) =
    AnimGroup { group | transformOrder = transformOrder }


setDiscreteEntry : Dict String String -> AnimGroup -> AnimGroup
setDiscreteEntry entry (AnimGroup group) =
    AnimGroup { group | discreteEntry = entry }


setDiscreteExit : Dict String DiscreteExitProperty -> AnimGroup -> AnimGroup
setDiscreteExit exit (AnimGroup group) =
    AnimGroup { group | discreteExit = exit }
