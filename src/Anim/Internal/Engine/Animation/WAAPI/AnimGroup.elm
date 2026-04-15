module Anim.Internal.Engine.Animation.WAAPI.AnimGroup exposing
    ( AnimGroup
    , AnimationStatus(..)
    , PropertyAnimation
    , init
    , setDiscreteEntry
    , setDiscreteExit
    , setSnapshot
    )

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty(..))
import Anim.Internal.Builder exposing (DiscreteExitProperty)
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.Animation.AnimGroups as AnimGroups exposing (AnimGroups)
import Dict exposing (Dict)


type alias AnimGroup =
    { propertySnapshot : PropertyBaselines
    , properties : AnimGroups PropertyAnimation -- Tracks version and status per property type ("position", "opacity", etc.)
    , transformOrder : List TransformProperty -- Order to apply transforms (default: Translate → Rotate → Scale)
    , progress : Float -- Current animation progress (0.0 to 1.0)
    , discreteEntry : Dict String String
    , discreteExit : Dict String DiscreteExitProperty
    }


init : AnimGroup
init =
    { propertySnapshot = PropertyBaselines.empty
    , properties = AnimGroups.init
    , transformOrder = TransformProperty.default
    , progress = 0
    , discreteEntry = Dict.empty
    , discreteExit = Dict.empty
    }


setSnapshot : PropertyBaselines -> AnimGroup -> AnimGroup
setSnapshot snapshot group =
    { group | propertySnapshot = snapshot }


setDiscreteEntry : Dict String String -> AnimGroup -> AnimGroup
setDiscreteEntry entry group =
    { group | discreteEntry = entry }


setDiscreteExit : Dict String DiscreteExitProperty -> AnimGroup -> AnimGroup
setDiscreteExit exit group =
    { group | discreteExit = exit }


type alias PropertyAnimation =
    { version : Int
    , status : AnimationStatus
    }


type AnimationStatus
    = NotStarted
    | Running
    | Paused
    | Complete
