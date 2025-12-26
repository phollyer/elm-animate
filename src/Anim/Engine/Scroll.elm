module Anim.Engine.Scroll exposing
    ( AnimState, init, AnimBuilder, builder
    , animate, toCmd, toTask
    , AnimationMsg, update, subscriptions
    , onBothAxes, onXAxis, onYAxis
    , onBothAxesWithOffset, onXAxisWithOffset, onYAxisWithOffset
    , duration, speed
    , easing
    , delay
    , toElement, toTop, toBottom, toCenter
    , toXY, toX, toY, toCoordinates, toPercentage
    , document, container
    , isAnimationRunning, getDuration
    , getScrollPosition, getScrollPositionXY, getScrollPositionX, getScrollPositionY
    )

{-| Smooth Document and Container scrolling.

This module provides smooth scrolling animations using `subscriptions`, `Cmd`s, and `Task`s.
Choose the approach that best fits your application's architecture.

  - **Cmd**: For simple, fire-and-forget scrolling where you don't need state management.
  - **Tasks**: For scroll animations that require error handling and composition with other tasks.
  - **Subscriptions**: For managing ongoing scroll animations with state tracking.


# Build

@docs AnimState, init, AnimBuilder, builder


# Execute

@docs animate, toCmd, toTask


# Manage

@docs AnimationMsg, update, subscriptions


# Axis Selection

@docs onBothAxes, onXAxis, onYAxis


## With Offsets

@docs onBothAxesWithOffset, onXAxisWithOffset, onYAxisWithOffset


# Global Settings

These settings will be used for all scroll animations unless overridden on a per-animation basis.


## Timing

@docs duration, speed


## Easing

@docs easing


## Delay

@docs delay


# Scroll Targeting


## Element and Position Targeting

@docs toElement, toTop, toBottom, toCenter


## Coordinate Targeting

@docs toXY, toX, toY, toCoordinates, toPercentage


## Container Selection

@docs document, container


# Querying Animation State

@docs isAnimationRunning, getDuration


# Querying Scroll Position

@docs getScrollPosition, getScrollPositionXY, getScrollPositionX, getScrollPositionY

-}

import Anim.Internal.Properties.ScrollTarget as ScrollTarget exposing (Axis(..))
import Anim.Internal.Scroll as InternalScroll
import Anim.Internal.Scroll.Common as ScrollCommon
import Anim.Internal.Scroll.Container.Cmd as ContainerCmd
import Anim.Internal.Scroll.Container.Task as ContainerTask
import Anim.Internal.Scroll.Document.Cmd as DocumentCmd
import Anim.Internal.Scroll.Document.Task as DocumentTask
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Anim.Timing.Easing as Easing exposing (Easing)
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
            |> Scroll.toElement "target-element"
            |> Scroll.speed 500
            |> Scroll.toCmd ScrollCompleted

-}
init : AnimState
init =
    InternalScroll.init


{-| Turn the AnimState into an AnimBuilder.

Use this to start new scroll animations.

    -- Start a new scroll animation based on current state
    newAnimations =
        model.scrollAnimations
            |> Scroll.builder
            |> Scroll.toElement "section-1"
            |> Scroll.speed 500
            |> Scroll.animate

    -- Start a new fire-and-forget scroll animation
    newAnimations =
        Scroll.init
            |> Scroll.builder
            |> Scroll.toElement "section-1"
            |> Scroll.speed 500
            |> Scroll.animate

-}
builder : AnimState -> AnimBuilder
builder =
    InternalScroll.builder


{-| Generate scroll animation state and command from the builder.

    type Msg
        = ScrollMsg Scroll.AnimationMsg
        | ScrollToSection String
        | ...

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollMsg scrollMsg ->
                let
                    ( newScrollState, scrollCmd ) =
                        Scroll.update ScrollMsg scrollMsg model.scrollAnimations

                in
                ( { model | scrollAnimations = newScrollState }, scrollCmd )

            ScrollToSection sectionId ->
                let
                    ( scrollState, scrollCmd ) =
                        Scroll.init
                            |> Scroll.builder
                            |> Scroll.toElement "section-1"
                            |> Scroll.speed 500
                            |> Scroll.animate ScrollMsg
                in
                ( { model | scrollAnimations = scrollState }, scrollCmd )

-}
animate : (AnimationMsg -> msg) -> AnimBuilder -> ( AnimState, Cmd msg )
animate =
    InternalScroll.animate



-- GLOBAL SETTINGS


