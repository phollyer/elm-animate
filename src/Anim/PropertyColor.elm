module Anim.PropertyColor exposing
    ( Builder, AnimGroupName
    , init
    , for, build
    , from
    , to
    , delay, duration, speed
    , easing
    )

{-| Animate any color CSS property.

This is an escape hatch for color CSS properties not covered by the first-class
property modules (BackgroundColor, FontColor).

    import Anim.Extra.Color as Color
    import Anim.Extra.Easing exposing (Easing(..))
    import Anim.PropertyColor as PropertyColor

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        PropertyColor.for "box" "border-color"
            >> PropertyColor.to (Color.rgb 255 0 0)
            >> PropertyColor.duration 300
            >> PropertyColor.easing EaseInOut
            >> PropertyColor.build


# Types

@docs Builder, AnimGroupName


# Initialize

@docs init


# Build

@docs for, build


# Configure


## Start Value

@docs from


## End Value

@docs to


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Extra.Color exposing (Color)
import Anim.Internal.PropertyColor as Internal



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Type alias for the internal `CustomColorBuilder`.
-}
type alias Builder =
    Internal.CustomColorBuilder



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Set the initial value for a custom color CSS property.

Use this to initialize the property in your Engine's `init` function.

    import Anim.Engine.* as Engine
    import Anim.Extra.Color as Color
    import Anim.PropertyColor as PropertyColor

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState =
                Engine.init
                    [ PropertyColor.init "box" "border-color"
                        (Color.rgb 99 102 241)
                    ]
          }
        , Cmd.none
        )

-}
init : AnimGroupName -> String -> Color -> AnimBuilder -> AnimBuilder
init animGroupName cssPropertyName value animBuilder =
    animBuilder
        |> Internal.for animGroupName cssPropertyName
        |> Internal.from value
        |> Internal.to value
        |> Internal.build



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a custom color property animation `Builder`.

The first argument is the animation group name and the second is the CSS
property name.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        PropertyColor.for "box" "border-color"
            >> PropertyColor.to (Color.rgb 255 0 0)
            >> PropertyColor.build

-}
for : AnimGroupName -> String -> AnimBuilder -> Builder
for =
    Internal.for


{-| Complete the animation configuration and return an `AnimBuilder`.
-}
build : Builder -> AnimBuilder
build =
    Internal.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting color.
-}
from : Color -> Builder -> Builder
from =
    Internal.from



-- ============================================================
-- TO
-- ============================================================


{-| Set the target color.
-}
to : Color -> Builder -> Builder
to =
    Internal.to



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the animation speed (0.0 to 1.0 range per second).
-}
speed : Float -> Builder -> Builder
speed =
    Internal.speed


{-| Set the animation duration (milliseconds).
-}
duration : Int -> Builder -> Builder
duration =
    Internal.duration


{-| Set the delay (milliseconds) before the animation starts.
-}
delay : Int -> Builder -> Builder
delay =
    Internal.delay



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function.
-}
easing : Easing -> Builder -> Builder
easing =
    Internal.easing
