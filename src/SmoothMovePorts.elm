module SmoothMovePorts exposing
    ( Config
    , defaultConfig
    , TargetId
    , Timing(..)
    , Model
    , init
    , animateTo
    , animateToX
    , animateToY
    , animateToWithConfig
    , animateToXWithConfig
    , animateToYWithConfig
    , animateBatch
    , animateBatchWithPort
    , setPosition
    , stopAnimation
    , stopAnimationWithPort
    , stopBatch
    , stopBatchWithPort
    , isAnimating
    , getPosition
    , getAllPositions
    , transform
    , transformElement
    , handlePositionUpdate
    , handlePositionUpdateFromJson
    , handleAnimationComplete
    , encodeAnimationCommand
    , encodeStopCommand
    , AnimationCommand
    , AnimationSpec
    , PositionUpdate
    , positionUpdateDecoder
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
@docs TargetId
@docs Timing


# State Management

@docs Model
@docs init


# Animation Control

@docs animateTo
@docs animateToX
@docs animateToY
@docs animateToWithConfig
@docs animateToXWithConfig
@docs animateToYWithConfig
@docs animateBatch
@docs animateBatchWithPort
@docs setPosition
@docs stopAnimation
@docs stopAnimationWithPort
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
@docs handlePositionUpdateFromJson
@docs handleAnimationComplete
@docs encodeAnimationCommand
@docs encodeStopCommand
@docs AnimationCommand
@docs AnimationSpec
@docs PositionUpdate
@docs positionUpdateDecoder

-}

import Dict exposing (Dict)
import Json.Decode as Decode


{-| Type alias for target element IDs that we want to scroll to.
-}
type alias TargetId =
    String


{-| Animation timing configuration

Choose between speed-based or duration-based timing:

  - Speed: Animation speed in pixels per second (higher = faster)
  - Duration: Animation duration in milliseconds (higher = slower)

-}
type Timing
    = Speed Float
    | Duration Int


