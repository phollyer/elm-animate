module Internal.Builder.TestProperty exposing (suite)

import Anim.Extra.Color as Color
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.Property as Property
import Anim.Internal.Property.Opacity as InternalOpacity
import Anim.Internal.Property.Translate as InternalTranslate
import Anim.Property.CustomColor as CustomColor exposing (ColorProperty(..))
import Anim.Property.Opacity as Opacity
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Easing exposing (Easing(..))
import Expect
import Shared.TimeSpec exposing (TimeSpec(..))
import Test exposing (..)


animBuilder : Builder.AnimBuilder
animBuilder =
    Builder.init []


processAndStore : Builder.AnimBuilder -> Builder.AnimBuilder
processAndStore builder =
    Builder.addAnimationToHistory (Builder.process builder) builder


suite : Test
suite =
    describe "Internal.Builder.Property"
        [ defaultConfigTests
        , withTests
        , upsertTests
        , propertyGetters
        ]



-- ============================================================
-- defaultConfig
-- ============================================================


defaultConfigTests : Test
defaultConfigTests =
    describe "defaultConfig"
        [ test "creates a config with the given end value and Nothing for everything else" <|
            \_ ->
                let
                    config =
                        Property.defaultConfig 42
                in
                Expect.all
                    [ \c -> Expect.equal Nothing c.start
                    , \c -> Expect.equal 42 c.end
                    , \c -> Expect.equal 0 c.distance
                    , \c -> Expect.equal Nothing c.timing
                    , \c -> Expect.equal Nothing c.delay
                    , \c -> Expect.equal Nothing c.easing
                    ]
                    config
        ]



-- ============================================================
-- with* functions
-- ============================================================


withTests : Test
withTests =
    describe "with* config modifiers"
        [ test "withSpeed sets timing to Speed" <|
            \_ ->
                Property.defaultConfig 0
                    |> Property.speed 150
                    |> .timing
                    |> Expect.equal (Just (Speed 150))
        , test "withDuration sets timing to Duration" <|
            \_ ->
                Property.defaultConfig 0
                    |> Property.duration 500
                    |> .timing
                    |> Expect.equal (Just (Duration 500))
        , test "withEasing sets easing" <|
            \_ ->
                Property.defaultConfig 0
                    |> Property.easing CubicInOut
                    |> .easing
                    |> Expect.equal (Just CubicInOut)
        , test "withDelay sets delay" <|
            \_ ->
                Property.defaultConfig 0
                    |> Property.delay 200
                    |> .delay
                    |> Expect.equal (Just 200)
        , test "withSpeed overwrites previous timing" <|
            \_ ->
                Property.defaultConfig 0
                    |> Property.duration 500
                    |> Property.speed 100
                    |> .timing
                    |> Expect.equal (Just (Speed 100))
        , test "duration overwrites previous timing" <|
            \_ ->
                Property.defaultConfig 0
                    |> Property.speed 100
                    |> Property.duration 300
                    |> .timing
                    |> Expect.equal (Just (Duration 300))
        ]



-- ============================================================
-- upsert
-- ============================================================


