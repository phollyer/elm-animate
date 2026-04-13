module Anim.Extra.TransformOrder exposing (TransformOrder(..), default, toString)

{-| Defines the order in which transform properties are applied when multiple
transform properties are being animated at the same time.

This is important because the order of transforms can affect the final result of the animation.
For example, if you rotate an element and then translate it, you will get a different result
than if you translate it first and then rotate it.

All Engines use the same default transform order, which is: `translate`, then `rotate`, then `scale`.
This should suffice for most use cases, so ordinarily, you don't need to change it, but you can customize
the transform order if needed using the `transformOrder` function from each engine.

The only Engine that does not support customizing the transform order is the Transition Engine, which
was a design trade-off. See the
[Transform Ordering](https://phollyer.github.io/elm-animate/engines/animation/transitions/#transform-ordering)
section in the Transition Engine docs for more details.

@docs TransformOrder, default, toString

-}


{-| Represents the order in which transform properties are applied.
-}
type TransformOrder
    = Translate
    | Rotate
    | Scale


{-| The default order in which transform properties are applied when multiple transform
properties are being animated at the same time.

The default order is: `translate`, then `rotate`, then `scale`.

-}
default : List TransformOrder
default =
    [ Translate, Rotate, Scale ]


{-| Convert a `TransformOrder` to a string that can be used in CSS or other contexts.
-}
toString : TransformOrder -> String
toString o =
    case o of
        Translate ->
            "translate"

        Rotate ->
            "rotate"

        Scale ->
            "scale"
