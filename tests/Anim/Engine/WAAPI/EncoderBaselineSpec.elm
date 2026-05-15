module Anim.Engine.WAAPI.EncoderBaselineSpec exposing (suite)

{-| Tests for the `transformBaseline` field in the WAAPI animate port
payload.

When a transform sub-property begins animating, ownership of the
inline `transform` style flips from Elm to JS. JS needs Elm's
current snapshot of init/baseline transform values so that
init-only properties (e.g. `Translate.initZ animGroup 200`) survive
the handover instead of being silently defaulted to identity by a
DOM read of the now-empty inline transform.

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.WAAPI.AnimGroup as AnimGroup
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Translate as Translate
import Anim.Property.Rotate as Rotate
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Encoder transformBaseline"
        [ test "includes translate baseline when snapshot has translate set" <|
            \_ ->
                let
                    snapshot =
                        PropertyBaselines.empty
                            |> PropertyBaselines.setTranslate (Translate.fromTriple ( 0, 0, 200 ))

                    animGroups =
                        AnimGroups.init
                            |> AnimGroups.insert "cube"
                                (AnimGroup.init |> AnimGroup.setSnapshot snapshot)

                    processed =
                        Builder.init [ rotateBuilder ] |> Builder.process

                    json =
                        Encoder.encode animGroups processed |> Encode.encode 0
                in
                json
                    |> decodeBaselineTranslateZ "cube"
                    |> Expect.equal (Just 200)
        , test "includes scale baseline when snapshot has scale set" <|
            \_ ->
                let
                    snapshot =
                        PropertyBaselines.empty
                            |> PropertyBaselines.setScale (Scale.fromTriple ( 1.5, 1.5, 1.5 ))

                    animGroups =
                        AnimGroups.init
                            |> AnimGroups.insert "cube"
                                (AnimGroup.init |> AnimGroup.setSnapshot snapshot)

                    processed =
                        Builder.init [ rotateBuilder ] |> Builder.process

                    json =
                        Encoder.encode animGroups processed |> Encode.encode 0
                in
                json
                    |> decodeBaselineScaleX "cube"
                    |> Expect.equal (Just 1.5)
        , test "omits transformBaseline when snapshot has no transform values" <|
            \_ ->
                let
                    animGroups =
                        AnimGroups.init
                            |> AnimGroups.insert "cube"
                                (AnimGroup.init |> AnimGroup.setSnapshot PropertyBaselines.empty)

                    processed =
                        Builder.init [ rotateBuilder ] |> Builder.process

                    json =
                        Encoder.encode animGroups processed |> Encode.encode 0
                in
                json
                    |> decodeHasBaseline "cube"
                    |> Expect.equal False
        , test "combines translate and scale baselines together" <|
            \_ ->
                let
                    snapshot =
                        PropertyBaselines.empty
                            |> PropertyBaselines.setTranslate (Translate.fromTriple ( 10, 20, 200 ))
                            |> PropertyBaselines.setScale (Scale.fromTriple ( 2, 2, 2 ))

                    animGroups =
                        AnimGroups.init
                            |> AnimGroups.insert "cube"
                                (AnimGroup.init |> AnimGroup.setSnapshot snapshot)

                    processed =
                        Builder.init [ rotateBuilder ] |> Builder.process

                    json =
                        Encoder.encode animGroups processed |> Encode.encode 0
                in
                ( decodeBaselineTranslateZ "cube" json
                , decodeBaselineScaleX "cube" json
                )
                    |> Expect.equal ( Just 200, Just 2 )
        ]



-- HELPERS


rotateBuilder : Builder.AnimBuilder mode -> Builder.AnimBuilder mode
rotateBuilder =
    Rotate.for "cube"
        >> Rotate.toZ 90
        >> Rotate.duration 200
        >> Rotate.build


elementsField : String -> Decode.Decoder a -> Decode.Decoder a
elementsField animGroupName inner =
    Decode.at [ "elements", animGroupName ] inner


decodeBaselineTranslateZ : String -> String -> Maybe Float
decodeBaselineTranslateZ animGroupName json =
    Decode.decodeString
        (elementsField animGroupName
            (Decode.at [ "transformBaseline", "translate", "z" ] Decode.float)
        )
        json
        |> Result.toMaybe


decodeBaselineScaleX : String -> String -> Maybe Float
decodeBaselineScaleX animGroupName json =
    Decode.decodeString
        (elementsField animGroupName
            (Decode.at [ "transformBaseline", "scale", "x" ] Decode.float)
        )
        json
        |> Result.toMaybe


decodeHasBaseline : String -> String -> Bool
decodeHasBaseline animGroupName json =
    Decode.decodeString
        (elementsField animGroupName
            (Decode.maybe (Decode.field "transformBaseline" Decode.value))
        )
        json
        |> Result.toMaybe
        |> Maybe.withDefault Nothing
        |> (\m ->
                case m of
                    Just _ ->
                        True

                    Nothing ->
                        False
           )
