module Move.Ports exposing
    ( Model
    , init
    , subscriptions
    , Position
    , TargetId
    , getPosition
    , getAllPositions
    , setPosition
    , animateTo
    , animateToX
    , animateToY
    , animateToWithConfig
    , animateToXWithConfig
    , animateToYWithConfig
    , animateBatch
    , animateBatchWithPort
    , stopAnimation
    , stopAnimationWithPort
    , stopBatch
    , stopBatchWithPort
    , isAnimating
    , transform
    , transformElement
    , AnimationCommand
    , AnimationSpec
    , PositionUpdate
    , handlePositionUpdate
    , handlePositionUpdateFromJson
    , handleAnimationComplete
    , encodeAnimationCommand
    , encodeStopCommand
    , positionUpdateDecoder
    )

{-| Port-based animations using JavaScript's Web Animations API for high-performance element movement.


## Key Features:

  - Access to Web Animations API for optimal performance
  - Hardware acceleration when available
  - Native JavaScript easing functions
  - Ability to leverage future browser animation improvements


### Perfect for:

  - Game elements that need 60fps movement (sprites, particles, UI overlays)
  - Data visualizations with hundreds of animated chart elements
  - Interactive dashboards with real-time animated metrics
  - Mobile apps requiring battery-efficient animations
  - Complex animation sequences (rotate + scale + move simultaneously)
  - Apps targeting older devices where performance is critical

Since Elm packages cannot contain ports, this module provides helper functions and data types
to make it easy to implement your own ports for JavaScript-based animations.

The accompanying `smooth-move-ports.js` file provides the JavaScript implementation, you can install it
with `npm install smooth-move-ports` and include it in your HTML.


# State Management

@docs Model
@docs init
@docs subscriptions


# Position Management

@docs Position
@docs TargetId
@docs getPosition
@docs getAllPositions
@docs setPosition


# Animation Control

@docs animateTo
@docs animateToX
@docs animateToY
@docs animateToWithConfig
@docs animateToXWithConfig
@docs animateToYWithConfig
@docs animateBatch
@docs animateBatchWithPort
@docs stopAnimation
@docs stopAnimationWithPort
@docs stopBatch
@docs stopBatchWithPort
@docs isAnimating


# CSS Generation

@docs transform
@docs transformElement


# Port Integration Helpers


## Port Data Types

Types for communicating with JavaScript through ports.

@docs AnimationCommand
@docs AnimationSpec
@docs PositionUpdate


## Message Handling

Functions to process incoming messages from JavaScript ports.

@docs handlePositionUpdate
@docs handlePositionUpdateFromJson
@docs handleAnimationComplete


## JSON Serialization

Encoders and decoders for port communication.

@docs encodeAnimationCommand
@docs encodeStopCommand
@docs positionUpdateDecoder


# Complete Integration Example

Here's a complete example showing how all the port integration pieces work together:

**Step 1: Define your ports in Main.elm**

    -- Outgoing ports (Elm -> JavaScript)
    port animateElement : Encode.Value -> Cmd msg

    port stopElement : Encode.Value -> Cmd msg

    -- Incoming ports (JavaScript -> Elm)
    port positionUpdates : (Decode.Value -> msg) -> Sub msg

    port animationComplete : (String -> msg) -> Sub msg

**Step 2: Set up your Model and Messages**

    type alias Model =
        { movePortsModel : Move.Ports.Model
        , -- your other model fields
        }

    type Msg
        = AnimateClicked
        | PositionUpdateReceived (Result Decode.Error Move.Ports.PositionUpdate)
        | AnimationCompleted String
        | -- your other messages

**Step 3: Initialize and handle subscriptions**

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { movePortsModel = Move.Ports.init }, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Move.Ports.subscriptions
            { positionUpdates =
                positionUpdates (PositionUpdateReceived << Move.Ports.handlePositionUpdateFromJson)
            , animationComplete = animationComplete AnimationCompleted
            }
            model.movePortsModel

**Step 4: Handle animations in your update function**

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            AnimateClicked ->
                let
                    ( newMoveModel, maybeCommand ) =
                        Move.Ports.animateTo "my-element" (Position 200 300) model.movePortsModel
                in
                case maybeCommand of
                    Just command ->
                        ( { model | movePortsModel = newMoveModel }
                        , animateElement (Move.Ports.encodeAnimationCommand command)
                        )

                    Nothing ->
                        ( { model | movePortsModel = newMoveModel }, Cmd.none )

            PositionUpdateReceived (Ok positionUpdate) ->
                ( { model | movePortsModel = Move.Ports.handlePositionUpdate positionUpdate model.movePortsModel }
                , Cmd.none
                )

            AnimationCompleted elementId ->
                ( { model | movePortsModel = Move.Ports.handleAnimationComplete elementId model.movePortsModel }
                , Cmd.none
                )

**Step 5: Include smooth-move-ports.js in your HTML**

    <script src="https://unpkg.com/elm-smooth-move/dist/smooth-move-ports.js"></script>
    <script>
        var app = Elm.Main.init({ node: document.getElementById('elm') });
        SmoothMovePorts.init(app.ports);
    </script>

This complete flow shows how the AnimationCommand type gets encoded, sent through ports to JavaScript,
while PositionUpdate messages flow back from JavaScript to update your Elm model state.

-}

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Move exposing (Config, EasePreset(..), Easing(..), Timing(..))
import Move.Internal exposing (easingToString, timingToMilliseconds)



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


