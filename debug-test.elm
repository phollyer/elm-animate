module DebugTest exposing (..)

import Anim.Properties.Position as Position
import Anim.Engine.Sub as Sub
import Anim.Timing.Easing as Easing


debugDuration : ()
debugDuration =
    let
        animationState =
            Sub.init
                |> Sub.builder
                |> Position.for "page-content"
                |> Position.toX 100.0
                |> Position.duration 2000
                |> Position.easing Easing.Linear
                |> Position.build
                |> Sub.animate

        duration =
            Sub.getDuration "page-content" animationState

        _ =
            Debug.log "Duration result" duration
    in
    ()