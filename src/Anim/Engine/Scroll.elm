module Anim.Engine.Scroll exposing
    ( AnimState, init, AnimBuilder, builder
    , toCmd
    , ScrollError(..), ScrollResult, toTask
    , animate
    , duration, speed
    , easing
    , delay
    , AnimationMsg, update, subscriptions
    , isAnimationRunning, getDuration
    , getPosition, getPositionXY, getPositionX, getPositionY
    )

{-| Smooth Document and Container scrolling.

This Engine converts [AnimBuilder](#AnimBuilder) configurations to scroll animations
that can target specific elements or coordinates within the document or scrollable containers.


## Usage

    import Anim.Action.Scroll as ScrollAction
    import Anim.Engine.Scroll as Scroll

    -- Single scroll with subscription-based state management
    ( scrollState, scrollCmd ) =
        Scroll.init
            |> Scroll.builder
            |> Scroll.speed 500  -- global default
            |> ScrollAction.for "document"
            |> ScrollAction.toElement "section-1"
            |> ScrollAction.build
            |> Scroll.animate ScrollMsg

    -- Single fire-and-forget Cmd with multiple scrolls in different containers
    scrollCmd =
        Scroll.init
            |> Scroll.builder
            |> Scroll.duration 1000  -- global default
            |> ScrollAction.forDocument
            |> ScrollAction.toTop
            |> ScrollAction.easing BounceOut
            |> ScrollAction.build
            |> ScrollAction.for "container-1"
            |> ScrollAction.toElement "target-1"
            |> ScrollAction.speed 800  -- override global duration for this scroll
            |> ScrollAction.build
            |> ScrollAction.for "container-2"
            |> ScrollAction.toElement "target-2"
            |> ScrollAction.build
            |> Scroll.toCmd ScrollCompleted


# Build

@docs AnimState, init, AnimBuilder, builder


# Execute


## Cmd

@docs toCmd


## Task

@docs ScrollError, ScrollResult, toTask


## Stateful Animation

@docs animate


# Global Settings

These settings will be used for all scroll animations unless overridden on a per-scroll basis.


## Timing

@docs duration, speed


## Easing

@docs easing


## Delay

@docs delay


# Update

**Note:** Only required for stateful subscription-based animations. Not needed for Cmd or Task based scrolling.

@docs AnimationMsg, update, subscriptions


# Query

**Note:** These functions are only applicable for stateful subscription-based animations.


## Animation State

@docs isAnimationRunning, getDuration


## Scroll Position

@docs getPosition, getPositionXY, getPositionX, getPositionY

-}

import Anim.Easing exposing (Easing)
import Anim.Internal.Easing as InternalEasing
import Anim.Internal.Properties.ScrollTarget as ScrollTarget exposing (Axis(..))
import Anim.Internal.Scroll as InternalScroll
import Anim.Internal.Scroll.Common as ScrollCommon
import Anim.Internal.Scroll.Container.Cmd as ContainerCmd
import Anim.Internal.Scroll.Container.Task as ContainerTask
import Anim.Internal.Scroll.Document.Cmd as DocumentCmd
import Anim.Internal.Scroll.Document.Task as DocumentTask
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Dom as Dom
import Browser.Events
import Task exposing (Task)


{-| Animation builder for scroll animations
-}
type alias AnimBuilder =
    InternalScroll.AnimBuilder


{-| State for managing subscription-based scroll animations.

    import Anim.Engine.Scroll as Scroll

    { model | scrollAnimations : Scroll.AnimState }

You don't need to include this in your model if you only use `Cmd` or `Task` based scrolling.

-}
type alias AnimState =
    InternalScroll.AnimState


{-| Animation message type for scroll animations
-}
type alias AnimationMsg =
    InternalScroll.AnimationMsg


{-| Error type for scroll tasks with rich context information.

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


{-| Result type for successful scroll tasks with context information.

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

    -- For subscription-based scroll animations
    init : Model
    init =
        { scrollAnimations = Scroll.init
        , ...
        }

    -- For fire-and-forget Cmd or Task based scrolling
    scrollCmd =
        Scroll.init
            |> Scroll.builder
            |> ... -- configure scroll animation
            |> Scroll.toCmd ScrollCompleted

-}
init : AnimState
init =
    InternalScroll.init


{-| Turn the AnimState into an AnimBuilder.

Use this to start new scroll animations.

    -- Start a new scroll animation based on current state
    (newAnimations, scrollCmd) =
        model.scrollAnimations
            |> Scroll.builder
            |> ... -- configure scroll animation
            |> Scroll.animate

    -- Start a new fire-and-forget scroll animation
    scrollCmd =
        Scroll.init
            |> Scroll.builder
            |>.. -- configure scroll animation
            |> Scroll.toCmd ScrollCompleted

-}
builder : AnimState -> AnimBuilder
builder =
    InternalScroll.builder


{-| Execute a scroll animation as a Cmd, keeping the animation state updated.

Use this when you want to manage animation state, or receive updates
during a scroll animation and intervene or react accordingly.

    doScroll : Model -> ( Model, Cmd Msg )
    doScroll model =
        let
            ( scrollState, scrollCmd ) =
                model.scrollAnimations
                    |> Scroll.builder
                    |> ... -- configure scroll animation
                    |> Scroll.animate ScrollMsg
        in
        ( { model | scrollAnimations = scrollState }
        , scrollCmd
        )

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

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.batch
            [ Scroll.subscriptions ScrollMsg model.scrollAnimations
            , ...
            ]

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

**Note**: Cmd and Task based scrolling should handle easings fine, although,
because they run a sequence of Tasks or Cmds under the hood, they may not appear as smooth
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
subscriptions toMsg animationState =
    if InternalScroll.isAnimationRunning animationState then
        Browser.Events.onAnimationFrameDelta (InternalScroll.AnimationFrame >> toMsg)

    else
        Sub.none


{-| Update the scroll animation state.

    type Msg
        = ScrollMsg Scroll.AnimationMsg

    -- ... other messages
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
        if Scroll.isAnimationRunning model.scrollAnimations then
            div [ class "scrolling-indicator" ] [ text "Scrolling..." ]

        else
            div [] []

-}
isAnimationRunning : AnimState -> Bool
isAnimationRunning =
    InternalScroll.isAnimationRunning


{-| Get the maximum duration of currently running scroll animations.
Returns the longest duration when multiple animations are running.
-}
getDuration : AnimState -> Maybe Int
getDuration =
    InternalScroll.getDuration



-- QUERYING SCROLL POSITION


{-| Get the current scroll position for a specific container.

Returns X and Y coordinates as a record.

Returns `Nothing` if the container is not found or scroll position is unavailable.

-}
getPosition : String -> AnimState -> Maybe { x : Float, y : Float }
getPosition =
    InternalScroll.getScrollPosition


{-| Get the current scroll position for a specific container.

Returns X and Y coordinates as a tuple `(x, y)`.

Returns `Nothing` if the container is not found or scroll position is unavailable.

-}
getPositionXY : String -> AnimState -> Maybe ( Float, Float )
getPositionXY =
    InternalScroll.getScrollPositionXY


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


{-| Execute scroll animations as a command.

Use this for fire-and-forget scrolling where you don't need state management.
The animation will run automatically without requiring subscriptions.

When multiple scroll targets are configured, all scroll animations will be batched into
a single command. The browser should then execute them simultaneously.

    -- Multiple scrolls happening at once
    scrollCmd =
        Scroll.init
            |> Scroll.builder
            |> Scroll.duration 1000
            |> ScrollAction.for "container-1"
            |> ScrollAction.toElement "target-1"
            |> ScrollAction.build
            |> ScrollAction.for "document"
            |> ScrollAction.toTop
            |> ScrollAction.build
            |> Scroll.toCmd ScrollCompleted

-}
toCmd : msg -> AnimBuilder -> Cmd msg
toCmd completionMsg animBuilder =
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

        -- Create a command for each scroll target
        createScrollCmd target =
            let
                containerType =
                    ScrollTarget.getContainerId target
            in
            case ( containerType, ScrollTarget.getTargetType target ) of
                ( "document", ScrollTarget.Element elementId ) ->
                    DocumentCmd.scrollWithConfig elementId completionMsg config

                ( "document", ScrollTarget.Coordinates x y ) ->
                    DocumentCmd.scrollToCoordinatesWithConfig x y completionMsg config

                ( "document", ScrollTarget.Top ) ->
                    DocumentCmd.scrollToTopWithConfig completionMsg config

                ( "document", ScrollTarget.Bottom ) ->
                    DocumentCmd.scrollToBottomWithConfig completionMsg config

                ( "document", ScrollTarget.Center ) ->
                    DocumentCmd.scrollToCenterWithConfig completionMsg config

                ( containerId, ScrollTarget.Element elementId ) ->
                    ContainerCmd.scrollWithConfig containerId elementId completionMsg config

                ( containerId, ScrollTarget.Coordinates x y ) ->
                    ContainerCmd.scrollToCoordinatesWithConfig containerId x y completionMsg config

                ( containerId, ScrollTarget.Top ) ->
                    ContainerCmd.scrollToTopWithConfig containerId completionMsg config

                ( containerId, ScrollTarget.Bottom ) ->
                    ContainerCmd.scrollToBottomWithConfig containerId completionMsg config

                ( containerId, ScrollTarget.Center ) ->
                    ContainerCmd.scrollToCenterWithConfig containerId completionMsg config

                _ ->
                    Cmd.none
    in
    scrollTargets
        |> List.map createScrollCmd
        |> Cmd.batch


{-| Execute scroll animations as a [Task](https://package.elm-lang.org/packages/elm/core/latest/Task).

Use this when you want to handle success or failure of the scroll animations, or compose them with other tasks.

    type Msg
        = GotScrollResult (Result ScrollError ScrollResult)
        | ...

    let
        scrollCmd =
            Scroll.init
                |> Scroll.builder
                |> ... -- configure scroll animation
                |> Scroll.toTask
                |> Task.attempt GotScrollResult
    in
    ( model, scrollCmd )

When multiple scroll targets are configured, they execute in sequence (one after another, top to bottom in the builder pipeline).
The task then returns [ScrollResult](#ScrollResult) for the last scroll on success, and [ScrollError](#ScrollError)
on failure if any scroll fails (subsequent scrolls will not execute).

To run multiple scrolls simultaneously and/or get individual results per scroll, create separate tasks for each scroll target
and `Cmd.batch` them together as a single Cmd.

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
