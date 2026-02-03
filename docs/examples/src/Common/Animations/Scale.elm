module Common.Animations.Scale exposing
    ( scaleDown
    , scaleReset
    , scaleTall
    , scaleUp
    , scaleWide
    )

{-| Common Scale animations that work across all animation engines.
-}

import Anim.Builder as Builder
import Anim.Easing as Easing
import Anim.Property.Scale as Scale


{-| Scale up to 1.5x
-}
scaleUp : String -> Builder.AnimBuilder -> Builder.AnimBuilder
scaleUp elementId builder =
    builder
        |> Scale.for elementId
        |> Scale.toXY 1.5 1.5
        |> Scale.speed 2.0
        |> Scale.easing Easing.EaseOut
        |> Scale.build


{-| Scale down to 0.7x
-}
scaleDown : String -> Builder.AnimBuilder -> Builder.AnimBuilder
scaleDown elementId builder =
    builder
        |> Scale.for elementId
        |> Scale.toXY 0.7 0.7
        |> Scale.speed 2.0
        |> Scale.easing Easing.EaseOut
        |> Scale.build


{-| Reset scale to 1.0 (normal size)
-}
scaleReset : String -> Builder.AnimBuilder -> Builder.AnimBuilder
scaleReset elementId builder =
    builder
        |> Scale.for elementId
        |> Scale.toXY 1.0 1.0
        |> Scale.speed 1.5
        |> Scale.easing Easing.EaseInOut
        |> Scale.build


{-| Scale wider (2x width, normal height)
-}
scaleWide : String -> Builder.AnimBuilder -> Builder.AnimBuilder
scaleWide elementId builder =
    builder
        |> Scale.for elementId
        |> Scale.toXY 2.0 1.0
        |> Scale.duration 800
        |> Scale.easing Easing.ElasticOut
        |> Scale.build


{-| Scale taller (normal width, 2x height)
-}
scaleTall : String -> Builder.AnimBuilder -> Builder.AnimBuilder
scaleTall elementId builder =
    builder
        |> Scale.for elementId
        |> Scale.toXY 1.0 2.0
        |> Scale.duration 800
        |> Scale.easing Easing.BackOut
        |> Scale.build
