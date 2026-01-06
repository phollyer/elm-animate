module Anim.Engine.Scroll exposing
    ( toCmd
    , ScrollError(..), ScrollResult, toTask
    , animate
    , AnimState, init, AnimBuilder, builder
    , AnimationMsg, update, subscriptions
    , duration, speed
    , easing
    , delay
    , anyAnimationsRunning, isAnimationRunning, getMaxDuration, getDuration
    , getPosition, getPositionX, getPositionY
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


# Execute

For how to use each execution method, see the [How To Use](#how-to-use) section towards the end of this document.

For technical details on how each execution method works under the hood, see the [Under The Hood](#under-the-hood) section at the end of this document.


## Cmd

Use `Cmd` execution for fire-and-forget scrolling when you don't need state management or error handling.
The animation will run automatically without requiring subscriptions, and any errors will be ignored.

@docs toCmd


## Task

Use this when you want to handle success or failure of the scroll animations, or compose them with other tasks.

@docs ScrollError, ScrollResult, toTask


## Stateful Animation

@docs animate


# Build

@docs AnimState, init, AnimBuilder, builder


# Update

**Note:** Only required for stateful subscription-based animations. Not needed for [Cmd](#cmd) or [Task](#task) based scrolling.

@docs AnimationMsg, update, subscriptions


# Global Settings

These settings will be used for all scroll animations unless overridden on a per-scroll basis.


## Timing

@docs duration, speed


## Easing

@docs easing


## Delay

@docs delay


# Query

**Note:** These functions are only applicable for stateful, subscription-based animations executed with [animate](#animate).


## Animation State

@docs anyAnimationsRunning, isAnimationRunning, getMaxDuration, getDuration


## Scroll Position

@docs getPosition, getPositionX, getPositionY

---


## How To Use

You can configure and execute single or multiple scroll animations using any of the three execution methods.
Here's a quick guide on how to set up each method.


### Cmd Execution

**Single scroll:**

  - Configure one scroll target in your [AnimBuilder](#AnimBuilder) pipeline
  - Call [toCmd](#cmd) with your completion message constructor
  - Handle the completion message in your update function

**Multiple concurrent scrolls:**

  - Configure multiple scroll targets in the same [AnimBuilder](#AnimBuilder) pipeline
  - Call [toCmd](#cmd) with your completion message constructor
  - Handle multiple completion messages (one per target) in your update function


### Task Execution

**Single scroll:**

  - Configure one scroll target in your [AnimBuilder](#AnimBuilder) pipeline
  - Call [toTask](#task) to get a [Task](http://package.elm-lang.org/packages/elm/core/latest/Task) [ScrollError](#ScrollError) [ScrollResult](#ScrollResult)
  - Convert to [Cmd](http://package.elm-lang.org/packages/elm/core/latest/Platform-Cmd) with [Task.attempt](http://package.elm-lang.org/packages/elm/core/latest/Task#attempt)
  - Handle the [Result](http://package.elm-lang.org/packages/elm/core/latest/Result) [ScrollError](#ScrollError) [ScrollResult](#ScrollResult) in your update function

**Multiple sequential scrolls:**

  - Configure multiple scroll targets in the same [AnimBuilder](#AnimBuilder) pipeline
  - Call [toTask](#task) to get a [Task](http://package.elm-lang.org/packages/elm/core/latest/Task) [ScrollError](#ScrollError) [ScrollResult](#ScrollResult)
  - Convert to [Cmd](http://package.elm-lang.org/packages/elm/core/latest/Platform-Cmd) with [Task.attempt](http://package.elm-lang.org/packages/elm/core/latest/Task#attempt) (scrolls execute one after another)
  - Handle the [Result](http://package.elm-lang.org/packages/elm/core/latest/Result) [ScrollError](#ScrollError) [ScrollResult](#ScrollResult) in your update function (single [ScrollResult](#ScrollResult) for last successful scroll or [ScrollError](#ScrollError) first error - subsequent scrolls not attempted)

**Multiple concurrent scrolls with individual error handling:**

  - Create separate [AnimBuilder](#AnimBuilder)s for each scroll target
  - Convert each to a [Task](http://package.elm-lang.org/packages/elm/core/latest/Task) with [toTask](#task)
  - Convert each [Task](http://package.elm-lang.org/packages/elm/core/latest/Task) to a [Cmd](http://package.elm-lang.org/packages/elm/core/latest/Platform-Cmd) with [Task.attempt](http://package.elm-lang.org/packages/elm/core/latest/Task#attempt)
  - Batch all [Cmd](http://package.elm-lang.org/packages/elm/core/latest/Platform-Cmd)s with [Cmd.batch](http://package.elm-lang.org/packages/elm/core/latest/Platform-Cmd#batch)
  - Handle individual [Result](http://package.elm-lang.org/packages/elm/core/latest/Result) [ScrollError](#ScrollError) [ScrollResult](#ScrollResult) for each scroll in your update function


### Stateful Subscription-based Animation

**Single scroll:**

  - Add [AnimState](#AnimState) to your model
  - Configure one scroll target in your [AnimBuilder](#AnimBuilder) pipeline
  - Call [animate](#animate) with your message constructor
  - Store the returned [AnimState](#AnimState) in your model
  - Add [subscriptions](#subscriptions) to your subscriptions function
  - Handle animation messages in your update function with [update](#update)

**Multiple concurrent scrolls:**

  - Add [AnimState](#AnimState) to your model
  - Configure multiple scroll targets in the same [AnimBuilder](#AnimBuilder) pipeline
  - Call [animate](#animate) with your message constructor
  - Store the returned [AnimState](#AnimState) in your model
  - Add [subscriptions](#subscriptions) to your subscriptions function
  - Handle animation messages in your update function with [update](#update)
  - Use [query functions](#query) to track individual scroll progress

---


## Under The Hood

For the curious, here's how the different execution methods work after following the [How To Use](#how-to-use) guide.


### Cmd Execution

**Single scroll target:**

1.  DOM queries retrieve current scroll position and target element position
2.  Distance is calculated from current to target position
3.  Animation steps are pre-calculated based on distance, timing and easing
4.  Animation steps are sequenced into a `Task` chain
5.  `Task` chain is converted to a `Cmd` via `Task.attempt`
6.  Elm runtime receives the `Cmd` and executes each step in the `Task` chain in sequence
7.  Completion message fires with target identifier

**Multiple scroll targets:**

  - Each scroll is independently converted to a `Cmd` (following steps 1-5 above)
  - All `Cmd`s are `Cmd.batch`ed into a single `Cmd`
  - Elm runtime receives the single `Cmd` and executes all scrolls concurrently
  - Browser's rendering engine handles all simultaneous scroll animations in parallel
  - Each scroll fires the completion message independently as it finishes

**Completion behavior:**

  - The completion message fires when the scroll animation finishes (success or failure)
  - With multiple targets, the message fires once per target as each scroll completes
  - The `String` parameter identifies the target: element ID for element targets, or a description like "document:top" for position targets


### Task Execution

**Single scroll target:**

1.  DOM queries retrieve current scroll position and target element position
2.  Distance is calculated from current to target position
3.  Animation steps are pre-calculated based on distance, timing and easing
4.  Steps are sequenced into a `Task` chain
5.  `Task` is executed when converted to `Cmd` with [Task.attempt](https://package.elm-lang.org/packages/elm/core/latest/Task#attempt) or composed with other tasks
6.  Returns [ScrollResult](#ScrollResult) on success or [ScrollError](#ScrollError) on failure

**Multiple, sequential scroll targets:**

  - Each scroll is processed sequentially (one after another, in pipeline order)
  - First scroll goes through steps 1-5, then second scroll begins
  - Returns [ScrollError](#ScrollError) for the first scroll that fails, subsequent scrolls are not attempted
  - Returns [ScrollResult](#ScrollResult) only if all scrolls succeed, with details of the last completed scroll

**Multiple, concurrent scroll targets:**

  - Each scroll is independently converted to a `Task` (following steps 1-5 above)
  - Each `Task` is independently converted to a `Cmd` via [Task.attempt](https://package.elm-lang.org/packages/elm/core/latest/Task#attempt)
  - All `Cmd`s are `Cmd.batch`ed into a single `Cmd`
  - Elm runtime receives the single `Cmd` and executes all scrolls concurrently
  - Browser's rendering engine handles all simultaneous scroll animations in parallel
  - Each scroll returns its own [ScrollResult](#ScrollResult) or [ScrollError](#ScrollError) independently

**Error handling:**

  - Returns [ScrollResult](#ScrollResult) on success with details about the completed scroll
  - Returns [ScrollError](#ScrollError) on failure with details about what failed
  - Errors typically occur when target elements don't exist in the DOM
  - Can be composed with other tasks using [Task.andThen](https://package.elm-lang.org/packages/elm/core/latest/Task#andThen), [Task.map](https://package.elm-lang.org/packages/elm/core/latest/Task#map), etc.


### Stateful Subscription-based Animation

**Single scroll target:**

1.  DOM queries retrieve current scroll position and target element position
2.  Distance is calculated from current to target position
3.  AnimState is updated with new animation data
4.  Initial Cmd is returned (may trigger immediate first step)
5.  [subscriptions](#subscriptions) listen for animation frame updates
6.  Each frame: current position is updated and next scroll step is calculated
7.  Animation continues until target is reached

**Multiple scroll targets:**

  - Each scroll independently goes through steps 1-7 above
  - All scroll animations are tracked in the same AnimState
  - [subscriptions](#subscriptions) handle all animations simultaneously
  - All scroll animations run concurrently
  - Each animation can be queried independently during execution
  - Animations complete independently as they reach their targets

**State management:**

  - Returns updated [AnimState](#AnimState) that must be stored in your model
  - Requires [subscriptions](#subscriptions) to be active for animation to progress
  - Enables real-time [queries](#query) during animation (position, duration, status)
  - Allows intervention and reaction to ongoing animations

-}

import Anim.Easing exposing (Easing)
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

You don't need to include this in your model if you only use [Cmd](#cmd) or [Task](#task) based scrolling.

-}
type alias AnimState =
    InternalScroll.AnimState


{-| Animation message type for scroll animations
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


{-| Result type for successful scroll [Task](http://package.elm-lang.org/packages/elm/core/latest/Task)s.

Provides details about the completed scroll operation:

  - `containerId`: The container that was scrolled
  - `targetElementId`: The element ID if scrolled to an element target
  - `targetDescription`: Human-readable description of the scroll target

-}
type alias ScrollResult =
    { containerId : String
    , targetElementId : Maybe String
    , targetDescription : String
    }



-- ANIMATION EXECUTION


{-| Initialize empty scroll animation state.

    -- For stateful subscription-based scroll animations
    init : Model
    init =
        { scrollAnimations = Scroll.init
        , ...
        }

    -- For fire-and-forget Cmd or Task based scrolling
    Scroll.init
        |> ... -- configure scroll animation

-}
init : AnimState
init =
    InternalScroll.init


{-| Turn the [AnimState](#AnimState) into an [AnimBuilder](#AnimBuilder).

Use this to start new scroll animations.

    -- Start a new fire-and-forget scroll animation
    Scroll.init
        |> Scroll.builder
        |>.. -- configure scroll animation

    -- Start a new scroll animation based on current state
    (newState, scrollCmd) =
        model.scrollAnimations
            |> Scroll.builder
            |> ... -- configure scroll animation

-}
builder : AnimState -> AnimBuilder
builder =
    InternalScroll.builder


{-| Execute scroll animations using subscription-based animation with state management.

    (newAnimState, cmd) =
        model.scrollAnimations
            |> Scroll.builder
            |> ... -- configure scroll animation
            |> Scroll.animate ScrollMsg

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
animate : (AnimationMsg -> msg) -> AnimBuilder -> ( AnimState, Cmd msg )
animate =
    InternalScroll.animate



-- GLOBAL SETTINGS


{-| Set the global duration in milliseconds (overrides any previous speed setting).

    Scroll.init
        |> Scroll.builder
        |> Scroll.duration 1000
        |> ... -- configure scroll animation
        |> Scroll.animate

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalScroll.duration


{-| Set the global speed in pixels per second (overrides any previous duration setting).

    Scroll.init
        |> Scroll.builder
        |> Scroll.speed 500
        |> ... -- configure scroll animation
        |> Scroll.animate

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalScroll.speed


{-| Set the global easing function.

    Scroll.init
        |> Scroll.builder
        |> Scroll.easing EaseInOutQuad
        |> ... -- configure scroll animation
        |> Scroll.animate

**Note**: Cmd and Task based scrolling _should handle easings fine_, although,
because they run a sequence of Tasks under the hood, they may not appear as smooth
as subscription-based scrolling animations.

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    InternalScroll.easing


{-| Set the global delay in milliseconds.

    Scroll.init
        |> Scroll.builder
        |> Scroll.delay 500
        |> ... -- configure scroll animation
        |> Scroll.animate

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalScroll.delay



-- ANIMATION MANAGEMENT


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
        if Scroll.anyAnimationsRunning model.scrollAnimations then
            div [ class "scrolling-indicator" ] [ text "Scrolling..." ]

        else
            div [] []

-}
anyAnimationsRunning : AnimState -> Bool
anyAnimationsRunning =
    InternalScroll.isAnimationRunning


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


{-| Check if a scroll animation for a specific container is currently running. Use "document" for document body.

    if Scroll.isAnimationRunning "my-container" model.scrollAnimations then
        ...
    else
        ...

-}
isAnimationRunning : String -> AnimState -> Bool
isAnimationRunning =
    InternalScroll.isContainerAnimating


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


{-| Execute scroll animations as a [Cmd](https://package.elm-lang.org/packages/elm/core/latest/Cmd).

    ... -- Build your AnimBuilder
    |> Scroll.toCmd ScrollCompleted

    type Msg
        = ScrollCompleted String
        | ...

    update msg model =
        case msg of
            ScrollCompleted targetId ->
                -- targetId identifies which scroll completed
                ...

-}
toCmd : (String -> msg) -> AnimBuilder -> Cmd msg
toCmd =
    InternalScroll.toCmd


{-| Execute scroll animations as a [Task](https://package.elm-lang.org/packages/elm/core/latest/Task).

    ... -- Build your AnimBuilder
    |> Scroll.toTask
    |> Task.attempt HandleScrollResult

    type Msg
        = HandleScrollResult (Result Scroll.ScrollError Scroll.ScrollResult)
        | ...

    update msg model =
        case msg of
            HandleScrollResult (Ok result) ->
                -- result contains: containerId, targetElementId, targetDescription
                ...

            HandleScrollResult (Err error) ->
                -- error contains: containerId, targetElementId, domError
                ...

-}
toTask : AnimBuilder -> Task ScrollError ScrollResult
toTask animBuilder =
    let
        scrollTargets =
            InternalScroll.getScrollTargets animBuilder

        globalSettings =
            InternalScroll.getGlobalSettings animBuilder

        -- Create scroll config from global settings
        config =
            { timing =
                case globalSettings.timeSpec of
                    Speed s ->
                        ScrollCommon.Speed s

                    Duration d ->
                        ScrollCommon.Duration d
            , easing = InternalEasing.toFunction globalSettings.easing
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

                        _ ->
                            Task.succeed []
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
