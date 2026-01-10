module Common.Animations.Choreography exposing
    ( scatterFormation
    , circleFormation
    , resetToOrigin
    , ElementId
    )

{-| Common Choreography animations that work across all animation engines.

These functions provide coordinated multi-element animations for creating
formations and patterns. Each function takes an AnimBuilder and returns
an AnimBuilder, making them portable across all animation engines.

FEATURES:
- ✅ Scatter formation (organic random-looking spread)
- ✅ Circle formation (perfect hexagon arrangement)  
- ✅ Reset formation (return all elements to origin)
- ✅ Consistent element naming (elementA through elementF)

FORMATIONS:
- **Scatter**: Elements spread in an organic pattern across the canvas
- **Circle**: Elements arranged in a perfect hexagonal formation around a center
- **Reset**: All elements return to (0, 0) origin position

-}

import Anim.Easing as Easing
import Anim.Internal.Builder as Builder
import Anim.Property.Position as Position


{-| Type alias for element identifiers used in choreography
-}
type alias ElementId =
    String


{-| Create a scatter formation with elements spread organically across the canvas
The scatter pattern uses the same coordinates across all examples for consistency:
- elementA: (80, 60)   - Top left area
- elementB: (320, 80)  - Top right area  
- elementC: (40, 300)  - Bottom left area
- elementD: (380, 260) - Bottom right area
- elementE: (60, 120)  - Mid left area
- elementF: (350, 320) - Bottom right area
-}
scatterFormation : Builder.AnimBuilder -> Builder.AnimBuilder
scatterFormation builder =
    builder
        |> Position.for "elementA"
        |> Position.toXY 80 60
        |> Position.build
        |> Position.for "elementB" 
        |> Position.toXY 320 80
        |> Position.build
        |> Position.for "elementC"
        |> Position.toXY 40 300
        |> Position.build
        |> Position.for "elementD"
        |> Position.toXY 380 260
        |> Position.build
        |> Position.for "elementE"
        |> Position.toXY 60 120
        |> Position.build
        |> Position.for "elementF"
        |> Position.toXY 350 320
        |> Position.build


{-| Create a perfect circle formation with 6 elements arranged in a hexagon
Center at (225, 180) with radius of 90 pixels.
Elements are positioned at 60-degree intervals around the circle.
-}
circleFormation : Builder.AnimBuilder -> Builder.AnimBuilder
circleFormation builder =
    let
        centerX = 225
        centerY = 180  
        radius = 90
        
        -- Calculate positions for 6 points around a circle (hexagon)
        elementA_X = centerX + round radius
        elementA_Y = centerY
        
        elementB_X = centerX + round (radius * 0.5)
        elementB_Y = centerY + round (radius * 0.866)
        
        elementC_X = centerX - round (radius * 0.5)
        elementC_Y = centerY + round (radius * 0.866)
        
        elementD_X = centerX - round radius
        elementD_Y = centerY
        
        elementE_X = centerX - round (radius * 0.5)
        elementE_Y = centerY - round (radius * 0.866)
        
        elementF_X = centerX + round (radius * 0.5)
        elementF_Y = centerY - round (radius * 0.866)
    in
    builder
        |> Position.for "elementA"
        |> Position.toXY (toFloat elementA_X) (toFloat elementA_Y)
        |> Position.build
        |> Position.for "elementB"
        |> Position.toXY (toFloat elementB_X) (toFloat elementB_Y)
        |> Position.build
        |> Position.for "elementC"
        |> Position.toXY (toFloat elementC_X) (toFloat elementC_Y)
        |> Position.build
        |> Position.for "elementD"
        |> Position.toXY (toFloat elementD_X) (toFloat elementD_Y)
        |> Position.build
        |> Position.for "elementE"
        |> Position.toXY (toFloat elementE_X) (toFloat elementE_Y)
        |> Position.build
        |> Position.for "elementF"
        |> Position.toXY (toFloat elementF_X) (toFloat elementF_Y)
        |> Position.build


{-| Reset all elements to the origin position (0, 0)
Useful for returning to the starting formation before applying new patterns.
-}
resetToOrigin : Builder.AnimBuilder -> Builder.AnimBuilder
resetToOrigin builder =
    builder
        |> Position.for "elementA"
        |> Position.toXY 0 0
        |> Position.build
        |> Position.for "elementB"
        |> Position.toXY 0 0
        |> Position.build
        |> Position.for "elementC"
        |> Position.toXY 0 0
        |> Position.build
        |> Position.for "elementD"
        |> Position.toXY 0 0
        |> Position.build
        |> Position.for "elementE"
        |> Position.toXY 0 0
        |> Position.build
        |> Position.for "elementF"
        |> Position.toXY 0 0
        |> Position.build