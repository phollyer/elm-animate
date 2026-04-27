module Internal.Builder.TestPropertyBaselines exposing (suite)

import Anim.Internal.Builder.PropertyBaselines as Baselines
import Anim.Internal.Extra.Color as Color
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Translate as Translate
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Internal.Builder.PropertyBaselines"
        [ emptyTests
        , translateTests
        , rotateTests
        , scaleTests
        , opacityTests
        , sizeTests
        , colorTests
        , customPropertyTests
        , customColorPropertyTests
        , mergeTests
        ]



-- EMPTY


emptyTests : Test
emptyTests =
    describe "empty"
        [ test "getTranslate returns Nothing on empty" <|
            \_ ->
                Baselines.empty
                    |> Baselines.getTranslate
                    |> Expect.equal Nothing
        , test "getRotate returns Nothing on empty" <|
            \_ ->
                Baselines.empty
                    |> Baselines.getRotate
                    |> Expect.equal Nothing
        , test "getScale returns Nothing on empty" <|
            \_ ->
                Baselines.empty
                    |> Baselines.getScale
                    |> Expect.equal Nothing
        , test "getOpacity returns Nothing on empty" <|
            \_ ->
                Baselines.empty
                    |> Baselines.getOpacity
                    |> Expect.equal Nothing
        , test "getSize returns Nothing on empty" <|
            \_ ->
                Baselines.empty
                    |> Baselines.getSize
                    |> Expect.equal Nothing
        , test "getBackgroundColor returns Nothing on empty" <|
            \_ ->
                Baselines.empty
                    |> Baselines.getCustomColorProperty "background-color"
                    |> Expect.equal Nothing
        , test "getFontColor returns Nothing on empty" <|
            \_ ->
                Baselines.empty
                    |> Baselines.getCustomColorProperty "font-color"
                    |> Expect.equal Nothing
        , test "getCustomProperty returns Nothing on empty" <|
            \_ ->
                Baselines.empty
                    |> Baselines.getCustomProperty "anything"
                    |> Expect.equal Nothing
        , test "getCustomColorProperty returns Nothing on empty" <|
            \_ ->
                Baselines.empty
                    |> Baselines.getCustomColorProperty "anything"
                    |> Expect.equal Nothing
        ]



-- TRANSLATE


translateTests : Test
translateTests =
    describe "Translate baseline"
        [ test "set then get retrieves value" <|
            \_ ->
                let
                    t =
                        Translate.fromTriple ( 10, 20, 30 )
                in
                Baselines.empty
                    |> Baselines.setTranslate t
                    |> Baselines.getTranslate
                    |> Maybe.map Translate.toTriple
                    |> Expect.equal (Just ( 10, 20, 30 ))
        , test "overwrite replaces previous" <|
            \_ ->
                Baselines.empty
                    |> Baselines.setTranslate (Translate.fromTriple ( 1, 2, 3 ))
                    |> Baselines.setTranslate (Translate.fromTriple ( 4, 5, 6 ))
                    |> Baselines.getTranslate
                    |> Maybe.map Translate.toTriple
                    |> Expect.equal (Just ( 4, 5, 6 ))
        ]



-- ROTATE


rotateTests : Test
rotateTests =
    describe "Rotate baseline"
        [ test "set then get retrieves value" <|
            \_ ->
                let
                    r =
                        Rotate.fromTriple ( 45, 90, 180 )
                in
                Baselines.empty
                    |> Baselines.setRotate r
                    |> Baselines.getRotate
                    |> Maybe.map Rotate.toTriple
                    |> Expect.equal (Just ( 45, 90, 180 ))
        ]



-- SCALE


scaleTests : Test
scaleTests =
    describe "Scale baseline"
        [ test "set then get retrieves value" <|
            \_ ->
                let
                    s =
                        Scale.fromTriple ( 2, 3, 4 )
                in
                Baselines.empty
                    |> Baselines.setScale s
                    |> Baselines.getScale
                    |> Maybe.map Scale.toTriple
                    |> Expect.equal (Just ( 2, 3, 4 ))
        ]



-- OPACITY


opacityTests : Test
opacityTests =
    describe "Opacity baseline"
        [ test "set then get retrieves value" <|
            \_ ->
                let
                    o =
                        Opacity.fromFloat 0.5
                in
                Baselines.empty
                    |> Baselines.setOpacity o
                    |> Baselines.getOpacity
                    |> Maybe.map Opacity.toFloat
                    |> Expect.equal (Just 0.5)
        ]



-- SIZE


sizeTests : Test
sizeTests =
    describe "Size baseline"
        [ test "set then get retrieves value" <|
            \_ ->
                let
                    s =
                        Size.fromTuple ( 100, 200 )
                in
                Baselines.empty
                    |> Baselines.setSize s
                    |> Baselines.getSize
                    |> Maybe.map Size.toTuple
                    |> Expect.equal (Just ( 100, 200 ))
        ]



