module Anim.Internal.Builders.Position exposing
    ( PositionBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , from
    , speed
    , to
    , toX
    , toY
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Property as PropertyBuilder
import Anim.Internal.Properties.Position as Position exposing (Position)
import Anim.Internal.Timing.Delay exposing (Delay)
import Anim.Internal.Timing.Easing exposing (Easing)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))



{- POSITION CONFIGURATION BUILDER -}
{- Usage:

   Anim.init
       |> Position.for "my-element"
       |> Position.from (Position.fromTuple (0, 0))
       |> Position.to (Position.fromTuple (100, 200))
       |> Position.duration 2000
       |> Position.easing Easing.easeInOut
       |> Position.delay (Delay.millis 500)
       |> Position.build
       |> Anim.animate
-}


type PositionBuilder
    = PositionBuilder PositionConfig AnimBuilder


for : String -> AnimBuilder -> PositionBuilder
for elementId builder =
    let
        existingConfig =
            case Builder.getElementConfig elementId builder of
                Just { properties } ->
                    properties
                        |> List.filterMap
                            (\prop ->
                                case prop of
                                    Builder.PositionConfig config ->
                                        Just config

                                    _ ->
                                        Nothing
                            )
                        |> List.head

                _ ->
                    Nothing
    in
    case existingConfig of
        Just config ->
            PositionBuilder (PropertyBuilder.applyGlobalDefaults builder config) builder

        Nothing ->
            PositionBuilder (PropertyBuilder.applyGlobalDefaults builder defaultConfig) (Builder.for elementId builder)


build : PositionBuilder -> AnimBuilder
build (PositionBuilder config builder) =
    let
        newPositionConfig =
            Builder.PositionConfig config
    in
    PropertyBuilder.upsert newPositionConfig builder


type alias PositionConfig =
    { startAt : Maybe Position
    , endAt : Position
    , duration : Int -- Millis
    , speed : Float -- Pixels per second
    , distance : Float -- Pixels
    , timing : Maybe TimeSpec
    , easing : Maybe Easing
    , delay : Maybe Delay
    }


defaultConfig : PositionConfig
defaultConfig =
    { startAt = Nothing
    , endAt = Position.fromTuple ( 0, 0 )
    , duration = 0
    , speed = 0
    , distance = 0
    , timing = Nothing
    , easing = Nothing
    , delay = Nothing
    }


from : Position -> PositionBuilder -> PositionBuilder
from position (PositionBuilder config builder) =
    PositionBuilder { config | startAt = Just position } builder


to : Position -> PositionBuilder -> PositionBuilder
to position (PositionBuilder config builder) =
    PositionBuilder { config | endAt = position } builder


toX : Float -> PositionBuilder -> PositionBuilder
toX x (PositionBuilder config builder) =
    PositionBuilder { config | endAt = Position.fromTuple ( x, Position.y config.endAt ) } builder


toY : Float -> PositionBuilder -> PositionBuilder
toY y (PositionBuilder config builder) =
    PositionBuilder { config | endAt = Position.fromTuple ( Position.x config.endAt, y ) } builder


speed : Float -> PositionBuilder -> PositionBuilder
speed value (PositionBuilder config builder) =
    let
        ( speed_, timeSpec ) =
            case Builder.getTimespec builder of
                Just (Speed s) ->
                    ( s, Just <| Speed s )

                Just (Duration _) ->
                    ( value, Just <| Speed value )

                Nothing ->
                    ( value, Just <| Speed value )
    in
    PositionBuilder
        { config
            | speed = speed_
            , timing = timeSpec
        }
        builder


duration : Int -> PositionBuilder -> PositionBuilder
duration ms (PositionBuilder config builder) =
    PositionBuilder
        { config
            | duration = ms
            , timing =
                Just <|
                    Duration ms
        }
        builder


easing : Easing -> PositionBuilder -> PositionBuilder
easing easing_ (PositionBuilder config builder) =
    PositionBuilder { config | easing = Just easing_ } builder


delay : Delay -> PositionBuilder -> PositionBuilder
delay delay_ (PositionBuilder config builder) =
    PositionBuilder { config | delay = Just delay_ } builder
