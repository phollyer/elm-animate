module SmoothMovePorts exposing
    ( Config
    , defaultConfig
    , Axis(..)
    , Model
    , init
    , animateTo
    , animateToWithConfig
    , animateBatch
    , animateBatchWithPort
    , setInitialPosition
    , stopAnimation
    , stopBatch
    , stopBatchWithPort
    , isAnimating
    , getPosition
    , getAllPositions
    , transform
    , transformElement
    , handlePositionUpdate
    , handleAnimationComplete
    , encodeAnimationCommand
    , encodeStopCommand
    , AnimationCommand
    , AnimationSpec
    , PositionUpdate
    )

{-| A port-based animation library helper that works with JavaScript's Web Animations API for high-performance element movement.

Since Elm packages cannot contain ports, this module provides helper functions and data types
to make it easy to implement your own ports for JavaScript-based animations.

This approach provides:

  - Access to Web Animations API for optimal performance
  - Hardware acceleration when available
  - Native JavaScript easing functions
  - Ability to leverage future browser animation improvements

See the accompanying `smooth-move-ports.js` file for the JavaScript implementation.


# Configuration

@docs Config
@docs defaultConfig
@docs Timing
@docs Axis


# State Management

@docs Model
@docs init


# Animation Control

@docs animateTo
@docs animateToWithConfig
@docs animateBatch
@docs animateBatchWithPort
@docs setInitialPosition
@docs stopAnimation
@docs stopBatch
@docs stopBatchWithPort


# State Queries

@docs isAnimating
@docs getPosition
@docs getAllPositions


# Styling Helpers

@docs transform
@docs transformElement


# Port Integration Helpers

@docs handlePositionUpdate
@docs handleAnimationComplete
@docs encodeAnimationCommand
@docs encodeStopCommand
@docs AnimationCommand
@docs AnimationSpec
@docs PositionUpdate

-}

import Dict exposing (Dict)


{-| Animation timing configuration

Choose between speed-based or duration-based timing:

  - Speed: Animation speed in pixels per second (higher = faster)
  - Duration: Animation duration in milliseconds (higher = slower)

-}
type Timing
    = Speed Float
    | Duration Int


{-| Configuration for port-based animations

  - axis: Movement axis (X, Y, or Both)
  - timing: Animation timing (Speed in pixels per second or Duration in milliseconds)
  - easing: Web Animations API easing ("ease-out", "cubic-bezier(0.4, 0.0, 0.2, 1)", etc.)

-}
type alias Config =
    { axis : Axis
    , timing : Timing
    , easing : String
    }


{-| Convert timing configuration to milliseconds for Web Animations API
-}
timingToMilliseconds : Timing -> Float -> Float
timingToMilliseconds timing distance =
    case timing of
        Speed pixelsPerSecond ->
            -- Convert pixels per second to duration: distance / speed = seconds, then * 1000 for ms
            (distance / pixelsPerSecond) * 1000

        Duration milliseconds ->
            toFloat milliseconds


{-| Animation axis constraint
-}
type Axis
    = X
    | Y
    | Both


{-| Default configuration using Web Animations API
-}
defaultConfig : Config
defaultConfig =
    { axis = Both
    , timing = Duration 400
    , easing = "ease-out" -- Standard Web Animations API easing
    }


{-| Element state for port-based animations
-}
type alias ElementData =
    { currentX : Float
    , currentY : Float
    , targetX : Float
    , targetY : Float
    , isAnimating : Bool
    , config : Config
    }


{-| Main state container
-}
type Model
    = Model (Dict String ElementData)


{-| Initialize empty model
-}
init : Model
init =
    Model Dict.empty


{-| Animation command data to send to JavaScript

Use this with your own port:

    port animateElement : AnimationCommand -> Cmd msg

-}
type alias AnimationCommand =
    { elementId : String
    , targetX : Float
    , targetY : Float
    , duration : Float
    , easing : String
    , axis : String
    }


{-| Animation specification for batch operations

Use this with `animateBatch` to animate multiple elements at once.

-}
type alias AnimationSpec =
    { elementId : String
    , targetX : Float
    , targetY : Float
    , config : Config
    }


{-| Position update data received from JavaScript

Use this with your own port:

    port positionUpdates : (Decode.Value -> msg) -> Sub msg

-}
type alias PositionUpdate =
    { elementId : String
    , x : Float
    , y : Float
    , isAnimating : Bool
    }



-- PUBLIC API --


{-| Start animating an element to a target position using default config

Returns the updated model and an animation command for your port.

-}
animateTo : String -> Float -> Float -> Model -> ( Model, AnimationCommand )
animateTo elementId targetX targetY model =
    animateToWithConfig defaultConfig elementId targetX targetY model


