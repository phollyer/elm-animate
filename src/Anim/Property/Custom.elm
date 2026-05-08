module Anim.Property.Custom exposing
    ( Builder, AnimGroupName, CssUnit, Property(..)
    , init
    , for, build
    , from
    , to
    , delay, duration, speed
    , easing
    )

{-| Animate any numeric CSS property not covered by the first-class
property modules (Translate, Rotate, Scale etc.).

    import Anim.Property.Custom as Property
    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Property.for "box" (BorderRadius "px")
            >> Property.to 16
            >> Property.duration 300
            >> Property.easing EaseInOut
            >> Property.build


# Types

@docs Builder, AnimGroupName, CssUnit, Property


# Initialize

@docs init


# Build

@docs for, build


# Configure


## Start Value

When not set, the engine determines the start value - behaviour
varies by engine and context.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/engines/overview/#start-values)
for details.

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
type alias Builder mode =
    Internal.CustomPropertyBuilder mode


{-| Type alias for CSS units.

Can be any valid CSS unit, such as `"px"`, `"em"`, `"%"` etc.

    Property.for "box" (BorderRadius "px") --- uses pixels

    Property.for "box" (BorderRadius "%") --- uses percentage

-}
type alias CssUnit =
    String


{-| A typed set of common numeric CSS properties with a custom escape hatch.

Use the escape hatch `CustomProperty` to animate any numeric CSS property not currently supported out of the box.

    Property.for "box" (CustomProperty "property-name" "unit")
        >> Property.to 32
        >> Property.build

-}
type Property
    = -- Standard CSS
      BorderBottomLeftRadius CssUnit
    | BorderBottomRightRadius CssUnit
    | BorderBottomWidth CssUnit
    | BorderLeftWidth CssUnit
    | BorderRadius CssUnit
    | BorderRightWidth CssUnit
    | BorderTopLeftRadius CssUnit
    | BorderTopRightRadius CssUnit
    | BorderTopWidth CssUnit
    | BorderWidth CssUnit
    | Bottom CssUnit
    | ColumnGap CssUnit
    | ColumnWidth CssUnit
    | FontSize CssUnit
    | Gap CssUnit
    | Inset CssUnit
    | Left CssUnit
    | LetterSpacing CssUnit
    | LineHeight CssUnit
    | Margin CssUnit
    | MarginBottom CssUnit
    | MarginLeft CssUnit
    | MarginRight CssUnit
    | MarginTop CssUnit
    | MaxHeight CssUnit
    | MaxWidth CssUnit
    | MinHeight CssUnit
    | MinWidth CssUnit
    | OutlineOffset CssUnit
    | OutlineWidth CssUnit
    | Padding CssUnit
    | PaddingBottom CssUnit
    | PaddingLeft CssUnit
    | PaddingRight CssUnit
    | PaddingTop CssUnit
    | Perspective CssUnit
    | Right CssUnit
    | RowGap CssUnit
    | TabSize CssUnit
    | TextIndent CssUnit
    | Top CssUnit
    | WordSpacing CssUnit
      -- Flex
    | FlexBasis CssUnit
    | FlexGrow
    | FlexShrink
      -- SVG
    | Cx
    | Cy
    | R
    | Rx
    | Ry
    | StrokeDashOffset
    | StrokeWidth
      -- Escape hatch
    | CustomProperty String CssUnit


toCssArgs : Property -> ( String, String )
toCssArgs cssProperty =
    case cssProperty of
        -- Standard CSS
        BorderBottomLeftRadius unit ->
            ( "border-bottom-left-radius", unit )

        BorderBottomRightRadius unit ->
            ( "border-bottom-right-radius", unit )

        BorderBottomWidth unit ->
            ( "border-bottom-width", unit )

        BorderLeftWidth unit ->
            ( "border-left-width", unit )

        BorderRadius unit ->
            ( "border-radius", unit )

        BorderRightWidth unit ->
            ( "border-right-width", unit )

        BorderTopLeftRadius unit ->
            ( "border-top-left-radius", unit )

        BorderTopRightRadius unit ->
            ( "border-top-right-radius", unit )

        BorderTopWidth unit ->
            ( "border-top-width", unit )

        BorderWidth unit ->
            ( "border-width", unit )

        Bottom unit ->
            ( "bottom", unit )

        ColumnGap unit ->
            ( "column-gap", unit )

        ColumnWidth unit ->
            ( "column-width", unit )

        FontSize unit ->
            ( "font-size", unit )

        Gap unit ->
            ( "gap", unit )

        Inset unit ->
            ( "inset", unit )

        Left unit ->
            ( "left", unit )

        LetterSpacing unit ->
            ( "letter-spacing", unit )

        LineHeight unit ->
            ( "line-height", unit )

        Margin unit ->
            ( "margin", unit )

        MarginBottom unit ->
            ( "margin-bottom", unit )

        MarginLeft unit ->
            ( "margin-left", unit )

        MarginRight unit ->
            ( "margin-right", unit )

        MarginTop unit ->
            ( "margin-top", unit )

        MaxHeight unit ->
            ( "max-height", unit )

        MaxWidth unit ->
            ( "max-width", unit )

        MinHeight unit ->
            ( "min-height", unit )

        MinWidth unit ->
            ( "min-width", unit )

        OutlineOffset unit ->
            ( "outline-offset", unit )

        OutlineWidth unit ->
            ( "outline-width", unit )

        Padding unit ->
            ( "padding", unit )

        PaddingBottom unit ->
            ( "padding-bottom", unit )

        PaddingLeft unit ->
            ( "padding-left", unit )

        PaddingRight unit ->
            ( "padding-right", unit )

        PaddingTop unit ->
            ( "padding-top", unit )

        Perspective unit ->
            ( "perspective", unit )

        Right unit ->
            ( "right", unit )

        RowGap unit ->
            ( "row-gap", unit )

        TabSize unit ->
            ( "tab-size", unit )

        TextIndent unit ->
            ( "text-indent", unit )

        Top unit ->
            ( "top", unit )

        WordSpacing unit ->
            ( "word-spacing", unit )

        -- Flex
        FlexBasis unit ->
            ( "flex-basis", unit )

        FlexGrow ->
            ( "flex-grow", "" )

        FlexShrink ->
            ( "flex-shrink", "" )

        -- SVG
        Cx ->
            ( "cx", "" )

        Cy ->
            ( "cy", "" )

        R ->
            ( "r", "" )

        Rx ->
            ( "rx", "" )

        Ry ->
            ( "ry", "" )

        StrokeDashOffset ->
            ( "stroke-dashoffset", "" )

        StrokeWidth ->
            ( "stroke-width", "" )

        -- Escape hatch
        CustomProperty name unit ->
            ( name, unit )



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
                    [ Property.init "box" (BorderRadius "px") 0 ]
          }
        , Cmd.none
        )

