module Anim.Engine.WAAPI exposing
    ( AnimState, init, AnimBuilder, builder
    , animate, animateBatch
    , update
    , duration, speed
    , easing
    , delay
    , perspective, containerStyles, containerStylesFor
    , getPosition, getCurrentStyles
    , htmlAttributes
    )

{-| Ports-based animation system utilising the Web Animations API with optional state tracking.

This module converts [AnimBuilder](#AnimBuilder) configurations to JavaScript Web Animations API calls
via Elm ports for maximum performance and browser compatibility.

**Note:** This module requires the accompanying JavaScript library to handle the Web Animations API.

Install the `elm-animate-waapi` package from npm.

        npm install elm-animate-waapi

Then import and initialize it in your JavaScript code:

```javascript
    import ElmAnimateWAAPI from 'elm-animate-waapi';

    const app = Elm.Main.init({ ... });

    ElmAnimateWAAPI.init(app.ports);
```


# Build

@docs AnimState, init, AnimBuilder, builder


# Animation Execution

@docs animate, animateBatch


# Animation Updates

@docs update


# Global Settings

These settings will be used for all animations unless overridden on a per-animation basis.


## Timing

@docs duration, speed


## Easing

@docs easing


## Delay

@docs delay


## Perspective

@docs perspective, containerStyles, containerStylesFor


# Animation Data

@docs getPosition, getCurrentStyles


# JavaScript Integration

@docs htmlAttributes

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Properties.Position exposing (Position)
import Anim.Internal.WAAPI as InternalWAAPI
import Anim.Timing.Easing as Easing exposing (Easing)
import Html
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode


{-| Optional State for managing animations.

This state keeps track of animations and their configurations.

    import Anim.Engine.WAAPI as WAAPI

    { model | animations : WAAPI.AnimState }

If you only need to create fire-and-forget animations without tracking state,
you don't need to add this type to your model.

-}
type alias AnimState =
    InternalWAAPI.AnimState


{-| Initialize empty animation state.

    import Anim.Engine.WAAPI as WAAPI

    { model | animations = WAAPI.init }

-}
init : AnimState
init =
    InternalWAAPI.init


{-| Animation builder type.

This is used internally to configure animations before executing them.

-}
type alias AnimBuilder =
    Builder.AnimBuilder


{-| Turn the AnimState into an AnimBuilder.

Use this to start new animations based on current state.


    newBuilder =
        model.animations
            -- Start a new animation based on current state
            |> WAAPI.builder
            |> Position.for "element"
            |> Position.to { x = 100, y = 200 }
            |> Position.build
            |> WAAPI.animate

    -- "element" will animate from its current position

-}
builder : AnimState -> AnimBuilder
builder =
    InternalWAAPI.builder


{-| Execute stateful animation using JavaScript Web Animations API via ports.

Returns updated animation state and encoded animation data for ports.

    let
        ( newAnimState, animationData ) =
            WAAPI.builder model.animationState
                |> Position.for "my-element"
                |> Position.to { x = 100, y = 200 }
                |> Position.speed 500
                |> Position.build
                |> WAAPI.animate model.animationState
    in
    ( { model | animationState = newAnimState }
    , sendAnimationCommand animationData
    )

-}
animate : AnimState -> AnimBuilder -> ( AnimState, Encode.Value )
animate =
    InternalWAAPI.animate


{-| Execute animations using JavaScript Web Animations API via ports (stateless).

For state management and position continuity, use `animate` instead.

    Anim.init "my-element"
        |> Position.to { x = 100, y = 200 }
        |> Position.speed 500
        |> WAAPI.animateStateless sendAnimationCommand

The port function should have the signature:

    port sendAnimationCommand : Encode.Value -> Cmd msg

-}
animateStateless : (Encode.Value -> Cmd msg) -> AnimBuilder -> Cmd msg
animateStateless portFunction animBuilder =
    let
        processedData =
            Builder.processAnimationData animBuilder

        encodedData =
            Builder.encode processedData
    in
    portFunction encodedData


{-| Batch and send a List of animations in one go.

    createCircleAnimation index elementId =
        let
            angle =
                toFloat index * angleStep

            x =
                centerX + radius * cos angle

            y =
                centerY + radius * sin angle
        in
        Anim.init elementId
            |> Position.to { x = x, y = y }
            |> Position.duration 1000
            |> Position.easing Easing.easeInOut

    cmd1 =
        Anim.animateBatch animateElement <|
            [ createCircleAnimation 0 "element1"
            , createCircleAnimation 1 "element2"
            , createCircleAnimation 2 "element3"
            , createCircleAnimation 3 "element4"
            , createCircleAnimation 4 "element5"
            , createCircleAnimation 5 "element6"
            , createCircleAnimation 6 "element7"
            , createCircleAnimation 7 "element8"
            , createCircleAnimation 8 "element9"
            , createCircleAnimation 9 "element10"
            , createCircleAnimation 10 "element11"
            , createCircleAnimation 11 "element12"
            , createCircleAnimation 12 "element13"
            ]

-}
animateBatch : (Encode.Value -> Cmd msg) -> List AnimBuilder -> Cmd msg
animateBatch portFunction builders =
    builders
        |> List.map (animateStateless portFunction)
        |> Cmd.batch



-- ANIMATION DATA


{-| Get current position of an element.
-}
getPosition : String -> AnimState -> Maybe Position
getPosition =
    InternalWAAPI.getPosition


{-| Get current styles for an element (for debugging/display purposes).
-}
getCurrentStyles : String -> AnimState -> List ( String, String )
getCurrentStyles =
    InternalWAAPI.getCurrentStyles


{-| Set global duration in milliseconds (overrides any previous speed setting).

    WAAPI.init
        |> WAAPI.duration 1000
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> WAAPI.animate

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalWAAPI.duration


{-| Set global speed in units per second (overrides any previous duration setting).

    WAAPI.init
        |> WAAPI.speed 100
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> WAAPI.animate

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalWAAPI.speed


{-| Set global easing function.

    Ports.init
        |> Ports.easing EaseInOutQuad
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> Ports.animate

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Easing.mapInternal InternalWAAPI.easing


{-| Set global delay in milliseconds.

    Ports.init
        |> Ports.delay 500
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> Ports.animate

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalWAAPI.delay


{-| Set the global perspective value for 3D transforms.

The perspective value determines the distance between the viewer and the z=0 plane.
A smaller value creates a more pronounced 3D effect, while a larger value creates
a more subtle effect.

    WAAPI.init
        |> WAAPI.perspective "container-id" 1000
        |> Position.for "element"
        |> Position.toXYZ 100 200 50
        |> Position.build
        |> WAAPI.animate

You can override this global setting for specific properties using property-specific perspective functions:

    WAAPI.init
        |> WAAPI.perspective "default-container" 1000
        -- Global setting
        |> Position.for "special-element"
        |> Position.toXYZ 100 200 50
        |> Position.perspective "special-container" 800
        -- Override for position
        |> Position.build
        |> WAAPI.animate

-}
perspective : String -> Float -> AnimBuilder -> AnimBuilder
perspective =
    Builder.perspective


{-| Generate HTML attributes for container elements that need perspective.

This function generates the necessary CSS perspective attributes for container elements
that will contain 3D-transformed children. Use this on the parent container element
to establish the perspective context.

    div
        (WAAPI.containerStyles animState)
        [-- children with 3D transforms
        ]

The function will look for any elements in the animation state that have perspective
settings and generate the appropriate container styles.

-}
containerStyles : AnimState -> List (Html.Attribute msg)
containerStyles animState =
    case Builder.getPerspective (builder animState) of
        Just { containerId, value } ->
            containerStylesFor containerId value

        Nothing ->
            []


{-| Generate HTML attributes for a specific container with a given perspective value.

This is useful when you only need perspective styles for one container:

    div
        (WAAPI.containerStylesFor "my-container" 1000)
        [-- children with 3D transforms
        ]

-}
containerStylesFor : String -> Float -> List (Html.Attribute msg)
containerStylesFor containerId perspectiveValue =
    [ Html.Attributes.id containerId
    , Html.Attributes.style "perspective" (String.fromFloat perspectiveValue ++ "px")
    , Html.Attributes.style "transform-style" "preserve-3d"
    ]


{-| Generate HTML attributes for ports-based animations.

This function provides a way to add animation data attributes to elements,
which can be useful for debugging or JavaScript integration.

-}
htmlAttributes : String -> AnimState -> List (Html.Attribute msg)
htmlAttributes =
    InternalWAAPI.htmlAttributes


{-| Update animation state with data received from JavaScript via ports.

This function processes animation update data received from the JavaScript WAAPI
integration and updates the internal animation state accordingly.

    type Msg
        = ReceiveWAAPI Decode.Value
        | ...

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ReceiveWAAPI value ->
                ( { model | animations = WAAPI.update value model.animations }, Cmd.none )

-}
update : Decode.Value -> AnimState -> AnimState
update =
    InternalWAAPI.update
