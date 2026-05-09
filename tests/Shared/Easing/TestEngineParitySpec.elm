module Shared.Easing.TestEngineParitySpec exposing (suite)

import Easing exposing (Easing(..))
import Expect
import Shared.Easing exposing (toFunction)
import Shared.Easing.Keyframes exposing (defaultKeyframeCount, generateKeyframes)
import Test exposing (..)


{-| The Sub and Keyframe engines call `toFunction`, the WAAPI engine
calls `generateKeyframes`. After the toFunction rewrite, sampling the
function at the keyframe positions must reproduce the keyframe array
exactly (it IS the keyframe array, interpolated linearly between
samples).
-}
suite : Test
suite =
    let
        durationMs =
            1000.0

        sampleAtKeyframePositions easing =
            let
                f =
                    toFunction durationMs easing

                count =
                    List.length (generateKeyframes easing durationMs)
            in
            List.range 0 (count - 1)
                |> List.map
                    (\i ->
                        f (toFloat i / toFloat (count - 1))
                    )

        check label easing =
            test label <|
                \_ ->
                    let
                        viaFunction =
                            sampleAtKeyframePositions easing
                                |> List.map (roundN 6)

                        viaKeyframes =
                            generateKeyframes easing durationMs
                                |> List.map (roundN 6)
                    in
                    Expect.equalLists viaFunction viaKeyframes

        advBounce =
            { bounces = 3, amplitude = 0.4, decay = 0.6 }

        advBounceInOut =
            { in_ = advBounce, out = advBounce }

        advElastic =
            { elasticity = 3.0, amplitude = 0.6, decay = 6.5 }

        advElasticInOut =
            { in_ = advElastic, out = advElastic }
    in
    describe "toFunction sampled at keyframe positions equals generateKeyframes"
        [ check "BounceOutCustom 0.5" (BounceOutCustom 0.5)
        , check "BounceInCustom 0.4" (BounceInCustom 0.4)
        , check "BounceInOutCustom (0.4, 0.6)" (BounceInOutCustom ( 0.4, 0.6 ))
        , check "BounceOutAdvanced" (BounceOutAdvanced advBounce)
        , check "BounceInAdvanced" (BounceInAdvanced advBounce)
        , check "BounceInOutAdvanced" (BounceInOutAdvanced advBounceInOut)
        , check "ElasticOutCustom 0.5" (ElasticOutCustom 0.5)
        , check "ElasticInCustom 0.4" (ElasticInCustom 0.4)
        , check "ElasticInOutCustom (0.4, 0.6)" (ElasticInOutCustom ( 0.4, 0.6 ))
        , check "ElasticOutAdvanced" (ElasticOutAdvanced advElastic)
        , check "ElasticInAdvanced" (ElasticInAdvanced advElastic)
        , check "ElasticInOutAdvanced" (ElasticInOutAdvanced advElasticInOut)
        ]


roundN : Int -> Float -> Float
roundN n x =
    let
        m =
            10.0 ^ toFloat n
    in
    toFloat (round (x * m)) / m
