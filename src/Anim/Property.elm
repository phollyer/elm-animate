module Anim.Property exposing
    ( Builder, AnimGroupName
    , init
    , for, build
    , from
    , to
    , delay, duration, speed
    , easing
    )

{-| Animate any numeric CSS property with a unit.

This is an escape hatch for CSS properties not covered by the first-class
property modules (Translate, Rotate, Scale, Opacity, etc.).

    import Anim.Extra.Easing exposing (Easing(..))
    import Anim.Property as Property

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Property.for "box" "border-radius" "px"
            >> Property.to 16
            >> Property.duration 300
            >> Property.easing EaseInOut
            >> Property.build


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
import Anim.Internal.Property as Internal



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Type alias for the internal `CustomPropertyBuilder`.
-}
type alias Builder =
    Internal.CustomPropertyBuilder



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Set the initial value for a custom CSS property.

Use this to initialize the property in your Engine's `init` function.

    import Anim.Engine.* as Engine
    import Anim.Property as Property

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState =
                Engine.init
                    [ Property.init "box" "border-radius" "px" 0 ]
          }
        , Cmd.none
        )

-}
init : AnimGroupName -> String -> String -> Float -> AnimBuilder -> AnimBuilder
init animGroupName cssPropertyName unit value animBuilder =
    animBuilder
        |> Internal.for animGroupName cssPropertyName unit
        |> Internal.from value
        |> Internal.to value
        |> Internal.build



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a custom property animation `Builder`.

The first argument is the animation group name, the second is the CSS property
name, and the third is the CSS unit.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Property.for "box" "border-radius" "px"
            >> Property.to 16
            >> Property.build

-}
for : AnimGroupName -> String -> String -> AnimBuilder -> Builder
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


{-| Set the starting value.
-}
from : Float -> Builder -> Builder
from =
    Internal.from



-- ============================================================
-- TO
-- ============================================================


{-| Set the target value.
-}
to : Float -> Builder -> Builder
to =
    Internal.to



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the animation speed (units per second).
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
