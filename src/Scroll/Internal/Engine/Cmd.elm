module Scroll.Internal.Engine.Cmd exposing (scroll)

import Scroll.Internal.Engine.Task as ScrollTask
import Scroll.Internal.ScrollBuilder as SB exposing (ScrollBuilder)
import Task


scroll : msg -> (ScrollBuilder -> ScrollBuilder) -> Cmd msg
scroll completionMsg buildAnimation =
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
