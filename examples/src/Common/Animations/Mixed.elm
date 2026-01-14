module Common.Animations.Mixed exposing
    ( allProperties
    , colorSizeOpacity
    , elementId
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
import Anim.Easing as Easing exposing (Easing(..))
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Property.BackgroundColor as Color
import Anim.Property.Opacity as Opacity
import Anim.Property.Position as Position
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size


elementId : String
elementId =
    "mixed-box"


positionAnimation : Float -> Easing -> ( Float, Float ) -> AnimBuilder -> AnimBuilder
positionAnimation speed easing ( x, y ) builder =
    builder
        |> Position.for elementId
        |> Position.toXY x y
        |> Position.speed speed
        |> Position.easing easing
        |> Position.build


init : AnimBuilder -> AnimBuilder
init builder =
    builder
        |> Color.init elementId (Anim.Color.fromRgba { r = 200, g = 200, b = 200, a = 1 })
        |> Position.initXY elementId 0 0
        |> Scale.initXYZ elementId 1.0 1.0 1.0
        |> Size.initWH elementId 80 80
        |> Rotate.initXYZ elementId 0 0 0
        |> Opacity.init elementId 1.0
        |> Position.for elementId
        |> Position.toXY 0 0
        |> Position.build
        |> Scale.for elementId
        |> Scale.toXYZ 1.0 1.0 1.0
        |> Scale.build
        |> Size.for elementId
        |> Size.toHW 80 80
        |> Size.build
        |> Rotate.for elementId
        |> Rotate.perspective "animation-container" 1000
        |> Rotate.toXYZ 0 0 0
        |> Rotate.build
        |> Opacity.for elementId
        |> Opacity.to 1.0
        |> Opacity.build
        |> Color.for elementId
        |> Color.to (Maybe.withDefault Anim.Color.blue (Anim.Color.fromHex "#3498db"))
        |> Color.build


rotateAnimation : Float -> Easing -> Float -> AnimBuilder -> Rotate.Builder
rotateAnimation speed easing angle builder =
    builder
        |> Rotate.for elementId
        |> Rotate.toZ angle
        |> Rotate.speed speed
        |> Rotate.easing easing


{-| Move + Scale + Rotate with delayed animation starts
Position moves first, then rotation, then scale with bouncy effects
-}
moveScaleRotate : Builder.AnimBuilder -> Builder.AnimBuilder
moveScaleRotate builder =
    builder
        |> positionAnimation 200.0 EaseIn ( 200, 100 )
        |> rotateAnimation 120.0 BounceOut 90
        |> Rotate.delay 500
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
fadeMove : Builder.AnimBuilder -> Builder.AnimBuilder
fadeMove builder =
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
spinScaleColor : Builder.AnimBuilder -> Builder.AnimBuilder
spinScaleColor builder =
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
colorSizeOpacity : Builder.AnimBuilder -> Builder.AnimBuilder
colorSizeOpacity builder =
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
allProperties : Builder.AnimBuilder -> Builder.AnimBuilder
allProperties builder =
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
resetAll : Builder.AnimBuilder -> Builder.AnimBuilder
resetAll builder =
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
