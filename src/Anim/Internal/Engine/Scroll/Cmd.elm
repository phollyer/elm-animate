module Anim.Internal.Engine.Scroll.Cmd exposing (toCmd)

{-| Fire-and-forget scroll commands. Routes scroll targets to the merged
Task module and converts results to Cmd.
-}

import Anim.Extra.Easing exposing (Easing(..))
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Scroll.Common as ScrollCommon
import Anim.Internal.Engine.Scroll.Internal exposing (Container(..))
import Anim.Internal.Engine.Scroll.ScrollTarget as ScrollTarget
import Anim.Internal.Engine.Scroll.Task as ScrollTask
import Anim.Internal.Extra.Easing as Easing
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Task


{-| Execute scroll animations as fire-and-forget Cmds.
-}
toCmd : msg -> (Builder.AnimBuilder -> Builder.AnimBuilder) -> Cmd msg
toCmd completionMsg buildAnimation =
    let
        animBuilder =
            buildAnimation Builder.init

        scrollTargets =
            Builder.getScrollTargets animBuilder

        defaultSettings =
            getDefaultSettings animBuilder

        config =
            { timing =
                case defaultSettings.timeSpec of
                    Speed s ->
                        ScrollCommon.Speed s

                    Duration d ->
                        ScrollCommon.Duration d
            , easing = Easing.toFunction 1000.0 defaultSettings.easing
            , axis = ScrollCommon.Both
            }

        toContainer containerId =
            if containerId == "document" then
                DocumentBody

            else
                Container containerId

        createScrollCmd target =
            let
                containerId =
                    ScrollTarget.getContainerId target

                container =
                    toContainer containerId

                targetType =
                    ScrollTarget.getTargetType target
            in
            case targetType of
                ScrollTarget.Element elementId ->
                    ScrollTask.scrollWithConfig container elementId config
                        |> Task.attempt (always completionMsg)

                ScrollTarget.Coordinates x y ->
                    ScrollTask.scrollToCoordinatesWithConfig container x y config
                        |> Task.attempt (always completionMsg)

                ScrollTarget.Top ->
                    ScrollTask.scrollToTopWithConfig container config
                        |> Task.attempt (always completionMsg)

                ScrollTarget.Bottom ->
                    ScrollTask.scrollToBottomWithConfig container config
                        |> Task.attempt (always completionMsg)

                ScrollTarget.Center ->
                    ScrollTask.scrollToCenterWithConfig container config
                        |> Task.attempt (always completionMsg)

                ScrollTarget.Delta dx dy ->
                    ScrollTask.scrollByWithConfig container dx dy config
                        |> Task.attempt (always completionMsg)

                ScrollTarget.Percentage px py ->
                    ScrollTask.scrollToPercentageWithConfig container px py config
                        |> Task.attempt (always completionMsg)
    in
    scrollTargets
        |> List.map createScrollCmd
        |> Cmd.batch


{-| Get default settings from AnimBuilder.
-}
getDefaultSettings : Builder.AnimBuilder -> { timeSpec : TimeSpec, easing : Easing, offset : Float }
getDefaultSettings animBuilder =
    let
        timeSpec =
            Builder.getTimeSpecWithDefault animBuilder

        builderEasing =
            Builder.getEasing animBuilder |> Maybe.withDefault Linear
    in
    { timeSpec = timeSpec
    , easing = builderEasing
    , offset = 0.0
    }
