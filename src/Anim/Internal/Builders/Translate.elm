module Anim.Internal.Builders.Translate exposing
    ( TranslateBuilder
    , build
    , by
    , byX
    , byXY
    , byXYZ
    , byXZ
    , byY
    , byYZ
    , byZ
    , delay
    , duration
    , easing
    , for
    , from
    , fromX
    , fromXY
    , fromXYZ
    , fromXZ
    , fromY
    , fromYZ
    , fromZ
    , speed
    , to
    , toX
    , toXY
    , toXYZ
    , toXZ
    , toY
    , toYZ
    , toZ
    )

import Anim.Easing exposing (Easing(..))
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Property as PropertyBuilder
import Anim.Internal.Properties.Translate as Translate exposing (Translate)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))


type TranslateBuilder
    = TranslateBuilder (Builder.AnimationConfig Translate) AnimBuilder


for : String -> AnimBuilder -> TranslateBuilder
for elementId builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.TranslateConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        extractBaseline endStates =
            endStates.translate

        config =
            PropertyBuilder.createFor extractExisting extractBaseline defaultConfig elementId builder
    in
    TranslateBuilder config (Builder.for elementId builder)


build : TranslateBuilder -> AnimBuilder
build (TranslateBuilder config builder) =
    PropertyBuilder.upsert (Builder.TranslateConfig config) builder


type alias TranslateConfig =
    Builder.AnimationConfig Translate


defaultConfig : TranslateConfig
defaultConfig =
    PropertyBuilder.defaultConfig <|
        Translate.fromTriple ( 0, 0, 0 )


from : Translate -> TranslateBuilder -> TranslateBuilder
from value (TranslateBuilder config builder) =
    TranslateBuilder { config | start = Just value } builder


fromXYZ : Float -> Float -> Float -> TranslateBuilder -> TranslateBuilder
fromXYZ x y z =
    from (Translate.fromTriple ( x, y, z ))


fromXY : Float -> Float -> TranslateBuilder -> TranslateBuilder
fromXY x y (TranslateBuilder config builder) =
    let
        z =
            Maybe.withDefault 0 <|
                Maybe.map Translate.z config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromXZ : Float -> Float -> TranslateBuilder -> TranslateBuilder
fromXZ x z (TranslateBuilder config builder) =
    let
        y =
            Maybe.withDefault 0 (Maybe.map Translate.y config.start)
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromX : Float -> TranslateBuilder -> TranslateBuilder
fromX x (TranslateBuilder config builder) =
    let
        y =
            Maybe.withDefault 0 (Maybe.map Translate.y config.start)

        z =
            Maybe.withDefault 0 (Maybe.map Translate.z config.start)
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromYZ : Float -> Float -> TranslateBuilder -> TranslateBuilder
fromYZ y z (TranslateBuilder config builder) =
    let
        x =
            Maybe.withDefault 0 (Maybe.map Translate.x config.start)
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromY : Float -> TranslateBuilder -> TranslateBuilder
fromY y (TranslateBuilder config builder) =
    let
        x =
            Maybe.withDefault 0 (Maybe.map Translate.x config.start)

        z =
            Maybe.withDefault 0 (Maybe.map Translate.z config.start)
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromZ : Float -> TranslateBuilder -> TranslateBuilder
fromZ z (TranslateBuilder config builder) =
    let
        x =
            Maybe.withDefault 0 (Maybe.map Translate.x config.start)

        y =
            Maybe.withDefault 0 (Maybe.map Translate.y config.start)
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


to : Translate -> TranslateBuilder -> TranslateBuilder
to value (TranslateBuilder config builder) =
    let
        startVal =
            case config.start of
                Just s ->
                    s

                Nothing ->
                    Translate.default
    in
    TranslateBuilder
        { config
            | start = Just startVal
            , end = value
            , distance = Translate.distance startVal value
        }
        builder


toXYZ : Float -> Float -> Float -> TranslateBuilder -> TranslateBuilder
toXYZ x y z =
    to (Translate.fromTriple ( x, y, z ))


toXY : Float -> Float -> TranslateBuilder -> TranslateBuilder
toXY x y (TranslateBuilder config builder) =
    let
        z =
            Translate.z config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder


toXZ : Float -> Float -> TranslateBuilder -> TranslateBuilder
toXZ x z (TranslateBuilder config builder) =
    let
        y =
            Translate.y config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder


toX : Float -> TranslateBuilder -> TranslateBuilder
toX x (TranslateBuilder config builder) =
    let
        y =
            Translate.y config.end

        z =
            Translate.z config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder


toYZ : Float -> Float -> TranslateBuilder -> TranslateBuilder
toYZ y z (TranslateBuilder config builder) =
    let
        x =
            Translate.x config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder


toY : Float -> TranslateBuilder -> TranslateBuilder
toY y (TranslateBuilder config builder) =
    let
        x =
            Translate.x config.end

        z =
            Translate.z config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder


toZ : Float -> TranslateBuilder -> TranslateBuilder
toZ z (TranslateBuilder config builder) =
    let
        x =
            Translate.x config.end

        y =
            Translate.y config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder



-- BY (relative movement)


by : Translate -> TranslateBuilder -> TranslateBuilder
by delta (TranslateBuilder config builder) =
    let
        startVal =
            Maybe.withDefault Translate.default config.start

        endVal =
            Translate.fromTriple
                ( Translate.x startVal + Translate.x delta
                , Translate.y startVal + Translate.y delta
                , Translate.z startVal + Translate.z delta
                )
    in
    TranslateBuilder
        { config
            | start = Just startVal
            , end = endVal
            , distance = Translate.distance startVal endVal
        }
        builder


byXYZ : Float -> Float -> Float -> TranslateBuilder -> TranslateBuilder
byXYZ dx dy dz =
    by (Translate.fromTriple ( dx, dy, dz ))


byXY : Float -> Float -> TranslateBuilder -> TranslateBuilder
byXY dx dy =
    byXYZ dx dy 0


byXZ : Float -> Float -> TranslateBuilder -> TranslateBuilder
byXZ dx dz =
    byXYZ dx 0 dz


byX : Float -> TranslateBuilder -> TranslateBuilder
byX dx =
    byXYZ dx 0 0


byYZ : Float -> Float -> TranslateBuilder -> TranslateBuilder
byYZ dy dz =
    byXYZ 0 dy dz


byY : Float -> TranslateBuilder -> TranslateBuilder
byY dy =
    byXYZ 0 dy 0


byZ : Float -> TranslateBuilder -> TranslateBuilder
byZ dz =
    byXYZ 0 0 dz


delay : Int -> TranslateBuilder -> TranslateBuilder
delay delay_ (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.withDelay delay_ config) builder


duration : Int -> TranslateBuilder -> TranslateBuilder
duration ms (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.withDuration ms config) builder


speed : Float -> TranslateBuilder -> TranslateBuilder
speed value (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.withSpeed value config) builder


easing : Easing -> TranslateBuilder -> TranslateBuilder
easing easing_ (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.withEasing easing_ config) builder