upsertTests : Test
upsertTests =
    let
        translateConfig =
            Builder.TranslateConfig
                { start = Nothing
                , end = InternalTranslate.fromTriple ( 10, 20, 0 )
                , distance = 0
                , timing = Nothing
                , easing = Nothing
                , delay = Nothing
                }

        opacityConfig =
            Builder.OpacityConfig
                { start = Nothing
                , end = InternalOpacity.fromFloat 0.5
                , distance = 0
                , timing = Nothing
                , easing = Nothing
                , delay = Nothing
                }

        replacementTranslateConfig =
            Builder.TranslateConfig
                { start = Nothing
                , end = InternalTranslate.fromTriple ( 100, 200, 300 )
                , distance = 0
                , timing = Nothing
                , easing = Nothing
                , delay = Nothing
                }

        getProperties builder =
            (Builder.getCurrentAnimGroupConfig builder).properties
    in
    describe "upsert"
        [ test "adds a property when none of that type exists" <|
            \_ ->
                animBuilder
                    |> Builder.for "test"
                    |> Property.upsert translateConfig
                    |> getProperties
                    |> List.length
                    |> Expect.equal 1
        , test "adds different property types" <|
            \_ ->
                animBuilder
                    |> Builder.for "test"
                    |> Property.upsert translateConfig
                    |> Property.upsert opacityConfig
                    |> getProperties
                    |> List.length
                    |> Expect.equal 2
        , test "replaces an existing property of the same type" <|
            \_ ->
                animBuilder
                    |> Builder.for "test"
                    |> Property.upsert translateConfig
                    |> Property.upsert replacementTranslateConfig
                    |> getProperties
                    |> List.length
                    |> Expect.equal 1
        , test "replacement uses the new config values" <|
            \_ ->
                animBuilder
                    |> Builder.for "test"
                    |> Property.upsert translateConfig
                    |> Property.upsert replacementTranslateConfig
                    |> getProperties
                    |> List.head
                    |> Expect.equal (Just replacementTranslateConfig)
        , test "does not affect other property types when replacing" <|
            \_ ->
                animBuilder
                    |> Builder.for "test"
                    |> Property.upsert translateConfig
                    |> Property.upsert opacityConfig
                    |> Property.upsert replacementTranslateConfig
                    |> getProperties
                    |> List.length
                    |> Expect.equal 2
        ]



-- ============================================================
-- property getters
-- ============================================================


propertyGetters : Test
propertyGetters =
    describe "Property getters"
        [ getStartValue
        , getEndValue
        , getRangeValue
        ]


type alias GetStartTestConfig a =
    { label : String
    , getter : String -> Builder.AnimBuilder -> Maybe a
    , buildWithFrom : Builder.AnimBuilder -> Builder.AnimBuilder
    , expectedFrom : a
    , buildWithoutFrom : Builder.AnimBuilder -> Builder.AnimBuilder
    , expectedDefault : a
    }


getStartTests : GetStartTestConfig a -> Test
getStartTests config =
    describe config.label
        [ test "returns the start value when explicitly set" <|
            \_ ->
                animBuilder
                    |> config.buildWithFrom
                    |> processAndStore
                    |> config.getter "test"
                    |> Expect.equal (Just config.expectedFrom)
        , test "returns the default if there is no explicit start value" <|
            \_ ->
                animBuilder
                    |> config.buildWithoutFrom
                    |> processAndStore
                    |> config.getter "test"
                    |> Expect.equal (Just config.expectedDefault)
        , test "returns Nothing if there is no animation" <|
            \_ ->
                animBuilder
                    |> processAndStore
                    |> config.getter "test"
                    |> Expect.equal Nothing
        ]


