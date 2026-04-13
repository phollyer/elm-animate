module Anim.Internal.Engine.Animation.Sub.AnimGroup exposing
    ( AnimGroup
    , addAnimation
    , getAnimations
    , init
    , setAnimations
    , setCurrentIteration
    , setDiscreteEntry
    , setDiscreteExit
    , setIsComplete
    , setIsPaused
    , setIterationCount
    , setTransformOrder
    )

import Anim.Extra.TransformOrder as TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder exposing (DiscreteKeyframeProperty, Iterations(..))
import Anim.Internal.Engine.Animation.Sub.Animations as Animations exposing (Animations)
import Dict exposing (Dict)


type alias AnimGroup =
    { animations : Animations
    , isComplete : Bool
    , isPaused : Bool
    , transformOrder : List TransformProperty
    , iterationCount : Iterations
    , currentIteration : Int
    , discreteEntry : Dict String String
    , discreteExit : Dict String DiscreteKeyframeProperty
    }


init : AnimGroup
init =
    { animations = Animations.init
    , isComplete = False
    , isPaused = False
    , transformOrder = TransformOrder.default
    , iterationCount = Once
    , currentIteration = 0
    , discreteEntry = Dict.empty
    , discreteExit = Dict.empty
    }


addAnimation : Animations -> AnimGroup -> AnimGroup
addAnimation additional group =
    { group | animations = Animations.add additional group.animations }


getAnimations : AnimGroup -> Animations
getAnimations group =
    group.animations


setCurrentIteration : Int -> AnimGroup -> AnimGroup
setCurrentIteration currentIteration group =
    { group | currentIteration = currentIteration }


setIsComplete : Bool -> AnimGroup -> AnimGroup
setIsComplete isComplete group =
    { group | isComplete = isComplete }


setIsPaused : Bool -> AnimGroup -> AnimGroup
setIsPaused isPaused group =
    { group | isPaused = isPaused }


setIterationCount : Iterations -> AnimGroup -> AnimGroup
setIterationCount iterationCount group =
    { group | iterationCount = iterationCount }


setAnimations : Animations -> AnimGroup -> AnimGroup
setAnimations animations group =
    { group | animations = animations }


setTransformOrder : List TransformProperty -> AnimGroup -> AnimGroup
setTransformOrder transformOrder group =
    { group | transformOrder = transformOrder }


setDiscreteEntry : Dict String String -> AnimGroup -> AnimGroup
setDiscreteEntry entry group =
    { group | discreteEntry = entry }


setDiscreteExit : Dict String DiscreteKeyframeProperty -> AnimGroup -> AnimGroup
setDiscreteExit exit group =
    { group | discreteExit = exit }
