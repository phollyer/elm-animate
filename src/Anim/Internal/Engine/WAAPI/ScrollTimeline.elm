module Anim.Internal.Engine.WAAPI.ScrollTimeline exposing (AnimMsg(..))

import Json.Decode as Decode


type AnimMsg
    = JavascriptUpdate Decode.Value