{-| Main state container for port-based animations

The model tracks element positions and animation states, coordinating with
JavaScript through ports for actual Web Animations API calls.

-}
type Model
    = Model (Dict String ElementData)


{-| Initialize empty model

    init =
        Move.Ports.init

-}
init : Model
init =
    Model Dict.empty


{-| Create subscriptions for port-based animations

This helper function makes it easier to set up the necessary port subscriptions.
You still need to define the actual ports in your application.

    -- In your Main.elm, define the required ports:
    port positionUpdates : (Decode.Value -> msg) -> Sub msg
    port animationComplete : (String -> msg) -> Sub msg

    -- Then use this helper in your subscriptions:
    type Msg
        = PositionUpdateReceived (Result Decode.Error PositionUpdate)
        | AnimationCompleted String
        | -- other messages

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Move.Ports.subscriptions
            { positionUpdates = positionUpdates (PositionUpdateReceived << Move.Ports.handlePositionUpdateFromJson)
            , animationComplete = animationComplete AnimationCompleted
            }
            model.movePortsModel

-}
subscriptions :
    { positionUpdates : Sub msg
    , animationComplete : Sub msg
    }
    -> Model
    -> Sub msg
subscriptions ports_ (Model elementsDict) =
    let
        hasActiveAnimations =
            Dict.values elementsDict
                |> List.any .isAnimating
    in
    if hasActiveAnimations then
        Sub.batch
            [ ports_.positionUpdates
            , ports_.animationComplete
            ]

    else
        Sub.none


{-| Default configuration using Web Animations API optimized settings

    defaultConfig =
        { timing = Duration 400
        , easing = EasePreset EaseOut
        }

-}
defaultConfig : Config
defaultConfig =
    { timing = Duration 400
    , easing = EasePreset EaseOut
    }


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
    }


{-| Animation specification for batch operations
-}
type alias AnimationSpec =
    { elementId : String
    , target : Position
    }


{-| Position update data received from JavaScript

JavaScript sends these when animations update element positions.

-}
type alias PositionUpdate =
    { elementId : String
    , x : Float
    , y : Float
    }


{-| Start animating an element to a target position using default config

    -- Create the animation command
    animationCmd =
        Move.Ports.animateTo "my-element" 200 300 model.movePortsModel

    -- Send it through your port
    case animationCmd of
        ( newModel, Just command ) ->
            ( { model | movePortsModel = newModel }, animateElementPort command )

        ( newModel, Nothing ) ->
            ( { model | movePortsModel = newModel }, Cmd.none )

-}
animateTo : TargetId -> Position -> Model -> ( Model, Maybe AnimationCommand )
animateTo elementId position model =
    animateToWithConfig defaultConfig elementId position model


{-| Start animating an element horizontally to a target X position

Only the X coordinate will change - Y position remains at current value.

-}
animateToX : TargetId -> Float -> Model -> ( Model, Maybe AnimationCommand )
animateToX elementId targetX model =
    animateToXWithConfig defaultConfig elementId targetX model


{-| Start animating an element vertically to a target Y position

Only the Y coordinate will change - X position remains at current value.

-}
animateToY : TargetId -> Float -> Model -> ( Model, Maybe AnimationCommand )
animateToY elementId targetY model =
    animateToYWithConfig defaultConfig elementId targetY model


