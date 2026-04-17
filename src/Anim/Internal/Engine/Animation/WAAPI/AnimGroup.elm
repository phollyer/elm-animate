module Anim.Internal.Engine.Animation.WAAPI.AnimGroup exposing
    ( AnimGroup
    , AnimationStatus(..)
    , PropertyState
    , init
    , setDiscreteEntry
    , setDiscreteExit
    , setSnapshot
    )

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty(..))
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.Animation.AnimGroups as AnimGroups exposing (AnimGroups)
import Dict exposing (Dict)


type alias AnimGroup =
    { propertySnapshot : PropertyBaselines
    , propertyStates : AnimGroups PropertyState -- Tracks version and status per property type ("position", "opacity", etc.)
    , transformOrder : List TransformProperty -- Order to apply transforms (default: Translate → Rotate → Scale)
    , progress : Float -- Current animation progress (0.0 to 1.0)
    , iterations : Builder.Iterations
    , animationDirection : Builder.AnimationDirection
    , discreteEntry : Dict String Builder.DiscreteEntryProperty
    , discreteExit : Dict String Builder.DiscreteExitProperty
    }


init : AnimGroup
init =
    { propertySnapshot = PropertyBaselines.empty
    , propertyStates = AnimGroups.init
    , transformOrder = TransformProperty.default
    , progress = 0
    , iterations = Builder.Once
    , animationDirection = Builder.Normal
    , discreteEntry = Dict.empty
    , discreteExit = Dict.empty
    }


setSnapshot : PropertyBaselines -> AnimGroup -> AnimGroup
setSnapshot snapshot group =
    { group | propertySnapshot = snapshot }


setDiscreteEntry : Dict String Builder.DiscreteEntryProperty -> AnimGroup -> AnimGroup
setDiscreteEntry entry group =
    { group | discreteEntry = entry }


setDiscreteExit : Dict String Builder.DiscreteExitProperty -> AnimGroup -> AnimGroup
setDiscreteExit exit group =
    { group | discreteExit = exit }


type alias PropertyState =
    { version : Int
    , status : AnimationStatus
    }


type AnimationStatus
    = NotStarted
    | Running
    | Paused
    | Complete
