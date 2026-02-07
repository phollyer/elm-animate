import Anim.Engine.CSS.Keyframes as CSS
import Anim.Property.BackgroundColor as BackgroundColor
import Anim.Property.Scale as Scale
import Anim.Extra.Easing as Easing

animations =
    CSS.init []
        |> CSS.builder
        |> CSS.duration 900
        |> CSS.easing Easing.QuartInOut
        |> BackgroundColor.for "box"
        |> BackgroundColor.from (BackgroundColor.Rgb { r = 59, g = 130, b = 246 })
        |> BackgroundColor.to (BackgroundColor.Rgb { r = 255, g = 100, b = 150 })
        |> BackgroundColor.duration 900
        |> BackgroundColor.build
        |> Scale.for "box"
        |> Scale.fromXY 1.0 1.0
        |> Scale.toXY 1.3 1.3
        |> Scale.duration 900
        |> Scale.build
        |> CSS.animate

keyframes =
    CSS.getElementKeyframes "box" animations
        |> Maybe.withDefault "NONE"

main =
    Debug.log "Keyframes" keyframes
        |> always (text "Check console")
