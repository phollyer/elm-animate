module Anim exposing
    ( Config
    , defaultConfig
    , Timing(..)
    , Easing(..)
    , EasePreset(..)
    , AnimationTarget(..)
    , Position
    , ColorValue(..)
    , ScaleValue
    , RotationValue
    , DimensionValue
    , FilterValue(..)
    )

{-| Shared types for smooth element animations.

For actual animation functionality, import one of:

  - [Anim.CSS](Anim.CSS) for CSS transition-based API
  - [Anim.Sub](Anim.Sub) for subscription-based API
  - [Anim.Ports](Anim.Ports) for Web Animations API via JavaScript


# Configuration

@docs Config
@docs defaultConfig


## Timing

@docs Timing


## Easing

@docs Easing
@docs EasePreset


# Animation Targets

@docs AnimationTarget
@docs Position
@docs ColorValue
@docs ScaleValue
@docs RotationValue
@docs DimensionValue
@docs FilterValue

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

    import Anim exposing (EasePreset(..), Easing(..), Timing(..), defaultConfig)

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



-- ANIMATION TARGET TYPES


{-| Position type for X and Y coordinates in pixels.

This maintains backward compatibility with existing Position-based APIs.

-}
type alias Position =
    { x : Float
    , y : Float
    }


{-| Scale value for element scaling.

  - x: Horizontal scale factor (1.0 = normal, 2.0 = double width)
  - y: Vertical scale factor (1.0 = normal, 0.5 = half height)

-}
type alias ScaleValue =
    { x : Float
    , y : Float
    }


{-| Rotation value in degrees.

  - Positive values rotate clockwise
  - Negative values rotate counter-clockwise
  - Values automatically wrap (360° = 0°)

-}
type alias RotationValue =
    Float


{-| Dimension value for width and height in pixels.
-}
type alias DimensionValue =
    { width : Float
    , height : Float
    }


{-| Color values supporting multiple formats for maximum flexibility.

  - Hex: Standard hex color strings like "#FF5722" or "#f57c00"
  - Rgb: RGB values with integers 0-255
  - Rgba: RGB with alpha channel (0.0 = transparent, 1.0 = opaque)
  - Hsl: HSL color space (hue 0-360°, saturation 0-100%, lightness 0-100%)
  - Hsla: HSL with alpha channel

-}
type ColorValue
    = Hex String
    | Rgb { r : Int, g : Int, b : Int }
    | Rgba { r : Int, g : Int, b : Int, a : Float }
    | Hsl { h : Float, s : Float, l : Float }
    | Hsla { h : Float, s : Float, l : Float, a : Float }


{-| Filter effects for advanced visual animations.

  - Blur: Blur radius in pixels (0 = no blur)
  - Brightness: Brightness multiplier (0.0 = black, 1.0 = normal, 2.0+ = bright)
  - Contrast: Contrast multiplier (0.0 = gray, 1.0 = normal, 2.0+ = high contrast)
  - Grayscale: Grayscale amount (0.0 = color, 1.0 = full grayscale)
  - Saturate: Saturation multiplier (0.0 = grayscale, 1.0 = normal, 2.0+ = oversaturated)

-}
type FilterValue
    = Blur Float
    | Brightness Float
    | Contrast Float
    | Grayscale Float
    | Saturate Float


{-| Comprehensive animation targets supporting all major CSS properties.

  - ToPosition: Element position (translate transform) - maintains backward compatibility
  - ToOpacity: Element opacity (0.0 = transparent, 1.0 = opaque)
  - ToScale: Element scaling (transform: scale)
  - ToRotation: Element rotation in degrees (transform: rotate)
  - ToBackgroundColor: Background color animation
  - ToTextColor: Text color animation
  - ToBorderColor: Border color animation
  - ToDimensions: Width and height animation
  - ToBorderRadius: Border radius animation for morphing shapes
  - ToFilter: Advanced visual effects (blur, brightness, contrast, etc.)

This replaces the simple Position record with a rich set of animation possibilities
while maintaining full backward compatibility through the ToPosition variant.

-}
type AnimationTarget
    = ToPosition Position
    | ToOpacity Float
    | ToScale ScaleValue
    | ToRotation RotationValue
    | ToBackgroundColor ColorValue
    | ToTextColor ColorValue
    | ToBorderColor ColorValue
    | ToDimensions DimensionValue
    | ToBorderRadius Float
    | ToFilter FilterValue
