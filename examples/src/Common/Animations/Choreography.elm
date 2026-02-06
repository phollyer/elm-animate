module Common.Animations.Choreography exposing
    ( circleFormation
    , elements
    , init
    , resetToOrigin
    , scatterFormation
    )

{-| Common Choreography animations that work across all animation engines.

These functions provide coordinated multi-element animations for creating
formations and patterns. Each animation function takes an AnimBuilder and returns
an AnimBuilder, making them portable across all animation engines.

FEATURES:

  - ✅ Scatter formation (organic random-looking spread)
  - ✅ Circle formation (perfect hexagon arrangement)
  - ✅ Reset formation (return all elements to origin)

FORMATIONS:

  - **Scatter**: Elements spread in an organic pattern across the canvas
  - **Circle**: Elements arranged in a perfect hexagonal formation around a center
  - **Reset**: All elements return to (0, 0) origin position

-}

import Anim.Extra.Easing as Easing
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Property.Translate as Translate


initialCoords : List ( Float, Float )
initialCoords =
    [ ( 0, 0 ) -- elementA
    , ( 0, 0 ) -- elementB
    , ( 0, 0 ) -- elementC
    , ( 0, 0 ) -- elementD
    , ( 0, 0 ) -- elementE
    , ( 0, 0 ) -- elementF
    ]


scatterCoords : List ( Float, Float )
scatterCoords =
    [ ( 80, 60 ) -- elementA
    , ( 320, 80 ) -- elementB
    , ( 40, 300 ) -- elementC
    , ( 380, 260 ) -- elementD
    , ( 60, 120 ) -- elementE
    , ( 350, 320 ) -- elementF
    ]


{-| Center at (225, 180) with radius of 90 pixels.
Elements are positioned at 60-degree intervals around the circle.
-}
circleCoords : List ( Float, Float )
circleCoords =
    let
        centerX =
            225

        centerY =
            180

        radius =
            90
    in
    -- Calculate positions for 6 points around a circle (hexagon)
    [ ( centerX + radius, centerY )
    , ( centerX + (radius * 0.5), centerY + (radius * 0.866) )
    , ( centerX - (radius * 0.5), centerY + (radius * 0.866) )
    , ( centerX - radius, centerY )
    , ( centerX - (radius * 0.5), centerY - (radius * 0.866) )
    , ( centerX + (radius * 0.5), centerY - (radius * 0.866) )
    ]


elements : List ( Float, Float ) -> List ( String, ( Float, Float ) )
elements coordinates =
    List.map2
        (\elementId ( x, y ) -> ( elementId, ( x, y ) ))
        [ "elementA"
        , "elementB"
        , "elementC"
        , "elementD"
        , "elementE"
        , "elementF"
        ]
        coordinates


{-| Build the animation for multiple elements based on a list of (elementId, (x, y)) tuples.
-}
buildAnimation : List ( String, ( Float, Float ) ) -> AnimBuilder -> AnimBuilder
buildAnimation elementsList builder =
    List.foldl
        (\( elementId, ( x, y ) ) builder_ ->
            builder_
                |> Translate.for elementId
                |> Translate.toXY x y
                |> Translate.build
        )
        builder
        elementsList


{-| Set up the initial state for all elements before applying formations.
-}
init : AnimBuilder -> AnimBuilder
init builder =
    List.foldl
        (\( elementId, ( x, y ) ) builder_ ->
            Translate.initXY elementId x y builder_
        )
        builder
        (elements initialCoords)


{-| Create a scatter formation with elements spread organically across the canvas.
-}
scatterFormation : AnimBuilder -> AnimBuilder
scatterFormation =
    buildAnimation (elements scatterCoords)


{-| Create a perfect circle formation with 6 elements arranged in a hexagon
-}
circleFormation : AnimBuilder -> AnimBuilder
circleFormation =
    buildAnimation (elements circleCoords)


{-| Reset all elements to the origin position (0, 0)
Useful for returning to the starting formation before applying new patterns.
-}
resetToOrigin : AnimBuilder -> AnimBuilder
resetToOrigin =
    buildAnimation (elements initialCoords)
