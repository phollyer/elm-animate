module Move exposing
    ( Config
    , defaultConfig
    , Timing(..)
    , Easing(..)
    , EasePreset(..)
    )

{-| Shared types for smooth element movement and animation.

This module provides the common types used by all `Move.*` modules for animating DOM elements.

For actual animation functionality, import one of:

  - `Move.CSS` for CSS transition-based API
  - `Move.Sub` for subscription-based API
  - `Move.Ports` for Web Animations API via JavaScript


# Configuration

@docs Config
@docs defaultConfig


## Timing

@docs Timing


## Easing

@docs Easing
@docs EasePreset

-}

import Ease



-- TIMING AND EASING TYPES


{-| Animation timing configuration.

Choose between speed-based or duration-based timing:

  - Speed: Animation speed in pixels per second (higher = faster)
  - Duration: Animation duration in milliseconds (higher = slower)

-}
type Timing
    = Speed Float
    | Duration Int


{-| Easing configuration that works across all animation approaches.

  - EaseFunction: Uses elm-community/easing-functions (for Move.Sub)
  - EaseString: CSS easing strings like "ease-out" or "cubic-bezier(0.4, 0, 0.2, 1)" (for Move.CSS and Move.Ports)
  - EasePreset: Common easing presets that convert to appropriate format per module

-}
type Easing
    = EaseFunction Ease.Easing
    | EaseString String
    | EasePreset EasePreset


{-| Common easing presets that work across all animation modules.

These convert to the appropriate format for each animation approach:

  - Linear, EaseOut, EaseIn, EaseInOut map to corresponding CSS strings and Ease functions

-}
type EasePreset
    = Linear
    | EaseOut
    | EaseIn
    | EaseInOut


{-| Configuration for element animations.

  - **timing**: Animation timing (Speed in pixels per second or Duration in milliseconds). Default is `Duration 400`.
  - **easing**: Easing function that works across all animation approaches. Default is `EasePreset EaseOut`.

-}
type alias Config =
    { timing : Timing
    , easing : Easing
    }


{-| The default configuration which you can customize as needed.

    import Move exposing (EasePreset(..), Easing(..), Timing(..), defaultConfig)

    customConfig =
        { defaultConfig
            | timing = Duration 500
            , easing = EasePreset EaseInOut
        }

-}
defaultConfig : Config
defaultConfig =
    { timing = Duration 400
    , easing = EasePreset EaseOut
    }
