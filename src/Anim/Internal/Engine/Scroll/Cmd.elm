module Anim.Internal.Engine.Scroll.Cmd exposing (animate)

{-| Fire-and-forget scroll commands. Routes scroll targets to the merged
Task module and converts results to Cmd.
-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Scroll.Task as ScrollTask
import Task


animate : msg -> (Builder.AnimBuilder -> Builder.AnimBuilder) -> Cmd msg
animate completionMsg buildAnimation =
    let
        animBuilder =
            buildAnimation <|
                Builder.init []

        config =
            ScrollTask.buildConfig animBuilder
    in
    Builder.getScrollTargets animBuilder
        |> List.map
            (\target ->
                ScrollTask.routeScrollTarget target config
                    |> Task.attempt (always completionMsg)
            )
        |> Cmd.batch
