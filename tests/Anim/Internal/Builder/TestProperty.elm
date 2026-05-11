module Anim.Internal.Builder.TestProperty exposing (suite)

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
import Dict
import Expect
import Motion.Easing exposing (Easing(..))
import Set
import Shared.TimeSpec exposing (TimeSpec(..))
import Test exposing (..)


animBuilder : Builder.AnimBuilder {}
animBuilder =
    Builder.init []


processAndStore : Builder.AnimBuilder {} -> Builder.AnimBuilder {}
processAndStore builder =
    Builder.addAnimationToHistory (Builder.process builder) builder


suite : Test
suite =
    describe "Internal.Builder.Property"
        [ defaultConfigTests
        , withTests
        , upsertTests
        , propertyGetters
        , continueForTests
        , translateClampTests
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
                , spring = Nothing
                , delay = Nothing
                }

        opacityConfig =
            Builder.OpacityConfig
                { start = Nothing
                , end = InternalOpacity.fromFloat 0.5
                , distance = 0
                , timing = Nothing
                , easing = Nothing
                , spring = Nothing
                , delay = Nothing
                }

        replacementTranslateConfig =
            Builder.TranslateConfig
                { start = Nothing
                , end = InternalTranslate.fromTriple ( 100, 200, 300 )
                , distance = 0
                , timing = Nothing
                , easing = Nothing
                , spring = Nothing
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
    , getter : String -> Builder.AnimBuilder {} -> Maybe a
    , buildWithFrom : Builder.AnimBuilder {} -> Builder.AnimBuilder {}
    , expectedFrom : a
    , buildWithoutFrom : Builder.AnimBuilder {} -> Builder.AnimBuilder {}
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
    , getter : String -> Builder.AnimBuilder {} -> Maybe a
    , build : Builder.AnimBuilder {} -> Builder.AnimBuilder {}
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
    , getter : String -> Builder.AnimBuilder {} -> Maybe { start : Maybe a, end : a }
    , buildWithFrom : Builder.AnimBuilder {} -> Builder.AnimBuilder {}
    , expectedStart : a
    , expectedEndWithFrom : a
    , buildWithoutFrom : Builder.AnimBuilder {} -> Builder.AnimBuilder {}
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



-- ============================================================
-- continueFor
-- ============================================================


{-| Mimic what an Engine's `retarget` does after processing an animation:
push it to history, merge baselines, clear in-progress data, then mark
the named property as currently running on the given group so the next
`continueFor` call inherits timing from history.
-}
finishRetargetBatch : String -> List String -> Builder.AnimBuilder {} -> Builder.AnimBuilder {}
finishRetargetBatch animGroupName runningProps builder =
    builder
        |> processAndStore
        |> Builder.mergeBaselines
        |> Builder.clearAnimData
        |> Builder.injectRunningProperties
            (Dict.singleton animGroupName (Set.fromList runningProps))


{-| Mimic what an Engine's `animate` does after processing an animation
(without injecting any running-property set). `continueFor` after this
behaves like `for`.
-}
finishAnimateBatch : Builder.AnimBuilder {} -> Builder.AnimBuilder {}
finishAnimateBatch builder =
    builder
        |> processAndStore
        |> Builder.mergeBaselines
        |> Builder.clearAnimData


{-| Pull the first TranslateConfig out of the in-progress builder. Used to
inspect what `continueFor` produced before the animation is processed.
-}
firstTranslateConfig : Builder.AnimBuilder {} -> Maybe (Builder.AnimationConfig InternalTranslate.Translate)
firstTranslateConfig builder =
    (Builder.getCurrentAnimGroupConfig builder).properties
        |> List.filterMap
            (\p ->
                case p of
                    Builder.TranslateConfig cfg ->
                        Just cfg

                    _ ->
                        Nothing
            )
        |> List.head


continueForTests : Test
continueForTests =
    let
        firstAnim =
            Translate.for "test"
                >> Translate.toX 100
                >> Translate.speed 50
                >> Translate.easing BounceOut
                >> Translate.delay 200
                >> Translate.build

        afterRetarget =
            firstAnim >> finishRetargetBatch "test" [ "translate" ]

        afterAnimate =
            firstAnim >> finishAnimateBatch
    in
    describe "continueFor"
        [ test "inherits timing from history when retarget reports translate as running" <|
            \_ ->
                animBuilder
                    |> afterRetarget
                    |> (Translate.continueFor "test"
                            >> Translate.toX 300
                            >> Translate.build
                       )
                    |> firstTranslateConfig
                    |> Maybe.andThen .timing
                    |> Expect.equal (Just (Speed 50))
        , test "inherits easing from history when retarget reports translate as running" <|
            \_ ->
                animBuilder
                    |> afterRetarget
                    |> (Translate.continueFor "test"
                            >> Translate.toX 300
                            >> Translate.build
                       )
                    |> firstTranslateConfig
                    |> Maybe.andThen .easing
                    |> Expect.equal (Just BounceOut)
        , test "inherits delay from history when retarget reports translate as running" <|
            \_ ->
                animBuilder
                    |> afterRetarget
                    |> (Translate.continueFor "test"
                            >> Translate.toX 300
                            >> Translate.build
                       )
                    |> firstTranslateConfig
                    |> Maybe.andThen .delay
                    |> Expect.equal (Just 200)
        , test "uses the new target end value" <|
            \_ ->
                animBuilder
                    |> afterRetarget
                    |> (Translate.continueFor "test"
                            >> Translate.toX 300
                            >> Translate.build
                       )
                    |> firstTranslateConfig
                    |> Maybe.map (.end >> InternalTranslate.toRecord)
                    |> Expect.equal (Just { x = 300, y = 0, z = 0 })
        , test "explicit timing override wins over inherited timing" <|
            \_ ->
                animBuilder
                    |> afterRetarget
                    |> (Translate.continueFor "test"
                            >> Translate.toX 300
                            >> Translate.speed 200
                            >> Translate.build
                       )
                    |> firstTranslateConfig
                    |> Maybe.andThen .timing
                    |> Expect.equal (Just (Speed 200))
        , test "explicit easing override wins over inherited easing" <|
            \_ ->
                animBuilder
                    |> afterRetarget
                    |> (Translate.continueFor "test"
                            >> Translate.toX 300
                            >> Translate.easing Linear
                            >> Translate.build
                       )
                    |> firstTranslateConfig
                    |> Maybe.andThen .easing
                    |> Expect.equal (Just Linear)
        , test "behaves like for when there is no history" <|
            \_ ->
                animBuilder
                    |> (Translate.continueFor "test"
                            >> Translate.toX 300
                            >> Translate.build
                       )
                    |> firstTranslateConfig
                    |> Maybe.andThen .timing
                    |> Expect.equal Nothing
        , test "does NOT inherit when called from animate (no running set injected)" <|
            \_ ->
                animBuilder
                    |> afterAnimate
                    |> (Translate.continueFor "test"
                            >> Translate.toX 300
                            >> Translate.build
                       )
                    |> firstTranslateConfig
                    |> Maybe.andThen .timing
                    |> Expect.equal Nothing
        , test "does NOT inherit when retarget reports a different property running" <|
            \_ ->
                animBuilder
                    |> firstAnim
                    |> finishRetargetBatch "test" [ "opacity" ]
                    |> (Translate.continueFor "test"
                            >> Translate.toX 300
                            >> Translate.build
                       )
                    |> firstTranslateConfig
                    |> Maybe.andThen .timing
                    |> Expect.equal Nothing
        , test "for (without continueFor) does NOT inherit timing even with running set" <|
            \_ ->
                animBuilder
                    |> afterRetarget
                    |> (Translate.for "test"
                            >> Translate.toX 300
                            >> Translate.build
                       )
                    |> firstTranslateConfig
                    |> Maybe.andThen .timing
                    |> Expect.equal Nothing
        ]



-- ============================================================
-- TRANSLATE CLAMPS
-- ============================================================


translateClampTests : Test
translateClampTests =
    let
        endRecord builder =
            firstTranslateConfig builder
                |> Maybe.map (.end >> InternalTranslate.toRecord)

        startRecord builder =
            firstTranslateConfig builder
                |> Maybe.andThen .start
                |> Maybe.map InternalTranslate.toRecord
    in
    describe "Translate clamps"
        [ test "clampX clamps explicit toX above max" <|
            \_ ->
                animBuilder
                    |> (Translate.for "test"
                            >> Translate.clampX 0 200
                            >> Translate.toX 500
                            >> Translate.build
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 200, y = 0, z = 0 })
        , test "clampX still clamps when declared after toX" <|
            \_ ->
                animBuilder
                    |> (Translate.for "test"
                            >> Translate.toX 500
                            >> Translate.clampX 0 200
                            >> Translate.build
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 200, y = 0, z = 0 })
        , test "clampX clamps explicit fromX below min" <|
            \_ ->
                animBuilder
                    |> (Translate.for "test"
                            >> Translate.clampX 0 200
                            >> Translate.fromX -100
                            >> Translate.toX 50
                            >> Translate.build
                       )
                    |> startRecord
                    |> Expect.equal (Just { x = 0, y = 0, z = 0 })
        , test "clampX clamps a byX overshoot to the max boundary" <|
            \_ ->
                animBuilder
                    |> (Translate.for "test"
                            >> Translate.clampX 0 200
                            >> Translate.fromX 150
                            >> Translate.byX 100
                            >> Translate.build
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 200, y = 0, z = 0 })
        , test "clampY only clamps the Y axis" <|
            \_ ->
                animBuilder
                    |> (Translate.for "test"
                            >> Translate.clampY 0 100
                            >> Translate.toXY 500 500
                            >> Translate.build
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 500, y = 100, z = 0 })
        , test "clampZ clamps the Z axis" <|
            \_ ->
                animBuilder
                    |> (Translate.for "test"
                            >> Translate.clampZ -10 10
                            >> Translate.toZ 1000
                            >> Translate.build
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 0, y = 0, z = 10 })
        , test "clampX with reversed args (max < min) is normalized" <|
            \_ ->
                animBuilder
                    |> (Translate.for "test"
                            >> Translate.clampX 200 0
                            >> Translate.toX 500
                            >> Translate.build
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 200, y = 0, z = 0 })
        , test "unclampX removes only the X axis clamp" <|
            \_ ->
                animBuilder
                    |> (Translate.for "test"
                            >> Translate.clampX 0 200
                            >> Translate.clampY 0 100
                            >> Translate.unclampX
                            >> Translate.toXY 500 500
                            >> Translate.build
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 500, y = 100, z = 0 })
        , test "clamps are scoped to the active animGroup" <|
            \_ ->
                animBuilder
                    |> (Translate.for "ship"
                            >> Translate.clampX 0 200
                            >> Translate.toX 50
                            >> Translate.build
                       )
                    |> (Translate.for "other"
                            >> Translate.toX 500
                            >> Translate.build
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 500, y = 0, z = 0 })
        , test "no clamps means values pass through unchanged" <|
            \_ ->
                animBuilder
                    |> (Translate.for "test"
                            >> Translate.toX 500
                            >> Translate.build
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 500, y = 0, z = 0 })
        , test "clamps persist across an animate batch (not cleared by clearAnimData)" <|
            \_ ->
                animBuilder
                    |> (Translate.for "test"
                            >> Translate.clampX 0 200
                            >> Translate.toX 100
                            >> Translate.build
                       )
                    |> finishAnimateBatch
                    |> (Translate.for "test"
                            >> Translate.toX 500
                            >> Translate.build
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 200, y = 0, z = 0 })
        , test "out-of-range start snaps to boundary" <|
            \_ ->
                animBuilder
                    |> (Translate.for "test"
                            >> Translate.clampX 0 200
                            >> Translate.fromX 500
                            >> Translate.toX 100
                            >> Translate.build
                       )
                    |> startRecord
                    |> Expect.equal (Just { x = 200, y = 0, z = 0 })
        , test "distance is recomputed from clamped values" <|
            \_ ->
                animBuilder
                    |> (Translate.for "test"
                            >> Translate.clampX 0 200
                            >> Translate.fromX 0
                            >> Translate.toX 1000
                            >> Translate.build
                       )
                    |> firstTranslateConfig
                    |> Maybe.map (.distance >> round)
                    |> Expect.equal (Just 200)
        ]
