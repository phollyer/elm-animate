module Anim.Engine.Scroll exposing
    ( AnimState, init, AnimBuilder, builder
    , toCmd, toTask, animate
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

@docs toCmd, toTask, animate


# Update

If using subscription-based scroll animations with the [animate](#animate) function,
you need to handle updates to the animation state.

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


{-| Generate scroll animation state and command from the builder.

    import Anim.Action.Scroll as ScrollAction

    type Msg
        = ScrollMsg Scroll.AnimationMsg
        | ...

    let
        ( scrollState, scrollCmd ) =
            model.scrollAnimations
                |> Scroll.builder
                |> Scroll.speed 500
                |> ScrollAction.forDocument
                |> ScrollAction.toElement sectionId
                |> ScrollAction.build
                |> Scroll.animate ScrollMsg
    in
    ( { model | scrollAnimations = scrollState }
    , scrollCmd
    )

-}
animate : (AnimationMsg -> msg) -> AnimBuilder -> ( AnimState, Cmd msg )
animate =
    InternalScroll.animate



-- GLOBAL SETTINGS


{-| Set global duration in milliseconds (overrides any previous speed setting).

    import Anim.Action.Scroll as ScrollAction

    Scroll.init
        |> Scroll.builder
        |> Scroll.duration 1000
        |> ScrollAction.forDocument
        |> ScrollAction.toElement "section-1"
        |> ScrollAction.build
        |> Scroll.animate

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalScroll.duration


{-| Set global speed in pixels per second (overrides any previous duration setting).

    import Anim.Action.Scroll as ScrollAction

    Scroll.init
        |> Scroll.builder
        |> Scroll.speed 500
        |> ScrollAction.forDocument
        |> ScrollAction.toElement "section-1"
        |> ScrollAction.build
        |> Scroll.animate

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalScroll.speed


{-| Set global easing function.

    import Anim.Action.Scroll as ScrollAction

    Scroll.init
        |> Scroll.builder
        |> Scroll.easing EaseInOutQuad
        |> ScrollAction.forDocument
        |> ScrollAction.toElement "section-1"
        |> ScrollAction.build
        |> Scroll.animate

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    InternalScroll.easing


{-| Set global delay in milliseconds.

    import Anim.Action.Scroll as ScrollAction

    Scroll.init
        |> Scroll.builder
        |> Scroll.delay 500
        |> ScrollAction.forDocument
        |> ScrollAction.toElement "section-1"
        |> ScrollAction.build
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

    type Msg
        = NoOp
        | ShowError String
        | ...

    let
        scrollTask =
            Scroll.init
                |> Scroll.builder
                |> ... -- configure scroll animation
                |> Scroll.toTask

        handleResult result =
            case result of
                Ok () ->
                    -- Scroll completed successfully
                    NoOp

                Err domError ->
                    -- Handle error (element not found, etc.)
                    ShowError "Could not scroll to element"
    in
    ( model, Task.attempt handleResult scrollTask )

-}
toTask : AnimBuilder -> Task Dom.Error ()
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
            Task.succeed ()

        target :: _ ->
            let
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

                        ( containerId, ScrollTarget.Element elementId ) ->
                            ContainerTask.scrollWithConfig containerId elementId config

                        ( containerId, ScrollTarget.Coordinates x y ) ->
                            ContainerTask.scrollToCoordinatesWithConfig containerId x y config

                        ( containerId, ScrollTarget.Top ) ->
                            ContainerTask.scrollToTopWithConfig containerId config

                        ( containerId, ScrollTarget.Bottom ) ->
                            ContainerTask.scrollToBottomWithConfig containerId config

                        ( containerId, ScrollTarget.Center ) ->
                            ContainerTask.scrollToCenterWithConfig containerId config

                        _ ->
                            Task.succeed []
            in
            -- Convert Task (List ()) to Task ()
            Task.map (\_ -> ()) baseTask