{-| Start animating an element to a target position with custom configuration

    config =
        { defaultConfig | timing = Duration 600, easing = EasePreset EaseInOut }

    ( newModel, maybeCommand ) =
        Move.Ports.animateToWithConfig config "my-element" { x = 100, y = 150 } model.movePortsModel

-}
animateToWithConfig : Config -> TargetId -> Position -> Model -> ( Model, Maybe AnimationCommand )
animateToWithConfig config elementId position (Model elementsDict) =
    let
        currentData =
            Dict.get elementId elementsDict
                |> Maybe.withDefault
                    { currentX = 0
                    , currentY = 0
                    , targetX = 0
                    , targetY = 0
                    , isAnimating = False
                    , config = config
                    }

        distance =
            sqrt ((position.x - currentData.currentX) ^ 2 + (position.y - currentData.currentY) ^ 2)

        duration =
            timingToMilliseconds config.timing distance

        elementData =
            { currentData
                | targetX = position.x
                , targetY = position.y
                , isAnimating = True
                , config = config
            }

        updatedDict =
            Dict.insert elementId elementData elementsDict

        animationCommand =
            { elementId = elementId
            , targetX = position.x
            , targetY = position.y
            , duration = duration
            , easing = easingToString config.easing
            }
    in
    ( Model updatedDict, Just animationCommand )


{-| Start animating an element horizontally with custom configuration

    config =
        { defaultConfig | timing = Speed 600.0, easing = EasePreset EaseInOut }

    ( newModel, maybeCommand ) =
        Move.Ports.animateToXWithConfig config "my-element" 200 model.movePortsModel

-}
animateToXWithConfig : Config -> TargetId -> Float -> Model -> ( Model, Maybe AnimationCommand )
animateToXWithConfig config elementId targetX (Model elementsDict) =
    let
        currentData =
            Dict.get elementId elementsDict
                |> Maybe.withDefault
                    { currentX = 0
                    , currentY = 0
                    , targetX = 0
                    , targetY = 0
                    , isAnimating = False
                    , config = config
                    }

        -- Y target equals current Y for X-only animation
        targetY =
            currentData.currentY

        distance =
            abs (targetX - currentData.currentX)

        duration =
            timingToMilliseconds config.timing distance

        elementData =
            { currentData
                | targetX = targetX
                , targetY = targetY
                , isAnimating = True
                , config = config
            }

        updatedDict =
            Dict.insert elementId elementData elementsDict

        animationCommand =
            { elementId = elementId
            , targetX = targetX
            , targetY = targetY
            , duration = duration
            , easing = easingToString config.easing
            }
    in
    ( Model updatedDict, Just animationCommand )


{-| Start animating an element vertically with custom configuration

    config =
        { defaultConfig | timing = Speed 600.0, easing = EasePreset EaseInOut }

    ( newModel, maybeCommand ) =
        Move.Ports.animateToYWithConfig config "my-element" 300 model.movePortsModel

-}
animateToYWithConfig : Config -> TargetId -> Float -> Model -> ( Model, Maybe AnimationCommand )
animateToYWithConfig config elementId targetY (Model elementsDict) =
    let
        currentData =
            Dict.get elementId elementsDict
                |> Maybe.withDefault
                    { currentX = 0
                    , currentY = 0
                    , targetX = 0
                    , targetY = 0
                    , isAnimating = False
                    , config = config
                    }

        -- X target equals current X for Y-only animation
        targetX =
            currentData.currentX

        distance =
            abs (targetY - currentData.currentY)

        duration =
            timingToMilliseconds config.timing distance

        elementData =
            { currentData
                | targetX = targetX
                , targetY = targetY
                , isAnimating = True
                , config = config
            }

        updatedDict =
            Dict.insert elementId elementData elementsDict

        animationCommand =
            { elementId = elementId
            , targetX = targetX
            , targetY = targetY
            , duration = duration
            , easing = easingToString config.easing
            }
    in
    ( Model updatedDict, Just animationCommand )


{-| Animate multiple elements with the same configuration

Returns a list of animation commands to send through your port.

    animations =
        [ { elementId = "element-1", target = Position 100 200 }
        , { elementId = "element-2", target = Position 300 400 }
        ]

    ( newModel, commands ) =
        Move.Ports.animateBatch defaultConfig animations model.movePortsModel

-}
animateBatch : Config -> List AnimationSpec -> Model -> ( Model, List AnimationCommand )
animateBatch config specs model =
    List.foldl
        (\spec ( currentModel, commands ) ->
            let
                ( newModel, maybeCommand ) =
                    animateToWithConfig config spec.elementId spec.target currentModel
            in
            case maybeCommand of
                Just command ->
                    ( newModel, command :: commands )

                Nothing ->
                    ( newModel, commands )
        )
        ( model, [] )
        specs
        |> Tuple.mapSecond List.reverse


