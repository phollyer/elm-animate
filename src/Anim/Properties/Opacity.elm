module Anim.Properties.Opacity exposing (to, easing)

{-| Opacity property animations for Anim.

@docs to, easing

-}

import Anim exposing (AnimBuilder)
import Anim.Internal.Builder as Builder exposing (PropertyConfig(..))
import Anim.Timing.Easing exposing (Easing)


{-| Opacity value for elements.
-}
type alias Opacity =
    Float


{-| Animate to a specific opacity value.

    Anim.init "element"
        |> Opacity.to 0.5
        |> Anim.CSS.animate

-}
to : Opacity -> AnimBuilder -> AnimBuilder
to opacity builder =
    let
        opacityConfig =
            OpacityConfig opacity
                { timing = Nothing
                , easing = Nothing
                , delay = Nothing
                }

        currentElement =
            Builder.getCurrentElement builder

        updatedElement =
            { currentElement | properties = opacityConfig :: currentElement.properties }
    in
    Builder.updateCurrentElement updatedElement builder


{-| Set easing function for opacity animation.

    builder |> Opacity.easing EaseInOut

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing easingFunction builder =
    let
        elementConfig =
            Builder.getCurrentElement builder

        updatedProperties =
            List.map (updateOpacityProperty (\config -> { config | easing = Just easingFunction })) elementConfig.properties

        updatedElement =
            { elementConfig | properties = updatedProperties }
    in
    Builder.updateCurrentElement updatedElement builder


updateOpacityProperty : (Builder.UniversalPropertyData -> Builder.UniversalPropertyData) -> PropertyConfig -> PropertyConfig
updateOpacityProperty updateFn property =
    case property of
        OpacityConfig value config ->
            OpacityConfig value (updateFn config)

        other ->
            other