getStartValue : Test
getStartValue =
    describe "Get the start value of a property"
        [ getStartTests
            { label = "getBackgroundColorStart"
            , buildWithFrom =
                CustomColor.for "test" BackgroundColor
                    >> CustomColor.from (Color.rgba 100 200 50 1)
                    >> CustomColor.to Color.red
                    >> CustomColor.build
            , buildWithoutFrom =
                CustomColor.for "test" BackgroundColor
                    >> CustomColor.to Color.red
                    >> CustomColor.build
            , getter = \animGroup builder -> Property.getCustomColorPropertyStart animGroup "background-color" builder
            , expectedFrom = Color.rgba 100 200 50 1
            , expectedDefault = Color.rgba 255 255 255 0
            }
        , getStartTests
            { label = "getFontColorStart"
            , getter = \animGroup builder -> Property.getCustomColorPropertyStart animGroup "color" builder
            , buildWithFrom =
                CustomColor.for "test" TextColor
                    >> CustomColor.from (Color.rgba 100 200 50 1)
                    >> CustomColor.to Color.red
                    >> CustomColor.build
            , expectedFrom = Color.rgba 100 200 50 1
            , buildWithoutFrom =
                CustomColor.for "test" TextColor
                    >> CustomColor.to Color.red
                    >> CustomColor.build
            , expectedDefault = Color.rgba 255 255 255 0
            }
        , getStartTests
            { label = "getOpacityStart"
            , buildWithFrom =
                Opacity.for "test"
                    >> Opacity.from 0.5
                    >> Opacity.to 0
                    >> Opacity.build
            , buildWithoutFrom =
                Opacity.for "test"
                    >> Opacity.to 0
                    >> Opacity.build
            , getter = Property.getOpacityStart
            , expectedFrom = 0.5
            , expectedDefault = 1.0
            }
        , getStartTests
            { label = "getRotateStart"
            , buildWithFrom =
                Rotate.for "test"
                    >> Rotate.fromXYZ 10 20 30
                    >> Rotate.toXYZ 100 200 300
                    >> Rotate.build
            , buildWithoutFrom =
                Rotate.for "test"
                    >> Rotate.toXYZ 100 200 300
                    >> Rotate.build
            , getter = Property.getRotateStart
            , expectedFrom = { x = 10, y = 20, z = 30 }
            , expectedDefault = { x = 0, y = 0, z = 0 }
            }
        , getStartTests
            { label = "getScaleStart"
            , buildWithFrom =
                Scale.for "test"
                    >> Scale.fromXYZ 2 3 4
                    >> Scale.toXYZ 5 6 7
                    >> Scale.build
            , buildWithoutFrom =
                Scale.for "test"
                    >> Scale.toXYZ 5 6 7
                    >> Scale.build
            , getter = Property.getScaleStart
            , expectedFrom = { x = 2, y = 3, z = 4 }
            , expectedDefault = { x = 1, y = 1, z = 1 }
            }
        , getStartTests
            { label = "getSizeStart"
            , buildWithFrom =
                Size.for "test"
                    >> Size.fromHW 50 100
                    >> Size.toHW 200 300
                    >> Size.build
            , buildWithoutFrom =
                Size.for "test"
                    >> Size.toHW 200 300
                    >> Size.build
            , getter = Property.getSizeStart
            , expectedFrom = { width = 100, height = 50 }
            , expectedDefault = { width = 0, height = 0 }
            }
        , getStartTests
            { label = "getTranslateStart"
            , buildWithFrom =
                Translate.for "test"
                    >> Translate.fromXYZ 10 20 30
                    >> Translate.toXYZ 100 200 300
                    >> Translate.build
            , buildWithoutFrom =
                Translate.for "test"
                    >> Translate.toXYZ 100 200 300
                    >> Translate.build
            , getter = Property.getTranslateStart
            , expectedFrom = { x = 10, y = 20, z = 30 }
            , expectedDefault = { x = 0, y = 0, z = 0 }
            }
        ]


type alias GetEndTestConfig a =
    { label : String
    , getter : String -> Builder.AnimBuilder -> Maybe a
    , build : Builder.AnimBuilder -> Builder.AnimBuilder
    , expectedEnd : a
    }


getEndTests : GetEndTestConfig a -> Test
getEndTests config =
    describe config.label
        [ test "returns the end value" <|
            \_ ->
                animBuilder
                    |> config.build
                    |> processAndStore
                    |> config.getter "test"
                    |> Expect.equal (Just config.expectedEnd)
        , test "returns Nothing if there is no animation" <|
            \_ ->
                animBuilder
                    |> processAndStore
                    |> config.getter "test"
                    |> Expect.equal Nothing
        ]