-- COLOR


colorTests : Test
colorTests =
    describe "Color baselines"
        [ test "setBackgroundColor then get retrieves value" <|
            \_ ->
                Baselines.empty
                    |> Baselines.setCustomColorProperty "background-color" (Color.Hex "#ff0000")
                    |> Baselines.getCustomColorProperty "background-color"
                    |> Expect.equal (Just (Color.Hex "#ff0000"))
        , test "setFontColor then get retrieves value" <|
            \_ ->
                Baselines.empty
                    |> Baselines.setCustomColorProperty "color" (Color.Hex "#00ff00")
                    |> Baselines.getCustomColorProperty "color"
                    |> Expect.equal (Just (Color.Hex "#00ff00"))
        , test "backgroundColor and fontColor are independent" <|
            \_ ->
                Baselines.empty
                    |> Baselines.setCustomColorProperty "background-color" (Color.Hex "#ff0000")
                    |> Baselines.setCustomColorProperty "color" (Color.Hex "#0000ff")
                    |> Baselines.getCustomColorProperty "background-color"
                    |> Expect.equal (Just (Color.Hex "#ff0000"))
        ]



-- CUSTOM PROPERTY


customPropertyTests : Test
customPropertyTests =
    describe "Custom property baselines"
        [ test "set then get retrieves value" <|
            \_ ->
                Baselines.empty
                    |> Baselines.setCustomProperty "border-radius" 10 "px"
                    |> Baselines.getCustomProperty "border-radius"
                    |> Expect.equal (Just 10)
        , test "different names are independent" <|
            \_ ->
                Baselines.empty
                    |> Baselines.setCustomProperty "padding" 20 "px"
                    |> Baselines.setCustomProperty "margin" 30 "px"
                    |> Baselines.getCustomProperty "padding"
                    |> Expect.equal (Just 20)
        , test "wrong name returns Nothing" <|
            \_ ->
                Baselines.empty
                    |> Baselines.setCustomProperty "padding" 20 "px"
                    |> Baselines.getCustomProperty "margin"
                    |> Expect.equal Nothing
        , test "getAllCustomProperties returns full CSS value with unit" <|
            \_ ->
                Baselines.empty
                    |> Baselines.setCustomProperty "--my-var" 50 "px"
                    |> Baselines.getAllCustomProperties
                    |> Expect.equal [ ( "--my-var", "50px" ) ]
        ]



-- CUSTOM COLOR PROPERTY


customColorPropertyTests : Test
customColorPropertyTests =
    describe "Custom color property baselines"
        [ test "set then get retrieves value" <|
            \_ ->
                Baselines.empty
                    |> Baselines.setCustomColorProperty "border-color" (Color.Hex "#abc")
                    |> Baselines.getCustomColorProperty "border-color"
                    |> Expect.equal (Just (Color.Hex "#abc"))
        , test "custom and customColor are independent namespaces" <|
            \_ ->
                -- A custom numeric and custom color with same CSS name don't clash
                Baselines.empty
                    |> Baselines.setCustomProperty "my-prop" 42 ""
                    |> Baselines.setCustomColorProperty "my-prop" (Color.Hex "#fff")
                    |> Baselines.getCustomProperty "my-prop"
                    |> Expect.equal (Just 42)
        ]



-- MERGE


mergeTests : Test
mergeTests =
    describe "merge"
        [ test "override wins on conflict" <|
            \_ ->
                let
                    base =
                        Baselines.empty
                            |> Baselines.setTranslate (Translate.fromTriple ( 1, 1, 1 ))

                    override =
                        Baselines.empty
                            |> Baselines.setTranslate (Translate.fromTriple ( 9, 9, 9 ))
                in
                Baselines.merge base override
                    |> Baselines.getTranslate
                    |> Maybe.map Translate.toTriple
                    |> Expect.equal (Just ( 9, 9, 9 ))
        , test "non-conflicting properties are preserved" <|
            \_ ->
                let
                    base =
                        Baselines.empty
                            |> Baselines.setTranslate (Translate.fromTriple ( 1, 2, 3 ))

                    override =
                        Baselines.empty
                            |> Baselines.setScale (Scale.fromTriple ( 2, 2, 2 ))
                in
                Baselines.merge base override
                    |> Baselines.getTranslate
                    |> Maybe.map Translate.toTriple
                    |> Expect.equal (Just ( 1, 2, 3 ))
        , test "merge empty with populated returns populated" <|
            \_ ->
                let
                    populated =
                        Baselines.empty
                            |> Baselines.setOpacity (Opacity.fromFloat 0.8)
                in
                Baselines.merge Baselines.empty populated
                    |> Baselines.getOpacity
                    |> Maybe.map Opacity.toFloat
                    |> Expect.equal (Just 0.8)
        ]
