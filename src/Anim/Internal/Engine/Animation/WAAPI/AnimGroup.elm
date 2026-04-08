module Anim.Internal.Engine.Animation.WAAPI.AnimGroup exposing
    ( AnimGroup
    , AnimationStatus(..)
    , PropertyAnimation
    , PropertySnapshot
    , emptySnapshot
    , init
    , setSnpashot
    )

import Anim.Extra.TransformOrder as TransformOrder exposing (TransformOrder(..))
import Anim.Internal.Engine.Animation.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Extra.Color exposing (Color(..))
import Anim.Internal.Property.Opacity exposing (Opacity)
import Anim.Internal.Property.Rotate exposing (Rotate)
import Anim.Internal.Property.Scale exposing (Scale)
import Anim.Internal.Property.Size exposing (Size)
import Anim.Internal.Property.Translate exposing (Translate)


type alias AnimGroup =
    { propertySnapshot : PropertySnapshot -- Updated by JavaScript during playback
    , properties : AnimGroups PropertyAnimation -- Tracks version and status per property type ("position", "opacity", etc.)
    , transformOrder : List TransformOrder -- Order to apply transforms (default: Translate → Rotate → Scale)
    , progress : Float -- Current animation progress (0.0 to 1.0)
    }


init : AnimGroup
init =
    { propertySnapshot = emptySnapshot
    , properties = AnimGroups.init
    , transformOrder = TransformOrder.default
    , progress = 0
    }


setSnpashot : PropertySnapshot -> AnimGroup -> AnimGroup
setSnpashot snapshot group =
    { group | propertySnapshot = snapshot }


type alias PropertyAnimation =
    { version : Int
    , status : AnimationStatus
    }


type AnimationStatus
    = NotStarted
    | Running
    | Paused
    | Complete


type alias PropertySnapshot =
    { translate : Maybe Translate
    , rotate : Maybe Rotate
    , scale : Maybe Scale
    , backgroundColor : Maybe Color
    , fontColor : Maybe Color
    , opacity : Maybe Opacity
    , size : Maybe Size
    }


emptySnapshot : PropertySnapshot
emptySnapshot =
    { translate = Nothing
    , rotate = Nothing
    , scale = Nothing
    , backgroundColor = Nothing
    , fontColor = Nothing
    , opacity = Nothing
    , size = Nothing
    }
