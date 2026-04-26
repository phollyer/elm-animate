module Anim.Property.Custom exposing
    ( Builder, AnimGroupName, CssUnit, CssProperty(..)
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

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Property.for "box" (BorderRadius "px")
            >> Property.to 16
            >> Property.duration 300
            >> Property.easing EaseInOut
            >> Property.build


# Types

@docs Builder, AnimGroupName, CssUnit, CssProperty


# Initialize

@docs init


# Build

@docs for, build


# Configure


## Start Value

All engines track end values, so subsequent animations automatically
use the previous end as the new start. Use `from` to override this
behaviour and set an explicit start value.

**Note:** The Transition Engine ignores start values — the browser always computes
starting values from the current computed style.

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
type CssProperty
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


toCssArgs : CssProperty -> ( String, String )
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
init : AnimGroupName -> CssProperty -> Float -> AnimBuilder -> AnimBuilder
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

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Property.for "box" (BorderRadius "px")
            >> Property.to 16
            >> Property.build

-}
for : AnimGroupName -> CssProperty -> AnimBuilder -> Builder
for animGroupName cssProperty =
    let
        ( name, unit ) =
            toCssArgs cssProperty
    in
    Internal.for animGroupName name unit


{-| Complete the animation configuration and return an `AnimBuilder`.
-}
build : Builder -> AnimBuilder
build =
    Internal.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting value.

If not set explicitly, the animation will use the current value of the property at the moment the animation starts,
or `0` if the property is not currently set.

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
