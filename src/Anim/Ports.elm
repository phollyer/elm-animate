module Anim.Ports exposing
    ( Model
    , init
    , subscriptions
    , TargetId
    , animate
    , animateWithConfig
    , getCurrentValue
    , setValue
    , animateTo
    , animateToX
    , animateToY
    , animateToWithConfig
    , animateToXWithConfig
    , animateToYWithConfig
    , animateOpacity
    , animateOpacityWithConfig
    , animateScale
    , animateScaleWithConfig
    , animateRotation
    , animateRotationWithConfig
    , animateBackgroundColor
    , animateBackgroundColorWithConfig
    , defaultConfig
    , animateBatch
    , getPosition
    , getAllPositions
    , stopAnimation
    , stopBatch
    , isAnimating
    , transform
    , transformElement
    , styleProperties
    , AnimationCommand
    , AnimationSpec
    , PropertyUpdate
    , handlePropertyUpdate
    , handlePropertyUpdateFromJson
    , encodeAnimationCommand
    , encodeStopCommand
    , propertyUpdateDecoder
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


# Comprehensive Animation

@docs TargetId
@docs animate
@docs animateWithConfig
@docs getCurrentValue
@docs setValue


# Property-Specific Animation

@docs animateTo
@docs animateToX
@docs animateToY
@docs animateToWithConfig
@docs animateToXWithConfig
@docs animateToYWithConfig
@docs animateOpacity
@docs animateOpacityWithConfig
@docs animateScale
@docs animateScaleWithConfig
@docs animateRotation
@docs animateRotationWithConfig
@docs animateBackgroundColor
@docs animateBackgroundColorWithConfig


# Configuration

@docs defaultConfig


# Batch Operations

@docs animateBatch


# Value Management

@docs getPosition
@docs getAllPositions
@docs stopAnimation
@docs stopBatch
@docs isAnimating


# CSS Generation

@docs transform
@docs transformElement
@docs styleProperties


# Port Integration Helpers


## Port Data Types

Types for communicating with JavaScript through ports.

@docs AnimationCommand
@docs AnimationSpec
@docs PropertyUpdate


## Message Handling

Functions to process incoming messages from JavaScript ports.

@docs handlePropertyUpdate
@docs handlePropertyUpdateFromJson


## JSON Serialization

Encoders and decoders for port communication.

@docs encodeAnimationCommand
@docs encodeStopCommand
@docs propertyUpdateDecoder


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
                          -- Note: 'animateElement' is YOUR port definition defined in Step 1
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

import Anim exposing (AnimationTarget(..), ColorValue(..), Config, EasePreset(..), Easing(..), FilterValue(..), Position, RotationValue, ScaleValue, Timing(..))
import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode



-- CORE TYPES


{-| Type alias for target element IDs that we want to animate.
-}
type alias TargetId =
    String


{-| Element state for port-based comprehensive animations
-}
type alias ElementData =
    { properties : Dict String AnimationTarget
    , animating : Dict String Bool
    }



-- ANIMATION PROPERTY HELPERS


{-| Get the property key for an AnimationTarget.
-}
getPropertyKey : AnimationTarget -> String
getPropertyKey target =
    case target of
        ToPosition _ ->
            "position"

        ToOpacity _ ->
            "opacity"

        ToScale _ ->
            "scale"

        ToRotation _ ->
            "rotation"

        ToBackgroundColor _ ->
            "background-color"

        ToTextColor _ ->
            "text-color"

        ToBorderColor _ ->
            "border-color"

        ToDimensions _ ->
            "dimensions"

        ToBorderRadius _ ->
            "border-radius"

        ToFilter _ ->
            "filter"


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
    { propertyUpdates : Sub msg
    , animationComplete : Sub msg
    }
    -> Model
    -> Sub msg
subscriptions ports_ (Model elementsDict) =
    let
        hasActiveAnimations =
            Dict.values elementsDict
                |> List.any
                    (\elementData ->
                        Dict.values elementData.animating
                            |> List.any identity
                    )
    in
    if hasActiveAnimations then
        Sub.batch
            [ ports_.propertyUpdates
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



-- COMPREHENSIVE ANIMATION FUNCTIONS


{-| Start animating an element to a target animation property using default config.

This is the general-purpose animation function that can handle any AnimationTarget type.
Returns the updated model and optionally an AnimationCommand to send through your port.

    import Anim exposing (AnimationTarget(..))

    ( newModel, maybeCommand ) =
        Anim.Ports.animate "my-element" (ToOpacity 0.5) model.animPortsModel

-}
animate : TargetId -> AnimationTarget -> Model -> ( Model, Maybe AnimationCommand )
animate elementId target model =
    animateWithConfig defaultConfig elementId target model


{-| Start animating an element to a target animation property with custom configuration.

    import Anim exposing (AnimationTarget(..), EasePreset(..), Easing(..), Timing(..), defaultConfig)

    config =
        { defaultConfig | timing = Duration 800, easing = EasePreset EaseInOut }

    ( newModel, maybeCommand ) =
        Anim.Ports.animateWithConfig config "my-element" (ToScale { x = 2.0, y = 2.0 }) model.animPortsModel

-}
animateWithConfig : Config -> TargetId -> AnimationTarget -> Model -> ( Model, Maybe AnimationCommand )
animateWithConfig config elementId target (Model elementsDict) =
    let
        propertyKey =
            getPropertyKey target

        currentElementData =
            Dict.get elementId elementsDict
                |> Maybe.withDefault { properties = Dict.empty, animating = Dict.empty }

        updatedProperties =
            Dict.insert propertyKey target currentElementData.properties

        updatedAnimating =
            Dict.insert propertyKey True currentElementData.animating

        elementData =
            { properties = updatedProperties
            , animating = updatedAnimating
            }

        updatedDict =
            Dict.insert elementId elementData elementsDict

        animationCommand =
            { elementId = elementId
            , target = target
            , config = config
            }
    in
    ( Model updatedDict, Just animationCommand )



-- PROPERTY-SPECIFIC CONVENIENCE FUNCTIONS


{-| Animate element opacity with default configuration.

    ( newModel, maybeCommand ) =
        Anim.Ports.animateOpacity "my-element" 0.5 model.animPortsModel

-}
animateOpacity : TargetId -> Float -> Model -> ( Model, Maybe AnimationCommand )
animateOpacity elementId opacity model =
    animate elementId (ToOpacity opacity) model


{-| Animate element opacity with custom configuration.

    config =
        { defaultConfig | timing = Duration 800 }

    ( newModel, maybeCommand ) =
        Anim.Ports.animateOpacityWithConfig config "my-element" 0.5 model.animPortsModel

-}
animateOpacityWithConfig : Config -> TargetId -> Float -> Model -> ( Model, Maybe AnimationCommand )
animateOpacityWithConfig config elementId opacity model =
    animateWithConfig config elementId (ToOpacity opacity) model


{-| Animate element scale with default configuration.

    ( newModel, maybeCommand ) =
        Anim.Ports.animateScale "my-element" { x = 1.5, y = 1.5 } model.animPortsModel

-}
animateScale : TargetId -> ScaleValue -> Model -> ( Model, Maybe AnimationCommand )
animateScale elementId scale model =
    animate elementId (ToScale scale) model


{-| Animate element scale with custom configuration.

    config =
        { defaultConfig | timing = Duration 600, easing = EasePreset EaseInOut }

    ( newModel, maybeCommand ) =
        Anim.Ports.animateScaleWithConfig config "my-element" { x = 2.0, y = 2.0 } model.animPortsModel

-}
animateScaleWithConfig : Config -> TargetId -> ScaleValue -> Model -> ( Model, Maybe AnimationCommand )
animateScaleWithConfig config elementId scale model =
    animateWithConfig config elementId (ToScale scale) model


{-| Animate element rotation with default configuration.

    ( newModel, maybeCommand ) =
        Anim.Ports.animateRotation "my-element" 90.0 model.animPortsModel

-}
animateRotation : TargetId -> RotationValue -> Model -> ( Model, Maybe AnimationCommand )
animateRotation elementId rotation model =
    animate elementId (ToRotation rotation) model


{-| Animate element rotation with custom configuration.

    config =
        { defaultConfig | timing = Duration 1000 }

    ( newModel, maybeCommand ) =
        Anim.Ports.animateRotationWithConfig config "my-element" 180.0 model.animPortsModel

-}
animateRotationWithConfig : Config -> TargetId -> RotationValue -> Model -> ( Model, Maybe AnimationCommand )
animateRotationWithConfig config elementId rotation model =
    animateWithConfig config elementId (ToRotation rotation) model


{-| Animate element background color with default configuration.

    import Anim exposing (ColorValue(..))

    ( newModel, maybeCommand ) =
        Anim.Ports.animateBackgroundColor "my-element" (Rgb { r = 255, g = 0, b = 0 }) model.animPortsModel

-}
animateBackgroundColor : TargetId -> ColorValue -> Model -> ( Model, Maybe AnimationCommand )
animateBackgroundColor elementId color model =
    animate elementId (ToBackgroundColor color) model


{-| Animate element background color with custom configuration.

    import Anim exposing (ColorValue(..), EasePreset(..), Easing(..), Timing(..), defaultConfig)

    config =
        { defaultConfig | timing = Duration 500, easing = EasePreset EaseInOut }

    ( newModel, maybeCommand ) =
        Anim.Ports.animateBackgroundColorWithConfig config "my-element" (Hsl { h = 120, s = 100, l = 50 }) model.animPortsModel

-}
animateBackgroundColorWithConfig : Config -> TargetId -> ColorValue -> Model -> ( Model, Maybe AnimationCommand )
animateBackgroundColorWithConfig config elementId color model =
    animateWithConfig config elementId (ToBackgroundColor color) model


{-| Animation command data to send to JavaScript

Use this with your own port:

    port animateElement : AnimationCommand -> Cmd msg

-}
type alias AnimationCommand =
    { elementId : String
    , target : AnimationTarget
    , config : Config
    }


{-| Animation specification for batch operations
-}
type alias AnimationSpec =
    { elementId : String
    , target : Position
    }


{-| Property update data received from JavaScript

JavaScript sends these when animations update element properties.

-}
type alias PropertyUpdate =
    { elementId : String
    , propertyKey : String
    , target : AnimationTarget
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
    animate elementId (ToPosition position) model


{-| Start animating an element horizontally to a target X position

Only the X coordinate will change - Y position remains at current value.

-}
animateToX : TargetId -> Float -> Model -> ( Model, Maybe AnimationCommand )
animateToX elementId targetX model =
    let
        currentPos =
            getPosition elementId model
                |> Maybe.withDefault { x = 0, y = 0 }

        newPosition =
            { currentPos | x = targetX }
    in
    animate elementId (ToPosition newPosition) model


{-| Start animating an element vertically to a target Y position

Only the Y coordinate will change - X position remains at current value.

-}
animateToY : TargetId -> Float -> Model -> ( Model, Maybe AnimationCommand )
animateToY elementId targetY model =
    let
        currentPos =
            getPosition elementId model
                |> Maybe.withDefault { x = 0, y = 0 }

        newPosition =
            { currentPos | y = targetY }
    in
    animate elementId (ToPosition newPosition) model


{-| Start animating an element to a target position with custom configuration

    config =
        { defaultConfig | timing = Duration 600, easing = EasePreset EaseInOut }

    ( newModel, maybeCommand ) =
        Move.Ports.animateToWithConfig config "my-element" { x = 100, y = 150 } model.movePortsModel

-}
animateToWithConfig : Config -> TargetId -> Position -> Model -> ( Model, Maybe AnimationCommand )
animateToWithConfig config elementId position model =
    animateWithConfig config elementId (ToPosition position) model


{-| Start animating an element horizontally with custom configuration

    config =
        { defaultConfig | timing = Speed 600.0, easing = EasePreset EaseInOut }

    ( newModel, maybeCommand ) =
        Move.Ports.animateToXWithConfig config "my-element" 200 model.movePortsModel

-}
animateToXWithConfig : Config -> TargetId -> Float -> Model -> ( Model, Maybe AnimationCommand )
animateToXWithConfig config elementId targetX model =
    let
        currentPos =
            getPosition elementId model
                |> Maybe.withDefault { x = 0, y = 0 }

        newPosition =
            { currentPos | x = targetX }
    in
    animateWithConfig config elementId (ToPosition newPosition) model


{-| Start animating an element vertically with custom configuration

    config =
        { defaultConfig | timing = Duration 600, easing = EasePreset EaseInOut }

    ( newModel, maybeCommand ) =
        Move.Ports.animateToYWithConfig config "my-element" 300 model.movePortsModel

Only the Y coordinate will change - X position remains at current value.

-}
animateToYWithConfig : Config -> TargetId -> Float -> Model -> ( Model, Maybe AnimationCommand )
animateToYWithConfig config elementId targetY model =
    let
        currentPos =
            getPosition elementId model
                |> Maybe.withDefault { x = 0, y = 0 }

        newPosition =
            { currentPos | y = targetY }
    in
    animateWithConfig config elementId (ToPosition newPosition) model


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
                    { elementData | animating = Dict.empty }

                updatedDict =
                    Dict.insert elementId updatedData elementsDict
            in
            ( Model updatedDict, Just elementId )

        Nothing ->
            ( Model elementsDict, Nothing )


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


{-| Check if an element is currently animating

    if Move.Ports.isAnimating "my-element" model.movePortsModel then
        -- Element is moving
    else
        -- Element is stationary

-}
isAnimating : TargetId -> Model -> Bool
isAnimating elementId (Model elementsDict) =
    Dict.get elementId elementsDict
        |> Maybe.map (\elementData -> not (Dict.isEmpty elementData.animating))
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
getPosition elementId model =
    case getCurrentValue elementId "position" model of
        Just (ToPosition position) ->
            Just position

        _ ->
            Nothing


{-| Get the current value of a specific animation property for an element.

    import Anim exposing (AnimationTarget(..))

    case Anim.Ports.getCurrentValue "my-element" "opacity" model.animPortsModel of
        Just (ToOpacity opacity) ->
            -- Use the opacity value

        _ ->
            -- Property not found or different type

-}
getCurrentValue : TargetId -> String -> Model -> Maybe AnimationTarget
getCurrentValue elementId propertyKey (Model elementsDict) =
    Dict.get elementId elementsDict
        |> Maybe.andThen (\elementData -> Dict.get propertyKey elementData.properties)


{-| Set an element's animation property value without animation.

This is the general-purpose version of setPosition that works with any AnimationTarget.

    import Anim exposing (AnimationTarget(..))

    ( newModel, _ ) =
        model.animPortsModel
            |> Anim.Ports.setValue "my-element" (ToOpacity 0.5)
            |> Anim.Ports.setValue "my-element" (ToScale { x = 1.2, y = 1.2 })

-}
setValue : TargetId -> AnimationTarget -> Model -> ( Model, Maybe AnimationCommand )
setValue elementId target (Model elementsDict) =
    let
        propertyKey =
            getPropertyKey target

        currentElementData =
            Dict.get elementId elementsDict
                |> Maybe.withDefault { properties = Dict.empty, animating = Dict.empty }

        updatedProperties =
            Dict.insert propertyKey target currentElementData.properties

        -- Mark as not animating since we're setting a static value
        updatedAnimating =
            Dict.insert propertyKey False currentElementData.animating

        elementData =
            { properties = updatedProperties
            , animating = updatedAnimating
            }

        updatedDict =
            Dict.insert elementId elementData elementsDict
    in
    ( Model updatedDict, Nothing )


{-| Get all element positions as a Dict

Useful for debugging or bulk operations.

    allPositions =
        Move.Ports.getAllPositions model.movePortsModel

-}
getAllPositions : Model -> Dict TargetId Position
getAllPositions model =
    case model of
        Model elementsDict ->
            Dict.foldl
                (\elementId _ acc ->
                    case getCurrentValue elementId "position" model of
                        Just (ToPosition position) ->
                            Dict.insert elementId position acc

                        _ ->
                            acc
                )
                Dict.empty
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


{-| Generate comprehensive CSS properties for an element

This generates CSS properties for all the animation targets currently set on an element.
Returns a list of (property, value) tuples that can be applied to HTML attributes.

    div
        (List.map (\( prop, value ) -> style prop value)
            (Anim.Ports.styleProperties "my-element" model.animPortsModel)
        )
        [ text "Animated element" ]

-}
styleProperties : TargetId -> Model -> List ( String, String )
styleProperties elementId (Model elementsDict) =
    case Dict.get elementId elementsDict of
        Just elementData ->
            Dict.foldl
                (\_ target acc ->
                    animationTargetToCssProperty target ++ acc
                )
                []
                elementData.properties

        Nothing ->
            []


{-| Convert an AnimationTarget to CSS property-value pairs.
-}
animationTargetToCssProperty : AnimationTarget -> List ( String, String )
animationTargetToCssProperty target =
    case target of
        ToPosition position ->
            [ ( "transform", transformElement position ) ]

        ToOpacity opacity ->
            [ ( "opacity", String.fromFloat opacity ) ]

        ToScale scale ->
            [ ( "transform", "scale(" ++ String.fromFloat scale.x ++ ", " ++ String.fromFloat scale.y ++ ")" ) ]

        ToRotation rotation ->
            [ ( "transform", "rotate(" ++ String.fromFloat rotation ++ "deg)" ) ]

        ToBackgroundColor color ->
            [ ( "background-color", colorValueToCss color ) ]

        ToTextColor color ->
            [ ( "color", colorValueToCss color ) ]

        ToBorderColor color ->
            [ ( "border-color", colorValueToCss color ) ]

        ToDimensions dimensions ->
            [ ( "width", String.fromFloat dimensions.width ++ "px" )
            , ( "height", String.fromFloat dimensions.height ++ "px" )
            ]

        ToBorderRadius radius ->
            [ ( "border-radius", String.fromFloat radius ++ "px" ) ]

        ToFilter filter ->
            [ ( "filter", filterValueToCss filter ) ]


{-| Convert a ColorValue to CSS color string.
-}
colorValueToCss : ColorValue -> String
colorValueToCss color =
    case color of
        Hex hex ->
            hex

        Rgb rgb ->
            "rgb(" ++ String.fromInt rgb.r ++ ", " ++ String.fromInt rgb.g ++ ", " ++ String.fromInt rgb.b ++ ")"

        Rgba rgba ->
            "rgba(" ++ String.fromInt rgba.r ++ ", " ++ String.fromInt rgba.g ++ ", " ++ String.fromInt rgba.b ++ ", " ++ String.fromFloat rgba.a ++ ")"

        Hsl hsl ->
            "hsl(" ++ String.fromFloat hsl.h ++ ", " ++ String.fromFloat hsl.s ++ "%, " ++ String.fromFloat hsl.l ++ "%)"

        Hsla hsla ->
            "hsla(" ++ String.fromFloat hsla.h ++ ", " ++ String.fromFloat hsla.s ++ "%, " ++ String.fromFloat hsla.l ++ "%, " ++ String.fromFloat hsla.a ++ ")"


{-| Convert a FilterValue to CSS filter string.
-}
filterValueToCss : FilterValue -> String
filterValueToCss filter =
    case filter of
        Blur blur ->
            "blur(" ++ String.fromFloat blur ++ "px)"

        Brightness brightness ->
            "brightness(" ++ String.fromFloat brightness ++ ")"

        Contrast contrast ->
            "contrast(" ++ String.fromFloat contrast ++ ")"

        Grayscale grayscale ->
            "grayscale(" ++ String.fromFloat grayscale ++ ")"

        Saturate saturate ->
            "saturate(" ++ String.fromFloat saturate ++ ")"


{-| Handle property updates from JavaScript port

Call this when JavaScript sends position updates during animations:

    port positionUpdates : (Decode.Value -> msg) -> Sub msg

    -- In your subscriptions:
    subscriptions model =
        positionUpdates (PositionUpdateReceived << Move.Ports.handlePositionUpdateFromJson)

    -- In your update function:
    PositionUpdateReceived (Ok positionUpdate) ->
        ( { model | movePortsModel = Move.Ports.handlePositionUpdate positionUpdate model.movePortsModel }, Cmd.none )

-}
handlePropertyUpdate : PropertyUpdate -> Model -> Model
handlePropertyUpdate update (Model elementsDict) =
    let
        currentElementData =
            Dict.get update.elementId elementsDict
                |> Maybe.withDefault { properties = Dict.empty, animating = Dict.empty }

        updatedProperties =
            Dict.insert update.propertyKey update.target currentElementData.properties

        elementData =
            { currentElementData | properties = updatedProperties }

        updatedDict =
            Dict.insert update.elementId elementData elementsDict
    in
    Model updatedDict


{-| Handle position update from JSON value received through port

    case Move.Ports.handlePositionUpdateFromJson jsonValue of
        Ok positionUpdate ->
            -- Use the position update

        Err error ->
            -- Handle decode error

-}
handlePropertyUpdateFromJson : Decode.Value -> Result Decode.Error PropertyUpdate
handlePropertyUpdateFromJson value =
    Decode.decodeValue propertyUpdateDecoder value


{-| Helper function to encode ColorValue to JSON
-}
encodeColorValue : ColorValue -> Encode.Value
encodeColorValue colorValue =
    case colorValue of
        Hex hexStr ->
            Encode.object
                [ ( "type", Encode.string "hex" )
                , ( "value", Encode.string hexStr )
                ]

        Rgb rgb ->
            Encode.object
                [ ( "type", Encode.string "rgb" )
                , ( "r", Encode.int rgb.r )
                , ( "g", Encode.int rgb.g )
                , ( "b", Encode.int rgb.b )
                ]

        Rgba rgba ->
            Encode.object
                [ ( "type", Encode.string "rgba" )
                , ( "r", Encode.int rgba.r )
                , ( "g", Encode.int rgba.g )
                , ( "b", Encode.int rgba.b )
                , ( "a", Encode.float rgba.a )
                ]

        Hsl hsl ->
            Encode.object
                [ ( "type", Encode.string "hsl" )
                , ( "h", Encode.float hsl.h )
                , ( "s", Encode.float hsl.s )
                , ( "l", Encode.float hsl.l )
                ]

        Hsla hsla ->
            Encode.object
                [ ( "type", Encode.string "hsla" )
                , ( "h", Encode.float hsla.h )
                , ( "s", Encode.float hsla.s )
                , ( "l", Encode.float hsla.l )
                , ( "a", Encode.float hsla.a )
                ]


{-| Helper function to encode FilterValue to JSON
-}
encodeFilterValue : FilterValue -> Encode.Value
encodeFilterValue filterValue =
    case filterValue of
        Blur radius ->
            Encode.object
                [ ( "type", Encode.string "blur" )
                , ( "value", Encode.float radius )
                ]

        Brightness value ->
            Encode.object
                [ ( "type", Encode.string "brightness" )
                , ( "value", Encode.float value )
                ]

        Contrast value ->
            Encode.object
                [ ( "type", Encode.string "contrast" )
                , ( "value", Encode.float value )
                ]

        Grayscale value ->
            Encode.object
                [ ( "type", Encode.string "grayscale" )
                , ( "value", Encode.float value )
                ]

        Saturate value ->
            Encode.object
                [ ( "type", Encode.string "saturate" )
                , ( "value", Encode.float value )
                ]


{-| Encode animation command as JSON for sending to JavaScript

    jsonValue =
        Move.Ports.encodeAnimationCommand animationCommand

-}
encodeAnimationCommand : AnimationCommand -> Encode.Value
encodeAnimationCommand command =
    let
        duration =
            case command.config.timing of
                Duration ms ->
                    toFloat ms

                Speed _ ->
                    -- For encoding, we'll use a default duration of 500ms for speed-based timing
                    -- JavaScript can override this based on actual distance
                    500.0

        easing =
            case command.config.easing of
                EasePreset preset ->
                    case preset of
                        Linear ->
                            "linear"

                        EaseIn ->
                            "ease-in"

                        EaseOut ->
                            "ease-out"

                        EaseInOut ->
                            "ease-in-out"

                EaseString str ->
                    str

                EaseFunction _ ->
                    -- For ports, we'll use a default string representation
                    "ease-out"

        targetValue =
            case command.target of
                ToPosition pos ->
                    Encode.object
                        [ ( "type", Encode.string "position" )
                        , ( "x", Encode.float pos.x )
                        , ( "y", Encode.float pos.y )
                        ]

                ToOpacity value ->
                    Encode.object
                        [ ( "type", Encode.string "opacity" )
                        , ( "value", Encode.float value )
                        ]

                ToScale scale ->
                    Encode.object
                        [ ( "type", Encode.string "scale" )
                        , ( "x", Encode.float scale.x )
                        , ( "y", Encode.float scale.y )
                        ]

                ToRotation degrees ->
                    Encode.object
                        [ ( "type", Encode.string "rotation" )
                        , ( "value", Encode.float degrees )
                        ]

                ToBackgroundColor colorValue ->
                    Encode.object
                        [ ( "type", Encode.string "backgroundColor" )
                        , ( "value", encodeColorValue colorValue )
                        ]

                -- Add more cases for other AnimationTarget variants
                ToTextColor colorValue ->
                    Encode.object
                        [ ( "type", Encode.string "textColor" )
                        , ( "value", encodeColorValue colorValue )
                        ]

                ToBorderColor colorValue ->
                    Encode.object
                        [ ( "type", Encode.string "borderColor" )
                        , ( "value", encodeColorValue colorValue )
                        ]

                ToDimensions dim ->
                    Encode.object
                        [ ( "type", Encode.string "dimensions" )
                        , ( "width", Encode.float dim.width )
                        , ( "height", Encode.float dim.height )
                        ]

                ToBorderRadius radius ->
                    Encode.object
                        [ ( "type", Encode.string "borderRadius" )
                        , ( "value", Encode.float radius )
                        ]

                ToFilter filter ->
                    Encode.object
                        [ ( "type", Encode.string "filter" )
                        , ( "value", encodeFilterValue filter )
                        ]
    in
    Encode.object
        [ ( "elementId", Encode.string command.elementId )
        , ( "target", targetValue )
        , ( "duration", Encode.float duration )
        , ( "easing", Encode.string easing )
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
propertyUpdateDecoder : Decoder PropertyUpdate
propertyUpdateDecoder =
    Decode.map3 PropertyUpdate
        (Decode.field "elementId" Decode.string)
        (Decode.field "propertyKey" Decode.string)
        (Decode.field "target" animationTargetDecoder)


{-| Decoder for AnimationTarget from JavaScript
-}
animationTargetDecoder : Decoder AnimationTarget
animationTargetDecoder =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\targetType ->
                case targetType of
                    "position" ->
                        Decode.map2 (\x y -> ToPosition { x = x, y = y })
                            (Decode.field "x" Decode.float)
                            (Decode.field "y" Decode.float)

                    "opacity" ->
                        Decode.map ToOpacity (Decode.field "value" Decode.float)

                    "scale" ->
                        Decode.map2 (\x y -> ToScale { x = x, y = y })
                            (Decode.field "x" Decode.float)
                            (Decode.field "y" Decode.float)

                    "rotation" ->
                        Decode.map ToRotation (Decode.field "value" Decode.float)

                    "background-color" ->
                        Decode.map ToBackgroundColor (Decode.field "value" colorValueDecoder)

                    "text-color" ->
                        Decode.map ToTextColor (Decode.field "value" colorValueDecoder)

                    "border-color" ->
                        Decode.map ToBorderColor (Decode.field "value" colorValueDecoder)

                    "dimensions" ->
                        Decode.map2 (\w h -> ToDimensions { width = w, height = h })
                            (Decode.field "width" Decode.float)
                            (Decode.field "height" Decode.float)

                    "border-radius" ->
                        Decode.map ToBorderRadius (Decode.field "value" Decode.float)

                    "filter" ->
                        Decode.map ToFilter (Decode.field "value" filterValueDecoder)

                    _ ->
                        Decode.fail ("Unknown animation target type: " ++ targetType)
            )


{-| Decoder for ColorValue from JavaScript
-}
colorValueDecoder : Decoder ColorValue
colorValueDecoder =
    Decode.field "format" Decode.string
        |> Decode.andThen
            (\format ->
                case format of
                    "hex" ->
                        Decode.map Hex (Decode.field "value" Decode.string)

                    "rgb" ->
                        Decode.map3 (\r g b -> Rgb { r = r, g = g, b = b })
                            (Decode.field "r" Decode.int)
                            (Decode.field "g" Decode.int)
                            (Decode.field "b" Decode.int)

                    "rgba" ->
                        Decode.map4 (\r g b a -> Rgba { r = r, g = g, b = b, a = a })
                            (Decode.field "r" Decode.int)
                            (Decode.field "g" Decode.int)
                            (Decode.field "b" Decode.int)
                            (Decode.field "a" Decode.float)

                    "hsl" ->
                        Decode.map3 (\h s l -> Hsl { h = h, s = s, l = l })
                            (Decode.field "h" Decode.float)
                            (Decode.field "s" Decode.float)
                            (Decode.field "l" Decode.float)

                    "hsla" ->
                        Decode.map4 (\h s l a -> Hsla { h = h, s = s, l = l, a = a })
                            (Decode.field "h" Decode.float)
                            (Decode.field "s" Decode.float)
                            (Decode.field "l" Decode.float)
                            (Decode.field "a" Decode.float)

                    _ ->
                        Decode.fail ("Unknown color format: " ++ format)
            )


{-| Decoder for FilterValue from JavaScript
-}
filterValueDecoder : Decoder FilterValue
filterValueDecoder =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\filterType ->
                case filterType of
                    "blur" ->
                        Decode.map Blur (Decode.field "value" Decode.float)

                    "brightness" ->
                        Decode.map Brightness (Decode.field "value" Decode.float)

                    "contrast" ->
                        Decode.map Contrast (Decode.field "value" Decode.float)

                    "grayscale" ->
                        Decode.map Grayscale (Decode.field "value" Decode.float)

                    "saturate" ->
                        Decode.map Saturate (Decode.field "value" Decode.float)

                    _ ->
                        Decode.fail ("Unknown filter type: " ++ filterType)
            )
