module Scroll exposing
    ( Config
    , defaultConfig
    , Axis(..)
    , Timing(..)
    , ElementId
    , Container(..)
    )

{-| Shared types for smooth scrolling animations.

This module provides the common types used by all `Scroll.*.Cmd` and `Scroll.*.Task` modules.

For actual scrolling functionality, import one of:

  - `Scroll.*.Cmd` for command-based API
  - `Scroll.*.Task` for task-based API with error handling


# Configuration

@docs Config
@docs defaultConfig
@docs Axis
@docs Timing
@docs ElementId
@docs Container

-}

import Ease exposing (..)


{-| Type alias for DOM element IDs.
-}
type alias ElementId =
    String


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
  - **offsetX**: Horizontal offset in pixels from the target position. Default is 0.
  - **offsetY**: Vertical offset in pixels from the target position. Default is 12.
  - **easing**: Easing function from [elm-community/easing-functions](https://package.elm-lang.org/packages/elm-community/easing-functions/latest/). Default is [Ease.outQuint](https://package.elm-lang.org/packages/elm-community/easing-functions/latest/Ease#outQuint).
  - **axis**: Movement axis (Y for vertical, X for horizontal, Both for diagonal). Default is Y.

-}
type alias Config =
    { timing : Timing
    , offsetX : Int
    , offsetY : Int
    , easing : Ease.Easing
    , axis : Axis
    }


{-| Axis configuration for animation movement direction.

Use this to control whether your animation moves horizontally or vertically:

  - `Y` - Vertical scrolling (most common, default for page scrolling)
  - `X` - Horizontal scrolling (for sideways carousels or horizontal content)
  - `Both` - Both horizontal and vertical scrolling to reach the target element

-}
type Axis
    = X
    | Y
    | Both


{-| Type for configuring which element to scroll within.

Use `DocumentBody` for scrolling the main document, or `Container elementId`
for scrolling within a specific container element.

-}
type Container
    = DocumentBody
    | Container ElementId


{-| The default configuration which you can customize as needed.

    import Ease
    import SmoothMoveScroll exposing (Axis(..), Timing(..), defaultConfig)

    customConfig =
        { defaultConfig
            | timing = Duration 500
            , offsetY = 20
            , easing = Ease.inOutCubic
            , axis = Both
        }

-}
defaultConfig : Config
defaultConfig =
    { timing = Duration 400
    , offsetX = 0
    , offsetY = 12
    , easing = Ease.outQuint
    , axis = Y
    }
