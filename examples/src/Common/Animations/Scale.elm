module Common.Animations.Scale exposing
    ( scaleUp
    , scaleDown
    , scaleReset
    , scaleWide
    , scaleTall
    )

{-| Common Scale animations that work across all animation engines.
-}

import Anim.Easing as Easing
import Anim.Property.Scale as Scale


{-| Scale up to 1.5x
-}
scaleUp : String -> builder -> builder
scaleUp elementId builder =
    builder
        |> Scale.for elementId
        |> Scale.toXY 1.5 1.5
        |> Scale.speed 2.0
        |> Scale.easing Easing.EaseOut
        |> Scale.build


{-| Scale down to 0.7x
-}
scaleDown : String -> builder -> builder
scaleDown elementId builder =
    builder
        |> Scale.for elementId
        |> Scale.toXY 0.7 0.7
        |> Scale.speed 2.0
        |> Scale.easing Easing.EaseOut
        |> Scale.build


{-| Reset scale to 1.0 (normal size)
-}
scaleReset : String -> builder -> builder
scaleReset elementId builder =
    builder
        |> Scale.for elementId
        |> Scale.toXY 1.0 1.0
        |> Scale.speed 1.5
        |> Scale.easing Easing.EaseInOut
        |> Scale.build


{-| Scale wider (2x width, normal height)
-}
scaleWide : String -> builder -> builder
scaleWide elementId builder =
    builder
        |> Scale.for elementId
        |> Scale.toXY 2.0 1.0
        |> Scale.duration 800
        |> Scale.easing Easing.ElasticOut
        |> Scale.build


{-| Scale taller (normal width, 2x height)
-}
scaleTall : String -> builder -> builder
scaleTall elementId builder =
    builder
        |> Scale.for elementId
        |> Scale.toXY 1.0 2.0
        |> Scale.duration 800
        |> Scale.easing Easing.BackOut
        |> Scale.build
