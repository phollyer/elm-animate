module Anim.Internal.Engine.Animation.Sub.AnimGroup exposing
    ( AnimGroup
    , addAnimation
    , getAnimations
    , init
    , setAnimations
    , setCurrentIteration
    , setIsComplete
    , setIsPaused
    , setIterationCount
    , setTransformOrder
    )

import Anim.Extra.TransformOrder as TransformOrder exposing (TransformOrder)
import Anim.Internal.Builder exposing (Iterations(..))
import Anim.Internal.Engine.Animation.Sub.Animations as Animations exposing (Animations)


type alias AnimGroup =
    { animations : Animations
    , isComplete : Bool
    , isPaused : Bool
    , transformOrder : List TransformOrder
    , iterationCount : Iterations
    , currentIteration : Int
    }


init : AnimGroup
init =
    { animations = Animations.init
    , isComplete = False
    , isPaused = False
    , transformOrder = TransformOrder.default
    , iterationCount = Once
    , currentIteration = 0
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


setTransformOrder : List TransformOrder -> AnimGroup -> AnimGroup
setTransformOrder transformOrder group =
    { group | transformOrder = transformOrder }
