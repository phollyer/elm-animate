module Anim.Internal.Builders.Rotate exposing
    ( RotateBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , from
    , speed
    , to
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Property as PropertyBuilder
import Anim.Internal.Properties.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Timing.Easing exposing (Easing)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))



{- Rotation CONFIGURATION BUILDER -}
{- Usage:

   Anim.init
      |> Rotation.for "my-element"
      |> Rotation.from 0
      |> Rotation.to 360
      |> Rotation.duration 2000
      |> Rotation.easing Easing.easeInOut
      |> Rotation.delay (Delay.millis 500)
      |> Rotation.build
      |> Anim.animate
-}


type RotateBuilder
    = RotateBuilder RotateConfig AnimBuilder


for : String -> AnimBuilder -> RotateBuilder
for elementId builder =
    let
        existingConfig =
            case Builder.getElementConfig elementId builder of
                Just { properties } ->
                    properties
                        |> List.filterMap
                            (\prop ->
                                case prop of
                                    Builder.RotateConfig config ->
                                        Just config

                                    _ ->
                                        Nothing
                            )
                        |> List.head

                _ ->
                    Nothing

        newConfig =
            case existingConfig of
                Just config ->
                    PropertyBuilder.applyGlobalDefaults builder <|
                        { config
                            | startAt = Just config.endAt
                            , easing = Nothing
                            , delay = Nothing
                            , timing = Nothing
                            , duration = 0
                            , speed = 0
                            , distance = 0
                            , isDirty = False
                        }

                Nothing ->
                    PropertyBuilder.applyGlobalDefaults builder defaultConfig
    in
    RotateBuilder newConfig (Builder.for elementId builder)


build : RotateBuilder -> AnimBuilder
build (RotateBuilder config builder) =
    let
        newRotationConfig =
            Builder.RotateConfig config
    in
    PropertyBuilder.upsert newRotationConfig builder


type alias RotateConfig =
    { startAt : Maybe Rotate
    , endAt : Rotate
    , duration : Int -- Millis
    , speed : Float -- Pixels per second
    , distance : Float -- Pixels
    , timing : Maybe TimeSpec
    , easing : Maybe Easing
    , delay : Maybe Int
    , isDirty : Bool
    }


defaultConfig : RotateConfig
defaultConfig =
    { startAt = Nothing
    , endAt = Rotate.fromFloat 0.0
    , duration = 0
    , speed = 0.0
    , distance = 0.0
    , timing = Nothing
    , easing = Nothing
    , delay = Nothing
    , isDirty = False
    }


from : Rotate -> RotateBuilder -> RotateBuilder
from rotation (RotateBuilder config builder) =
    let
        startPos =
            case config.startAt of
                Just opacity_ ->
                    opacity_

                Nothing ->
                    Rotate.fromFloat 0.0
    in
    RotateBuilder
        { config
            | endAt = rotation
            , distance = Rotate.distance startPos rotation
            , startAt = Just startPos
        }
        builder


to : Rotate -> RotateBuilder -> RotateBuilder
to rotation (RotateBuilder config builder) =
    RotateBuilder { config | endAt = rotation } builder


speed : Float -> RotateBuilder -> RotateBuilder
speed value (RotateBuilder config builder) =
    RotateBuilder
        { config
            | speed = value
            , timing =
                Just <|
                    Speed value
        }
        builder


duration : Int -> RotateBuilder -> RotateBuilder
duration ms (RotateBuilder config builder) =
    RotateBuilder
        { config
            | duration = ms
            , timing =
                Just <|
                    Duration ms
        }
        builder


easing : Easing -> RotateBuilder -> RotateBuilder
easing easing_ (RotateBuilder config builder) =
    RotateBuilder { config | easing = Just easing_ } builder


delay : Int -> RotateBuilder -> RotateBuilder
delay delay_ (RotateBuilder config builder) =
    RotateBuilder { config | delay = Just delay_ } builder
