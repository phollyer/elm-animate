module Anim exposing
    ( Animation
    , position, opacity, scale, rotation
    , backgroundColor, textColor, borderColor
    , dimensions, borderRadius, filter
    , pixelsPerSecond, opacityPerSecond, scalePerSecond, degreesPerSecond
    , colorStepsPerSecond, textColorStepsPerSecond, borderColorStepsPerSecond
    , dimensionsPerSecond, borderRadiusDimensionsPerSecond, filtersPerSecond
    , duration, opacityDuration, scaleDuration, rotationDuration
    , backgroundColorDuration, textColorDuration, borderColorDuration
    , dimensionsDuration, borderRadiusDuration, filterDuration
    , easeIn, easeOut, easeInOut, linear, easeWith, easeFunction
    , delay
    , Position
    , ColorValue(..)
    , ScaleValue
    , RotationValue
    , DimensionValue
    , FilterValue(..)
    , AnimationTarget(..)
    , EasePreset(..)
    , Easing(..)
    , Timing(..)
    , getAnimationData
    , getElementId
    , getTarget
    , getTiming
    , getEasing
    , getDelay
    , ElementBuilder, element, toAnimations, withBackgroundColor, withOpacity, withPosition, withRotation, withScale
    )

{-| Fluent builder API for smooth element animations.

This module provides a type-safe, fluent builder pattern for creating animations.
Each property has its own builder with appropriate timing options, eliminating
the possibility of timing/property mismatches.

For actual animation execution, use one of:

  - [Anim.Sub](Anim.Sub) for subscription-based animations
  - [Anim.Ports](Anim.Ports) for Web Animations API via JavaScript


# Core Animation Type

@docs Animation


# Property Builders

Create animations for specific CSS properties:

@docs position, opacity, scale, rotation
@docs backgroundColor, textColor, borderColor
@docs dimensions, borderRadius, filter


# Speed-Based Timing

Configure animations with property-specific speeds:

@docs pixelsPerSecond, opacityPerSecond, scalePerSecond, degreesPerSecond
@docs colorStepsPerSecond, textColorStepsPerSecond, borderColorStepsPerSecond
@docs dimensionsPerSecond, borderRadiusDimensionsPerSecond, filtersPerSecond


# Duration-Based Timing

Configure animations with fixed durations:

@docs duration, opacityDuration, scaleDuration, rotationDuration
@docs backgroundColorDuration, textColorDuration, borderColorDuration
@docs dimensionsDuration, borderRadiusDuration, filterDuration


# Easing Functions

@docs easeIn, easeOut, easeInOut, linear, easeWith, easeFunction


# Animation Modifiers

@docs delay


# Value Types

@docs Position
@docs ColorValue
@docs ScaleValue
@docs RotationValue
@docs DimensionValue
@docs FilterValue


# Animation Types

@docs AnimationTarget
@docs EasePreset
@docs Easing
@docs Timing


# Internal Functions

Functions for accessing Animation data (used by other Anim modules):

@docs getAnimationData
@docs getElementId
@docs getTarget
@docs getTiming
@docs getEasing
@docs getDelay


# Examples

**Basic position animation:**

    animation =
        position "my-element" { x = 100, y = 200 }
            |> pixelsPerSecond 300.0
            |> easeOut

**Opacity animation with duration:**

    animation =
        opacity "my-element" 0.5
            |> duration 500
            |> easeInOut

**Complex animation with delay:**

    animation =
        scale "my-element" { x = 2.0, y = 2.0 }
            |> scalePerSecond 1.5
            |> easeIn
            |> delay 200

-}

import Ease



-- OPAQUE ANIMATION TYPE


{-| Opaque animation type that ensures type safety.
Create animations using the property builder functions, then configure with timing and easing.
-}
type Animation
    = Animation AnimationData


{-| Internal animation data (not exposed).
-}
type alias AnimationData =
    { elementId : String
    , target : AnimationTarget
    , timing : Timing
    , easing : Easing
    , delayMs : Int
    }



-- INTERNAL TYPES (NOT EXPOSED)


