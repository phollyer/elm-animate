module Anim.Internal.Properties.BackgroundColor exposing (default)

import Anim.Internal.Properties.Color as Color exposing (Color)


default : Color
default =
    Color.fromRGBA { r = 255, g = 255, b = 255, a = 1 }