{-| Start animating an element to a target position with custom configuration

Returns the updated model and an animation command for your port.

-}
animateToWithConfig : Config -> String -> Float -> Float -> Model -> ( Model, AnimationCommand )
animateToWithConfig config elementId targetX targetY (Model elements) =
    let
        currentPos =
            getPosition elementId (Model elements)
                |> Maybe.withDefault { x = 0, y = 0 }

        elementData =
            { currentX = currentPos.x
            , currentY = currentPos.y
            , targetX = targetX
            , targetY = targetY
            , isAnimating = True
            , config = config
            }

        updatedElements =
            Dict.insert elementId elementData elements

        distance =
            case config.axis of
                X ->
                    abs (targetX - currentPos.x)

                Y ->
                    abs (targetY - currentPos.y)

                Both ->
                    sqrt ((targetX - currentPos.x) ^ 2 + (targetY - currentPos.y) ^ 2)

        axisString =
            case config.axis of
                X ->
                    "x"

                Y ->
                    "y"

                Both ->
                    "both"

        command =
            { elementId = elementId
            , targetX = targetX
            , targetY = targetY
            , duration = timingToMilliseconds config.timing distance
            , easing = config.easing
            , axis = axisString
            }
    in
    ( Model updatedElements, command )


{-| Animate multiple elements at once

Takes a list of animation specifications and returns the updated model and list of commands.
This is much more convenient than chaining individual animateToWithConfig calls.

    specs =
        [ { elementId = "box1", targetX = 100, targetY = 200, config = defaultConfig }
        , { elementId = "box2", targetX = 300, targetY = 150, config = { defaultConfig | duration = 800 } }
        ]

    ( newModel, commands ) =
        animateBatch specs model

-}
animateBatch : List AnimationSpec -> Model -> ( Model, List AnimationCommand )
animateBatch specs model =
    specs
        |> List.foldl
            (\spec ( currentModel, commands ) ->
                let
                    ( newModel, command ) =
                        animateToWithConfig spec.config spec.elementId spec.targetX spec.targetY currentModel
                in
                ( newModel, command :: commands )
            )
            ( model, [] )
        |> Tuple.mapSecond List.reverse


{-| Animate multiple elements with automatic port handling

This is the most convenient way to animate multiple elements - it handles all the
encoding and batching internally. Just provide your animation specs and port function.

    animationSpecs =
        [ { elementId = "box1", targetX = 100, targetY = 200, config = defaultConfig }
        , { elementId = "box2", targetX = 300, targetY = 150, config = { defaultConfig | duration = 800 } }
        ]

    ( newModel, cmd ) =
        animateBatchWithPort animateElement animationSpecs model

-}
animateBatchWithPort : (String -> Cmd msg) -> List AnimationSpec -> Model -> ( Model, Cmd msg )
animateBatchWithPort portFunction specs model =
    let
        ( newModel, commands ) =
            animateBatch specs model
    in
    ( newModel
    , commands
        |> List.map (portFunction << encodeAnimationCommand)
        |> Cmd.batch
    )


{-| Set the initial position of an element without animation

This is useful for preventing the "jump to (0,0)" behavior on first animation.
Call this during initialization to establish element positions.

    initialModel =
        SmoothMovePorts.init
            |> SmoothMovePorts.setInitialPosition "element-a" 100 150

-}
setInitialPosition : String -> Float -> Float -> Model -> Model
setInitialPosition elementId x y (Model elements) =
    let
        elementData =
            { currentX = x
            , currentY = y
            , targetX = x
            , targetY = y
            , isAnimating = False
            , config = defaultConfig
            }

        updatedElements =
            Dict.insert elementId elementData elements
    in
    Model updatedElements


{-| Stop animation for a specific element

Returns the updated model and the element ID to stop (for your port).

-}
stopAnimation : String -> Model -> ( Model, Maybe String )
stopAnimation elementId (Model elements) =
    case Dict.get elementId elements of
        Just elementData ->
            let
                updatedElementData =
                    { elementData | isAnimating = False }

                updatedElements =
                    Dict.insert elementId updatedElementData elements
            in
            ( Model updatedElements, Just elementId )

        Nothing ->
            ( Model elements, Nothing )


