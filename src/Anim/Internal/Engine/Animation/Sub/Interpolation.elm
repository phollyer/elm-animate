module Anim.Internal.Engine.Animation.Sub.Interpolation exposing
    ( calculateProgress
    , interpolateEasedProgress
    , interpolateFloat
    , interpolateOpacity
    , interpolateRotate
    , interpolateScale
    , interpolateSize
    , interpolateTranslate
    , interpolateTriple
    , interpolateTuple
    )

import Anim.Internal.Engine.Animation.Sub.Animation exposing (PropertyAnimation)
import Anim.Internal.PropertyBuilder.Opacity as Opacity exposing (Opacity)
import Anim.Internal.PropertyBuilder.Rotate as Rotate exposing (Rotate)
import Anim.Internal.PropertyBuilder.Scale as Scale exposing (Scale)
import Anim.Internal.PropertyBuilder.Size as Size exposing (Size)
import Anim.Internal.PropertyBuilder.Translate as Translate exposing (Translate)



-- ============================================================
-- PROGRESS
-- ============================================================


calculateProgress : { a | elapsedMs : Float, delayMs : Float, totalDurationMs : Float, isComplete : Bool } -> Float
calculateProgress timing =
    if timing.isComplete || timing.totalDurationMs <= 0 then
        1.0

    else
        let
            animationElapsedMs =
                max 0 (timing.elapsedMs - timing.delayMs)
        in
        if animationElapsedMs <= 0 then
            0.0

        else
            min 1.0 (animationElapsedMs / timing.totalDurationMs)



-- ============================================================
-- CORE INTERPOLATION
-- ============================================================


interpolateEasedProgress : (Float -> a -> a -> a) -> PropertyAnimation a -> a
interpolateEasedProgress interpolate anim =
    let
        easedProgress =
            anim.easingFunction (calculateProgress anim)
    in
    interpolate easedProgress anim.start anim.end


interpolateFloat : Float -> Float -> Float -> Float
interpolateFloat t start end =
    start + (end - start) * t


interpolateTriple : (a -> ( Float, Float, Float )) -> (( Float, Float, Float ) -> a) -> Float -> a -> a -> a
interpolateTriple toTriple fromTriple t start end =
    let
        ( s1, s2, s3 ) =
            toTriple start

        ( e1, e2, e3 ) =
            toTriple end
    in
    fromTriple ( interpolateFloat t s1 e1, interpolateFloat t s2 e2, interpolateFloat t s3 e3 )


interpolateTuple : (a -> ( Float, Float )) -> (( Float, Float ) -> a) -> Float -> a -> a -> a
interpolateTuple toTuple fromTuple t start end =
    let
        ( s1, s2 ) =
            toTuple start

        ( e1, e2 ) =
            toTuple end
    in
    fromTuple ( interpolateFloat t s1 e1, interpolateFloat t s2 e2 )



-- ============================================================
-- PROPERTY INTERPOLATION
-- ============================================================


interpolateOpacity : Float -> Opacity -> Opacity -> Opacity
interpolateOpacity t start end =
    Opacity.fromFloat (interpolateFloat t (Opacity.toFloat start) (Opacity.toFloat end))


interpolateRotate : Float -> Rotate -> Rotate -> Rotate
interpolateRotate =
    interpolateTriple Rotate.toTriple Rotate.fromTriple


interpolateScale : Float -> Scale -> Scale -> Scale
interpolateScale =
    interpolateTriple Scale.toTriple Scale.fromTriple


interpolateSize : Float -> Size -> Size -> Size
interpolateSize =
    interpolateTuple Size.toTuple Size.fromTuple


interpolateTranslate : Float -> Translate -> Translate -> Translate
interpolateTranslate =
    interpolateTriple Translate.toTriple Translate.fromTriple
