module Anim.Extra.TransformOrder exposing
    ( TransformProperty(..)
    , default
    )

{-| **Note**: You probably won't need this module much, if at all. The default transform order is sufficient for the vast majority
of use cases, but you can customize it if needed.

The order of transform properties affects the final result of animations.
For example, if you rotate an element and then translate it, you will get a different result
than if you translate it first and then rotate it.

All Engines use the same default transform order, which is: `translate`, then `rotate`, then `skew`, then `scale`.
This should suffice for the vast majority of use cases, so ordinarily, you don't need to change it, but you can customize
the transform order if needed using the `transformOrder` function from each engine.

The only Engine that does not support customizing the transform order is the Transition Engine, which
was a design trade-off. See the
[Transition Engine - Transform Ordering](https://phollyer.github.io/elm-animate/engines/animation/transitions/#transform-ordering)
section in the docs for more details.

📖 Full documentation and examples:
[Transform Ordering](https://phollyer.github.io/elm-animate/concepts/transform-order/)

@docs TransformProperty

@docs default

-}


{-| Represents transform properties.
-}
type TransformProperty
    = Translate
    | Rotate
    | Skew
    | Scale


{-| The default order in which transform properties are applied when multiple transform
properties are being animated at the same time.

The default order is: `translate`, then `rotate`, then `skew`, then `scale`.

-}
default : List TransformProperty
default =
    [ Translate, Rotate, Skew, Scale ]