{-| Stop multiple animations at once

Takes a list of element IDs and returns the updated model and list of element IDs that were actually stopped.

    ( newModel, stoppedElements ) =
        stopBatch [ "box1", "box2", "box3", "box4" ] model

-}
stopBatch : List String -> Model -> ( Model, List String )
stopBatch elementIds model =
    elementIds
        |> List.foldl
            (\elementId ( currentModel, stoppedElements ) ->
                let
                    ( newModel, maybeStoppedId ) =
                        stopAnimation elementId currentModel
                in
                case maybeStoppedId of
                    Just stoppedId ->
                        ( newModel, stoppedId :: stoppedElements )

                    Nothing ->
                        ( newModel, stoppedElements )
            )
            ( model, [] )
        |> Tuple.mapSecond List.reverse


{-| Stop multiple animations with automatic port handling

This is the most convenient way to stop multiple animations - it handles all the
encoding and batching internally. Just provide your element IDs and port function.

    ( newModel, cmd ) =
        stopBatchWithPort stopElementAnimation [ "box1", "box2", "box3", "box4" ] model

-}
stopBatchWithPort : (String -> Cmd msg) -> List String -> Model -> ( Model, Cmd msg )
stopBatchWithPort portFunction elementIds model =
    let
        ( newModel, stoppedElements ) =
            stopBatch elementIds model
    in
    ( newModel
    , stoppedElements
        |> List.map (portFunction << encodeStopCommand)
        |> Cmd.batch
    )


{-| Check if any animations are currently running
-}
isAnimating : Model -> Bool
isAnimating (Model elements) =
    Dict.values elements
        |> List.any .isAnimating


{-| Get the current position of a specific element
-}
getPosition : String -> Model -> Maybe { x : Float, y : Float }
getPosition elementId (Model elements) =
    Dict.get elementId elements
        |> Maybe.map
            (\elementData ->
                { x = elementData.currentX, y = elementData.currentY }
            )


{-| Get all current element positions
-}
getAllPositions : Model -> Dict String { x : Float, y : Float }
getAllPositions (Model elements) =
    Dict.map
        (\_ elementData ->
            { x = elementData.currentX, y = elementData.currentY }
        )
        elements


{-| Create a CSS transform string for positioning
-}
transform : Float -> Float -> String
transform x y =
    "translate(" ++ String.fromFloat x ++ "px, " ++ String.fromFloat y ++ "px)"


{-| Create a CSS transform string by looking up the element's current position
-}
transformElement : String -> Model -> String
transformElement elementId model =
    case getPosition elementId model of
        Just pos ->
            transform pos.x pos.y

        Nothing ->
            transform 0 0


{-| Handle position updates from JavaScript

Call this from your update function when receiving position updates:

    updatePosition : String -> Float -> Float -> Bool -> Model -> Model
    updatePosition elementId x y isAnimating model =
        SmoothMovePorts.handlePositionUpdate elementId x y isAnimating model

-}
handlePositionUpdate : String -> Float -> Float -> Bool -> Model -> Model
handlePositionUpdate elementId x y animating (Model elements) =
    case Dict.get elementId elements of
        Just elementData ->
            let
                updatedElementData =
                    { elementData
                        | currentX = x
                        , currentY = y
                        , isAnimating = animating
                    }

                updatedElements =
                    Dict.insert elementId updatedElementData elements
            in
            Model updatedElements

        Nothing ->
            -- Create new element data if it doesn't exist
            let
                newElementData =
                    { currentX = x
                    , currentY = y
                    , targetX = x
                    , targetY = y
                    , isAnimating = animating
                    , config = defaultConfig
                    }

                updatedElements =
                    Dict.insert elementId newElementData elements
            in
            Model updatedElements


{-| Handle animation completion from JavaScript
-}
handleAnimationComplete : String -> Model -> Model
handleAnimationComplete elementId (Model elements) =
    case Dict.get elementId elements of
        Just elementData ->
            let
                updatedElementData =
                    { elementData
                        | currentX = elementData.targetX
                        , currentY = elementData.targetY
                        , isAnimating = False
                    }

                updatedElements =
                    Dict.insert elementId updatedElementData elements
            in
            Model updatedElements

        Nothing ->
            Model elements


{-| Create a string representation of an animation command for easy port integration

This creates a simple format that's easy to parse in JavaScript:
"elementId:targetX:targetY:duration:easing:axis"

-}
encodeAnimationCommand : AnimationCommand -> String
encodeAnimationCommand cmd =
    String.join ":"
        [ cmd.elementId
        , String.fromFloat cmd.targetX
        , String.fromFloat cmd.targetY
        , String.fromFloat cmd.duration
        , cmd.easing
        , cmd.axis
        ]


{-| Create a string representation of a stop command
-}
encodeStopCommand : String -> String
encodeStopCommand elementId =
    elementId