{-| Animate multiple elements and send commands through a provided port function

    port animateElements : List AnimationCommand -> Cmd msg

    ( newModel, cmd ) =
        Move.Ports.animateBatchWithPort animateElements defaultConfig animations model.movePortsModel

-}
animateBatchWithPort : (List AnimationCommand -> Cmd msg) -> Config -> List AnimationSpec -> Model -> ( Model, Cmd msg )
animateBatchWithPort portFunction config specs model =
    let
        ( newModel, commands ) =
            animateBatch config specs model
    in
    ( newModel, portFunction commands )


{-| Manually set an element's position without animation

Useful for initial positioning or teleporting elements.

    newModel =
        Move.Ports.setPosition "my-element" { x = 100, y = 200 } model.movePortsModel

-}
setPosition : TargetId -> Position -> Model -> Model
setPosition elementId position (Model elementsDict) =
    let
        elementData =
            Dict.get elementId elementsDict
                |> Maybe.withDefault
                    { currentX = 0
                    , currentY = 0
                    , targetX = 0
                    , targetY = 0
                    , isAnimating = False
                    , config = defaultConfig
                    }
                |> (\data ->
                        { data
                            | currentX = position.x
                            , currentY = position.y
                            , targetX = position.x
                            , targetY = position.y
                            , isAnimating = False
                        }
                   )

        updatedDict =
            Dict.insert elementId elementData elementsDict
    in
    Model updatedDict


{-| Stop animation for an element (returns stop command for your port)

    case Move.Ports.stopAnimation "my-element" model.movePortsModel of
        ( newModel, Just stopCmd ) ->
            ( { model | movePortsModel = newModel }, stopElementPort stopCmd )

        ( newModel, Nothing ) ->
            ( { model | movePortsModel = newModel }, Cmd.none )

-}
stopAnimation : TargetId -> Model -> ( Model, Maybe String )
stopAnimation elementId (Model elementsDict) =
    case Dict.get elementId elementsDict of
        Just elementData ->
            let
                updatedData =
                    { elementData | isAnimating = False }

                updatedDict =
                    Dict.insert elementId updatedData elementsDict
            in
            ( Model updatedDict, Just elementId )

        Nothing ->
            ( Model elementsDict, Nothing )


{-| Stop animation and send command through provided port

    port stopElement : String -> Cmd msg

    ( newModel, cmd ) =
        Move.Ports.stopAnimationWithPort stopElement "my-element" model.movePortsModel

-}
stopAnimationWithPort : (String -> Cmd msg) -> TargetId -> Model -> ( Model, Cmd msg )
stopAnimationWithPort portFunction elementId model =
    let
        ( newModel, maybeStopCmd ) =
            stopAnimation elementId model
    in
    case maybeStopCmd of
        Just stopCmd ->
            ( newModel, portFunction stopCmd )

        Nothing ->
            ( newModel, Cmd.none )


{-| Stop animations for multiple elements

    elementIds =
        [ "element-1", "element-2", "element-3" ]

    ( newModel, stopCommands ) =
        Move.Ports.stopBatch elementIds model.movePortsModel

-}
stopBatch : List TargetId -> Model -> ( Model, List String )
stopBatch elementIds model =
    List.foldl
        (\elementId ( currentModel, commands ) ->
            let
                ( newModel, maybeCommand ) =
                    stopAnimation elementId currentModel
            in
            case maybeCommand of
                Just command ->
                    ( newModel, command :: commands )

                Nothing ->
                    ( newModel, commands )
        )
        ( model, [] )
        elementIds
        |> Tuple.mapSecond List.reverse


{-| Stop animations for multiple elements using provided port

    port stopElements : List String -> Cmd msg

    ( newModel, cmd ) =
        Move.Ports.stopBatchWithPort stopElements elementIds model.movePortsModel

-}
stopBatchWithPort : (List String -> Cmd msg) -> List TargetId -> Model -> ( Model, Cmd msg )
stopBatchWithPort portFunction elementIds model =
    let
        ( newModel, commands ) =
            stopBatch elementIds model
    in
    ( newModel, portFunction commands )


{-| Check if an element is currently animating

    if Move.Ports.isAnimating "my-element" model.movePortsModel then
        -- Element is moving
    else
        -- Element is stationary

-}
isAnimating : TargetId -> Model -> Bool
isAnimating elementId (Model elementsDict) =
    Dict.get elementId elementsDict
        |> Maybe.map .isAnimating
        |> Maybe.withDefault False


{-| Get current position of an element

Returns Nothing if element has never been positioned.

    case Move.Ports.getPosition "my-element" model.movePortsModel of
        Just position ->
            -- Use position.x and position.y

        Nothing ->
            -- Element has no position yet

-}
getPosition : TargetId -> Model -> Maybe Position
getPosition elementId (Model elementsDict) =
    Dict.get elementId elementsDict
        |> Maybe.map (\data -> { x = data.currentX, y = data.currentY })


