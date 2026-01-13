module Common.Animations.BackgroundColor exposing
    ( changeToBlue
    , changeToGreen
    , changeToOrange
    , changeToPurple
    , changeToRed
    , resetColor
    )

{-| Common BackgroundColor animations that work across all animation engines.
-}

import Anim.Color as Color
import Anim.Easing as Easing
import Anim.Internal.Builder as Builder
import Anim.Property.BackgroundColor as ColorBuilder


{-| Change to blue color
-}
changeToBlue : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToBlue elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to Color.blue
        |> ColorBuilder.duration 0
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to green color
-}
changeToGreen : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToGreen elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to Color.green
        |> ColorBuilder.duration 0
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to orange color
-}
changeToOrange : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToOrange elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Color.fromRgb { r = 243, g = 156, b = 18 })
        |> ColorBuilder.duration 0
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to red color
-}
changeToRed : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToRed elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to Color.red
        |> ColorBuilder.duration 0
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to purple color
-}
changeToPurple : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToPurple elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Color.fromRgb { r = 155, g = 89, b = 182 })
        |> ColorBuilder.duration 0
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Reset to default gray color
-}
resetColor : String -> Builder.AnimBuilder -> Builder.AnimBuilder
resetColor elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Color.fromRgb { r = 149, g = 165, b = 166 })
        |> ColorBuilder.duration 0
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build
