module Scroll.Internal.Engine.Cmd exposing (animate)

import Scroll.Internal.Engine.Task as ScrollTask
import Scroll.Internal.ScrollBuilder as SB exposing (ScrollBuilder)
import Task


animate : msg -> (ScrollBuilder -> ScrollBuilder) -> Cmd msg
animate completionMsg buildAnimation =
    let
        scrollBuilder =
            buildAnimation SB.init

        config =
            ScrollTask.buildConfig scrollBuilder
    in
    SB.getScrollTargets scrollBuilder
        |> List.map
            (\target ->
                ScrollTask.routeScrollTarget target config
                    |> Task.attempt (always completionMsg)
            )
        |> Cmd.batch
