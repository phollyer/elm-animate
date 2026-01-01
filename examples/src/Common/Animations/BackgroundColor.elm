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

import Anim.Easing as Easing
import Anim.Internal.Builder as Builder
import Anim.Property.BackgroundColor as ColorBuilder exposing (Color(..))


{-| Change to blue color
-}
changeToBlue : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToBlue elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Hex "#3498db")
        |> ColorBuilder.duration 1000
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to green color
-}
changeToGreen : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToGreen elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Hex "#2ecc71")
        |> ColorBuilder.duration 1000
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to orange color
-}
changeToOrange : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToOrange elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Hex "#f39c12")
        |> ColorBuilder.duration 1000
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to red color
-}
changeToRed : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToRed elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Hex "#e74c3c")
        |> ColorBuilder.duration 1000
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to purple color
-}
changeToPurple : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToPurple elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Hex "#9b59b6")
        |> ColorBuilder.duration 1000
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Reset to default gray color
-}
resetColor : String -> Builder.AnimBuilder -> Builder.AnimBuilder
resetColor elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Hex "#95a5a6")
        |> ColorBuilder.duration 1000
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build
