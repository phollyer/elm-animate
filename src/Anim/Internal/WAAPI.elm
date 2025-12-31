module Anim.Internal.WAAPI exposing
    ( AnimState
    , allComplete
    , animate
    , anyRunning
    , builder
    , delay
    , duration
    , easing
    , getBackgroundColorRange
    , getCurrentStyles
    , getOpacityRange
    , getPosition
    , getPositionRange
    , getRotateRange
    , getScaleRange
    , getSizeRange
    , init
    , isElementComplete
    , isElementRunning
    , speed
    , update
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.Properties.BackgroundColor as BackgroundColor exposing (Color)
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Properties.Position as Position exposing (Position)
import Anim.Internal.Properties.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Properties.Scale as Scale exposing (Scale)
import Anim.Internal.Properties.Size as Size exposing (Size)
import Anim.Internal.Timing.Easing exposing (Easing)
import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode



-- Build


type alias AnimBuilder =
    Builder.AnimBuilder


type alias ElementId =
    String


type alias ElementEndStates =
    { position : Maybe Position
    , rotate : Maybe Rotate
    , scale : Maybe Scale
    , backgroundColor : Maybe Color
    , opacity : Maybe Opacity
    , size : Maybe Size
    }


type alias ElementAnimation =
    { commands : Encode.Value
    , endStates : ElementEndStates
    , currentStates : ElementEndStates -- Track current animated states for smooth interruption
    }


type AnimState
    = AnimState
        { elementAnimations : Dict ElementId ElementAnimation
        , isRunning : Bool
        , builder : AnimBuilder
        }


init : AnimState
init =
    AnimState
        { elementAnimations = Dict.empty
        , isRunning = False
        , builder = Builder.init
        }


builder : AnimState -> AnimBuilder
builder (AnimState state) =
    -- Just return the base builder - currentStates will be injected in animate function
    state.builder


{-| Inject current animated states into builder's element configs
-}
injectCurrentStatesForElement : ElementId -> ElementAnimation -> AnimBuilder -> AnimBuilder
injectCurrentStatesForElement elementId elementAnim baseBuilder =
    case Builder.getElementConfig elementId baseBuilder of
        Just elementConfig ->
            let
                updatedProperties =
                    List.map (injectCurrentStateIntoProperty elementAnim.currentStates) elementConfig.properties

                updatedElementConfig =
                    { elementConfig | properties = updatedProperties }
            in
            Builder.updateElementConfig elementId updatedElementConfig baseBuilder

        Nothing ->
            baseBuilder


{-| Update a property config to use current animated state as its startAt
-}
injectCurrentStateIntoProperty : ElementEndStates -> Builder.PropertyConfig -> Builder.PropertyConfig
injectCurrentStateIntoProperty currentStates propertyConfig =
    case propertyConfig of
        Builder.PositionConfig config ->
            Builder.PositionConfig
                { config
                    | startAt =
                        case config.startAt of
                            Just _ ->
                                config.startAt

                            -- Don't override explicit startAt
                            Nothing ->
                                currentStates.position

                    -- Use current animated position
                }

        Builder.RotateConfig config ->
            Builder.RotateConfig
                { config
                    | startAt =
                        case config.startAt of
                            Just _ ->
                                config.startAt

                            Nothing ->
                                currentStates.rotate
                }

        Builder.ScaleConfig config ->
            Builder.ScaleConfig
                { config
                    | startAt =
                        case config.startAt of
                            Just _ ->
                                config.startAt

                            Nothing ->
                                currentStates.scale
                }

        Builder.OpacityConfig config ->
            Builder.OpacityConfig
                { config
                    | startAt =
                        case config.startAt of
                            Just _ ->
                                config.startAt

                            Nothing ->
                                currentStates.opacity
                }

        Builder.BackgroundColorConfig config ->
            Builder.BackgroundColorConfig
                { config
                    | startAt =
                        case config.startAt of
                            Just _ ->
                                config.startAt

                            Nothing ->
                                currentStates.backgroundColor
                }

        Builder.SizeConfig config ->
            Builder.SizeConfig
                { config
                    | startAt =
                        case config.startAt of
                            Just _ ->
                                config.startAt

                            Nothing ->
                                currentStates.size
                }


animate : AnimState -> AnimBuilder -> ( AnimState, Encode.Value )
animate (AnimState state) builder_ =
    let
        -- Inject current animated states into builder BEFORE processing
        builderWithCurrentStates =
            Dict.foldl injectCurrentStatesForElement builder_ state.elementAnimations

        processedData =
            Builder.processAnimationData builderWithCurrentStates

        -- Create element animations from processed data
        newElementAnimations =
            processedData.elements
                |> Dict.map
                    (\elementId elementConfig ->
                        let
                            endStates =
                                extractElementEndStates elementConfig

                            -- Use current states from existing animation if available, otherwise use end states
                            currentStates =
                                Dict.get elementId state.elementAnimations
                                    |> Maybe.map .currentStates
                                    |> Maybe.withDefault endStates
                        in
                        { commands = Builder.encode processedData
                        , endStates = endStates
                        , currentStates = currentStates
                        }
                    )

        -- Merge with existing animations (new animations replace old ones for same elements)
        updatedElementAnimations =
            Dict.union newElementAnimations state.elementAnimations

        newAnimState =
            AnimState
                { elementAnimations = updatedElementAnimations
                , isRunning = not (Dict.isEmpty newElementAnimations)
                , builder = Builder.markDirty builderWithCurrentStates
                }

        encodedData =
            Builder.encode processedData
    in
    ( newAnimState, encodedData )


extractElementEndStates : Builder.ProcessedElementConfig -> ElementEndStates
extractElementEndStates elementConfig =
    List.foldl extractPropertyEndState emptyElementEndStates elementConfig.properties


emptyElementEndStates : ElementEndStates
emptyElementEndStates =
    { position = Nothing
    , rotate = Nothing
    , scale = Nothing
    , backgroundColor = Nothing
    , opacity = Nothing
    , size = Nothing
    }


extractPropertyEndState : Builder.ProcessedPropertyConfig -> ElementEndStates -> ElementEndStates
extractPropertyEndState property state =
    case property of
        Builder.ProcessedPositionConfig config ->
            { state | position = Just config.endAt }

        Builder.ProcessedRotateConfig config ->
            { state | rotate = Just config.endAt }

        Builder.ProcessedScaleConfig config ->
            { state | scale = Just config.endAt }

        Builder.ProcessedBackgroundColorConfig config ->
            { state | backgroundColor = Just config.endAt }

        Builder.ProcessedOpacityConfig config ->
            { state | opacity = Just config.endAt }

        Builder.ProcessedSizeConfig config ->
            { state | size = Just config.endAt }


{-| Get current position of an element.
-}
getPosition : String -> AnimState -> Maybe Position
getPosition elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.endStates >> .position)