{-| Animation timing configuration.

Defines how fast or slow an animation should progress. Use property-specific
timing methods for better semantic meaning and type safety.

**Duration-based timing:**

  - `Duration 500` - Animation completes in 500 milliseconds

**Speed-based timing:**

  - `PixelsPerSecond 300.0` - Position animations at 300 pixels/second
  - `DegreesPerSecond 90.0` - Rotation animations at 90 degrees/second
  - `OpacityPerSecond 2.0` - Opacity animations at 2.0 units/second
  - `ScalePerSecond 1.5` - Scale animations at 1.5 units/second
  - `ColorStepsPerSecond 30.0` - Color animations at 30 steps/second
  - `DimensionsPerSecond 100.0` - Size animations at 100 pixels/second
  - `FiltersPerSecond 5.0` - Filter animations at 5 units/second

Prefer using the builder functions instead of constructing these directly.

-}
type Timing
    = Duration Int
    | PixelsPerSecond Float
    | DegreesPerSecond Float
    | ColorStepsPerSecond Float
    | OpacityPerSecond Float
    | ScalePerSecond Float
    | DimensionsPerSecond Float
    | FiltersPerSecond Float


{-| Animation easing configuration.

Defines the acceleration curve for animations. Controls how the animation
progresses from start to finish.

**Common presets:**

  - `EasePreset Linear` - Constant speed throughout
  - `EasePreset EaseOut` - Fast start, slow finish (natural feeling)
  - `EasePreset EaseIn` - Slow start, fast finish
  - `EasePreset EaseInOut` - Slow start and finish, fast middle

**Custom options:**

  - `EaseFunction customFunction` - Use elm-community/easing-functions
  - `EaseString "cubic-bezier(0.25, 0.1, 0.25, 1)"` - CSS easing string

Prefer using the fluent builder methods like `easeOut`, `easeIn`, etc.

-}
type Easing
    = EaseFunction Ease.Easing
    | EaseString String
    | EasePreset EasePreset


{-| Predefined easing curves for common animation styles.

**Easing behaviors:**

  - `Linear` - Constant speed, no acceleration (mechanical feeling)
  - `EaseOut` - Fast start, gradual slowdown (natural, recommended default)
  - `EaseIn` - Gradual acceleration from rest (feels heavy)
  - `EaseInOut` - Smooth acceleration and deceleration (elegant)

Most UI animations benefit from `EaseOut` as it feels most natural to users.
Use `EaseIn` for objects disappearing and `EaseInOut` for emphasis.

    -- Recommended for most animations
    opacity "button" 0.5 |> duration 300 |> easeOut

    -- For elegant, attention-drawing animations
    scale "modal" { x = 1.1, y = 1.1 } |> duration 400 |> easeInOut

-}
type EasePreset
    = Linear
    | EaseOut
    | EaseIn
    | EaseInOut


