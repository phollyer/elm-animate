module Common.Animations.Mixed exposing
    ( allProperties
    , colorSizeOpacity
    , elementId
    , fadeMove
    , init
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

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.Color exposing (Color)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.BackgroundColor as Color
import Anim.Property.Opacity as Opacity
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate


elementId : String
elementId =
    "mixed-box"


colorAnimation : Float -> Easing -> Color -> AnimBuilder -> Color.Builder
colorAnimation speed easing targetColor =
    Color.for elementId
        >> Color.to targetColor
        >> Color.speed speed
        >> Color.easing easing


opacityAnimation : Float -> Easing -> Float -> AnimBuilder -> Opacity.Builder
opacityAnimation speed easing targetOpacity =
    Opacity.for elementId
        >> Opacity.to targetOpacity
        >> Opacity.speed speed
        >> Opacity.easing easing


positionAnimation : Float -> Easing -> ( Float, Float ) -> AnimBuilder -> Translate.Builder
positionAnimation speed easing ( x, y ) =
    Translate.for elementId
        >> Translate.toXY x y
        >> Translate.speed speed
        >> Translate.easing easing


rotateAnimation : Float -> Easing -> Float -> AnimBuilder -> Rotate.Builder
rotateAnimation speed easing angle =
    Rotate.for elementId
        >> Rotate.toZ angle
        >> Rotate.speed speed
        >> Rotate.easing easing


scaleAnimation : Float -> Easing -> ( Float, Float ) -> AnimBuilder -> Scale.Builder
scaleAnimation speed easing ( sx, sy ) =
    Scale.for elementId
        >> Scale.toXY sx sy
        >> Scale.speed speed
        >> Scale.easing easing


sizeAnimation : Float -> Easing -> ( Float, Float ) -> AnimBuilder -> Size.Builder
sizeAnimation speed easing ( w, h ) =
    Size.for elementId
        >> Size.toHW h w
        >> Size.speed speed
        >> Size.easing easing


init : AnimBuilder -> AnimBuilder
init =
    Color.init elementId (Anim.Extra.Color.fromRgba { r = 200, g = 200, b = 200, a = 1 })
        >> Opacity.init elementId 1.0
        >> Translate.initXY elementId 0 0
        >> Rotate.initXYZ elementId 0 0 0
        >> Scale.initXYZ elementId 1.0 1.0 1.0
        >> Size.initWH elementId 80 80


{-| Move + Scale + Rotate with delayed animation starts
Position moves first, then rotation, then scale with bouncy effects
-}
moveScaleRotate : AnimBuilder -> AnimBuilder
moveScaleRotate =
    positionAnimation 200.0 EaseIn ( 200, 100 )
        >> Translate.build
        >> rotateAnimation 120.0 BounceOut 90
        >> Rotate.delay 500
        >> Rotate.build
        >> scaleAnimation 2.0 BounceOut ( 1.5, 1.9 )
        >> Scale.delay 2000
        >> Scale.build


{-| Fade + Move with synchronized timing
Opacity and position change together smoothly
-}
fadeMove : AnimBuilder -> AnimBuilder
fadeMove =
    opacityAnimation 2.0 EaseOut 0.3
        >> Opacity.build
        >> positionAnimation 200.0 EaseOut ( 250, 80 )
        >> Translate.build


{-| Spin + Scale + Color change with coordinated timing
Rotation, scaling, and color morph working together
-}
spinScaleColor : AnimBuilder -> AnimBuilder
spinScaleColor =
    colorAnimation 1.0 EaseInOut (Anim.Extra.Color.fromHsl { h = 120 / 360, s = 0.8, l = 0.6 })
        >> Color.build
        >> rotateAnimation 180.0 EaseInOut 180
        >> Rotate.build
        >> scaleAnimation 1.5 EaseInOut ( 0.8, 0.8 )
        >> Scale.build


{-| Color + Size + Opacity coordination
Background color, element size, and opacity changing together
-}
colorSizeOpacity : AnimBuilder -> AnimBuilder
colorSizeOpacity =
    colorAnimation 1.5 EaseOut (Anim.Extra.Color.fromHsl { h = 280 / 360, s = 0.7, l = 0.5 })
        >> Color.build
        >> opacityAnimation 1.5 EaseOut 0.8
        >> Opacity.build
        >> sizeAnimation 80.0 EaseOut ( 120, 120 )
        >> Size.build


{-| All properties animation - kitchen sink!
Position, Scale, Size, Rotation, Opacity, and Color all animating
-}
allProperties : AnimBuilder -> AnimBuilder
allProperties =
    colorAnimation 1.0 EaseOut (Anim.Extra.Color.fromHsl { h = 60 / 360, s = 0.9, l = 0.7 })
        >> Color.build
        >> opacityAnimation 1.2 EaseOut 0.6
        >> Opacity.build
        >> positionAnimation 200.0 EaseInOut ( 200, 200 )
        >> Translate.build
        >> rotateAnimation 200.0 EaseInOut 360
        >> Rotate.build
        >> scaleAnimation 1.5 EaseOut ( 1.3, 1.3 )
        >> Scale.build
        >> sizeAnimation 60.0 EaseOut ( 100, 100 )
        >> Size.build


{-| Reset all properties to initial state
Returns all animated properties to their starting values
-}
resetAll : AnimBuilder -> AnimBuilder
resetAll =
    colorAnimation 300.0 EaseOut (Anim.Extra.Color.fromHsl { h = 207 / 360, s = 0.9, l = 0.54 })
        >> Color.build
        >> opacityAnimation 1.5 EaseInOut 1.0
        >> Opacity.build
        >> positionAnimation 200.0 BounceOut ( 0, 0 )
        >> Translate.build
        >> rotateAnimation 180.0 EaseInOut 0
        >> Rotate.build
        >> scaleAnimation 1.5 EaseInOut ( 1.0, 1.0 )
        >> Scale.build
        >> sizeAnimation 2000 EaseInOut ( 80, 80 )
        >> Size.build
