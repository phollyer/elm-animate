module Anim.Property.CustomColor exposing
    ( Builder, AnimGroupName, ColorProperty(..)
    , init
    , for, build
    , from
    , to
    , delay, duration, speed
    , easing
    )

{-| Animate any CSS color property.

    import Anim.Extra.Color as Color
    import Anim.Property.CustomColor as PropertyColor
    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        PropertyColor.for "box" BackgroundColor
            >> PropertyColor.to (Color.rgb 255 0 0)
            >> PropertyColor.duration 300
            >> PropertyColor.easing EaseInOut
            >> PropertyColor.build


# Types

@docs Builder, AnimGroupName, ColorProperty


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
import Anim.Internal.Extra.Color exposing (Color)
import Anim.Internal.PropertyColor as Internal
import Easing exposing (Easing)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Type alias for the internal `CustomColorBuilder`.
-}
type alias Builder =
    Internal.CustomColorBuilder


{-| A typed set of common color properties with a custom escape hatch.

Use the escape hatch `CustomColorProperty` to animate any CSS color property not currently supported out of the box.

    PropertyColor.for "box" (CustomColorProperty "property-name")
        >> PropertyColor.to (Color.rgb 255 0 0)
        >> PropertyColor.build

-}
type ColorProperty
    = AccentColor
    | BackgroundColor
    | BorderColor
    | BorderTopColor
    | BorderRightColor
    | BorderBottomColor
    | BorderLeftColor
    | BorderBlockColor
    | BorderBlockStartColor
    | BorderBlockEndColor
    | BorderInlineColor
    | BorderInlineStartColor
    | BorderInlineEndColor
    | CaretColor
    | ColumnRuleColor
    | OutlineColor
    | TextColor
    | TextDecorationColor
    | TextEmphasisColor
    | Fill
    | Stroke
    | StopColor
    | FloodColor
    | LightingColor
    | CustomColorProperty String



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Set the initial value for a custom color CSS property.

Use this to initialize the property in your Engine's `init` function.

    import Anim.Engine.* as Engine
    import Anim.Extra.Color as Color
    import Anim.Property.CustomColor as PropertyColor

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState =
                Engine.init
                    [ PropertyColor.init "box" BorderColor <|
                        Color.rgb 99 102 241
                    ]
          }
        , Cmd.none
        )

-}
init : AnimGroupName -> ColorProperty -> Color -> AnimBuilder -> AnimBuilder
init animGroupName cssProperty value animBuilder =
    animBuilder
        |> Internal.for animGroupName (toCssPropertyName cssProperty)
        |> Internal.from value
        |> Internal.to value
        |> Internal.build



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a custom color property animation `Builder`.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        PropertyColor.for "box" TextColor
            >> PropertyColor.to (Color.rgb 255 0 0)
            >> PropertyColor.build

-}
for : AnimGroupName -> ColorProperty -> AnimBuilder -> Builder
for animGroupName cssProperty =
    Internal.for animGroupName (toCssPropertyName cssProperty)


toCssPropertyName : ColorProperty -> String
toCssPropertyName cssProperty =
    case cssProperty of
        BackgroundColor ->
            "background-color"

        AccentColor ->
            "accent-color"

        TextColor ->
            "color"

        BorderColor ->
            "border-color"

        BorderTopColor ->
            "border-top-color"

        BorderRightColor ->
            "border-right-color"

        BorderBottomColor ->
            "border-bottom-color"

        BorderLeftColor ->
            "border-left-color"

        BorderBlockColor ->
            "border-block-color"

        BorderBlockStartColor ->
            "border-block-start-color"

        BorderBlockEndColor ->
            "border-block-end-color"

        BorderInlineColor ->
            "border-inline-color"

        BorderInlineStartColor ->
            "border-inline-start-color"

        BorderInlineEndColor ->
            "border-inline-end-color"

        OutlineColor ->
            "outline-color"

        TextDecorationColor ->
            "text-decoration-color"

        TextEmphasisColor ->
            "text-emphasis-color"

        CaretColor ->
            "caret-color"

        Fill ->
            "fill"

        Stroke ->
            "stroke"

        StopColor ->
            "stop-color"

        FloodColor ->
            "flood-color"

        LightingColor ->
            "lighting-color"

        ColumnRuleColor ->
            "column-rule-color"

        CustomColorProperty cssName ->
            cssName


{-| Complete the animation configuration and return an `AnimBuilder`.
-}
build : Builder -> AnimBuilder
build =
    Internal.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting color.

If not set explicitly, the animation will use the current value
of the property at the moment the animation starts, or transparent white
if the property is not currently set.

-}
from : Color -> Builder -> Builder
from =
    Internal.from



-- ============================================================
-- TO
-- ============================================================


{-| Set the target color.
-}
to : Color -> Builder -> Builder
to =
    Internal.to



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the animation speed (0.0 to 1.0 range per second).
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
