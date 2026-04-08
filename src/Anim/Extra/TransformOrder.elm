module Anim.Extra.TransformOrder exposing
    ( TransformOrder(..)
    , default
    , toString
    )


type TransformOrder
    = Translate
    | Rotate
    | Scale


default : List TransformOrder
default =
    [ Translate, Rotate, Scale ]


toString : TransformOrder -> String
toString o =
    case o of
        Translate ->
            "translate"

        Rotate ->
            "rotate"

        Scale ->
            "scale"