{-| Animation target values for different CSS properties.

Represents the final value an element should animate to. Each variant
corresponds to a specific CSS property type with appropriate value constraints.

**Transform properties:**

  - `ToPosition {x = 100, y = 200}` - Element position (translate)
  - `ToScale {x = 1.5, y = 1.5}` - Element scaling
  - `ToRotation 45.0` - Element rotation in degrees

**Visual properties:**

  - `ToOpacity 0.5` - Element transparency (0.0 to 1.0)
  - `ToBackgroundColor (Hex "#ff0000")` - Background color
  - `ToTextColor (Rgb {r = 255, g = 0, b = 0})` - Text color
  - `ToBorderColor (Rgba {r = 0, g = 0, b = 255, a = 0.8})` - Border color

**Size properties:**

  - `ToDimensions {width = 200, height = 100}` - Element dimensions
  - `ToBorderRadius 8.0` - Border radius in pixels

**Effects:**

  - `ToFilter (Blur 5.0)` - CSS filter effects

Prefer using the typed builder functions instead of constructing these directly.

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



-- PROPERTY BUILDERS (OPAQUE)


{-| Opaque position builder. Use timing methods to create final Animation.
-}
type PositionBuilder
    = PositionBuilder String Position


{-| Opaque opacity builder. Use timing methods to create final Animation.
-}
type OpacityBuilder
    = OpacityBuilder String Float


{-| Opaque scale builder. Use timing methods to create final Animation.
-}
type ScaleBuilder
    = ScaleBuilder String ScaleValue


{-| Opaque rotation builder. Use timing methods to create final Animation.
-}
type RotationBuilder
    = RotationBuilder String RotationValue


{-| Opaque color builder for background color. Use timing methods to create final Animation.
-}
type BackgroundColorBuilder
    = BackgroundColorBuilder String ColorValue


{-| Opaque color builder for text color. Use timing methods to create final Animation.
-}
type TextColorBuilder
    = TextColorBuilder String ColorValue


{-| Opaque color builder for border color. Use timing methods to create final Animation.
-}
type BorderColorBuilder
    = BorderColorBuilder String ColorValue


{-| Opaque dimensions builder. Use timing methods to create final Animation.
-}
type DimensionsBuilder
    = DimensionsBuilder String DimensionValue


{-| Opaque border radius builder. Use timing methods to create final Animation.
-}
type BorderRadiusBuilder
    = BorderRadiusBuilder String Float


{-| Opaque filter builder. Use timing methods to create final Animation.
-}
type FilterBuilder
    = FilterBuilder String FilterValue


{-| Opaque multi-property element builder for animating multiple properties simultaneously.
-}
type ElementBuilder
    = ElementBuilder String (List PropertySpec)


{-| Internal type for property specifications in multi-property animations.
-}
type PropertySpec
    = PositionSpec Position
    | OpacitySpec Float
    | ScaleSpec ScaleValue
    | RotationSpec RotationValue
    | BackgroundColorSpec ColorValue



-- PROPERTY BUILDER FUNCTIONS


{-| Create a position animation builder.

    position "my-element" { x = 100, y = 200 }
        |> pixelsPerSecond 300.0

-}
position : String -> Position -> PositionBuilder
position elementId pos =
    PositionBuilder elementId pos


{-| Create an opacity animation builder.

    opacity "my-element" 0.5
        |> opacityPerSecond 2.0

-}
opacity : String -> Float -> OpacityBuilder
opacity elementId value =
    OpacityBuilder elementId value


{-| Create a scale animation builder.

    scale "my-element" { x = 2.0, y = 2.0 }
        |> scalePerSecond 1.5

-}
scale : String -> ScaleValue -> ScaleBuilder
scale elementId value =
    ScaleBuilder elementId value


{-| Create a rotation animation builder.

    rotation "my-element" 90.0
        |> degreesPerSecond 45.0

-}
rotation : String -> RotationValue -> RotationBuilder
rotation elementId value =
    RotationBuilder elementId value


{-| Create a background color animation builder.

    backgroundColor "my-element" (Rgb { r = 255, g = 0, b = 0 })
        |> colorStepsPerSecond 50.0

-}
backgroundColor : String -> ColorValue -> BackgroundColorBuilder
backgroundColor elementId value =
    BackgroundColorBuilder elementId value


{-| Create a text color animation builder.

    textColor "my-element" (Hex "#ff0000")
        |> colorStepsPerSecond 50.0

-}
textColor : String -> ColorValue -> TextColorBuilder
textColor elementId value =
    TextColorBuilder elementId value


{-| Create a border color animation builder.

    borderColor "my-element" (Rgba { r = 255, g = 0, b = 0, a = 0.8 })
        |> colorStepsPerSecond 50.0

-}
borderColor : String -> ColorValue -> BorderColorBuilder
borderColor elementId value =
    BorderColorBuilder elementId value


{-| Create a dimensions animation builder.

    dimensions "my-element" { width = 200, height = 150 }
        |> dimensionsPerSecond 100.0

-}
dimensions : String -> DimensionValue -> DimensionsBuilder
dimensions elementId value =
    DimensionsBuilder elementId value


{-| Create a border radius animation builder.

    borderRadius "my-element" 20.0
        |> dimensionsPerSecond 50.0

-}
borderRadius : String -> Float -> BorderRadiusBuilder
borderRadius elementId value =
    BorderRadiusBuilder elementId value


{-| Create a filter animation builder.

    filter "my-element" (Blur 10.0)
        |> filtersPerSecond 5.0

-}
filter : String -> FilterValue -> FilterBuilder
filter elementId value =
    FilterBuilder elementId value



-- MULTI-PROPERTY ELEMENT BUILDER


{-| Start building animations for a single element with multiple properties.

    element "my-box"
        |> withPosition { x = 100, y = 200 }
        |> withScale { x = 1.5, y = 1.5 }
        |> withRotation 45
        |> toAnimations
            { duration = 1000
            , easing = EaseInOut
            }

-}
element : String -> ElementBuilder
element elementId =
    ElementBuilder elementId []


{-| Add position animation to the element builder.
-}
withPosition : Position -> ElementBuilder -> ElementBuilder
withPosition pos (ElementBuilder elementId specs) =
    ElementBuilder elementId (PositionSpec pos :: specs)


{-| Add opacity animation to the element builder.
-}
withOpacity : Float -> ElementBuilder -> ElementBuilder
withOpacity value (ElementBuilder elementId specs) =
    ElementBuilder elementId (OpacitySpec value :: specs)


{-| Add scale animation to the element builder.
-}
withScale : ScaleValue -> ElementBuilder -> ElementBuilder
withScale value (ElementBuilder elementId specs) =
    ElementBuilder elementId (ScaleSpec value :: specs)


{-| Add rotation animation to the element builder.
-}
withRotation : RotationValue -> ElementBuilder -> ElementBuilder
withRotation value (ElementBuilder elementId specs) =
    ElementBuilder elementId (RotationSpec value :: specs)


{-| Add background color animation to the element builder.
-}
withBackgroundColor : ColorValue -> ElementBuilder -> ElementBuilder
withBackgroundColor value (ElementBuilder elementId specs) =
    ElementBuilder elementId (BackgroundColorSpec value :: specs)


{-| Convert element builder to a list of individual animations with shared timing.

    element "my-box"
        |> withPosition { x = 100, y = 200 }
        |> withScale { x = 1.5, y = 1.5 }
        |> toAnimations
            { duration = 1000
            , easing = EaseInOut
            }

-}
toAnimations : { duration : Int, easing : Easing } -> ElementBuilder -> List Animation
toAnimations config (ElementBuilder elementId specs) =
    let
        createAnimation spec =
            case spec of
                PositionSpec pos ->
                    Animation
                        { elementId = elementId
                        , target = ToPosition pos
                        , timing = Duration config.duration
                        , easing = config.easing
                        , delayMs = 0
                        }

                OpacitySpec value ->
                    Animation
                        { elementId = elementId
                        , target = ToOpacity value
                        , timing = Duration config.duration
                        , easing = config.easing
                        , delayMs = 0
                        }

                ScaleSpec value ->
                    Animation
                        { elementId = elementId
                        , target = ToScale value
                        , timing = Duration config.duration
                        , easing = config.easing
                        , delayMs = 0
                        }

                RotationSpec value ->
                    Animation
                        { elementId = elementId
                        , target = ToRotation value
                        , timing = Duration config.duration
                        , easing = config.easing
                        , delayMs = 0
                        }

                BackgroundColorSpec value ->
                    Animation
                        { elementId = elementId
                        , target = ToBackgroundColor value
                        , timing = Duration config.duration
                        , easing = config.easing
                        , delayMs = 0
                        }
    in
    List.map createAnimation specs



-- SPEED-BASED TIMING METHODS


{-| Set pixels per second timing for position animations.

    position "element" { x = 100, y = 200 }
        |> pixelsPerSecond 300.0

-}
pixelsPerSecond : Float -> PositionBuilder -> Animation
pixelsPerSecond speed (PositionBuilder elementId pos) =
    Animation
        { elementId = elementId
        , target = ToPosition pos
        , timing = PixelsPerSecond speed
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set opacity per second timing for opacity animations.

    opacity "element" 0.5
        |> opacityPerSecond 2.0

-}
opacityPerSecond : Float -> OpacityBuilder -> Animation
opacityPerSecond speed (OpacityBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToOpacity value
        , timing = OpacityPerSecond speed
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set scale per second timing for scale animations.

    scale "element" { x = 2.0, y = 2.0 }
        |> scalePerSecond 1.5

-}
scalePerSecond : Float -> ScaleBuilder -> Animation
scalePerSecond speed (ScaleBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToScale value
        , timing = ScalePerSecond speed
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set degrees per second timing for rotation animations.

    rotation "element" 90.0
        |> degreesPerSecond 45.0

-}
degreesPerSecond : Float -> RotationBuilder -> Animation
degreesPerSecond speed (RotationBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToRotation value
        , timing = DegreesPerSecond speed
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set color steps per second timing for background color animations.

    backgroundColor "element" (Rgb { r = 255, g = 0, b = 0 })
        |> colorStepsPerSecond 50.0

-}
colorStepsPerSecond : Float -> BackgroundColorBuilder -> Animation
colorStepsPerSecond speed (BackgroundColorBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToBackgroundColor value
        , timing = ColorStepsPerSecond speed
        , easing = EasePreset EaseOut
        , delayMs = 0
        }



-- Additional timing method overloads for other builders


{-| Set color steps per second timing for text color animations.
-}
textColorStepsPerSecond : Float -> TextColorBuilder -> Animation
textColorStepsPerSecond speed (TextColorBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToTextColor value
        , timing = ColorStepsPerSecond speed
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set color steps per second timing for border color animations.
-}
borderColorStepsPerSecond : Float -> BorderColorBuilder -> Animation
borderColorStepsPerSecond speed (BorderColorBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToBorderColor value
        , timing = ColorStepsPerSecond speed
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set dimensions per second timing for border radius animations.
-}
borderRadiusDimensionsPerSecond : Float -> BorderRadiusBuilder -> Animation
borderRadiusDimensionsPerSecond speed (BorderRadiusBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToBorderRadius value
        , timing = DimensionsPerSecond speed
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set dimensions per second timing for dimension animations.

Works with dimensions and borderRadius builders.

    dimensions "element" { width = 200, height = 150 }
        |> dimensionsPerSecond 100.0

-}
dimensionsPerSecond : Float -> DimensionsBuilder -> Animation
dimensionsPerSecond speed (DimensionsBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToDimensions value
        , timing = DimensionsPerSecond speed
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set filters per second timing for filter animations.

    filter "element" (Blur 10.0)
        |> filtersPerSecond 5.0

-}
filtersPerSecond : Float -> FilterBuilder -> Animation
filtersPerSecond speed (FilterBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToFilter value
        , timing = FiltersPerSecond speed
        , easing = EasePreset EaseOut
        , delayMs = 0
        }



-- DURATION-BASED TIMING (WORKS WITH ANY BUILDER)


{-| Set fixed duration timing for position animations.
-}
duration : Int -> PositionBuilder -> Animation
duration ms (PositionBuilder elementId pos) =
    Animation
        { elementId = elementId
        , target = ToPosition pos
        , timing = Duration ms
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set fixed duration timing for opacity animations.
-}
opacityDuration : Int -> OpacityBuilder -> Animation
opacityDuration ms (OpacityBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToOpacity value
        , timing = Duration ms
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set fixed duration timing for scale animations.
-}
scaleDuration : Int -> ScaleBuilder -> Animation
scaleDuration ms (ScaleBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToScale value
        , timing = Duration ms
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set fixed duration timing for rotation animations.
-}
rotationDuration : Int -> RotationBuilder -> Animation
rotationDuration ms (RotationBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToRotation value
        , timing = Duration ms
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set fixed duration timing for background color animations.
-}
backgroundColorDuration : Int -> BackgroundColorBuilder -> Animation
backgroundColorDuration ms (BackgroundColorBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToBackgroundColor value
        , timing = Duration ms
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set fixed duration timing for text color animations.
-}
textColorDuration : Int -> TextColorBuilder -> Animation
textColorDuration ms (TextColorBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToTextColor value
        , timing = Duration ms
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set fixed duration timing for border color animations.
-}
borderColorDuration : Int -> BorderColorBuilder -> Animation
borderColorDuration ms (BorderColorBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToBorderColor value
        , timing = Duration ms
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set fixed duration timing for dimensions animations.
-}
dimensionsDuration : Int -> DimensionsBuilder -> Animation
dimensionsDuration ms (DimensionsBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToDimensions value
        , timing = Duration ms
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set fixed duration timing for border radius animations.
-}
borderRadiusDuration : Int -> BorderRadiusBuilder -> Animation
borderRadiusDuration ms (BorderRadiusBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToBorderRadius value
        , timing = Duration ms
        , easing = EasePreset EaseOut
        , delayMs = 0
        }


{-| Set fixed duration timing for filter animations.
-}
filterDuration : Int -> FilterBuilder -> Animation
filterDuration ms (FilterBuilder elementId value) =
    Animation
        { elementId = elementId
        , target = ToFilter value
        , timing = Duration ms
        , easing = EasePreset EaseOut
        , delayMs = 0
        }



-- EASING METHODS (MODIFY EXISTING ANIMATIONS)


{-| Apply ease-in easing to an animation.

    position "element" { x = 100, y = 200 }
        |> pixelsPerSecond 300.0
        |> easeIn

-}
easeIn : Animation -> Animation
easeIn (Animation data) =
    Animation { data | easing = EasePreset EaseIn }


{-| Apply ease-out easing to an animation.

    position "element" { x = 100, y = 200 }
        |> pixelsPerSecond 300.0
        |> easeOut

-}
easeOut : Animation -> Animation
easeOut (Animation data) =
    Animation { data | easing = EasePreset EaseOut }


{-| Apply ease-in-out easing to an animation.

    position "element" { x = 100, y = 200 }
        |> pixelsPerSecond 300.0
        |> easeInOut

-}
easeInOut : Animation -> Animation
easeInOut (Animation data) =
    Animation { data | easing = EasePreset EaseInOut }


{-| Apply linear easing to an animation.

    position "element" { x = 100, y = 200 }
        |> pixelsPerSecond 300.0
        |> linear

-}
linear : Animation -> Animation
linear (Animation data) =
    Animation { data | easing = EasePreset Linear }


{-| Apply custom CSS easing string to an animation.

    position "element" { x = 100, y = 200 }
        |> pixelsPerSecond 300.0
        |> easeWith "cubic-bezier(0.4, 0, 0.2, 1)"

-}
easeWith : String -> Animation -> Animation
easeWith easingString (Animation data) =
    Animation { data | easing = EaseString easingString }


{-| Apply custom easing function to an animation (for subscription-based animations).

    position "element" { x = 100, y = 200 }
        |> pixelsPerSecond 300.0
        |> easeFunction Ease.inOutQuad

-}
easeFunction : Ease.Easing -> Animation -> Animation
easeFunction easingFunc (Animation data) =
    Animation { data | easing = EaseFunction easingFunc }



-- ANIMATION MODIFIERS


{-| Add delay to an animation.

    position "element" { x = 100, y = 200 }
        |> pixelsPerSecond 300.0
        |> delay 200

-}
delay : Int -> Animation -> Animation
delay ms (Animation data) =
    Animation { data | delayMs = ms }



-- VALUE TYPES (EXPOSED FOR TYPE SIGNATURES)


{-| Position type for X and Y coordinates in pixels.
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



-- INTERNAL HELPER FUNCTIONS FOR OTHER MODULES (NOT EXPOSED)


{-| Extract animation data from opaque Animation type (for internal use by other modules).
-}
getAnimationData : Animation -> { elementId : String, target : AnimationTarget, timing : Timing, easing : Easing, delayMs : Int }
getAnimationData (Animation data) =
    data


{-| Extract element ID from Animation (for internal use by other modules).
-}
getElementId : Animation -> String
getElementId (Animation data) =
    data.elementId


{-| Extract animation target from Animation (for internal use by other modules).
-}
getTarget : Animation -> AnimationTarget
getTarget (Animation data) =
    data.target


{-| Extract timing from Animation (for internal use by other modules).
-}
getTiming : Animation -> Timing
getTiming (Animation data) =
    data.timing


{-| Extract easing from Animation (for internal use by other modules).
-}
getEasing : Animation -> Easing
getEasing (Animation data) =
    data.easing


{-| Extract delay from Animation (for internal use by other modules).
-}
getDelay : Animation -> Int
getDelay (Animation data) =
    data.delayMs
