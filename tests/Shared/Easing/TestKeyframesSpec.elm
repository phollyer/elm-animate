module Shared.Easing.TestKeyframesSpec exposing (suite)

import Easing exposing (Easing(..))
import Expect
import Shared.Easing.Keyframes exposing (generateKeyframes)
import Test exposing (..)


suite : Test
suite =
    describe "Shared.Easing.Keyframes.generateKeyframes"
        [ test "fingerprints" <|
            \_ ->
                let
                    fp easing duration =
                        let
                            xs =
                                generateKeyframes easing duration

                            len =
                                List.length xs

                            first =
                                List.head xs |> Maybe.withDefault -999

                            last =
                                List.reverse xs |> List.head |> Maybe.withDefault -999

                            sumX10000 =
                                xs |> List.sum |> (*) 10000 |> round
                        in
                        ( len, ( roundN 6 first, roundN 6 last ), sumX10000 )

                    advParamsBounce =
                        { bounces = 4, amplitude = 0.5, decay = 0.6 }

                    advParamsElastic =
                        { elasticity = 3, amplitude = 0.5, decay = 6 }

                    advBounceInOut =
                        { in_ = advParamsBounce, out = advParamsBounce }

                    advElasticInOut =
                        { in_ = advParamsElastic, out = advParamsElastic }
                in
                Expect.equalLists
                    [ fp (BounceOutCustom 0.5) 1000
                    , fp (BounceInCustom 0.5) 1000
                    , fp (BounceInOutCustom ( 0.5, 0.5 )) 1000
                    , fp (BounceOutAdvanced advParamsBounce) 1000
                    , fp (BounceInAdvanced advParamsBounce) 1000
                    , fp (BounceInOutAdvanced advBounceInOut) 1000
                    , fp (ElasticOutCustom 0.5) 1000
                    , fp (ElasticInCustom 0.5) 1000
                    , fp (ElasticInOutCustom ( 0.5, 0.5 )) 1000
                    , fp (ElasticOutAdvanced advParamsElastic) 1000
                    , fp (ElasticInAdvanced advParamsElastic) 1000
                    , fp (ElasticInOutAdvanced advElasticInOut) 1000
                    , fp Linear 1000
                    , fp QuadIn 1000
                    , fp (BounceOutCustom 0.8) 500
                    , fp (ElasticInCustom 0.3) 2000
                    ]
                    [ ( 63, ( 0, 1 ), 354332 )
                    , ( 63, ( 0, 1 ), 275668 )
                    , ( 75, ( 0, 1 ), 375000 )
                    , ( 83, ( 0, 1 ), 491792 )
                    , ( 83, ( 0, 1 ), 338208 )
                    , ( 114, ( 0, 1 ), 570000 )
                    , ( 272, ( 0, 1 ), 2301939 )
                    , ( 272, ( 0, 1 ), 418061 )
                    , ( 1508, ( 0, 1 ), 7540000 )
                    , ( 242, ( 0, 1 ), 2222370 )
                    , ( 272, ( 0, 1 ), 437688 )
                    , ( 1028, ( 0, 1 ), 5140000 )
                    , ( 30, ( 0, 1 ), 150000 )
                    , ( 30, ( 0, 1 ), 101724 )
                    , ( 56, ( 0, 1 ), 310115 )
                    , ( 332, ( 0, 1 ), 931748 )
                    ]
        ]


roundN : Int -> Float -> Float
roundN n x =
    let
        factor =
            10 ^ n |> toFloat
    in
    toFloat (round (x * factor)) / factor