{-| Check if any animations are currently running.
-}
anyRunning : AnimState -> Bool
anyRunning (AnimState state) =
    not (Dict.isEmpty state.elementAnimations) && state.isRunning


{-| Check if a specific element has any animations currently running.
-}
isElementRunning : String -> AnimState -> Bool
isElementRunning elementId (AnimState state) =
    Dict.member elementId state.elementAnimations && state.isRunning



-- RANGE QUERYING (Start/End values)


{-| Get both start and end positions for an element's animation.
Returns Nothing if the element has no position animation.
-}
getPositionRange : String -> AnimState -> Maybe { start : Maybe Position, end : Position }
getPositionRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedPositionConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end scales for an element's animation.
Returns Nothing if the element has no scale animation.
-}
getScaleRange : String -> AnimState -> Maybe { start : Maybe Scale, end : Scale }
getScaleRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedScaleConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end rotations for an element's animation.
Returns Nothing if the element has no rotate animation.
-}
getRotateRange : String -> AnimState -> Maybe { start : Maybe Rotate, end : Rotate }
getRotateRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedRotateConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end opacity values for an element's animation.
Returns Nothing if the element has no opacity animation.
-}
getOpacityRange : String -> AnimState -> Maybe { start : Maybe Opacity, end : Opacity }
getOpacityRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedOpacityConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end background colors for an element's animation.
Returns Nothing if the element has no background color animation.
-}
getBackgroundColorRange : String -> AnimState -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedBackgroundColorConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end sizes for an element's animation.
Returns Nothing if the element has no size animation.
-}
getSizeRange : String -> AnimState -> Maybe { start : Maybe Size, end : Size }
getSizeRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedSizeConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Check if all animations are complete.
-}
allComplete : AnimState -> Maybe Bool
allComplete (AnimState state) =
    if Dict.isEmpty state.elementAnimations then
        Nothing

    else
        Just (not state.isRunning)


{-| Check if a specific element's animations have completed.
-}
isElementComplete : String -> AnimState -> Maybe Bool
isElementComplete elementId (AnimState state) =
    if Dict.member elementId state.elementAnimations then
        Just (not state.isRunning)

    else
        Nothing


duration : Int -> AnimBuilder -> AnimBuilder
duration =
    Builder.duration


speed : Float -> AnimBuilder -> AnimBuilder
speed value =
    Builder.speed value


easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Builder.easing


delay : Int -> AnimBuilder -> AnimBuilder
delay =
    Builder.delay


