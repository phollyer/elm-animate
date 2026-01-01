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
import Anim.Property.Color as ColorBuilder exposing (ColorValue(..))


{-| Change to blue color
-}
changeToBlue : String -> builder -> builder
changeToBlue elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Rgb { r = 52, g = 152, b = 219 })
        |> ColorBuilder.duration 1000
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to green color
-}
changeToGreen : String -> builder -> builder
changeToGreen elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Rgb { r = 46, g = 204, b = 113 })
        |> ColorBuilder.duration 1000
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to orange color
-}
changeToOrange : String -> builder -> builder
changeToOrange elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Rgb { r = 243, g = 156, b = 18 })
        |> ColorBuilder.duration 1000
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to red color
-}
changeToRed : String -> builder -> builder
changeToRed elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Rgb { r = 231, g = 76, b = 60 })
        |> ColorBuilder.duration 1000
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Change to purple color
-}
changeToPurple : String -> builder -> builder
changeToPurple elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Rgb { r = 155, g = 89, b = 182 })
        |> ColorBuilder.duration 1000
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build


{-| Reset to original gray color
-}
resetColor : String -> builder -> builder
resetColor elementId builder =
    builder
        |> ColorBuilder.for elementId
        |> ColorBuilder.to (Rgb { r = 149, g = 165, b = 166 })
        |> ColorBuilder.duration 1000
        |> ColorBuilder.easing Easing.EaseInOut
        |> ColorBuilder.build
