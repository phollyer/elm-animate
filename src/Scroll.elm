module Scroll exposing
    ( Config
    , defaultConfig
    , Timing(..)
    , XOffsetFloat, YOffsetFloat
    , Axis(..)
    )

{-| Shared types for smooth scrolling animations.

This module provides the common types used by all `Scroll.*.Cmd` and `Scroll.*.Task` modules.

For actual scrolling functionality, import one of:

  - `Scroll.*.Cmd` for command-based API
  - `Scroll.*.Task` for task-based API with error handling


# Configuration

@docs Config
@docs defaultConfig


## Timing

@docs Timing


## Axis

@docs XOffsetFloat, YOffsetFloat
@docs Axis

-}

import Ease exposing (..)



-- TYPE ALIASES FOR CORE TYPES


{-| Type alias for horizontal offset values in pixels.
-}
type alias XOffsetFloat =
    Float


{-| Type alias for vertical offset values in pixels.
-}
type alias YOffsetFloat =
    Float



-- MODULE TYPES


{-| Animation timing configuration.

Choose between speed-based or duration-based timing:

  - Speed: Animation speed in pixels per second (higher = faster)
  - Duration: Animation duration in milliseconds (higher = slower)

-}
type Timing
    = Speed Float
    | Duration Int


{-| Configuration for scrolling.

  - **timing**: Animation timing (Speed in pixels per second or Duration in milliseconds). Default is `Duration 400`.
  - **easing**: Easing function from [elm-community/easing-functions](https://package.elm-lang.org/packages/elm-community/easing-functions/latest/). Default is [Ease.outQuint](https://package.elm-lang.org/packages/elm-community/easing-functions/latest/Ease#outQuint).
  - **axis**: Movement axis with optional offsets. Default is `YWithOffset 12`.

-}
type alias Config =
    { timing : Timing
    , easing : Ease.Easing
    , axis : Axis
    }


{-| Axis configuration for animation movement direction with optional offsets.

Use this to control whether your animation moves horizontally or vertically, and specify any offsets:

  - `Y` - Vertical scrolling (most common)
  - `X` - Horizontal scrolling (for sideways carousels or horizontal content)
  - `Both` - Both horizontal and vertical scrolling to reach the target element
  - `YWithOffset YOffsetFloat` - Vertical scrolling with vertical offset in pixels
  - `XWithOffset XOffsetFloat` - Horizontal scrolling with horizontal offset in pixels
  - `BothWithOffset XOffsetFloat YOffsetFloat` - Both axes scrolling with horizontal and vertical offsets

-}
type Axis
    = X
    | Y
    | Both
    | YWithOffset YOffsetFloat
    | XWithOffset XOffsetFloat
    | BothWithOffset XOffsetFloat YOffsetFloat


{-| The default configuration which you can customize as needed.

    import Ease
    import SmoothMoveScroll exposing (Axis(..), Timing(..), defaultConfig)

    customConfig =
        { defaultConfig
            | timing = Duration 500
            , easing = Ease.inOutCubic
            , axis = BothWithOffset 10.0 20.0
        }

-}
defaultConfig : Config
defaultConfig =
    { timing = Duration 400
    , easing = Ease.outQuint
    , axis = YWithOffset 12.0
    }
