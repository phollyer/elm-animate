module Common.Animations.Opacity exposing
    ( fadeIn
    , fadeOut
    , fadeToggle
    , fadeToHalf
    , fadeToQuarter
    )

{-| Common Opacity animations that work across all animation engines.
-}

import Anim.Easing as Easing
import Anim.Property.Opacity as Opacity


{-| Fade in to fully visible (opacity 1.0)
-}
fadeIn : String -> builder -> builder
fadeIn elementId builder =
    builder
        |> Opacity.for elementId
        |> Opacity.to 1.0
        |> Opacity.duration 2000
        |> Opacity.easing Easing.EaseOut
        |> Opacity.build


{-| Fade out to fully invisible (opacity 0.0)
-}
fadeOut : String -> builder -> builder
fadeOut elementId builder =
    builder
        |> Opacity.for elementId
        |> Opacity.to 0.0
        |> Opacity.duration 2000
        |> Opacity.easing Easing.EaseOut
        |> Opacity.build


{-| Toggle between visible (1.0) and invisible (0.0)
-}
fadeToggle : String -> Float -> builder -> builder
fadeToggle elementId currentOpacity builder =
    let
        newOpacity =
            if currentOpacity > 0.5 then
                0.0

            else
                1.0
    in
    builder
        |> Opacity.for elementId
        |> Opacity.to newOpacity
        |> Opacity.duration 1500
        |> Opacity.easing Easing.EaseInOut
        |> Opacity.build


{-| Fade to half opacity (0.5)
-}
fadeToHalf : String -> builder -> builder
fadeToHalf elementId builder =
    builder
        |> Opacity.for elementId
        |> Opacity.to 0.5
        |> Opacity.duration 1000
        |> Opacity.easing Easing.EaseInOut
        |> Opacity.build


{-| Fade to quarter opacity (0.25)
-}
fadeToQuarter : String -> builder -> builder
fadeToQuarter elementId builder =
    builder
        |> Opacity.for elementId
        |> Opacity.to 0.25
        |> Opacity.duration 1000
        |> Opacity.easing Easing.EaseOut
        |> Opacity.build
