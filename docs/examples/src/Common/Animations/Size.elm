module Common.Animations.Size exposing
    ( sizeLarge
    , sizeReset
    , sizeSquare
    , sizeTall
    , sizeWide
    )

{-| Common Size animations that work across all animation engines.

Note: Size animations often need current size context, so these are simpler
fixed-target animations. More complex relative sizing can be done in examples.

-}

import Anim.Builder as Builder
import Anim.Property.Size as Size
import Easing


{-| Reset to default size (150x150)
-}
sizeReset : String -> Builder.AnimBuilder -> Builder.AnimBuilder
sizeReset elementId builder =
    builder
        |> Size.for elementId
        |> Size.toHW 150 150
        |> Size.duration 1500
        |> Size.easing Easing.EaseInOut
        |> Size.build


{-| Make element wide (300x100)
-}
sizeWide : String -> Builder.AnimBuilder -> Builder.AnimBuilder
sizeWide elementId builder =
    builder
        |> Size.for elementId
        |> Size.toHW 100 300
        |> Size.duration 1200
        |> Size.easing Easing.ElasticOut
        |> Size.build


{-| Make element tall (100x300)
-}
sizeTall : String -> Builder.AnimBuilder -> Builder.AnimBuilder
sizeTall elementId builder =
    builder
        |> Size.for elementId
        |> Size.toHW 300 100
        |> Size.duration 1200
        |> Size.easing Easing.BackOut
        |> Size.build


{-| Make element a small square (100x100)
-}
sizeSquare : String -> Builder.AnimBuilder -> Builder.AnimBuilder
sizeSquare elementId builder =
    builder
        |> Size.for elementId
        |> Size.toHW 100 100
        |> Size.duration 1000
        |> Size.easing Easing.QuadInOut
        |> Size.build


{-| Make element large (250x250)
-}
sizeLarge : String -> Builder.AnimBuilder -> Builder.AnimBuilder
sizeLarge elementId builder =
    builder
        |> Size.for elementId
        |> Size.toHW 250 250
        |> Size.duration 2000
        |> Size.easing Easing.BounceOut
        |> Size.build
