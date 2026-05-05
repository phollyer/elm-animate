module Anim.Internal.Engine.WAAPI.ViewTimeline exposing (AnimMsg(..))

import Json.Decode as Decode


type AnimMsg
    = JavascriptUpdate Decode.Value
