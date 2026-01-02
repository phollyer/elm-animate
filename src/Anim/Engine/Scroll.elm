module Anim.Engine.Scroll exposing
    ( AnimState, init, AnimBuilder, builder
    , toCmd
    , ScrollError(..), ScrollResult, toTask
    , animate
    , AnimationMsg, update, subscriptions
    , duration, speed
    , easing
    , delay
    , isAnimationRunning, getDuration
    , getScrollPosition, getScrollPositionXY, getScrollPositionX, getScrollPositionY
    )

{-| Smooth Document and Container scrolling.

This Engine converts [AnimBuilder](#AnimBuilder) configurations to scroll animations
that can target specific elements or coordinates within the document or scrollable containers.


## Usage

    import Anim.Engine.Scroll as Scroll
    import Anim.Action.Scroll as ScrollAction

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


# Update

Only required for stateful subscription-based animations. Not needed for Cmd or Task based scrolling.

@docs AnimationMsg, update, subscriptions


# Global Settings

These settings will be used for all scroll animations unless overridden on a per-animation basis.


## Timing

@docs duration, speed


## Easing

@docs easing


## Delay

@docs delay


# Querying Animation State

@docs isAnimationRunning, getDuration


# Querying Scroll Position

@docs getScrollPosition, getScrollPositionXY, getScrollPositionX, getScrollPositionY

-}

import Anim.Easing exposing (Easing)
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
import Ease
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

    import Anim.Action.Scroll as ScrollAction

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

    import Anim.Action.Scroll as ScrollAction

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

    import Anim.Action.Scroll as ScrollAction

    Scroll.init
        |> Scroll.builder
        |> Scroll.easing EaseInOutQuad
        |> ... -- configure scroll animation
        |> Scroll.animate

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    InternalScroll.easing


{-| Set the global delay in milliseconds.

    import Anim.Action.Scroll as ScrollAction

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


{-| Get the duration of currently running scroll animations.
-}
getDuration : AnimState -> Maybe Int
getDuration =
    InternalScroll.getDuration



-- QUERYING SCROLL POSITION


{-| Get current scroll position for a specific container.
-}
getScrollPosition : String -> AnimState -> Maybe { x : Float, y : Float }
getScrollPosition =
    InternalScroll.getScrollPosition


{-| Get current scroll position as a tuple (x, y) for a specific container.
-}
getScrollPositionXY : String -> AnimState -> Maybe ( Float, Float )
getScrollPositionXY =
    InternalScroll.getScrollPositionXY


{-| Get current horizontal scroll position for a specific container.
-}
getScrollPositionX : String -> AnimState -> Maybe Float
getScrollPositionX =
    InternalScroll.getScrollPositionX


{-| Get current vertical scroll position for a specific container.
-}
getScrollPositionY : String -> AnimState -> Maybe Float
getScrollPositionY =
    InternalScroll.getScrollPositionY


{-| Execute a scroll animation as a command.

Use this for fire-and-forget scrolling where you don't need state management.
The animation will run automatically without requiring subscriptions.

    scrollCmd =
        Scroll.init
            |> Scroll.builder
            |> ... -- configure scroll animation
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
            , easing = Ease.linear -- Default easing for compatibility
            , axis = ScrollCommon.Both
            }

        containerType =
            InternalScroll.getContainer animBuilder
    in
    case scrollTargets of
        [] ->
            Cmd.none

        target :: _ ->
            let
                baseCmd =
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
            baseCmd


{-| Execute a scroll animation as a [Task](https://package.elm-lang.org/packages/elm/core/latest/Task).

Use this when you want to handle success or failure of the scroll animation, or compose it with other tasks.

The task returns [ScrollResult](#ScrollResult) on success with information about what was scrolled,
and [ScrollError](#ScrollError) on failure with detailed error context.

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
            , easing = Ease.linear -- Default easing for compatibility
            , axis = ScrollCommon.Both
            }

        containerType =
            InternalScroll.getContainer animBuilder
    in
    case scrollTargets of
        [] ->
            Task.succeed
                { containerId = containerType
                , targetElementId = Nothing
                , targetDescription = "No scroll target"
                }

        target :: _ ->
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
                    case ( containerType, ScrollTarget.getTargetType target ) of
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