{-| Get all element positions as a Dict

Useful for debugging or bulk operations.

    allPositions =
        Move.Ports.getAllPositions model.movePortsModel

-}
getAllPositions : Model -> Dict TargetId Position
getAllPositions (Model elementsDict) =
    Dict.map
        (\_ data -> { x = data.currentX, y = data.currentY })
        elementsDict


{-| Generate CSS transform string for an element

Apply this to your element's style attribute:

    div
        [ style "transform" (Move.Ports.transform "my-element" model.movePortsModel) ]
        [ text "Animated element" ]

-}
transform : TargetId -> Model -> String
transform elementId model =
    case getPosition elementId model of
        Just position ->
            "translate(" ++ String.fromFloat position.x ++ "px, " ++ String.fromFloat position.y ++ "px)"

        Nothing ->
            "translate(0px, 0px)"


{-| Generate CSS transform for a specific element position

Useful when you want to transform based on a known position:

    elementTransform =
        Move.Ports.transformElement { x = 100, y = 200 }

-}
transformElement : Position -> String
transformElement position =
    "translate(" ++ String.fromFloat position.x ++ "px, " ++ String.fromFloat position.y ++ "px)"


{-| Handle position updates from JavaScript port

Call this when JavaScript sends position updates during animations:

    port positionUpdates : (Decode.Value -> msg) -> Sub msg

    -- In your subscriptions:
    subscriptions model =
        positionUpdates (PositionUpdateReceived << Move.Ports.handlePositionUpdateFromJson)

    -- In your update function:
    PositionUpdateReceived (Ok positionUpdate) ->
        ( { model | movePortsModel = Move.Ports.handlePositionUpdate positionUpdate model.movePortsModel }, Cmd.none )

-}
handlePositionUpdate : PositionUpdate -> Model -> Model
handlePositionUpdate update (Model elementsDict) =
    let
        updatedDict =
            Dict.update update.elementId
                (Maybe.map
                    (\data ->
                        { data
                            | currentX = update.x
                            , currentY = update.y
                        }
                    )
                )
                elementsDict
    in
    Model updatedDict


{-| Handle position update from JSON value received through port

    case Move.Ports.handlePositionUpdateFromJson jsonValue of
        Ok positionUpdate ->
            -- Use the position update

        Err error ->
            -- Handle decode error

-}
handlePositionUpdateFromJson : Decode.Value -> Result Decode.Error PositionUpdate
handlePositionUpdateFromJson value =
    Decode.decodeValue positionUpdateDecoder value


{-| Handle animation completion from JavaScript

Call this when JavaScript notifies that an animation has finished:

    port animationComplete : (String -> msg) -> Sub msg

    -- In your update function:
    AnimationCompleted elementId ->
        ( { model | movePortsModel = Move.Ports.handleAnimationComplete elementId model.movePortsModel }, Cmd.none )

-}
handleAnimationComplete : TargetId -> Model -> Model
handleAnimationComplete elementId (Model elementsDict) =
    let
        updatedDict =
            Dict.update elementId
                (Maybe.map
                    (\data ->
                        { data
                            | currentX = data.targetX
                            , currentY = data.targetY
                            , isAnimating = False
                        }
                    )
                )
                elementsDict
    in
    Model updatedDict


{-| Encode animation command as JSON for sending to JavaScript

    jsonValue =
        Move.Ports.encodeAnimationCommand animationCommand

-}
encodeAnimationCommand : AnimationCommand -> Encode.Value
encodeAnimationCommand command =
    Encode.object
        [ ( "elementId", Encode.string command.elementId )
        , ( "targetX", Encode.float command.targetX )
        , ( "targetY", Encode.float command.targetY )
        , ( "duration", Encode.float command.duration )
        , ( "easing", Encode.string command.easing )
        ]


{-| Encode stop command as JSON

    jsonValue =
        Move.Ports.encodeStopCommand elementId

-}
encodeStopCommand : String -> Encode.Value
encodeStopCommand elementId =
    Encode.object
        [ ( "elementId", Encode.string elementId ) ]


{-| JSON decoder for position updates received from JavaScript

Use this with your incoming port:

    port positionUpdates : (Decode.Value -> msg) -> Sub msg

-}
positionUpdateDecoder : Decoder PositionUpdate
positionUpdateDecoder =
    Decode.map3 PositionUpdate
        (Decode.field "elementId" Decode.string)
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)
