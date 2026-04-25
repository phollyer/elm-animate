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

import Anim.Extra.Color as Color
import Easing as Easing
import Anim.Internal.Builder as Builder
import Anim.Property.BackgroundColor as ColorBuilder


changeColor : Color.Color -> String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeColor color elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to color
        |> ColorBuilder.duration 0
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to blue color
-}
changeToBlue : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToBlue =
    changeColor Color.blue


{-| Change to green color
-}
changeToGreen : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToGreen =
    changeColor Color.green


{-| Change to orange color
-}
changeToOrange : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToOrange =
    changeColor (Color.fromRgb { r = 243, g = 156, b = 18 })


{-| Change to red color
-}
changeToRed : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToRed =
    changeColor Color.red


{-| Change to purple color
-}
changeToPurple : String -> Builder.AnimBuilder -> Builder.AnimBuilder
changeToPurple =
    changeColor (Color.fromRgb { r = 155, g = 89, b = 182 })


{-| Reset to default gray color
-}
resetColor : String -> Builder.AnimBuilder -> Builder.AnimBuilder
resetColor =
    changeColor (Color.fromRgb { r = 149, g = 165, b = 166 })
