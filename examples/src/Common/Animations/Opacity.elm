module Common.Animations.Opacity exposing
    ( fadeIn
    , fadeOut
    , fadeToHalf
    , fadeToQuarter
    , fadeToggle
    )

{-| Common Opacity animations that work across all animation engines.
-}

import Anim.Extra.Easing as Easing
import Anim.Internal.Builder as Builder
import Anim.Property.Opacity as Opacity


{-| Fade in to fully visible (opacity 1.0)
-}
fadeIn : String -> Builder.AnimBuilder -> Builder.AnimBuilder
fadeIn elementId builder =
    builder
        |> Opacity.for elementId
        |> Opacity.to 1.0
        |> Opacity.duration 2000
        |> Opacity.easing Easing.EaseOut
        |> Opacity.build


{-| Fade out to fully invisible (opacity 0.0)
-}
fadeOut : String -> Builder.AnimBuilder -> Builder.AnimBuilder
fadeOut elementId builder =
    builder
        |> Opacity.for elementId
        |> Opacity.to 0.0
        |> Opacity.duration 2000
        |> Opacity.easing Easing.EaseOut
        |> Opacity.build


{-| Toggle between visible (1.0) and invisible (0.0)
-}
fadeToggle : String -> Float -> Builder.AnimBuilder -> Builder.AnimBuilder
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
fadeToHalf : String -> Builder.AnimBuilder -> Builder.AnimBuilder
fadeToHalf elementId builder =
    builder
        |> Opacity.for elementId
        |> Opacity.to 0.5
        |> Opacity.duration 1000
        |> Opacity.easing Easing.EaseInOut
        |> Opacity.build


{-| Fade to quarter opacity (0.25)
-}
fadeToQuarter : String -> Builder.AnimBuilder -> Builder.AnimBuilder
fadeToQuarter elementId builder =
    builder
        |> Opacity.for elementId
        |> Opacity.to 0.25
        |> Opacity.duration 1000
        |> Opacity.easing Easing.EaseOut
        |> Opacity.build