getEndValue : Test
getEndValue =
    describe "Get the end value of a property"
        [ getEndTests
            { label = "getBackgroundColorEnd"
            , build =
                CustomColor.for "test" BackgroundColor
                    >> CustomColor.to Color.red
                    >> CustomColor.build
            , getter = \animGroup builder -> Property.getCustomColorPropertyEnd animGroup "background-color" builder
            , expectedEnd = Color.red
            }
        , getEndTests
            { label = "getFontColorEnd"
            , build =
                CustomColor.for "test" TextColor
                    >> CustomColor.to Color.red
                    >> CustomColor.build
            , getter = \animGroup builder -> Property.getCustomColorPropertyEnd animGroup "color" builder
            , expectedEnd = Color.red
            }
        , getEndTests
            { label = "getOpacityEnd"
            , build =
                Opacity.for "test"
                    >> Opacity.to 0.5
                    >> Opacity.build
            , getter = Property.getOpacityEnd
            , expectedEnd = 0.5
            }
        , getEndTests
            { label = "getRotateEnd"
            , build =
                Rotate.for "test"
                    >> Rotate.toXYZ 100 200 300
                    >> Rotate.build
            , getter = Property.getRotateEnd
            , expectedEnd = { x = 100, y = 200, z = 300 }
            }
        , getEndTests
            { label = "getScaleEnd"
            , build =
                Scale.for "test"
                    >> Scale.toXYZ 5 6 7
                    >> Scale.build
            , getter = Property.getScaleEnd
            , expectedEnd = { x = 5, y = 6, z = 7 }
            }
        , getEndTests
            { label = "getSizeEnd"
            , build =
                Size.for "test"
                    >> Size.toHW 200 300
                    >> Size.build
            , getter = Property.getSizeEnd
            , expectedEnd = { width = 300, height = 200 }
            }
        , getEndTests
            { label = "getTranslateEnd"
            , build =
                Translate.for "test"
                    >> Translate.toXYZ 100 200 300
                    >> Translate.build
            , getter = Property.getTranslateEnd
            , expectedEnd = { x = 100, y = 200, z = 300 }
            }
        ]


type alias GetRangeTestConfig a =
    { label : String
    , getter : String -> Builder.AnimBuilder -> Maybe { start : Maybe a, end : a }
    , buildWithFrom : Builder.AnimBuilder -> Builder.AnimBuilder
    , expectedStart : a
    , expectedEndWithFrom : a
    , buildWithoutFrom : Builder.AnimBuilder -> Builder.AnimBuilder
    , expectedDefaultStart : Maybe a
    , expectedEnd : a
    }


getRangeTests : GetRangeTestConfig a -> Test
getRangeTests config =
    describe config.label
        [ test "returns range with explicit start" <|
            \_ ->
                animBuilder
                    |> config.buildWithFrom
                    |> processAndStore
                    |> config.getter "test"
                    |> Expect.equal
                        (Just
                            { start = Just config.expectedStart
                            , end = config.expectedEndWithFrom
                            }
                        )
        , test "returns range with default start when no explicit start" <|
            \_ ->
                animBuilder
                    |> config.buildWithoutFrom
                    |> processAndStore
                    |> config.getter "test"
                    |> Expect.equal
                        (Just
                            { start = config.expectedDefaultStart
                            , end = config.expectedEnd
                            }
                        )
        , test "returns Nothing if there is no animation" <|
            \_ ->
                animBuilder
                    |> processAndStore
                    |> config.getter "test"
                    |> Expect.equal Nothing
        ]


