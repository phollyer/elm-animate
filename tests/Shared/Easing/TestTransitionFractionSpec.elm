module Shared.Easing.TestTransitionFractionSpec exposing (suite)

import Easing exposing (Easing(..))
import Expect
import Shared.Easing exposing (transitionFractionOf)
import Test exposing (..)


suite : Test
suite =
    describe "Shared.Easing.transitionFractionOf"
        [ describe "simple easings return 1.0"
            [ test "Linear" <|
                \_ -> transitionFractionOf Linear |> Expect.within (Expect.Absolute 0.0001) 1.0
            , test "QuadIn" <|
                \_ -> transitionFractionOf QuadIn |> Expect.within (Expect.Absolute 0.0001) 1.0
            , test "CubicBezier" <|
                \_ -> transitionFractionOf (CubicBezier 0.25 0.1 0.25 1.0) |> Expect.within (Expect.Absolute 0.0001) 1.0
            , test "BackOutCustom (algebraic, no bounces)" <|
                \_ -> transitionFractionOf (BackOutCustom 1.5) |> Expect.within (Expect.Absolute 0.0001) 1.0
            , test "ElasticOut (built-in, not Custom)" <|
                \_ -> transitionFractionOf ElasticOut |> Expect.within (Expect.Absolute 0.0001) 1.0
            ]
        , describe "BounceCustom physics: 1 / (1 + 2 * sum(cor^n))"
            -- strength 0.2: clamped 0.2, cor = 0.5 + 0.05 = 0.55,
            --   firstAmp = 0.15 + 0.04*0.75 = 0.18,
            --   visibleBounces: 0.18, 0.0545, 0.0165 -> 0.005 < 0.02 stops, count = 2
            --   sum = 0.55 + 0.55^2 = 0.8525, fraction = 1/(1 + 1.705) = 0.3697
            [ test "BounceOutCustom 0.2 -> ~0.37" <|
                \_ -> transitionFractionOf (BounceOutCustom 0.2) |> Expect.within (Expect.Absolute 0.005) 0.37

            -- strength 0.5: cor = 0.625, firstAmp = 0.3375
            --   bounces 0.3375 -> 0.132 -> 0.052 -> 0.020 (>= 0.02) -> count = 4
            --   sum = 0.625 + 0.391 + 0.244 + 0.153 = 1.413
            --   fraction = 1/(1 + 2.825) = 0.2614
            , test "BounceOutCustom 0.5 -> ~0.26" <|
                \_ -> transitionFractionOf (BounceOutCustom 0.5) |> Expect.within (Expect.Absolute 0.005) 0.26

            -- BounceIn uses same fraction as BounceOut for the same strength
            , test "BounceInCustom 0.5 == BounceOutCustom 0.5" <|
                \_ ->
                    Expect.within (Expect.Absolute 0.0001)
                        (transitionFractionOf (BounceOutCustom 0.5))
                        (transitionFractionOf (BounceInCustom 0.5))

            -- strength clamps to 0.1 below
            , test "BounceOutCustom 0 clamps to 0.1" <|
                \_ ->
                    Expect.within (Expect.Absolute 0.0001)
                        (transitionFractionOf (BounceOutCustom 0))
                        (transitionFractionOf (BounceOutCustom 0.1))

            -- strength clamps to 1.0 above
            , test "BounceOutCustom 5 clamps to 1.0" <|
                \_ ->
                    Expect.within (Expect.Absolute 0.0001)
                        (transitionFractionOf (BounceOutCustom 5))
                        (transitionFractionOf (BounceOutCustom 1.0))
            ]
        , describe "BounceAdvanced uses effective cor = 2^(-decay/2)"
            -- decay 1.0 -> cor = 2^-0.5 = 0.7071, with bounces=4
            -- sum = 0.707 + 0.5 + 0.354 + 0.25 = 1.811, fraction = 1/(1 + 3.621) = 0.216
            [ test "decay=1, bounces=4 -> ~0.22" <|
                \_ ->
                    transitionFractionOf
                        (BounceOutAdvanced { bounces = 4, amplitude = 0.5, decay = 1.0 })
                        |> Expect.within (Expect.Absolute 0.005) 0.22

            -- decay 4 -> cor = 2^-2 = 0.25, with bounces=4
            -- sum = 0.25 + 0.0625 + 0.0156 + 0.0039 = 0.332
            -- fraction = 1/(1 + 0.664) = 0.601
            , test "decay=4, bounces=4 -> ~0.60 (high decay, less extension)" <|
                \_ ->
                    transitionFractionOf
                        (BounceOutAdvanced { bounces = 4, amplitude = 0.5, decay = 4.0 })
                        |> Expect.within (Expect.Absolute 0.005) 0.601
            ]
        , describe "ElasticCustom physics: decay / (decay + log2(100))"
            -- log2(100) ~= 6.6438
            -- strength 0.2: decay = 6 + 0.4 = 6.4, fraction = 6.4/13.04 = 0.491
            [ test "ElasticOutCustom 0.2 -> ~0.49" <|
                \_ -> transitionFractionOf (ElasticOutCustom 0.2) |> Expect.within (Expect.Absolute 0.005) 0.49

            -- strength 0.5: decay = 7.0, fraction = 7/13.64 = 0.513
            , test "ElasticOutCustom 0.5 -> ~0.51" <|
                \_ -> transitionFractionOf (ElasticOutCustom 0.5) |> Expect.within (Expect.Absolute 0.005) 0.51

            -- strength 1.0: decay = 8.0, fraction = 8/14.64 = 0.546
            , test "ElasticOutCustom 1.0 -> ~0.55" <|
                \_ -> transitionFractionOf (ElasticOutCustom 1.0) |> Expect.within (Expect.Absolute 0.005) 0.55

            -- ElasticIn matches ElasticOut for the same strength
            , test "ElasticInCustom 0.5 == ElasticOutCustom 0.5" <|
                \_ ->
                    Expect.within (Expect.Absolute 0.0001)
                        (transitionFractionOf (ElasticOutCustom 0.5))
                        (transitionFractionOf (ElasticInCustom 0.5))
            ]
        , describe "ElasticAdvanced uses decay parameter directly"
            [ test "decay=6 -> ~0.475" <|
                \_ ->
                    transitionFractionOf
                        (ElasticOutAdvanced { elasticity = 3, amplitude = 0.5, decay = 6.0 })
                        |> Expect.within (Expect.Absolute 0.005) 0.475
            , test "decay=10 -> ~0.601" <|
                \_ ->
                    transitionFractionOf
                        (ElasticOutAdvanced { elasticity = 3, amplitude = 0.5, decay = 10.0 })
                        |> Expect.within (Expect.Absolute 0.005) 0.601
            ]
        , describe "InOut variants combine both halves"
            -- For BounceInOutCustom (0.5, 0.5): each half has fraction 0.2614
            -- inExtension = (1-0.2614)/0.2614 = 2.825
            -- combined = 1/(1 + 2*2.825) = 1/6.65 = 0.150
            [ test "BounceInOutCustom (0.5, 0.5) -> ~0.150" <|
                \_ ->
                    transitionFractionOf (BounceInOutCustom ( 0.5, 0.5 ))
                        |> Expect.within (Expect.Absolute 0.005) 0.150

            -- Asymmetric strengths: same total as the average of two pure halves' extensions.
            , test "BounceInOutCustom asymmetric is between the two pure variants" <|
                \_ ->
                    let
                        f =
                            transitionFractionOf (BounceInOutCustom ( 0.2, 0.8 ))
                    in
                    -- Bounded between weakest and strongest single-half pairings
                    Expect.all
                        [ \v -> v |> Expect.lessThan (transitionFractionOf (BounceInOutCustom ( 0.2, 0.2 )))
                        , \v -> v |> Expect.greaterThan (transitionFractionOf (BounceInOutCustom ( 0.8, 0.8 )))
                        ]
                        f
            ]
        , describe "all fractions are in (0, 1] for reasonable inputs"
            [ test "every Custom variant returns a finite fraction in (0, 1]" <|
                \_ ->
                    let
                        fractions =
                            [ transitionFractionOf (BounceOutCustom 0.5)
                            , transitionFractionOf (BounceInCustom 0.5)
                            , transitionFractionOf (BounceInOutCustom ( 0.5, 0.5 ))
                            , transitionFractionOf (ElasticOutCustom 0.5)
                            , transitionFractionOf (ElasticInCustom 0.5)
                            , transitionFractionOf (ElasticInOutCustom ( 0.5, 0.5 ))
                            ]

                        allValid =
                            List.all (\f -> f > 0 && f <= 1.0 && not (isNaN f)) fractions
                    in
                    Expect.equal True allValid
            ]
        ]
