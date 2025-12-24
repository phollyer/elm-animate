module Anim.Engine.Sub exposing
    ( AnimationState, init, AnimBuilder, builder
    , animate, AnimationMsg
    , update, subscriptions
    , htmlAttributes
    , duration, speed
    , easing
    , delay
    , ElementId
    , getPosition, getPositionXY, getPositionX, getPositionY
    , getSize, getSizeHW, getSizeH, getSizeW
    , getCurrentStyles
    , isAnimationRunning, getDuration
    )

{-| Subscription-based animation system with state tracking.

This module converts [AnimBuilder](#AnimBuilder) configurations to frame-based animations using
subscriptions for smooth, controlled animations.


# Build

@docs AnimationState, init, AnimBuilder, builder


# Execute

@docs animate, AnimationMsg


# Update

@docs update, subscriptions


# View


# CSS Generation

@docs htmlAttributes


# Global Settings

These settings will be used for all animations unless overridden on a per-animation basis.


## Timing

@docs duration, speed


## Easing

@docs easing


## Delay

@docs delay


# Animation Querying

@docs ElementId


## Position

@docs getPosition, getPositionXY, getPositionX, getPositionY


## Size

@docs getSize, getSizeHW, getSizeH, getSizeW


## Current Styles

@docs getCurrentStyles


## Animation State

@docs isAnimationRunning, getDuration

-}

import Anim.Internal.Properties.Position exposing (Position)
import Anim.Internal.Properties.Size exposing (Size)
import Anim.Internal.Sub as InternalSub
import Anim.Timing.Easing as Easing exposing (Easing)
import Html


{-| Animation builder type.

This is used internally to configure animations before executing them.

-}
type alias AnimBuilder =
    InternalSub.AnimBuilder



-- ANIMATION STATE


{-| State for managing animations.

This state keeps track of animations and their configurations.

    import Anim.Engine.Sub as Sub

    { model | animations : Sub.AnimationState }

-}
type alias AnimationState =
    InternalSub.AnimationState



-- ANIMATION EXECUTION


{-| The ID of the target element being animated.
-}
type alias ElementId =
    String


{-| Initialize empty animation state.

    import Anim.Engine.Sub as Sub

    { model | animations = Sub.init }

-}
init : AnimationState
init =
    InternalSub.init


{-| Turn the AnimationState into an AnimBuilder.

Use this to start new animations based on current state.

    -- Start a new animation based on current state
    newBuilder =
        model.animations
            |> Sub.builder
            |> Position.for "element"
            |> Position.to { x = 100, y = 200 }
            |> Position.build
            |> Sub.animate

-}
builder : AnimationState -> AnimBuilder
builder =
    InternalSub.builder


{-| Create animation state from AnimBuilder.

    let
        animationState =
            Anim.init "my-element"
                |> Position.to { x = 100, y = 200 }
                |> Scale.to { x = 1.5, y = 1.5 }
                |> Sub.animate
    in
    -- Use with subscriptions and update

-}
animate : AnimBuilder -> AnimationState
animate =
    InternalSub.animate


{-| Set global duration in milliseconds (overrides any previous speed setting).

    Sub.init
        |> Sub.duration 1000
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> Sub.animate

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalSub.duration


{-| Set global speed in units per second (overrides any previous duration setting).

    Sub.init
        |> Sub.speed 100
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> Sub.animate

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalSub.speed


{-| Set global easing function.

    Sub.init
        |> Sub.easing EaseInOutQuad
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> Sub.animate

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Easing.mapInternal InternalSub.easing


{-| Set global delay in milliseconds.

    Sub.init
        |> Sub.delay 500
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> Sub.animate

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalSub.delay



-- SUBSCRIPTIONS


{-| Subscribe to animation frames when animations are running.
-}
subscriptions : AnimationState -> Sub AnimationMsg
subscriptions =
    InternalSub.subscriptions



-- UPDATE


{-| Messages for animation updates.
-}
type alias AnimationMsg =
    InternalSub.AnimationMsg


{-| Update animation state with frame delta time.
-}
update : AnimationMsg -> AnimationState -> AnimationState
update =
    InternalSub.update



-- POSITION


{-| Get current position of an element being animated.
-}
getPosition : ElementId -> AnimationState -> Maybe Position
getPosition =
    InternalSub.getPosition


{-| Get current X and Y position of an element being animated.
-}
getPositionXY : ElementId -> AnimationState -> Maybe ( Float, Float )
getPositionXY =
    InternalSub.getPositionXY


{-| Get current X position of an element being animated.
-}
getPositionX : ElementId -> AnimationState -> Maybe Float
getPositionX =
    InternalSub.getPositionX


{-| Get current Y position of an element being animated.
-}
getPositionY : ElementId -> AnimationState -> Maybe Float
getPositionY =
    InternalSub.getPositionY



-- SIZE


{-| Get current size of an element being animated.
-}
getSize : ElementId -> AnimationState -> Maybe Size
getSize =
    InternalSub.getSize


{-| Get current width and height of an element being animated.
-}
getSizeHW : ElementId -> AnimationState -> Maybe ( Float, Float )
getSizeHW =
    InternalSub.getSizeHW


{-| Get current height of an element being animated.
-}
getSizeH : ElementId -> AnimationState -> Maybe Float
getSizeH =
    InternalSub.getSizeH


{-| Get current width of an element being animated.
-}
getSizeW : ElementId -> AnimationState -> Maybe Float
getSizeW =
    InternalSub.getSizeW


{-| Get duration of the first animation found for an element.
Returns Nothing if the element has no animations.
-}
getDuration : ElementId -> AnimationState -> Maybe Int
getDuration =
    InternalSub.getDuration


{-| Check if an animation is currently running for the given element.
Returns True if the element has active animations, False otherwise.
-}
isAnimationRunning : ElementId -> AnimationState -> Bool
isAnimationRunning =
    InternalSub.isAnimationRunning



-- CURRENT STYLES


{-| Get current animation values as CSS-compatible styles.
-}
getCurrentStyles : ElementId -> AnimationState -> List ( String, String )
getCurrentStyles =
    InternalSub.getCurrentStyles


{-| Get all the HTML attributes needed for the CSS animations on the target element.


### HTML Example

    div
        ([ Html.Attributes.id "my-element"
         , ...
         ]
            ++ CSS.htmlAttributes "my-element" animationState
        )
        [ text "Animating element" ]


### Elm UI Example

For Elm UI, just wrap each attribute with [htmlAttribute](https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/Element#htmlAttribute):

    el
        ([ htmlAttribute (Html.Attributes.id "my-element")
         , ...
         ]
            ++ List.map htmlAttribute <|
                CSS.htmlAttributes "my-element" animationState
        )
        (text "Animating element")

-}
htmlAttributes : ElementId -> AnimationState -> List (Html.Attribute msg)
htmlAttributes =
    InternalSub.htmlAttributes
