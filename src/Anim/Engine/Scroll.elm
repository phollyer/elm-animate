module Anim.Engine.Scroll exposing
    ( AnimBuilder, AnimState
    , init
    , animate
    , toCmd
    , ScrollError(..), ScrollOk, toTask
    , AnimMsg, update, subscriptions
    , defaultDelay
    , defaultDuration, defaultSpeed
    , defaultEasing
    , stop, stopContainer
    , pause, pauseContainer
    , resume, resumeContainer
    , reset, resetContainer
    , restart, restartContainer
    , anyRunning, isRunning
    , getPosition, getPositionX, getPositionY
    )

{-| Smooth Document and Container scrolling.

For detailed guides, examples, and engine comparisons, see the
[full documentation](https://phollyer.github.io/elm-animate/engines/scroll/).

Per-scroll configuration (targets, offsets, timing overrides, easing overrides,
and axis selection) is handled by the [Builder](Anim-Engine-Scroll-Builder) module.


# Types

@docs AnimBuilder, AnimState


# Initialize

@docs init


# Trigger


## Stateful Animation

Use stateful subscription-based animations when you need to track ongoing scrolls,
query their state, react to their progress, or redirect mid-flight.

@docs animate


## Fire-And-Forget Cmd

Use `Cmd` execution for fire-and-forget scrolling when you don't need state management
or error handling.

@docs toCmd


## Composable Task

Use `Task` execution when you want to handle success or failure of the scroll animations,
or compose them with other tasks.

@docs ScrollError, ScrollOk, toTask


# Update

@docs AnimMsg, update, subscriptions


# Default Settings

@docs defaultDelay

@docs defaultDuration, defaultSpeed

@docs defaultEasing


# Animation Control


## Stop

@docs stop, stopContainer


## Pause

@docs pause, pauseContainer


## Resume

@docs resume, resumeContainer


## Reset

@docs reset, resetContainer


## Restart

@docs restart, restartContainer


# Querying Animation State

@docs anyRunning, isRunning


# Querying Scroll Position

@docs getPosition, getPositionX, getPositionY

-}

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as InternalBuilder
import Anim.Internal.Easing as InternalEasing
import Anim.Internal.Properties.ScrollTarget as ScrollTarget exposing (Axis(..))
import Anim.Internal.Scroll as InternalScroll
import Anim.Internal.Scroll.Common as ScrollCommon
import Anim.Internal.Scroll.Container.Task as ContainerTask
import Anim.Internal.Scroll.Document.Task as DocumentTask
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser exposing (UrlRequest(..))
import Browser.Dom as Dom
import Task exposing (Task)


{-| Animation builder type for configuring scroll animations.
-}
type alias AnimBuilder =
    InternalScroll.AnimBuilder


{-| The animation state type used to store scroll animation state.

Store it in your model.

    type alias Model =
        { scrollState : Scroll.AnimState }

-}
type alias AnimState =
    InternalScroll.AnimState


{-| Opaque message type.
-}
type alias AnimMsg =
    InternalScroll.AnimMsg


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


{-| Initialize empty scroll animation state.

    init : Model
    init =
        { scrollState = Scroll.init }

-}
init : AnimState
init =
    InternalScroll.init


{-| Trigger a stateful scroll animation.

    let
        ( newScrollState, scrollCmd ) =
            Scroll.animate ScrollMsg model.scrollState <|
                scrollToElement "target-section"
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

-}
animate : (AnimMsg -> msg) -> AnimState -> (AnimBuilder -> AnimBuilder) -> ( AnimState, Cmd msg )
animate =
    InternalScroll.animate



-- GLOBAL SETTINGS


{-| Set the global default duration in milliseconds.

    Scroll.toCmd ScrollCompleted <|
        Scroll.defaultDuration 1000
            >> ScrollTo.forDocument
            >> ScrollTo.toElement "target-section"
            >> ScrollTo.build

-}
defaultDuration : Int -> AnimBuilder -> AnimBuilder
defaultDuration =
    InternalScroll.duration


{-| Set the global default speed in pixels per second.

    Scroll.toCmd ScrollCompleted <|
        Scroll.defaultSpeed 500
            >> ScrollTo.forDocument
            >> ScrollTo.toElement "target-section"
            >> ScrollTo.build

-}
defaultSpeed : Float -> AnimBuilder -> AnimBuilder
defaultSpeed =
    InternalScroll.speed


{-| Set the global default easing function.

    Scroll.toCmd ScrollCompleted <|
        Scroll.defaultEasing EaseInOutQuad
            >> ScrollTo.forDocument
            >> ScrollTo.toElement "target-section"
            >> ScrollTo.build

-}
defaultEasing : Easing -> AnimBuilder -> AnimBuilder
defaultEasing =
    InternalScroll.easing


{-| Set the global default delay in milliseconds.

    Scroll.toCmd ScrollCompleted <|
        Scroll.defaultDelay 500
            >> ScrollTo.forDocument
            >> ScrollTo.toElement "target-section"
            >> ScrollTo.build

-}
defaultDelay : Int -> AnimBuilder -> AnimBuilder
defaultDelay =
    InternalScroll.delay


{-| Subscribe to receive scroll animation updates.

    type Msg
        = ScrollMsg Scroll.AnimMsg
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Scroll.subscriptions ScrollMsg model.scrollState

-}
subscriptions : (AnimMsg -> msg) -> AnimState -> Sub msg
subscriptions =
    InternalScroll.subscriptions


{-| Handle scroll animation lifecycle messages.

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollMsg scrollMsg ->
                let
                    ( newScrollState, scrollCmd ) =
                        Scroll.update ScrollMsg scrollMsg model.scrollState
                in
                ( { model | scrollState = newScrollState }, scrollCmd )

-}
update : (AnimMsg -> msg) -> AnimMsg -> AnimState -> ( AnimState, Cmd msg )
update =
    InternalScroll.update



-- QUERYING ANIMATION STATE


{-| Check if any scroll animations are currently running.

Returns `Nothing` if there are no animations.

-}
anyRunning : AnimState -> Maybe Bool
anyRunning =
    InternalScroll.anyRunning


{-| Check if a scroll animation for a specific container is currently running.

Use `"document"` for document body.

Returns `Nothing` if there are no animations for the container.

-}
isRunning : String -> AnimState -> Maybe Bool
isRunning =
    InternalScroll.isRunning



-- QUERYING SCROLL POSITION


{-| Get the current scroll position for a specific container.

Returns X and Y coordinates as a record.

Returns `Nothing` if the container is not found or scroll position is unavailable.

-}
getPosition : String -> AnimState -> Maybe { x : Float, y : Float }
getPosition =
    InternalScroll.getScrollPosition


{-| Get current horizontal scroll position for a specific container.
-}
getPositionX : String -> AnimState -> Maybe Float
getPositionX =
    InternalScroll.getScrollPositionX


{-| Get current vertical scroll position for a specific container.
-}
getPositionY : String -> AnimState -> Maybe Float
getPositionY =
    InternalScroll.getScrollPositionY



-- ANIMATION CONTROLS


{-| Stop the document scroll animation by jumping to the target position.

    let
        ( newScrollState, scrollCmd ) =
            Scroll.stop ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

-}
stop : (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
stop toMsg =
    InternalScroll.stopContainer "document" toMsg


{-| Stop a scroll animation for a specific container by jumping to the target position.

    let
        ( newScrollState, scrollCmd ) =
            Scroll.stopContainer "my-container" ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

-}
stopContainer : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
stopContainer =
    InternalScroll.stopContainer


{-| Pause a document scroll animation.

    Scroll.pause model.scrollState

-}
pause : AnimState -> AnimState
pause =
    InternalScroll.pauseContainer "document"


{-| Pause a scroll animation for a specific container.

    Scroll.pauseContainer "my-container" model.scrollState

-}
pauseContainer : String -> AnimState -> AnimState
pauseContainer =
    InternalScroll.pauseContainer


{-| Resume a document scroll animation.

    Scroll.resume model.scrollState

-}
resume : AnimState -> AnimState
resume =
    InternalScroll.resumeContainer "document"


{-| Resume a scroll animation for a specific container.

    Scroll.resumeContainer "my-container" model.scrollState

-}
resumeContainer : String -> AnimState -> AnimState
resumeContainer =
    InternalScroll.resumeContainer


{-| Reset a document scroll animation to its starting position.

    let
        ( newScrollState, scrollCmd ) =
            Scroll.reset ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

-}
reset : (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
reset toMsg =
    InternalScroll.resetContainer "document" toMsg


{-| Reset a scroll animation for a specific container.

    let
        ( newScrollState, scrollCmd ) =
            Scroll.resetContainer "my-container" ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

-}
resetContainer : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
resetContainer =
    InternalScroll.resetContainer


{-| Restart a document scroll animation from its starting position.

    let
        ( newScrollState, scrollCmd ) =
            Scroll.restart ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

-}
restart : (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart toMsg =
    InternalScroll.restartContainer "document" toMsg


{-| Restart scroll animation for a specific container.

    let
        ( newScrollState, scrollCmd ) =
            Scroll.restartContainer "my-container" ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

-}
restartContainer : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restartContainer =
    InternalScroll.restartContainer


{-| Execute scroll animations as a [Cmd](https://package.elm-lang.org/packages/elm/core/latest/Cmd).

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.toElement "target-section"
            >> ScrollTo.build

-}
toCmd : (String -> msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg
toCmd =
    InternalScroll.toCmd


{-| Execute scroll animations as a [Task](https://package.elm-lang.org/packages/elm/core/latest/Task).

    Scroll.toTask
        (ScrollTo.forDocument
            >> ScrollTo.toElement "target-section"
            >> ScrollTo.build
        )
        |> Task.attempt HandleScrollResult

-}
toTask : (AnimBuilder -> AnimBuilder) -> Task ScrollError ScrollOk
toTask buildAnimation =
    let
        animBuilder =
            buildAnimation InternalBuilder.init

        scrollTargets =
            InternalScroll.getScrollTargets animBuilder

        defaultSettings =
            InternalScroll.getDefaultSettings animBuilder

        -- Create scroll config from default settings
        -- Note: We use 1000ms (1 second) as baseline duration for easing function
        -- The actual animation duration is determined later based on distance and speed/duration
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

        -- Create a task for a single scroll target
        createScrollTask target =
            let
                -- Extract context information
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
                    case ( containerId, ScrollTarget.getTargetType target ) of
                        ( "document", ScrollTarget.Element elementId ) ->
                            DocumentTask.scrollWithConfig elementId config

                        ( "document", ScrollTarget.Coordinates x y ) ->
                            DocumentTask.scrollToCoordinatesWithConfig x y config

                        ( "document", ScrollTarget.Top ) ->
                            DocumentTask.scrollToTopWithConfig config

                        ( "document", ScrollTarget.Bottom ) ->
                            DocumentTask.scrollToBottomWithConfig config

                        ( "document", ScrollTarget.Center ) ->
                            DocumentTask.scrollToCenterWithConfig config

                        ( "document", ScrollTarget.Percentage px py ) ->
                            DocumentTask.scrollToPercentageWithConfig px py config

                        ( "document", ScrollTarget.Delta dx dy ) ->
                            DocumentTask.scrollByWithConfig dx dy config

                        ( otherContainerId, ScrollTarget.Element elementId ) ->
                            ContainerTask.scrollWithConfig otherContainerId elementId config

                        ( otherContainerId, ScrollTarget.Coordinates x y ) ->
                            ContainerTask.scrollToCoordinatesWithConfig otherContainerId x y config

                        ( otherContainerId, ScrollTarget.Top ) ->
                            ContainerTask.scrollToTopWithConfig otherContainerId config

                        ( otherContainerId, ScrollTarget.Bottom ) ->
                            ContainerTask.scrollToBottomWithConfig otherContainerId config

                        ( otherContainerId, ScrollTarget.Center ) ->
                            ContainerTask.scrollToCenterWithConfig otherContainerId config

                        ( otherContainerId, ScrollTarget.Percentage px py ) ->
                            ContainerTask.scrollToPercentageWithConfig otherContainerId px py config

                        ( otherContainerId, ScrollTarget.Delta dx dy ) ->
                            ContainerTask.scrollByWithConfig otherContainerId dx dy config
            in
            -- Convert Task Dom.Error (List ()) to Task ScrollError ScrollResult
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

        -- Sequence all scroll tasks and return the last result
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
