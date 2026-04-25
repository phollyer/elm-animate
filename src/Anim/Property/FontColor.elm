module Anim.Property.FontColor exposing
    ( Builder, AnimGroupName
    , init
    , for, build
    , from
    , to
    , delay, duration, speed
    , easing
    )

{-| Animate the font color of elements.

**Default**: opaque black

This property uses a 'sensible default' approach to configuring animations.
When no start value is available, the default will be used.

    import Anim.Extra.Color exposing (hex)
    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        FontColor.for "animGroupName"
            >> FontColor.to (hex "#ff0000")
            >> FontColor.duration 1000
            >> FontColor.easing EaseInOut
            >> FontColor.build

The Engines track the end value of each animation, so new animations with no start value
will use the current end value as the start, ensuring a smooth transition between animations.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs init


# Build

@docs for, build


# Configure


## Start Value

All engines track end values, so subsequent animations automatically
use the previous end as the new start. Use `from` to override this
behaviour and set an explicit start value.

**Note:** The Transition Engine ignores start values — the browser always computes
starting values from the current computed style.

@docs from


## End Value

@docs to


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Extra.Color exposing (Color(..))
import Anim.Internal.PropertyBuilder.FontColor as CB
import Easing exposing (Easing)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Type alias for the internal `ColorBuilder`.
-}
type alias Builder =
    CB.ColorBuilder



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Set the initial font color.

Use this to initialize the font color in your Engine's `init` function.

    import Anim.Extra.Color exposing (hex)
    import Anim.Engine.* as Engine
    import Anim.Property.FontColor as FontColor

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ FontColor.init "animGroupName" (hex "#ff0000") ] }
        , Cmd.none
        )

-}
init : AnimGroupName -> Color -> AnimBuilder -> AnimBuilder
init animationKey color animBuilder =
    animBuilder
        |> CB.for animationKey
        |> CB.init color
        |> CB.build



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a font color animation `Builder` for the specified animation group.

Use this to start configuring a font color animation.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        FontColor.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : AnimGroupName -> AnimBuilder -> Builder
for animationKey =
    CB.for animationKey


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        FontColor.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> FontColor.build
            >> ... -- continue with animation

-}
build : Builder -> AnimBuilder
build =
    CB.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting font color.

    import Anim.Extra.Color exposing (hex)

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        FontColor.for "animGroupName"
            >> FontColor.from (hex "#0000ff")
            >> ... -- continue with animation

-}
from : Color -> Builder -> Builder
from =
    CB.from



-- ============================================================
-- TO
-- ============================================================


{-| Set the target color for the current animation group.

    import Anim.Extra.Color exposing (hex)

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        FontColor.for "animGroupName"
            >> FontColor.to (hex "#0000ff")
            >> ... -- continue with animation

-}
to : Color -> Builder -> Builder
to =
    CB.to



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before the animation starts.

    import Anim.Extra.Color exposing (hex)

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        FontColor.for "animGroupName"
            >> FontColor.to (hex "#0000ff")
            >> FontColor.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder -> Builder
delay =
    CB.delay


{-| Set the animation duration (milliseconds).

    import Anim.Extra.Color exposing (hex)

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        FontColor.for "animGroupName"
            >> FontColor.to (hex "#0000ff")
            >> FontColor.duration 300
            >> ... -- continue with animation

-}
duration : Int -> Builder -> Builder
duration =
    CB.duration


{-| Set the animation speed.

The speed is calibrated so that `1.0` means the maximum possible color change
(black to white) takes 1 second. Most color changes will be faster since they
cover less distance in color space.

**Note:** For color animations, `duration` is usually more intuitive than `speed`.
Most folks would tend to think "this color change should take 300ms" rather than "this should
change at a specific rate". Consider using `duration` unless you specifically need
speed-based timing that adapts to color distance.

    import Anim.Extra.Color exposing (hex)

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        FontColor.for "animGroupName"
            >> FontColor.to (hex "#0000ff")
            >> FontColor.speed 0.5
            >> ... -- continue with animation

-}
speed : Float -> Builder -> Builder
speed =
    CB.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Anim.Extra.Color exposing (hex)
    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        FontColor.for "animGroupName"
            >> FontColor.to (hex "#0000ff")
            >> FontColor.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder -> Builder
easing =
    CB.easing
