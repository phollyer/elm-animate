module Anim.Internal.Engine.Animation.CSS.TransitionGenerator exposing
    ( AnimGroup
    , AnimGroupName
    )

import Anim.Internal.Engine.Animation.CSS.Styles exposing (Styles)


type alias AnimGroupName =
    String


type alias AnimGroup =
    { styles : Styles
    }
