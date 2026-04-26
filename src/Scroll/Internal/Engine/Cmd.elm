module Scroll.Internal.Engine.Cmd exposing (animate)

{-| Fire-and-forget scroll commands. Routes scroll targets to the merged
Task module and converts results to Cmd.
-}

import Scroll.Internal.Engine.Task as ScrollTask
import Scroll.Internal.ScrollBuilder as SB
import Task


animate : msg -> (SB.ScrollBuilder -> SB.ScrollBuilder) -> Cmd msg
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