getRangeValue : Test
getRangeValue =
    describe "Get the range of a property"
        [ getRangeTests
            { label = "getBackgroundColorRange"
            , buildWithFrom =
                CustomColor.for "test" BackgroundColor
                    >> CustomColor.from (Color.rgba 100 200 50 1)
                    >> CustomColor.to (Color.rgba 255 0 0 1)
                    >> CustomColor.build
            , buildWithoutFrom =
                CustomColor.for "test" BackgroundColor
                    >> CustomColor.to Color.red
                    >> CustomColor.build
            , getter = \animGroup builder -> Property.getCustomColorPropertyRange animGroup "background-color" builder
            , expectedStart = Color.rgba 100 200 50 1
            , expectedEndWithFrom = Color.rgba 255 0 0 1
            , expectedDefaultStart = Just (Color.rgba 255 255 255 0)
            , expectedEnd = Color.red
            }
        , getRangeTests
            { label = "getFontColorRange"
            , buildWithFrom =
                CustomColor.for "test" TextColor
                    >> CustomColor.from (Color.rgba 100 200 50 1)
                    >> CustomColor.to (Color.rgba 255 0 0 1)
                    >> CustomColor.build
            , buildWithoutFrom =
                CustomColor.for "test" TextColor
                    >> CustomColor.to Color.red
                    >> CustomColor.build
            , getter = \animGroup builder -> Property.getCustomColorPropertyRange animGroup "color" builder
            , expectedStart = Color.rgba 100 200 50 1
            , expectedEndWithFrom = Color.rgba 255 0 0 1
            , expectedDefaultStart = Just (Color.rgba 255 255 255 0)
            , expectedEnd = Color.red
            }
        , getRangeTests
            { label = "getOpacityRange"
            , buildWithFrom =
                Opacity.for "test"
                    >> Opacity.from 0.5
                    >> Opacity.to 0
                    >> Opacity.build
            , buildWithoutFrom =
                Opacity.for "test"
                    >> Opacity.to 0
                    >> Opacity.build
            , getter = Property.getOpacityRange
            , expectedStart = 0.5
            , expectedEndWithFrom = 0
            , expectedDefaultStart = Just 1.0
            , expectedEnd = 0
            }
        , getRangeTests
            { label = "getRotateRange"
            , buildWithFrom =
                Rotate.for "test"
                    >> Rotate.fromXYZ 10 20 30
                    >> Rotate.toXYZ 100 200 300
                    >> Rotate.build
            , buildWithoutFrom =
                Rotate.for "test"
                    >> Rotate.toXYZ 100 200 300
                    >> Rotate.build
            , getter = Property.getRotateRange
            , expectedStart = { x = 10, y = 20, z = 30 }
            , expectedEndWithFrom = { x = 100, y = 200, z = 300 }
            , expectedDefaultStart = Just { x = 0, y = 0, z = 0 }
            , expectedEnd = { x = 100, y = 200, z = 300 }
            }
        , getRangeTests
            { label = "getScaleRange"
            , buildWithFrom =
                Scale.for "test"
                    >> Scale.fromXYZ 2 3 4
                    >> Scale.toXYZ 5 6 7
                    >> Scale.build
            , buildWithoutFrom =
                Scale.for "test"
                    >> Scale.toXYZ 5 6 7
                    >> Scale.build
            , getter = Property.getScaleRange
            , expectedStart = { x = 2, y = 3, z = 4 }
            , expectedEndWithFrom = { x = 5, y = 6, z = 7 }
            , expectedDefaultStart = Just { x = 1, y = 1, z = 1 }
            , expectedEnd = { x = 5, y = 6, z = 7 }
            }
        , getRangeTests
            { label = "getSizeRange"
            , buildWithFrom =
                Size.for "test"
                    >> Size.fromHW 50 100
                    >> Size.toHW 200 300
                    >> Size.build
            , buildWithoutFrom =
                Size.for "test"
                    >> Size.toHW 200 300
                    >> Size.build
            , getter = Property.getSizeRange
            , expectedStart = { width = 100, height = 50 }
            , expectedEndWithFrom = { width = 300, height = 200 }
            , expectedDefaultStart = Just { width = 0, height = 0 }
            , expectedEnd = { width = 300, height = 200 }
            }
        , getRangeTests
            { label = "getTranslateRange"
            , buildWithFrom =
                Translate.for "test"
                    >> Translate.fromXYZ 10 20 30
                    >> Translate.toXYZ 100 200 300
                    >> Translate.build
            , buildWithoutFrom =
                Translate.for "test"
                    >> Translate.toXYZ 100 200 300
                    >> Translate.build
            , getter = Property.getTranslateRange
            , expectedStart = { x = 10, y = 20, z = 30 }
            , expectedEndWithFrom = { x = 100, y = 200, z = 300 }
            , expectedDefaultStart = Just { x = 0, y = 0, z = 0 }
            , expectedEnd = { x = 100, y = 200, z = 300 }
            }
        ]
