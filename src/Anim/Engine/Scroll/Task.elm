module Anim.Engine.Scroll.Task exposing
    ( AnimBuilder
    , ScrollError(..), ScrollOk
    , animate
    , delay
    , duration, speed
    , easing
    )

{-| Composable scroll animations via Task with error handling.

Use this module when you need to handle scroll success or failure,
or compose scroll operations with other Tasks.

For detailed guides and examples, see the
[full documentation](https://phollyer.github.io/elm-animate/engines/scroll/).

Use the [Builder](Anim-Engine-Scroll-Builder) module to configure scroll targets.


# Types

@docs AnimBuilder

@docs ScrollError, ScrollOk


# Trigger

@docs animate


# Default Settings

@docs delay

@docs duration, speed

@docs easing

-}

import Anim.Extra.Easing exposing (Easing(..))
import Anim.Internal.Builder as InternalBuilder
import Anim.Internal.Engine.Scroll.Common as ScrollCommon
import Anim.Internal.Engine.Scroll.Internal exposing (Container(..))
import Anim.Internal.Engine.Scroll.Task as ScrollTask
import Anim.Internal.Extra.Easing as InternalEasing
import Anim.Internal.Property.ScrollTarget as ScrollTarget
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Dom as Dom
import Task exposing (Task)


{-| Animation builder type for configuring scroll animations.
-}
type alias AnimBuilder =
    InternalBuilder.AnimBuilder


{-| Error type for failed scroll [Task](http://package.elm-lang.org/packages/elm/core/latest/Task)s.

Provides details about what failed during a scroll operation:

  - `containerId`: The container that was being scrolled ("document" for document body)
  - `targetElementId`: The element ID if scrolling to an element target
  - `domError`: The underlying DOM error (typically element not found)

-}
type ScrollError
    = ScrollError
        { containerId : String
        , targetElementId : Maybe String
        , domError : Dom.Error
        }


{-| Value type for successful scroll [Task](http://package.elm-lang.org/packages/elm/core/latest/Task)s.

Provides details about the completed scroll operation:

  - `containerId`: The container that was scrolled
  - `targetElementId`: The element ID if scrolled to an element target
  - `targetDescription`: Human-readable description of the scroll target

-}
type alias ScrollOk =
    { containerId : String
    , targetElementId : Maybe String
    , targetDescription : String
    }


{-| Execute scroll animations as a [Task](https://package.elm-lang.org/packages/elm/core/latest/Task).

    type Msg
        = HandleScrollResult (Result ScrollError ScrollOk)
        | ...

    Scroll.animate (scrollToElement "target-section")
         |> Task.attempt HandleScrollResult

-}
animate : (AnimBuilder -> AnimBuilder) -> Task ScrollError ScrollOk
animate buildAnimation =
    let
        animBuilder =
            buildAnimation InternalBuilder.init

        scrollTargets =
            InternalBuilder.getScrollTargets animBuilder

        defaultSettings =
            getDefaultSettings animBuilder

        config =
            { timing =
                case defaultSettings.timeSpec of
                    Speed s ->
                        ScrollCommon.Speed s

                    Duration d ->
                        ScrollCommon.Duration d
            , easing = InternalEasing.toFunction 1000.0 defaultSettings.easing
            , axis = ScrollCommon.Both
            }

        createScrollTask target =
            let
                containerId =
                    ScrollTarget.getContainerId target

                targetElementId =
                    ScrollTarget.getTargetElement target

                targetDescription =
                    case ScrollTarget.getTargetType target of
                        ScrollTarget.Element id ->
                            "element '" ++ id ++ "'"

                        ScrollTarget.Coordinates x y ->
                            "coordinates (" ++ String.fromFloat x ++ ", " ++ String.fromFloat y ++ ")"

                        ScrollTarget.Top ->
                            "top"

                        ScrollTarget.Bottom ->
                            "bottom"

                        ScrollTarget.Center ->
                            "center"

                        ScrollTarget.Percentage x y ->
                            "percentage (" ++ String.fromFloat (x * 100) ++ "%, " ++ String.fromFloat (y * 100) ++ "%)"

                        ScrollTarget.Delta dx dy ->
                            "delta (" ++ String.fromFloat dx ++ ", " ++ String.fromFloat dy ++ ")"

                scrollResult =
                    { containerId = containerId
                    , targetElementId = targetElementId
                    , targetDescription = targetDescription
                    }

                baseTask =
                    let
                        container =
                            if containerId == "document" then
                                DocumentBody

                            else
                                Container containerId
                    in
                    case ScrollTarget.getTargetType target of
                        ScrollTarget.Element elementId ->
                            ScrollTask.scrollWithConfig container elementId config

                        ScrollTarget.Coordinates x y ->
                            ScrollTask.scrollToCoordinatesWithConfig container x y config

                        ScrollTarget.Top ->
                            ScrollTask.scrollToTopWithConfig container config

                        ScrollTarget.Bottom ->
                            ScrollTask.scrollToBottomWithConfig container config

                        ScrollTarget.Center ->
                            ScrollTask.scrollToCenterWithConfig container config

                        ScrollTarget.Percentage px py ->
                            ScrollTask.scrollToPercentageWithConfig container px py config

                        ScrollTarget.Delta dx dy ->
                            ScrollTask.scrollByWithConfig container dx dy config
            in
            baseTask
                |> Task.map (\_ -> scrollResult)
                |> Task.mapError
                    (\domError ->
                        ScrollError
                            { containerId = containerId
                            , targetElementId = targetElementId
                            , domError = domError
                            }
                    )

        sequenceTasks tasks =
            case tasks of
                [] ->
                    Task.succeed
                        { containerId = "document"
                        , targetElementId = Nothing
                        , targetDescription = "No scroll target"
                        }

                [ single ] ->
                    single

                first :: rest ->
                    first
                        |> Task.andThen (\_ -> sequenceTasks rest)
    in
    scrollTargets
        |> List.map createScrollTask
        |> sequenceTasks


{-| Set the global default duration in milliseconds.

    scrollToElement : String -> AnimBuilder -> AnimBuilder
    scrollToElement elementId =
        Scroll.duration 1000
            >> Builder.forDocument
            >> Builder.toElement elementId
            >> Builder.build

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalBuilder.duration


{-| Set the global default speed in pixels per second.

    scrollToElement : String -> AnimBuilder -> AnimBuilder
    scrollToElement elementId =
        Scroll.speed 200
            >> Builder.forDocument
            >> Builder.toElement elementId
            >> Builder.build

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalBuilder.speed


{-| Set the global default easing function.

    scrollToElement : String -> AnimBuilder -> AnimBuilder
    scrollToElement elementId =
        Scroll.easing BounceOut
            >> Builder.forDocument
            >> Builder.toElement elementId
            >> Builder.speed 200
            >> Builder.build

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    InternalBuilder.easing


{-| Set the global default delay in milliseconds.

    scrollToElement : String -> AnimBuilder -> AnimBuilder
    scrollToElement elementId =
        Scroll.delay 100
            >> Builder.forDocument
            >> Builder.toElement elementId
            >> Builder.speed 200
            >> Builder.build

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalBuilder.delay


{-| Get default settings from AnimBuilder for Task implementations.
-}
getDefaultSettings : InternalBuilder.AnimBuilder -> { timeSpec : TimeSpec, easing : Easing, offset : Float }
getDefaultSettings animBuilder =
    let
        timeSpec =
            InternalBuilder.getTimeSpecWithDefault animBuilder

        builderEasing =
            InternalBuilder.getEasing animBuilder |> Maybe.withDefault Linear
    in
    { timeSpec = timeSpec
    , easing = builderEasing
    , offset = 0.0
    }
