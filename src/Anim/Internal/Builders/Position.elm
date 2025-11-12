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
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Properties.Position as Position exposing (Position)
import Anim.Internal.Timing.Delay exposing (Delay)
import Anim.Internal.Timing.Easing exposing (Easing)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec)
import Html exposing (a)


type PositionBuilder
    = PositionBuilder PositionConfig AnimBuilder


for : String -> AnimBuilder -> PositionBuilder
for elementId builder =
    PositionBuilder defaultConfig (Builder.for elementId builder)


build : PositionBuilder -> AnimBuilder
build (PositionBuilder config builder) =
    let
        currentElement =
            Builder.getCurrentElement builder

        newPositionConfig =
            Builder.PositionConfig config

        addProp =
            newPositionConfig :: currentElement.properties

        replaceProp =
            currentElement.properties
                |> List.map
                    (\p ->
                        case p of
                            Builder.PositionConfig _ ->
                                newPositionConfig

                            _ ->
                                p
                    )

        findProp : List Builder.PropertyConfig -> List Builder.PropertyConfig
        findProp =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.PositionConfig c ->
                            Just (Builder.PositionConfig c)

                        _ ->
                            Nothing
                )

        upsertProp : List Builder.PropertyConfig -> List Builder.PropertyConfig
        upsertProp props =
            case props of
                [] ->
                    addProp

                [ Builder.PositionConfig _ ] ->
                    replaceProp

                _ ->
                    currentElement.properties

        updatedElement =
            { currentElement
                | properties =
                    currentElement.properties
                        |> findProp
                        |> upsertProp
            }
    in
    Builder.updateCurrentElement updatedElement builder


type alias PositionConfig =
    { startAt : Position
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
    { startAt = Position.fromTuple ( 0, 0 )
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
    PositionBuilder { config | startAt = position } builder


to : Position -> PositionBuilder -> PositionBuilder
to position (PositionBuilder config builder) =
    PositionBuilder { config | endAt = position } builder


speed : Float -> PositionBuilder -> PositionBuilder
speed value (PositionBuilder config builder) =
    PositionBuilder { config | speed = value } builder


duration : Int -> PositionBuilder -> PositionBuilder
duration ms (PositionBuilder config builder) =
    PositionBuilder { config | duration = ms } builder


easing : Easing -> PositionBuilder -> PositionBuilder
easing easing_ (PositionBuilder config builder) =
    PositionBuilder { config | easing = Just easing_ } builder


delay : Delay -> PositionBuilder -> PositionBuilder
delay delay_ (PositionBuilder config builder) =
    PositionBuilder { config | delay = Just delay_ } builder