{-| Set global duration in milliseconds (overrides any previous speed setting).

    Scroll.init
        |> Scroll.builder
        |> Scroll.duration 1000
        |> Scroll.toElement "section-1"
        |> Scroll.animate

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalScroll.duration


{-| Set global speed in pixels per second (overrides any previous duration setting).

    Scroll.init
        |> Scroll.builder
        |> Scroll.speed 500
        |> Scroll.toElement "section-1"
        |> Scroll.animate

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalScroll.speed


{-| Set global easing function.

    Scroll.init
        |> Scroll.builder
        |> Scroll.easing EaseInOutQuad
        |> Scroll.toElement "section-1"
        |> Scroll.animate

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Easing.mapInternal InternalScroll.easing


{-| Set global delay in milliseconds.

    Scroll.init
        |> Scroll.builder
        |> Scroll.delay 500
        |> Scroll.toElement "section-1"
        |> Scroll.animate

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalScroll.delay



-- SCROLL TARGETING


{-| Scroll to a specific element by ID.

    Scroll.init
        |> Scroll.builder
        |> Scroll.toElement "section-header"
        |> Scroll.speed 500
        |> Scroll.animate

-}
toElement : String -> AnimBuilder -> AnimBuilder
toElement elementId =
    InternalScroll.addScrollTarget (ScrollTarget.for "document" |> ScrollTarget.toElement elementId)


{-| Scroll to specific X and Y coordinates.

    Scroll.init
        |> Scroll.builder
        |> Scroll.toXY 100 200
        |> Scroll.speed 500
        |> Scroll.animate

-}
toXY : Float -> Float -> AnimBuilder -> AnimBuilder
toXY x y =
    InternalScroll.addScrollTarget (ScrollTarget.for "document" |> ScrollTarget.toXY x y)


{-| Scroll to specific X coordinate only.

    Scroll.init
        |> Scroll.builder
        |> Scroll.toX 100
        |> Scroll.speed 500
        |> Scroll.animate

-}
toX : Float -> AnimBuilder -> AnimBuilder
toX x =
    InternalScroll.addScrollTarget (ScrollTarget.for "document" |> ScrollTarget.toX x)


{-| Scroll to specific Y coordinate only.

    Scroll.init
        |> Scroll.builder
        |> Scroll.toY 200
        |> Scroll.speed 500
        |> Scroll.animate

-}
toY : Float -> AnimBuilder -> AnimBuilder
toY y =
    InternalScroll.addScrollTarget (ScrollTarget.for "document" |> ScrollTarget.toY y)


{-| Scroll to the top of the container.

    Scroll.init
        |> Scroll.builder
        |> Scroll.toTop
        |> Scroll.speed 500
        |> Scroll.animate

-}
toTop : AnimBuilder -> AnimBuilder
toTop =
    InternalScroll.addScrollTarget (ScrollTarget.for "document" |> ScrollTarget.toTop)


{-| Scroll to the bottom of the container.

    Scroll.init
        |> Scroll.builder
        |> Scroll.toBottom
        |> Scroll.speed 500
        |> Scroll.animate

-}
toBottom : AnimBuilder -> AnimBuilder
toBottom =
    InternalScroll.addScrollTarget (ScrollTarget.for "document" |> ScrollTarget.toBottom)


{-| Scroll to the center of the container.

    Scroll.init
        |> Scroll.builder
        |> Scroll.toCenter
        |> Scroll.speed 500
        |> Scroll.animate

-}
toCenter : AnimBuilder -> AnimBuilder
toCenter =
    InternalScroll.addScrollTarget (ScrollTarget.for "document" |> ScrollTarget.toCenter)


{-| Scroll to specific coordinates.

    Scroll.init
        |> Scroll.builder
        |> Scroll.toCoordinates 150 300
        |> Scroll.speed 500
        |> Scroll.animate

-}
toCoordinates : Float -> Float -> AnimBuilder -> AnimBuilder
toCoordinates x y =
    InternalScroll.addScrollTarget (ScrollTarget.for "document" |> ScrollTarget.toCoordinates x y)


{-| Scroll to percentage of container size.

    Scroll.init
        |> Scroll.builder
        |> Scroll.toPercentage 0.5 0.8
        -- 50% width, 80% height
        |> Scroll.speed 500
        |> Scroll.animate

-}
toPercentage : Float -> Float -> AnimBuilder -> AnimBuilder
toPercentage xPercent yPercent =
    InternalScroll.addScrollTarget (ScrollTarget.for "document" |> ScrollTarget.toPercentage xPercent yPercent)


{-| Set the container to the document body (default).

    Scroll.init
        |> Scroll.builder
        |> Scroll.document
        |> Scroll.toElement "section-1"
        |> Scroll.speed 500
        |> Scroll.animate

-}
document : AnimBuilder -> AnimBuilder
document =
    InternalScroll.setContainer "document"


{-| Set the container to a specific element ID.

    Scroll.init
        |> Scroll.builder
        |> Scroll.container "scrollable-content"
        |> Scroll.toElement "section-1"
        |> Scroll.speed 500
        |> Scroll.animate

-}
container : String -> AnimBuilder -> AnimBuilder
container containerId =
    InternalScroll.setContainer containerId



-- ANIMATION MANAGEMENT


{-| Subscription for scroll animations.

Add this to your application's subscriptions function:

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.batch
            [ Scroll.subscriptions ScrollAnimationMsg model.scrollAnimations

            -- ... other subscriptions
            ]

-}
subscriptions : (AnimationMsg -> msg) -> AnimState -> Sub msg
subscriptions toMsg animationState =
    if InternalScroll.isAnimationRunning animationState then
        Browser.Events.onAnimationFrameDelta (InternalScroll.AnimationFrame >> toMsg)

    else
        Sub.none


{-| Update scroll animation state.

Add this to your application's update function:


    type Msg
        = ScrollAnimationMsg Scroll.AnimationMsg

    -- ... other messages
    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollAnimationMsg scrollMsg ->
                ( { model | scrollAnimations = Scroll.update scrollMsg model.scrollAnimations }
                , Cmd.none
                )

    -- ... other message handling

-}
update : (AnimationMsg -> msg) -> AnimationMsg -> AnimState -> ( AnimState, Cmd msg )
update toMsg animationMsg animState =
    InternalScroll.update toMsg animationMsg animState



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

For simple, fire-and-forget scrolling where you don't need state management.
The animation will run automatically without requiring subscriptions.

    let
        scrollCmd =
            Scroll.init
                |> Scroll.builder
                |> Scroll.duration 1000
                |> Scroll.speed 800
                |> Scroll.toElement "target-element"
                |> Scroll.document
                |> Scroll.toCmd ScrollCompleted
    in
    ( model, scrollCmd )

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


{-| Execute a scroll animation as a task.

Returns a task that can be composed with other tasks and provides error handling
for cases where the scroll target cannot be found or accessed.

    let
        scrollTask =
            Scroll.init
                |> Scroll.builder
                |> Scroll.duration 1000
                |> Scroll.toElement "target-element"
                |> Scroll.document
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



-- AXIS SELECTION


{-| Scroll on both X and Y axes (default).

    Scroll.init
        |> Scroll.builder
        |> Scroll.onBothAxes
        |> Scroll.toElement "section-1"
        |> Scroll.animate

-}
onBothAxes : AnimBuilder -> AnimBuilder
onBothAxes =
    InternalScroll.setAxis Both


{-| Scroll on X axis only.

    Scroll.init
        |> Scroll.builder
        |> Scroll.onXAxis
        |> Scroll.toElement "section-1"
        |> Scroll.animate

-}
onXAxis : AnimBuilder -> AnimBuilder
onXAxis =
    InternalScroll.setAxis X


{-| Scroll on Y axis only.

    Scroll.init
        |> Scroll.builder
        |> Scroll.onYAxis
        |> Scroll.toElement "section-1"
        |> Scroll.animate

-}
onYAxis : AnimBuilder -> AnimBuilder
onYAxis =
    InternalScroll.setAxis Y


{-| Scroll on both X and Y axes with an offset.

    Scroll.init
        |> Scroll.builder
        |> Scroll.onBothAxesWithOffset 60
        |> Scroll.toElement "section-1"
        |> Scroll.animate

-}
onBothAxesWithOffset : Float -> Float -> AnimBuilder -> AnimBuilder
onBothAxesWithOffset offsetX offsetY =
    InternalScroll.setAxis Both >> InternalScroll.setOffset ( offsetX, offsetY )


{-| Scroll on X axis only with an offset.

    Scroll.init
        |> Scroll.builder
        |> Scroll.onXAxisWithOffset 60
        |> Scroll.toElement "section-1"
        |> Scroll.animate

-}
onXAxisWithOffset : Float -> AnimBuilder -> AnimBuilder
onXAxisWithOffset offset =
    InternalScroll.setAxis X >> InternalScroll.setOffsetX offset


{-| Scroll on Y axis only with an offset.

    Scroll.init
        |> Scroll.builder
        |> Scroll.onYAxisWithOffset 60
        |> Scroll.toElement "section-1"
        |> Scroll.animate

-}
onYAxisWithOffset : Float -> AnimBuilder -> AnimBuilder
onYAxisWithOffset offset =
    InternalScroll.setAxis Y >> InternalScroll.setOffsetY offset
