module Anim.Sub exposing
    ( ElementId
    , init, builder, animate, AnimationState, AnimationMsg
    , subscriptions, update
    , getPosition, getCurrentStyles, getDuration, isAnimationRunning
    , htmlAttributes
    )

{-| Subscription-based animation system for Anim.

This module converts AnimBuilder configurations to frame-based animations using
onAnimationFrameDelta subscriptions for smooth, controlled animations.


# Animation Execution

@docs ElementId

@docs init, builder, animate, AnimationState, AnimationMsg


# Animation Management

@docs subscriptions, update


# Animation Data

@docs getPosition, getCurrentStyles, getDuration, isAnimationRunning


# CSS Generation

@docs htmlAttributes

-}

import Anim exposing (AnimBuilder)
import Anim.Internal.Properties.Position exposing (Position)
import Anim.Internal.Sub as InternalSub
import Anim.Internal.Timing.Easing exposing (Easing(..))
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser exposing (UrlRequest(..))
import Html



-- ANIMATION STATE


{-| State for managing subscription-based animations.
-}
type alias AnimationState =
    InternalSub.AnimationState



-- ANIMATION EXECUTION


{-| The ID of the target element to animate.
-}
type alias ElementId =
    String


{-| Initialize empty animation builder.
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
getPosition : String -> AnimationState -> Maybe Position
getPosition =
    InternalSub.getPosition


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
getCurrentStyles : String -> AnimationState -> List ( String, String )
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
