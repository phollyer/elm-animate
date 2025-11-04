module Move.CSS exposing
    ( Model
    , init
    , Position
    , TargetId
    , getPosition
    , setPosition
    , animateTo
    , animateToX
    , animateToY
    , transform
    , transformPosition
    , transformElement
    , transition
    , transitionWithDistance
    , transitionWithSpeed
    , onTransitionStart
    , onTransitionEnd
    , onTransitionRun
    , onTransitionCancel
    )

{-| This module generates CSS properties for transitions, letting the browser handle all animation logic.


## Key Features:

  - Better performance through native browser optimization
  - Smooth animations even when JavaScript is busy
  - Automatic easing handled by CSS
  - Less CPU usage compared to frame-based animation
  - Multiple element management with Model-based state


### Perfect for:

  - Landing page hero animations (fade-in, slide-in effects)
  - Modal dialogs and drawer transitions
  - Button hover effects and micro-interactions
  - Card animations in lists and grids
  - Simple layout transitions (sidebar expand/collapse)
  - Progressive web apps prioritizing battery life


# State Management

@docs Model
@docs init


# Position Management

@docs Position
@docs TargetId
@docs getPosition
@docs setPosition


# Animation Control

@docs animateTo
@docs animateToX
@docs animateToY


# CSS Generation


## Transform

Transform functions generate CSS `transform` properties that specify the current position of elements.
These define **where** an element should be positioned but don't handle the animation timing.

For smooth animations, combine transforms with transitions - the transform sets the target position
while the transition controls how smoothly the element moves there.

**See:** [MDN CSS transform](https://developer.mozilla.org/en-US/docs/Web/CSS/transform)

@docs transform
@docs transformPosition
@docs transformElement


## Transition

Transition functions generate CSS `transition` properties that control **how** elements animate
between different transform states. They define the duration, easing, and other timing aspects.

Without transitions, transform changes happen instantly. With transitions, the browser smoothly
animates between the old and new transform values over the specified duration.

**See:** [MDN CSS transition](https://developer.mozilla.org/en-US/docs/Web/CSS/transition)

@docs transition
@docs transitionWithDistance
@docs transitionWithSpeed


# CSS Transition Events

Hook into CSS transition events.

    type Msg
        = TransitionStarted
        | TransitionCompleted
        | TransitionRunning
        | TransitionCancelled

    div
        [ onTransitionStart TransitionStarted
        , onTransitionEnd TransitionCompleted
        , onTransitionRun TransitionRunning
        , onTransitionCancel TransitionCancelled
        , style "transition" (transition defaultConfig)
        ]
        []

@docs onTransitionStart
@docs onTransitionEnd
@docs onTransitionRun
@docs onTransitionCancel

-}

import Dict exposing (Dict)
import Html exposing (Attribute)
import Html.Events exposing (on)
import Json.Decode as Decode
import Move exposing (Config)
import Move.Internal as Internal



-- CORE TYPES


{-| Type alias for target element IDs that we want to animate.
-}
type alias TargetId =
    String


{-| Position type for X and Y coordinates in pixels.
-}
type alias Position =
    { x : Float
    , y : Float
    }



-- MODEL


{-| Model for tracking multiple element positions

Uses a Dict for O(1) position lookups and efficient management of many elements.

-}
type Model
    = Model (Dict String Position)


{-| Initialize an empty model with no element positions

    initialModel =
        init

-}
init : Model
init =
    Model Dict.empty



-- POSITION MANAGEMENT


{-| Set the position for an element

If not set, the element defaults to (0,0):

    model
        |> setPosition "box1" { x = 100, y = 150 }
        |> setPosition "box2" { x = 200, y = 250 }

-}
setPosition : TargetId -> Position -> Model -> Model
setPosition targetId position (Model positions) =
    Model (Dict.insert targetId position positions)


{-| Animate to a specific position (both X and Y axes)

    model
        |> animateTo "box1" { x = 200, y = 300 }

-}
animateTo : TargetId -> Position -> Model -> Model
animateTo targetId position model =
    setPosition targetId position model


{-| Animate to a specific X position (horizontal movement)

    model
        |> animateToX "box1" 200

-}
animateToX : TargetId -> Float -> Model -> Model
animateToX targetId x model =
    let
        currentY =
            getPosition targetId model
                |> Maybe.map .y
                |> Maybe.withDefault 0
    in
    setPosition targetId { x = x, y = currentY } model


{-| Animate to a specific Y position (vertical movement)

    model
        |> animateToY "box1" 300

-}
animateToY : TargetId -> Float -> Model -> Model
animateToY targetId y model =
    let
        currentX =
            getPosition targetId model
                |> Maybe.map .x
                |> Maybe.withDefault 0
    in
    setPosition targetId { x = currentX, y = y } model


{-| Get the current position of an element

    case getPosition "box1" model of
        Just position ->
            -- Use position.x and position.y

        Nothing ->
            -- Element not found in model

-}
getPosition : TargetId -> Model -> Maybe Position
getPosition targetId (Model positions) =
    Dict.get targetId positions



-- CSS GENERATION


{-| Generate CSS transform style for current element positions

    div
        [ style "transform" (transform "box1" model)
        , style "transition" (transition defaultConfig)
        ]
        [ text "Moving element" ]

-}
transform : TargetId -> Model -> String
transform targetId model =
    case getPosition targetId model of
        Just position ->
            transformPosition position

        Nothing ->
            transformPosition { x = 0, y = 0 }


{-| Generate CSS transform property declaration for a specific element

Returns a complete CSS property declaration string that can be used in custom CSS generation.

    -- For custom CSS generation:
    customStyles =
        [ transformElement "box1" model -- "transform: translate3d(100px, 50px, 0)"
        , "transition: transform 0.3s ease-out"
        ]
            |> String.join "; "

    -- Use the combined CSS string:
    div
        [ Html.Attributes.attribute "style" customStyles ]
        [ text "Animated element" ]

-}
transformElement : TargetId -> Model -> String
transformElement targetId model =
    "transform: " ++ transform targetId model


{-| Generate CSS transform string from a [Position](#Position) record

    transformPosition { x = 100, y = 50 }

    div
        [ style "transform" (transformPosition { x = 100, y = 50 }) ]
        []

-}
transformPosition : Position -> String
transformPosition position =
    "translate3d(" ++ String.fromFloat position.x ++ "px, " ++ String.fromFloat position.y ++ "px, 0)"


{-| Generate CSS transition property with default timing

    div
        [ style "transition" (transition defaultConfig) ]
        []

-}
transition : Config -> String
transition config =
    let
        duration =
            Internal.timingToMilliseconds config.timing 100

        easing =
            Internal.easingToString config.easing
    in
    "transform " ++ String.fromFloat duration ++ "ms " ++ easing


{-| Generate CSS transition property with distance-based duration

Calculates duration based on the distance traveled and timing configuration.
Use this when you want the animation speed to feel consistent regardless of distance.

    -- For a 100px movement
    div
        [ style "transition" (transitionWithDistance 100 defaultConfig)
        ]
        []

-}
transitionWithDistance : Float -> Config -> String
transitionWithDistance distance config =
    transitionWithConfig config distance


{-| Generate CSS transition with specific speed in pixels per second

Calculates the duration based on the distance and speed (pixels per second).

    let
        -- Distance in pixels
        distance =
            150

        -- Pixels per second
        speed =
            200
    in
    div
        [ style "transition" (transitionWithSpeed speed distance defaultConfig)
        ]
        []

-}
transitionWithSpeed : Float -> Float -> Config -> String
transitionWithSpeed speed distance config =
    let
        duration =
            (distance / speed) * 1000

        easing =
            Internal.easingToString config.easing
    in
    "transform " ++ String.fromFloat duration ++ "ms " ++ easing



-- INTERNAL HELPERS


transitionWithConfig : Config -> Float -> String
transitionWithConfig config distance =
    let
        duration =
            Internal.timingToMilliseconds config.timing distance

        easing =
            Internal.easingToString config.easing
    in
    "transform " ++ String.fromFloat duration ++ "ms " ++ easing



-- CSS TRANSITION EVENTS


{-| Listen for CSS transition start events
-}
onTransitionStart : msg -> Attribute msg
onTransitionStart msg =
    on "transitionstart" (Decode.succeed msg)


{-| Listen for CSS transition end events
-}
onTransitionEnd : msg -> Attribute msg
onTransitionEnd msg =
    on "transitionend" (Decode.succeed msg)


{-| Listen for CSS transition run events

Fired when a transition starts running (after any delay).

-}
onTransitionRun : msg -> Attribute msg
onTransitionRun msg =
    on "transitionrun" (Decode.succeed msg)


{-| Listen for CSS transition cancel events

Fired when a transition is cancelled.

-}
onTransitionCancel : msg -> Attribute msg
onTransitionCancel msg =
    on "transitioncancel" (Decode.succeed msg)
