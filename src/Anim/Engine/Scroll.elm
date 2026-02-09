module Anim.Engine.Scroll exposing
    ( AnimBuilder
    , toCmd
    , ScrollError(..), ScrollOk, toTask
    , animate
    , AnimState, init
    , AnimationMsg, update, subscriptions
    , defaultDuration, defaultSpeed
    , defaultEasing
    , defaultDelay
    , ScrollBuilder, forDocument, forContainer, build
    , toElement
    , toTop, toBottom, toCenter
    , toLeft, toRight
    , toTopLeft, toTopRight, toBottomLeft, toBottomRight
    , toXY, toX, toY, toPercentageXY, toPercentageX, toPercentageY
    , byXY, byX, byY
    , withOffsetXY, withOffsetX, withOffsetY
    , delay, duration, speed
    , easing
    , anyRunning, isRunning, getMaxDuration, getDuration
    , getPosition, getPositionX, getPositionY
    , stop, stopContainer
    , pause, pauseContainer
    , resume, resumeContainer
    , reset, resetContainer
    , restart, restartContainer
    , onBothAxes, onXAxis, onYAxis
    )

{-| Smooth Document and Container scrolling.

This Engine converts [AnimBuilder](#AnimBuilder) configurations to scroll animations
that can target the Document or scrollable containers as:

1.  **Fire-and-forget** commands
2.  **Tasks** that can be composed with other tasks, or,
3.  **Stateful subscription-based animations** that keep track of ongoing scrolls


## Design Decisions

**Choose Your Execution Method**

The choice between **fire-and-forget**, **task-based**, and **stateful subscription-based** execution is the main decision you need to make when using this engine.
The way you configure scroll animations using the [AnimBuilder](#AnimBuilder) API is the same regardless of execution method.

**For fire-and-forget scrolling, use [toCmd](#cmd) for:**

  - Simple use cases without error handling
  - No state management or subscriptions
  - Minimal boilerplate

**For Task-based scrolling, use [toTask](#task) when you need:**

  - Error handling (element not found, etc.)
  - Sequential scrolling with intermediate logic
  - No state management or subscriptions
  - Integration with other task-based operations

**For stateful subscription-based scrolling, use [animate](#stateful-animation) when you need:**

  - Real-time position tracking during scroll
  - Ability to query scroll state mid-flight
  - Ability to react to or interrupt ongoing scrolls
  - Duration and progress information

**Note**: Because [Cmd](#cmd) and [Task](#task) based scrolling both execute a sequence of Tasks under the hood,
which Elm executes as fast as it can, they may not appear as smooth as subscription-based
scrolling animations. They should be perfectly sufficient for most use cases, but if you find the animation
is not smooth enough, consider using subscription-based scrolling with [animate](#animate) instead.

**Further Reading**: [How To Use](#how-to-use) and [Under The Hood](#under-the-hood) sections.

---


# Execute

@docs AnimBuilder


## Fire-And-Forget Cmd

Use `Cmd` execution for fire-and-forget scrolling when you don't need state management or error handling.
The animation will run automatically without requiring subscriptions, and any errors will be ignored.

@docs toCmd


## Composable Task

Use `Task` execution when you want to handle success or failure of the scroll animations, or compose them with other tasks.

@docs ScrollError, ScrollOk, toTask


## Stateful Animation

Use stateful subscription-based animations when you need to track ongoing scrolls, query their state, react to their progress,
or redirect mid-flight.

@docs animate


# State

@docs AnimState, init


# Update

**Note:** Only required for stateful subscription-based animations. Not needed for [Cmd](#cmd) or [Task](#task) based scrolling.

@docs AnimationMsg, update, subscriptions


# Default Settings

These settings will be used for all scroll animations unless overridden on a per-scroll basis.


## Timing

@docs defaultDuration, defaultSpeed


## Easing

@docs defaultEasing


## Delay

@docs defaultDelay


# Per-Scroll Configuration

Build scroll animations with per-scroll settings.

@docs ScrollBuilder, forDocument, forContainer, build


## Element Targeting

@docs toElement


## Position Targeting

@docs toTop, toBottom, toCenter
@docs toLeft, toRight
@docs toTopLeft, toTopRight, toBottomLeft, toBottomRight


## Coordinate Targeting

@docs toXY, toX, toY, toPercentageXY, toPercentageX, toPercentageY


## Relative Scrolling

@docs byXY, byX, byY


## Offsets

@docs withOffsetXY, withOffsetX, withOffsetY


## Per-Scroll Timing

These override default settings for individual scroll targets.

@docs delay, duration, speed


## Per-Scroll Easing

This overrides the global easing setting.

@docs easing


# Query

**Note:** These functions are only applicable for stateful, subscription-based animations executed with [animate](#animate).


## Animation State

@docs anyRunning, isRunning, getMaxDuration, getDuration


## Scroll Position

@docs getPosition, getPositionX, getPositionY


# Controls

**Note:** These functions are only applicable for stateful, subscription-based animations executed with [animate](#animate).

Use these functions to control ongoing scroll animations:


## Stop

Stop a scroll animation by jumping to the target position.

@docs stop, stopContainer


## Pause

Paused scrolls retain their current position and progress. Use [resume](#resume) to continue.

@docs pause, pauseContainer


## Resume

Resume a paused scroll animation from its current position and progress.

@docs resume, resumeContainer


## Reset

Resets a scroll animation to its starting position.

@docs reset, resetContainer


## Restart

Restart a scroll animation from its starting position. Animation begins playing immediately from the beginning.

@docs restart, restartContainer


## Axis Selection

Most containers only scroll on one axis (CSS `overflow-y: auto` or `overflow-x: auto`),
so axis selection is rarely needed. However, for 2D scrollable containers like
spreadsheets, maps, or canvas-style interfaces where both axes are scrollable,
you can select one or both axes to scroll.

@docs onBothAxes, onXAxis, onYAxis

-}

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as InternalBuilder
import Anim.Internal.Builders.Scroll as SB
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


{-| Animation builder type.

This is used internally to configure scroll animations.

-}
type alias AnimBuilder =
    InternalScroll.AnimBuilder


{-| State for managing subscription-based scroll animations.

    import Anim.Engine.Scroll as Scroll

    { model | scrollAnimations : Scroll.AnimState }

**Note**: You don't need to include this in your model if you only use [Cmd](#cmd) or [Task](#task) based scrolling.

-}
type alias AnimState =
    InternalScroll.AnimState


{-| Animation message type.
-}
type alias AnimationMsg =
    InternalScroll.AnimationMsg


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
        { scrollAnimations = Scroll.init
        , ...
        }

-}
init : AnimState
init =
    InternalScroll.init


{-| Execute a subscription-based scroll animation with state management.

    ( newAnimState, cmd ) =
        Scroll.animate ScrollMsg model.scrollState <|
            scrollToElement "target-section"

    type Msg
        = ScrollMsg Scroll.AnimationMsg
        | ...

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollMsg scrollMsg ->
                let
                    ( newScrollState, scrollCmd ) =
                        Scroll.update ScrollMsg scrollMsg model.scrollState
                in
                ( { model | scrollState = newScrollState }
                , scrollCmd
                )

            ...

-}
animate : (AnimationMsg -> msg) -> AnimState -> (AnimBuilder -> AnimBuilder) -> ( AnimState, Cmd msg )
animate =
    InternalScroll.animate



-- GLOBAL SETTINGS


{-| Set the global default duration in milliseconds (overrides any previous speed setting).

    Scroll.toCmd ScrollCompleted <|
        (Scroll.defaultDuration 1000
            >> Scroll.forDocument
            >> Scroll.toElement "target-section"
            >> Scroll.build
        )

-}
defaultDuration : Int -> AnimBuilder -> AnimBuilder
defaultDuration =
    InternalScroll.duration


{-| Set the global default speed in pixels per second (overrides any previous duration setting).

    Scroll.toCmd ScrollCompleted <|
        (Scroll.defaultSpeed 500
            >> Scroll.forDocument
            >> Scroll.toElement "target-section"
            >> Scroll.build
        )

-}
defaultSpeed : Float -> AnimBuilder -> AnimBuilder
defaultSpeed =
    InternalScroll.speed


{-| Set the global default easing function.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.defaultEasing EaseInOutQuad
            >> Scroll.forDocument
            >> Scroll.toElement "target-section"
            >> Scroll.build
        )

-}
defaultEasing : Easing -> AnimBuilder -> AnimBuilder
defaultEasing =
    InternalScroll.easing


{-| Set the global default delay in milliseconds.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.defaultDelay 500
            >> Scroll.forDocument
            >> Scroll.toElement "target-section"
            >> Scroll.build
        )

-}
defaultDelay : Int -> AnimBuilder -> AnimBuilder
defaultDelay =
    InternalScroll.delay


{-| Subscribe for scroll animation updates.

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.batch
            [ Scroll.subscriptions ScrollMsg model.scrollAnimations
            , ...
            ]

-}
subscriptions : (AnimationMsg -> msg) -> AnimState -> Sub msg
subscriptions =
    InternalScroll.subscriptions


{-| Update the scroll animation state.

    type Msg
        = ScrollMsg Scroll.AnimationMsg
        | ...

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollMsg scrollMsg ->
                let
                    ( newScrollState, scrollCmd ) =
                        Scroll.update ScrollMsg scrollMsg model.scrollAnimations
                in
                ( { model | scrollAnimations = newScrollState }
                , scrollCmd
                )

            ...

-}
update : (AnimationMsg -> msg) -> AnimationMsg -> AnimState -> ( AnimState, Cmd msg )
update =
    InternalScroll.update



-- QUERYING ANIMATION STATE


{-| Check if any scroll animations are currently running.

    view : Model -> Html Msg
    view model =
        if Scroll.anyRunning model.scrollAnimations then
            div [ class "scrolling-indicator" ] [ text "Scrolling..." ]

        else
            div [] []

-}
anyRunning : AnimState -> Bool
anyRunning =
    InternalScroll.anyRunning


{-| Check if a scroll animation for a specific container is currently running. Use "document" for document body.

    if Scroll.isRunning "my-container" model.scrollAnimations then
        ...
    else
        ...

-}
isRunning : String -> AnimState -> Bool
isRunning =
    InternalScroll.isRunning


{-| Get the maximum duration of currently running scroll animations.
Returns the longest duration when multiple animations are running.
-}
getMaxDuration : AnimState -> Maybe Int
getMaxDuration =
    InternalScroll.getDuration



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



-- CONTAINER-SPECIFIC QUERIES


{-| Get the duration of the scroll animation for a specific container.

Returns `Nothing` if no animation is running for the specified container.

    case Scroll.getDuration "my-container" model.scrollAnimations of
        Just durationMs ->
            -- Animation duration in milliseconds
            ...

        Nothing ->
            -- No animation for this container
            ...

-}
getDuration : String -> AnimState -> Maybe Int
getDuration =
    InternalScroll.getContainerDuration



-- ANIMATION CONTROLS


{-| Stop the document scroll animation by jumping to the target position.

The scroll completes immediately and the animation is removed.

    update msg model =
        case msg of
            StopScrolling ->
                let
                    ( newScrollState, scrollCmd ) =
                        Scroll.stop GotScrollMsg model.scrollAnimations
                in
                ( { model | scrollAnimations = newScrollState }
                , scrollCmd
                )

-}
stop : (AnimationMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
stop toMsg =
    InternalScroll.stopContainer toMsg "document"


{-| Stop a scroll animation for a specific container by jumping to the target position.

    let
        ( newScrollState, scrollCmd ) =
            Scroll.stopContainer GotScrollMsg "my-container" model.scrollAnimations
    in
    ( { model | scrollAnimations = newScrollState }, scrollCmd )

-}
stopContainer : (AnimationMsg -> msg) -> String -> AnimState -> ( AnimState, Cmd msg )
stopContainer =
    InternalScroll.stopContainer


{-| Pause a document scroll animation.

Paused animations retain their current position and progress. Use [resume](#resume) to continue.

    update msg model =
        case msg of
            PauseScrolling ->
                ( { model | scrollAnimations = Scroll.pause model.scrollAnimations }
                , Cmd.none
                )

-}
pause : AnimState -> AnimState
pause =
    InternalScroll.pauseContainer "document"


{-| Pause a scroll animation for a specific container.

    Scroll.pauseContainer "my-container" model.scrollAnimations

-}
pauseContainer : String -> AnimState -> AnimState
pauseContainer =
    InternalScroll.pauseContainer


{-| Resume a document scroll animation.

    update msg model =
        case msg of
            ResumeScrolling ->
                ( { model | scrollAnimations = Scroll.resume model.scrollAnimations }
                , Cmd.none
                )

-}
resume : AnimState -> AnimState
resume =
    InternalScroll.resumeContainer "document"


{-| Resume a scroll animation for a specific container.

    Scroll.resumeContainer "my-container" model.scrollAnimations

-}
resumeContainer : String -> AnimState -> AnimState
resumeContainer =
    InternalScroll.resumeContainer


{-| Reset a document scroll animation to its starting position.

The scroll jumps back to the start immediately and remains paused.
Use [resume](#resume) or [restart](#restart) to continue.

    update msg model =
        case msg of
            ResetScrolling ->
                let
                    ( newScrollState, scrollCmd ) =
                        Scroll.reset GotScrollMsg model.scrollAnimations
                in
                ( { model | scrollAnimations = newScrollState }
                , scrollCmd
                )

-}
reset : (AnimationMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
reset toMsg =
    InternalScroll.resetContainer toMsg "document"


{-| Reset a scroll animation for a specific container.

    let
        ( newScrollState, scrollCmd ) =
            Scroll.resetContainer GotScrollMsg "my-container" model.scrollAnimations
    in
    ( { model | scrollAnimations = newScrollState }, scrollCmd )

-}
resetContainer : (AnimationMsg -> msg) -> String -> AnimState -> ( AnimState, Cmd msg )
resetContainer =
    InternalScroll.resetContainer


{-| Restart a document scroll animation from its starting position.

The scroll jumps back to the start immediately and begins playing.

    update msg model =
        case msg of
            RestartScrolling ->
                let
                    ( newScrollState, scrollCmd ) =
                        Scroll.restart GotScrollMsg model.scrollAnimations
                in
                ( { model | scrollAnimations = newScrollState }
                , scrollCmd
                )

-}
restart : (AnimationMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart toMsg =
    InternalScroll.restartContainer toMsg "document"


{-| Restart scroll animation for a specific container.

    let
        ( newScrollState, scrollCmd ) =
            Scroll.restartContainer GotScrollMsg "my-container" model.scrollAnimations
    in
    ( { model | scrollAnimations = newScrollState }, scrollCmd )

-}
restartContainer : (AnimationMsg -> msg) -> String -> AnimState -> ( AnimState, Cmd msg )
restartContainer =
    InternalScroll.restartContainer


{-| Execute scroll animations as a [Cmd](https://package.elm-lang.org/packages/elm/core/latest/Cmd).

    Scroll.toCmd ScrollCompleted <|
        scrollToElement "target-section"

    type Msg
        = ScrollCompleted String
        | ...

    update msg model =
        case msg of
            ScrollCompleted targetId ->
                -- targetId identifies which scroll completed
                ...

-}
toCmd : (String -> msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg
toCmd =
    InternalScroll.toCmd


{-| Execute scroll animations as a [Task](https://package.elm-lang.org/packages/elm/core/latest/Task).

    Scroll.toTask (scrollToElement "target-section")
        |> Task.attempt HandleScrollResult

    type Msg
        = HandleScrollResult (Result ScrollError ScrollOk)
        | ...

    update msg model =
        case msg of
            HandleScrollResult (Ok value) ->
                ...

            HandleScrollResult (Err error) ->
                ...

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



-- PER-SCROLL BUILDER


{-| Type alias for the internal ScrollBuilder.
-}
type alias ScrollBuilder =
    SB.ScrollBuilder


{-| Start configuring a scroll animation for the document body.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forDocument
            >> Scroll.toTop
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
forDocument : AnimBuilder -> ScrollBuilder
forDocument =
    SB.forDocument


{-| Start configuring a scroll animation for a specific container element.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "container-id"
            >> Scroll.toBottom
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
forContainer : String -> AnimBuilder -> ScrollBuilder
forContainer =
    SB.forContainer


{-| Complete the scroll animation configuration and return an `AnimBuilder`.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "container"
            >> Scroll.toElement "target-id"
            >> Scroll.speed 500
            >> Scroll.build
        )

From here, you can either execute it, or continue configuring other scroll animations
in the same `AnimBuilder` pipeline.

-}
build : ScrollBuilder -> AnimBuilder
build =
    SB.build



-- TARGET CONFIGURATION


{-| Scroll to a specific element by ID.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forDocument
            >> Scroll.toElement "section-header"
            >> Scroll.speed 500
            >> Scroll.build
        )

-}
toElement : String -> ScrollBuilder -> ScrollBuilder
toElement =
    SB.toElement


{-| Scroll to specific X and Y coordinates.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "element-id"
            >> Scroll.toXY 100 200
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
toXY : Float -> Float -> ScrollBuilder -> ScrollBuilder
toXY =
    SB.toXY


{-| Scroll to specific X coordinate only.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forDocument
            >> Scroll.toX 100
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
toX : Float -> ScrollBuilder -> ScrollBuilder
toX =
    SB.toX


{-| Scroll to specific Y coordinate only.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forDocument
            >> Scroll.toY 200
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
toY : Float -> ScrollBuilder -> ScrollBuilder
toY =
    SB.toY


{-| Scroll to the top of the container.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forDocument
            >> Scroll.toTop
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
toTop : ScrollBuilder -> ScrollBuilder
toTop =
    SB.toTop


{-| Scroll to the bottom of the container.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "element-id"
            >> Scroll.toBottom
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
toBottom : ScrollBuilder -> ScrollBuilder
toBottom =
    SB.toBottom


{-| Scroll to the center of the container.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "element-id"
            >> Scroll.toCenter
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
toCenter : ScrollBuilder -> ScrollBuilder
toCenter =
    SB.toCenter


{-| Scroll to the left edge of the container.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "element-id"
            >> Scroll.toLeft
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
toLeft : ScrollBuilder -> ScrollBuilder
toLeft =
    SB.toLeft


{-| Scroll to the right edge of the container.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "element-id"
            >> Scroll.toRight
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
toRight : ScrollBuilder -> ScrollBuilder
toRight =
    SB.toRight


{-| Scroll to the top-left corner of the container.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "element-id"
            >> Scroll.toTopLeft
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
toTopLeft : ScrollBuilder -> ScrollBuilder
toTopLeft =
    SB.toTopLeft


{-| Scroll to the top-right corner of the container.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "element-id"
            >> Scroll.toTopRight
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
toTopRight : ScrollBuilder -> ScrollBuilder
toTopRight =
    SB.toTopRight


{-| Scroll to the bottom-left corner of the container.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "element-id"
            >> Scroll.toBottomLeft
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
toBottomLeft : ScrollBuilder -> ScrollBuilder
toBottomLeft =
    SB.toBottomLeft


{-| Scroll to the bottom-right corner of the container.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "element-id"
            >> Scroll.toBottomRight
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
toBottomRight : ScrollBuilder -> ScrollBuilder
toBottomRight =
    SB.toBottomRight


{-| Scroll to percentage of container size.

    -- Scroll to 50% X and 80% Y of the container size.
    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "element-id"
            >> Scroll.toPercentageXY 0.5 0.8
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
toPercentageXY : Float -> Float -> ScrollBuilder -> ScrollBuilder
toPercentageXY =
    SB.toPercentageXY


{-| Scroll to percentage of container width (X axis only).

    -- Scroll to 50% of the container width.
    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "element-id"
            >> Scroll.toPercentageX 0.5
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
toPercentageX : Float -> ScrollBuilder -> ScrollBuilder
toPercentageX =
    SB.toPercentageX


{-| Scroll to percentage of container height (Y axis only).

    -- Scroll to 80% of the container height.
    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "element-id"
            >> Scroll.toPercentageY 0.8
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
toPercentageY : Float -> ScrollBuilder -> ScrollBuilder
toPercentageY =
    SB.toPercentageY


{-| Scroll by a relative amount on both X and Y axes.

Positive values scroll right/down, negative values scroll left/up.

    -- Scroll right 100px and down 200px
    Scroll.toCmd ScrollCompleted <|
        (Scroll.forDocument
            >> Scroll.byXY 100 200
            >> Scroll.duration 500
            >> Scroll.build
        )

    -- Scroll left 50px and up 100px
    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "element-id"
            >> Scroll.byXY -50 -100
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
byXY : Float -> Float -> ScrollBuilder -> ScrollBuilder
byXY =
    SB.byXY


{-| Scroll by a relative amount on X axis only.

Positive values scroll right, negative values scroll left.

    -- Scroll right 100px
    Scroll.toCmd ScrollCompleted <|
        (Scroll.forDocument
            >> Scroll.byX 100
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
byX : Float -> ScrollBuilder -> ScrollBuilder
byX =
    SB.byX


{-| Scroll by a relative amount on Y axis only.

Positive values scroll down, negative values scroll up.

    -- Scroll down 200px
    Scroll.toCmd ScrollCompleted <|
        (Scroll.forDocument
            >> Scroll.byY 200
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
byY : Float -> ScrollBuilder -> ScrollBuilder
byY =
    SB.byY



-- AXIS SELECTION


{-| Scroll on both X and Y axes (default).

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "element-id"
            >> Scroll.onBothAxes
            >> Scroll.toElement "section-1"
            >> Scroll.speed 500
            >> Scroll.build
        )

-}
onBothAxes : ScrollBuilder -> ScrollBuilder
onBothAxes =
    SB.onBothAxes


{-| Scroll on X axis only.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forContainer "element-id"
            >> Scroll.onXAxis
            >> Scroll.toX 500
            >> Scroll.speed 500
            >> Scroll.build
        )

-}
onXAxis : ScrollBuilder -> ScrollBuilder
onXAxis =
    SB.onXAxis


{-| Scroll on Y axis only.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forDocument
            >> Scroll.onYAxis
            >> Scroll.toElement "section-1"
            >> Scroll.speed 500
            >> Scroll.build
        )

-}
onYAxis : ScrollBuilder -> ScrollBuilder
onYAxis =
    SB.onYAxis


{-| Set X and Y scroll offsets.

Offsets are added to the target scroll position. Useful for accounting for
fixed headers or other UI elements.

    -- Scroll to element with 20px X offset and 60px Y offset.
    Scroll.toCmd ScrollCompleted <|
        (Scroll.forDocument
            >> Scroll.toElement "section-1"
            >> Scroll.withOffsetXY 20 60
            >> Scroll.speed 500
            >> Scroll.build
        )

-}
withOffsetXY : Float -> Float -> ScrollBuilder -> ScrollBuilder
withOffsetXY =
    SB.withOffsetXY


{-| Set X scroll offset.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forDocument
            >> Scroll.toElement "section-1"
            >> Scroll.withOffsetX 20
            >> Scroll.speed 500
            >> Scroll.build
        )

-}
withOffsetX : Float -> ScrollBuilder -> ScrollBuilder
withOffsetX =
    SB.withOffsetX


{-| Set Y scroll offset.

Commonly used to account for fixed headers.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forDocument
            >> Scroll.toElement "section-1"
            >> Scroll.withOffsetY 60
            >> Scroll.speed 500
            >> Scroll.build
        )

-}
withOffsetY : Float -> ScrollBuilder -> ScrollBuilder
withOffsetY =
    SB.withOffsetY



-- PER-SCROLL TIMING


{-| Set the delay (milliseconds) before this scroll animation starts.

Overrides the global [defaultDelay](#defaultDelay) for this scroll.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forDocument
            >> Scroll.toTop
            >> Scroll.delay 500
            >> Scroll.duration 500
            >> Scroll.build
        )

-}
delay : Int -> ScrollBuilder -> ScrollBuilder
delay =
    SB.delay


{-| Set the duration (milliseconds) for this scroll animation.

Overrides the global [defaultDuration](#defaultDuration) for this scroll.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forDocument
            >> Scroll.toElement "target"
            >> Scroll.duration 1000
            >> Scroll.build
        )

-}
duration : Int -> ScrollBuilder -> ScrollBuilder
duration =
    SB.duration


{-| Set the speed (pixels per second) for this scroll animation.

Overrides the global [defaultSpeed](#defaultSpeed) for this scroll.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forDocument
            >> Scroll.toTop
            >> Scroll.speed 500
            >> Scroll.build
        )

-}
speed : Float -> ScrollBuilder -> ScrollBuilder
speed =
    SB.speed



-- PER-SCROLL EASING


{-| Set the easing function for this scroll animation.

Overrides the global [defaultEasing](#defaultEasing) for this scroll.

    Scroll.toCmd ScrollCompleted <|
        (Scroll.forDocument
            >> Scroll.toElement "section-1"
            >> Scroll.duration 500
            >> Scroll.easing BounceOut
            >> Scroll.build
        )

-}
easing : Easing -> ScrollBuilder -> ScrollBuilder
easing =
    SB.easing
