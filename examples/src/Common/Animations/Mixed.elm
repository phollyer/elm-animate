module Common.Animations.Mixed exposing
    ( allProperties
    , colorSizeOpacity
    , fadeMove
    , moveScaleRotate
    , resetAll
    , spinScaleColor
    )

{-| Common Mixed property animations that work across all animation engines.

These functions provide coordinated multi-property animations that can be used
across CSS Transitions, CSS Keyframes, Sub, and WAAPI engines. Each animation
demonstrates different combinations of properties working together.

FEATURES:

  - ✅ Multi-property coordination
  - ✅ Consistent timing and effects across engines
  - ✅ Complex animation choreography
  - ✅ Real-world usage patterns

ANIMATIONS:

  - **moveScaleRotate**: Position + Scale + Rotation with delayed start
  - **fadeMove**: Opacity + Position with synchronized timing
  - **spinScaleColor**: Rotation + Scale + Background color
  - **colorSizeOpacity**: Background color + Size + Opacity
  - **allProperties**: All animation properties in one coordinated sequence

-}

import Anim.Color
import Anim.Easing as Easing
import Anim.Internal.Builder as Builder
import Anim.Property.BackgroundColor as Color
import Anim.Property.Opacity as Opacity
import Anim.Property.Position as Position
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size


{-| Move + Scale + Rotate with delayed animation starts
Position moves first, then rotation, then scale with bouncy effects
-}
moveScaleRotate : String -> Builder.AnimBuilder -> Builder.AnimBuilder
moveScaleRotate elementId builder =
    builder
        |> Position.for elementId
        |> Position.toXY 200 100
        |> Position.speed 200.0
        |> Position.easing Easing.EaseIn
        |> Position.build
        |> Rotate.for elementId
        |> Rotate.delay 500
        |> Rotate.toZ 90
        |> Rotate.speed 120.0
        |> Rotate.easing Easing.BounceOut
        |> Rotate.build
        |> Scale.for elementId
        |> Scale.delay 2000
        |> Scale.toXY 1.5 1.9
        |> Scale.speed 2.0
        |> Scale.easing Easing.BounceOut
        |> Scale.build


{-| Fade + Move with synchronized timing
Opacity and position change together smoothly
-}
fadeMove : String -> Builder.AnimBuilder -> Builder.AnimBuilder
fadeMove elementId builder =
    builder
        |> Opacity.for elementId
        |> Opacity.to 0.3
        |> Opacity.speed 2.0
        |> Opacity.easing Easing.EaseOut
        |> Opacity.build
        |> Position.for elementId
        |> Position.toXY 250 80
        |> Position.speed 200.0
        |> Position.easing Easing.EaseOut
        |> Position.build


{-| Spin + Scale + Color change with coordinated timing
Rotation, scaling, and color morph working together
-}
spinScaleColor : String -> Builder.AnimBuilder -> Builder.AnimBuilder
spinScaleColor elementId builder =
    builder
        |> Rotate.for elementId
        |> Rotate.toZ 180
        |> Rotate.speed 180.0
        |> Rotate.easing Easing.EaseInOut
        |> Rotate.build
        |> Scale.for elementId
        |> Scale.toXY 0.8 0.8
        |> Scale.speed 1.5
        |> Scale.easing Easing.EaseInOut
        |> Scale.build
        |> Color.for elementId
        |> Color.to (Anim.Color.fromHsl { h = 120 / 360, s = 0.8, l = 0.6 })
        |> Color.speed 1.0
        |> Color.easing Easing.EaseInOut
        |> Color.build


{-| Color + Size + Opacity coordination
Background color, element size, and opacity changing together
-}
colorSizeOpacity : String -> Builder.AnimBuilder -> Builder.AnimBuilder
colorSizeOpacity elementId builder =
    builder
        |> Color.for elementId
        |> Color.to (Anim.Color.fromHsl { h = 280 / 360, s = 0.7, l = 0.5 })
        |> Color.speed 1.5
        |> Color.easing Easing.EaseOut
        |> Color.build
        |> Size.for elementId
        |> Size.toHW 120 120
        |> Size.speed 80.0
        |> Size.easing Easing.EaseOut
        |> Size.build
        |> Opacity.for elementId
        |> Opacity.to 0.8
        |> Opacity.speed 1.5
        |> Opacity.easing Easing.EaseOut
        |> Opacity.build


{-| All properties animation - kitchen sink!
Position, Scale, Size, Rotation, Opacity, and Color all animating
-}
allProperties : String -> Builder.AnimBuilder -> Builder.AnimBuilder
allProperties elementId builder =
    builder
        |> Position.for elementId
        |> Position.toXY 200 200
        |> Position.speed 200.0
        |> Position.easing Easing.EaseInOut
        |> Position.build
        |> Scale.for elementId
        |> Scale.toXY 1.3 1.3
        |> Scale.speed 1.5
        |> Scale.easing Easing.EaseOut
        |> Scale.build
        |> Size.for elementId
        |> Size.toHW 100 100
        |> Size.speed 60.0
        |> Size.easing Easing.EaseOut
        |> Size.build
        |> Rotate.for elementId
        |> Rotate.toZ 360
        |> Rotate.speed 200.0
        |> Rotate.easing Easing.EaseInOut
        |> Rotate.build
        |> Opacity.for elementId
        |> Opacity.to 0.6
        |> Opacity.speed 1.2
        |> Opacity.easing Easing.EaseOut
        |> Opacity.build
        |> Color.for elementId
        |> Color.to (Anim.Color.fromHsl { h = 60 / 360, s = 0.9, l = 0.7 })
        |> Color.speed 1.0
        |> Color.easing Easing.EaseOut
        |> Color.build


{-| Reset all properties to initial state
Returns all animated properties to their starting values
-}
resetAll : String -> Builder.AnimBuilder -> Builder.AnimBuilder
resetAll elementId builder =
    builder
        |> Position.for elementId
        |> Position.toXY 0 0
        |> Position.speed 200.0
        |> Position.easing Easing.BounceOut
        |> Position.build
        |> Scale.for elementId
        |> Scale.toXY 1.0 1.0
        |> Scale.speed 1.5
        |> Scale.easing Easing.EaseInOut
        |> Scale.build
        |> Size.for elementId
        |> Size.toHW 80 80
        |> Size.speed 2000
        |> Size.easing Easing.EaseInOut
        |> Size.build
        |> Rotate.for elementId
        |> Rotate.toZ 0
        |> Rotate.speed 180.0
        |> Rotate.easing Easing.EaseInOut
        |> Rotate.build
        |> Opacity.for elementId
        |> Opacity.to 1.0
        |> Opacity.speed 1.5
        |> Opacity.easing Easing.EaseInOut
        |> Opacity.build
        |> Color.for elementId
        |> Color.to (Anim.Color.fromHsl { h = 207 / 360, s = 0.9, l = 0.54 })
        |> Color.speed 300.0
        |> Color.easing Easing.EaseOut
        |> Color.build