-}
init : AnimGroupName -> Property -> Float -> AnimBuilder mode -> AnimBuilder mode
init animGroupName cssProperty value animBuilder =
    let
        ( name, unit ) =
            toCssArgs cssProperty
    in
    animBuilder
        |> Internal.for animGroupName name unit
        |> Internal.from value
        |> Internal.to value
        |> Internal.build



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a custom property animation `Builder`.

The first argument is the animation group name, the second is the CSS property.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Property.for "box" (BorderRadius "px")
            >> Property.to 16
            >> Property.build

-}
for : AnimGroupName -> Property -> AnimBuilder mode -> Builder mode
for animGroupName cssProperty =
    let
        ( name, unit ) =
            toCssArgs cssProperty
    in
    Internal.for animGroupName name unit


{-| Complete the animation configuration and return an `AnimBuilder`.
-}
build : Builder mode -> AnimBuilder mode
build =
    Internal.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting value.
-}
from : Float -> Builder mode -> Builder mode
from =
    Internal.from



-- ============================================================
-- TO
-- ============================================================


{-| Set the target value.
-}
to : Float -> Builder mode -> Builder mode
to =
    Internal.to



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the animation speed (units per second).
-}
speed : Float -> Builder mode -> Builder mode
speed =
    Internal.speed


{-| Set the animation duration (milliseconds).
-}
duration : Int -> Builder mode -> Builder mode
duration =
    Internal.duration


{-| Set the delay (milliseconds) before the animation starts.
-}
delay : Int -> Builder mode -> Builder mode
delay =
    Internal.delay



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function.
-}
easing : Easing -> Builder mode -> Builder mode
easing =
    Internal.easing
