module Common.Animations.Color exposing
    ( changeToBlue
    , changeToGreen
    , changeToOrange
    , changeToPurple
    , changeToRed
    , resetColor
    )

{-| Common Color animations that work across all animation engines.
-}

import Anim.Easing as Easing
import Anim.Internal.Builder as Builder
import Anim.Property.Color as ColorBuilder exposing (ColorValue(..))


{-| Change to blue color
-}
changeToBlue : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToBlue elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Rgb { r = 52, g = 152, b = 219 })
        |> ColorBuilder.duration 0
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to green color
-}
changeToGreen : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToGreen elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Rgb { r = 46, g = 204, b = 113 })
        |> ColorBuilder.duration 0
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to orange color
-}
changeToOrange : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToOrange elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Rgb { r = 243, g = 156, b = 18 })
        |> ColorBuilder.duration 0
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to red color
-}
changeToRed : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToRed elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Rgb { r = 231, g = 76, b = 60 })
        |> ColorBuilder.duration 0
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to purple color
-}
changeToPurple : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToPurple elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Rgb { r = 155, g = 89, b = 182 })
        |> ColorBuilder.duration 0
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Reset to original gray color
-}
resetColor : String -> Builder.AnimBuilder -> Builder.AnimBuilder
resetColor elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Rgb { r = 149, g = 165, b = 166 })
        |> ColorBuilder.duration 0
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build