{-| Configuration for port-based animations

  - timing: Animation timing (Speed in pixels per second or Duration in milliseconds)
  - easing: Web Animations API easing ("ease-out", "cubic-bezier(0.4, 0.0, 0.2, 1)", etc.)

-}
type alias Config =
    { timing : Timing
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


{-| Default configuration using Web Animations API
-}
defaultConfig : Config
defaultConfig =
    { timing = Duration 400
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


{-| Decode position updates from JavaScript

Use this with your port subscription:

    case Decode.decodeValue SmoothMovePorts.positionUpdateDecoder value of
        Ok positionUpdate ->
            SmoothMovePorts.handlePositionUpdate positionUpdate model

-}
positionUpdateDecoder : Decode.Decoder PositionUpdate
positionUpdateDecoder =
    Decode.map4 PositionUpdate
        (Decode.field "elementId" Decode.string)
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)
        (Decode.field "isAnimating" Decode.bool)



-- PUBLIC API --


{-| Start animating an element to a target position using default config

Returns the updated model and an animation command for your port.

-}
animateTo : TargetId -> Float -> Float -> Model -> ( Model, AnimationCommand )
animateTo elementId targetX targetY model =
    animateToWithConfig defaultConfig elementId targetX targetY model


{-| Start animating an element horizontally to a target X position

Only the X coordinate will change - Y position remains at current value.
Returns the updated model and an animation command for your port.

-}
animateToX : TargetId -> Float -> Model -> ( Model, AnimationCommand )
animateToX elementId targetX model =
    animateToXWithConfig defaultConfig elementId targetX model


{-| Start animating an element vertically to a target Y position

Only the Y coordinate will change - X position remains at current value.
Returns the updated model and an animation command for your port.

-}
animateToY : TargetId -> Float -> Model -> ( Model, AnimationCommand )
animateToY elementId targetY model =
    animateToYWithConfig defaultConfig elementId targetY model


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

        -- For animateToWithConfig (both axes), calculate Euclidean distance
        distance =
            sqrt ((targetX - currentPos.x) ^ 2 + (targetY - currentPos.y) ^ 2)

        command =
            { elementId = elementId
            , targetX = targetX
            , targetY = targetY
            , duration = timingToMilliseconds config.timing distance
            , easing = config.easing
            , axis = "both"
            }
    in
    ( Model updatedElements, command )


{-| Start animating an element horizontally to a target X position with custom configuration

Only the X coordinate will change - Y position remains at current value.
Returns the updated model and an animation command for your port.

-}
animateToXWithConfig : Config -> String -> Float -> Model -> ( Model, AnimationCommand )
animateToXWithConfig config elementId targetX (Model elements) =
    let
        currentPos =
            getPosition elementId (Model elements)
                |> Maybe.withDefault { x = 0, y = 0 }

        -- For X-only animation, Y target equals current Y
        targetY =
            currentPos.y

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

        -- For X-only animation, only calculate X distance
        distance =
            abs (targetX - currentPos.x)

        command =
            { elementId = elementId
            , targetX = targetX
            , targetY = targetY
            , duration = timingToMilliseconds config.timing distance
            , easing = config.easing
            , axis = "x"
            }
    in
    ( Model updatedElements, command )


{-| Start animating an element vertically to a target Y position with custom configuration

Only the Y coordinate will change - X position remains at current value.
Returns the updated model and an animation command for your port.

-}
animateToYWithConfig : Config -> String -> Float -> Model -> ( Model, AnimationCommand )
animateToYWithConfig config elementId targetY (Model elements) =
    let
        currentPos =
            getPosition elementId (Model elements)
                |> Maybe.withDefault { x = 0, y = 0 }

        -- For Y-only animation, X target equals current X
        targetX =
            currentPos.x

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

        -- For Y-only animation, only calculate Y distance
        distance =
            abs (targetY - currentPos.y)

        command =
            { elementId = elementId
            , targetX = targetX
            , targetY = targetY
            , duration = timingToMilliseconds config.timing distance
            , easing = config.easing
            , axis = "y"
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


{-| Set the position of an element without animation

Call this during initialization to establish element positions, otherwise they will start at (0,0).

Pipe this in your init function for as many elements as needed:

    initialModel =
        SmoothMovePorts.init
            |> SmoothMovePorts.setPosition "element-a" 100 150
            |> SmoothMovePorts.setPosition "element-b" 200 250
            |> SmoothMovePorts.setPosition "element-c" 300 150

-}
setPosition : TargetId -> Float -> Float -> Model -> Model
setPosition elementId x y (Model elements) =
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
stopAnimation : TargetId -> Model -> ( Model, Maybe String )
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


{-| Stop animation for a specific element with automatic port handling

This is the most convenient way to stop a single animation - it handles all the
encoding internally. Just provide your element ID and port function.

    ( newModel, cmd ) =
        stopAnimationWithPort stopElementAnimation "box1" model

-}
stopAnimationWithPort : (String -> Cmd msg) -> String -> Model -> ( Model, Cmd msg )
stopAnimationWithPort portFunction elementId model =
    let
        ( newModel, maybeStoppedId ) =
            stopAnimation elementId model
    in
    case maybeStoppedId of
        Just stoppedId ->
            ( newModel, portFunction (encodeStopCommand stoppedId) )

        Nothing ->
            ( newModel, Cmd.none )


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
getPosition : TargetId -> Model -> Maybe { x : Float, y : Float }
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
transformElement : TargetId -> Model -> String
transformElement elementId model =
    case getPosition elementId model of
        Just pos ->
            transform pos.x pos.y

        Nothing ->
            transform 0 0


{-| Handle position updates from JavaScript

Call this from your update function when receiving position updates:

    case Decode.decodeValue positionDecoder value of
        Ok positionUpdate ->
            SmoothMovePorts.handlePositionUpdate positionUpdate model

-}
handlePositionUpdate : PositionUpdate -> Model -> Model
handlePositionUpdate positionUpdate (Model elements) =
    let
        elementId =
            positionUpdate.elementId

        x =
            positionUpdate.x

        y =
            positionUpdate.y

        animating =
            positionUpdate.isAnimating
    in
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


{-| Handle position updates from JavaScript with automatic JSON decoding

This is the most convenient way to handle position updates - it combines
decoding and model updating in a single function call.

    PositionUpdateMsg value ->
        case SmoothMovePorts.handlePositionUpdateFromJson value model.animations of
            Ok newAnimations ->
                ( { model | animations = newAnimations }, Cmd.none )

            Err _ ->
                ( model, Cmd.none )

-}
handlePositionUpdateFromJson : Decode.Value -> Model -> Result Decode.Error Model
handlePositionUpdateFromJson value model =
    case Decode.decodeValue positionUpdateDecoder value of
        Ok positionUpdate ->
            Ok (handlePositionUpdate positionUpdate model)

        Err error ->
            Err error


{-| Handle animation completion from JavaScript
-}
handleAnimationComplete : TargetId -> Model -> Model
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
encodeStopCommand : TargetId -> String
encodeStopCommand elementId =
    elementId
