module Common.Animations.Rotate exposing
    ( resetRotate
    , rotate180
    , rotate45
    , rotate90
    , rotateLeft
    , rotateRight
    )

{-| Common Rotation animations that work across all animation engines.
-}

import Anim.Builder as Builder
import Anim.Property.Rotate as Rotate
import Easing


{-| Rotate 45 degrees clockwise
-}
rotate45 : String -> Builder.AnimBuilder -> Builder.AnimBuilder
rotate45 elementId builder =
    builder
        |> Rotate.for elementId
        |> Rotate.toZ 45
        |> Rotate.easing Easing.QuadInOut
        |> Rotate.duration 500
        |> Rotate.build


{-| Rotate 90 degrees clockwise
-}
rotate90 : String -> Builder.AnimBuilder -> Builder.AnimBuilder
rotate90 elementId builder =
    builder
        |> Rotate.for elementId
        |> Rotate.toZ 90
        |> Rotate.easing Easing.SineInOut
        |> Rotate.speed 100
        |> Rotate.build


{-| Rotate 180 degrees clockwise
-}
rotate180 : String -> Builder.AnimBuilder -> Builder.AnimBuilder
rotate180 elementId builder =
    builder
        |> Rotate.for elementId
        |> Rotate.toZ 180
        |> Rotate.easing Easing.BackInOut
        |> Rotate.duration 900
        |> Rotate.build


{-| Rotate 90 degrees counter-clockwise
-}
rotateLeft : String -> Builder.AnimBuilder -> Builder.AnimBuilder
rotateLeft elementId builder =
    builder
        |> Rotate.for elementId
        |> Rotate.toZ -90
        |> Rotate.easing Easing.BounceInOut
        |> Rotate.delay 500
        |> Rotate.duration 700
        |> Rotate.build


{-| Rotate 90 degrees clockwise with elastic effect
-}
rotateRight : String -> Builder.AnimBuilder -> Builder.AnimBuilder
rotateRight elementId builder =
    builder
        |> Rotate.for elementId
        |> Rotate.toZ 90
        |> Rotate.easing Easing.ElasticInOut
        |> Rotate.duration 600
        |> Rotate.build


{-| Reset rotation to 0 degrees
-}
resetRotate : String -> Builder.AnimBuilder -> Builder.AnimBuilder
resetRotate elementId builder =
    builder
        |> Rotate.for elementId
        |> Rotate.toZ 0
        |> Rotate.easing Easing.EaseInOut
        |> Rotate.duration 500
        |> Rotate.build