{-| Get current styles for an element (for debugging/display purposes).
-}
getCurrentStyles : String -> AnimState -> List ( String, String )
getCurrentStyles elementId (AnimState state) =
    case Dict.get elementId state.elementAnimations of
        Nothing ->
            []

        Just elementAnimation ->
            let
                endStates =
                    elementAnimation.endStates

                transformParts =
                    [ endStates.position |> Maybe.map positionToTransform
                    , endStates.rotate |> Maybe.map rotateToTransform
                    , endStates.scale |> Maybe.map scaleToTransform
                    ]
                        |> List.filterMap identity

                nonTransformStyles =
                    [ endStates.backgroundColor |> Maybe.map colorToStyle
                    , endStates.opacity |> Maybe.map opacityToStyle
                    ]
                        |> List.filterMap identity

                transformStyle =
                    if List.isEmpty transformParts then
                        []

                    else
                        [ ( "transform", String.join " " transformParts ) ]
            in
            transformStyle ++ nonTransformStyles


positionToTransform : Position -> String
positionToTransform pos =
    let
        ( x, y, z ) =
            Position.toTriple pos
    in
    "translate3d(" ++ String.fromFloat x ++ "px, " ++ String.fromFloat y ++ "px, " ++ String.fromFloat z ++ "px)"


rotateToTransform : Rotate -> String
rotateToTransform rot =
    Rotate.to3DCssString rot


scaleToTransform : Scale -> String
scaleToTransform scl =
    let
        ( x, y ) =
            Scale.toTuple scl
    in
    "scale(" ++ String.fromFloat x ++ ", " ++ String.fromFloat y ++ ")"


colorToStyle : Color -> ( String, String )
colorToStyle col =
    ( "background-color", BackgroundColor.toString col )


opacityToStyle : Opacity -> ( String, String )
opacityToStyle op =
    ( "opacity", String.fromFloat (Opacity.toFloat op) )


{-| Update animation state with data received from JavaScript via ports.

This function processes animation update data received from the JavaScript WAAPI
integration and updates the internal animation state accordingly.

    case msg of
        ReceiveWAAPI value ->
            { model | animations = WAAPI.update value model.animations }

-}
update : Decode.Value -> AnimState -> AnimState
update jsonValue (AnimState state) =
    case Decode.decodeValue animationUpdateDecoder jsonValue of
        Ok animationUpdate ->
            let
                updatedAnimations =
                    Dict.update animationUpdate.elementId
                        (Maybe.map (updateElementAnimation animationUpdate))
                        state.elementAnimations

                newState =
                    AnimState
                        { state
                            | elementAnimations = updatedAnimations
                            , isRunning = not (Dict.isEmpty updatedAnimations)
                        }
            in
            newState

        Err _ ->
            -- Silently ignore decode errors since we control the data shape
            AnimState state


type alias AnimationUpdate =
    { elementId : String
    , x : Float
    , y : Float
    , z : Float
    , opacity : Float
    , rotationX : Float
    , rotationY : Float
    , rotationZ : Float
    , scaleX : Float
    , scaleY : Float
    , scaleZ : Float
    , backgroundColor : String
    , width : Float
    , height : Float
    , isAnimating : Bool
    }


animationUpdateDecoder : Decoder AnimationUpdate
animationUpdateDecoder =
    Decode.succeed AnimationUpdate
        |> andMap (Decode.field "elementId" Decode.string)
        |> andMap (Decode.field "x" Decode.float)
        |> andMap (Decode.field "y" Decode.float)
        |> andMap (Decode.field "z" Decode.float)
        |> andMap (Decode.field "opacity" Decode.float)
        |> andMap (Decode.field "rotationX" Decode.float)
        |> andMap (Decode.field "rotationY" Decode.float)
        |> andMap (Decode.field "rotationZ" Decode.float)
        |> andMap (Decode.field "scaleX" Decode.float)
        |> andMap (Decode.field "scaleY" Decode.float)
        |> andMap (Decode.field "scaleZ" Decode.float)
        |> andMap (Decode.field "backgroundColor" Decode.string)
        |> andMap (Decode.field "width" Decode.float)
        |> andMap (Decode.field "height" Decode.float)
        |> andMap (Decode.field "isAnimating" Decode.bool)


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)


updateElementAnimation : AnimationUpdate -> ElementAnimation -> ElementAnimation
updateElementAnimation animUpdate elementAnimation =
    let
        -- Update current animated states based on port data
        updatedCurrentStates =
            { position = Just (Position.fromTriple ( animUpdate.x, animUpdate.y, animUpdate.z ))
            , rotate = Just (Rotate.fromTriple ( animUpdate.rotationX, animUpdate.rotationY, animUpdate.rotationZ ))
            , scale = Just (Scale.fromTriple ( animUpdate.scaleX, animUpdate.scaleY, animUpdate.scaleZ ))
            , opacity = Just (Opacity.fromFloat animUpdate.opacity)
            , backgroundColor = BackgroundColor.fromRgbString animUpdate.backgroundColor
            , size = Just (Size.fromTuple ( animUpdate.width, animUpdate.height ))
            }
    in
    { elementAnimation
        | currentStates = updatedCurrentStates

        -- Keep endStates as-is - they represent target, not current
    }
