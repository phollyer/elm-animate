module Anim.Property.Custom exposing
    ( Builder, AnimGroupName, CssProperty(..)
    , init
    , for, build
    , from
    , to
    , delay, duration, speed
    , easing
    )

{-| Animate any numeric CSS property with a unit.

This is an escape hatch for CSS properties not covered by the first-class
property modules (Translate, Rotate, Scale, Opacity, etc.).

    import Anim.Property.Custom as Property
    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Property.for "box" BorderRadius "px"
            >> Property.to 16
            >> Property.duration 300
            >> Property.easing EaseInOut
            >> Property.build


# Types

@docs Builder, AnimGroupName, CssProperty


# Initialize

@docs init


# Build

@docs for, build


# Configure


## Start Value

@docs from


## End Value

@docs to


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Property as Internal
import Easing exposing (Easing)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Type alias for the internal `CustomPropertyBuilder`.
-}
type alias Builder =
    Internal.CustomPropertyBuilder


{-| A typed set of common numeric CSS properties with a custom escape hatch.
-}
type CssProperty
    = -- Standard CSS
      BorderBottomLeftRadius
    | BorderBottomRightRadius
    | BorderBottomWidth
    | BorderLeftWidth
    | BorderRadius
    | BorderRightWidth
    | BorderTopLeftRadius
    | BorderTopRightRadius
    | BorderTopWidth
    | BorderWidth
    | Bottom
    | ColumnGap
    | ColumnWidth
    | FontSize
    | Gap
    | Inset
    | Left
    | LetterSpacing
    | LineHeight
    | Margin
    | MarginBottom
    | MarginLeft
    | MarginRight
    | MarginTop
    | MaxHeight
    | MaxWidth
    | MinHeight
    | MinWidth
    | OutlineOffset
    | OutlineWidth
    | Padding
    | PaddingBottom
    | PaddingLeft
    | PaddingRight
    | PaddingTop
    | Perspective
    | Right
    | RowGap
    | TabSize
    | TextIndent
    | Top
    | WordSpacing
      -- Flex
    | FlexBasis
    | FlexGrow
    | FlexShrink
      -- SVG
    | Cx
    | Cy
    | R
    | Rx
    | Ry
    | StrokeDashoffset
    | StrokeWidth
      -- Escape hatch
    | CustomProperty String


toCssPropertyName : CssProperty -> String
toCssPropertyName cssProperty =
    case cssProperty of
        -- Standard CSS
        BorderBottomLeftRadius ->
            "border-bottom-left-radius"

        BorderBottomRightRadius ->
            "border-bottom-right-radius"

        BorderBottomWidth ->
            "border-bottom-width"

        BorderLeftWidth ->
            "border-left-width"

        BorderRadius ->
            "border-radius"

        BorderRightWidth ->
            "border-right-width"

        BorderTopLeftRadius ->
            "border-top-left-radius"

        BorderTopRightRadius ->
            "border-top-right-radius"

        BorderTopWidth ->
            "border-top-width"

        BorderWidth ->
            "border-width"

        Bottom ->
            "bottom"

        ColumnGap ->
            "column-gap"

        ColumnWidth ->
            "column-width"

        FontSize ->
            "font-size"

        Gap ->
            "gap"

        Inset ->
            "inset"

        Left ->
            "left"

        LetterSpacing ->
            "letter-spacing"

        LineHeight ->
            "line-height"

        Margin ->
            "margin"

        MarginBottom ->
            "margin-bottom"

        MarginLeft ->
            "margin-left"

        MarginRight ->
            "margin-right"

        MarginTop ->
            "margin-top"

        MaxHeight ->
            "max-height"

        MaxWidth ->
            "max-width"

        MinHeight ->
            "min-height"

        MinWidth ->
            "min-width"

        OutlineOffset ->
            "outline-offset"

        OutlineWidth ->
            "outline-width"

        Padding ->
            "padding"

        PaddingBottom ->
            "padding-bottom"

        PaddingLeft ->
            "padding-left"

        PaddingRight ->
            "padding-right"

        PaddingTop ->
            "padding-top"

        Perspective ->
            "perspective"

        Right ->
            "right"

        RowGap ->
            "row-gap"

        TabSize ->
            "tab-size"

        TextIndent ->
            "text-indent"

        Top ->
            "top"

        WordSpacing ->
            "word-spacing"

        -- Flex
        FlexBasis ->
            "flex-basis"

        FlexGrow ->
            "flex-grow"

        FlexShrink ->
            "flex-shrink"

        -- SVG
        Cx ->
            "cx"

        Cy ->
            "cy"

        R ->
            "r"

        Rx ->
            "rx"

        Ry ->
            "ry"

        StrokeDashoffset ->
            "stroke-dashoffset"

        StrokeWidth ->
            "stroke-width"

        -- Escape hatch
        CustomProperty cssName ->
            cssName



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Set the initial value for a custom CSS property.

Use this to initialize the property in your Engine's `init` function.

    import Anim.Engine.* as Engine
    import Anim.Property.Custom as Property

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState =
                Engine.init
                    [ Property.init "box" BorderRadius "px" 0 ]
          }
        , Cmd.none
        )

-}
init : AnimGroupName -> CssProperty -> String -> Float -> AnimBuilder -> AnimBuilder
init animGroupName cssProperty unit value animBuilder =
    animBuilder
        |> Internal.for animGroupName (toCssPropertyName cssProperty) unit
        |> Internal.from value
        |> Internal.to value
        |> Internal.build



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a custom property animation `Builder`.

The first argument is the animation group name, the second is the CSS property
name, and the third is the CSS unit.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Property.for "box" BorderRadius "px"
            >> Property.to 16
            >> Property.build

-}
for : AnimGroupName -> CssProperty -> String -> AnimBuilder -> Builder
for animGroupName cssProperty unit =
    Internal.for animGroupName (toCssPropertyName cssProperty) unit


{-| Complete the animation configuration and return an `AnimBuilder`.
-}
build : Builder -> AnimBuilder
build =
    Internal.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting value.
-}
from : Float -> Builder -> Builder
from =
    Internal.from



-- ============================================================
-- TO
-- ============================================================


{-| Set the target value.
-}
to : Float -> Builder -> Builder
to =
    Internal.to



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the animation speed (units per second).
-}
speed : Float -> Builder -> Builder
speed =
    Internal.speed


{-| Set the animation duration (milliseconds).
-}
duration : Int -> Builder -> Builder
duration =
    Internal.duration


{-| Set the delay (milliseconds) before the animation starts.
-}
delay : Int -> Builder -> Builder
delay =
    Internal.delay



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function.
-}
easing : Easing -> Builder -> Builder
easing =
    Internal.easing
