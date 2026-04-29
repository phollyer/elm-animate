module Anim.Internal.Engine.WAAPI.TestAnimGroup exposing (suite)

import Anim.Extra.TransformOrder as TransformOrder exposing (TransformProperty(..))
import Anim.Internal.Engine.AnimGroups as AnimGroups
import Anim.Internal.Engine.WAAPI.AnimGroup as AnimGroup exposing (AnimationStatus(..))
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Anim.Internal.Engine.WAAPI.AnimGroup"
        [ initTests
        , isRunningTests
        , isCompleteTests
        , setStatusTests
        , bumpVersionsTests
        , progressTests
        , transformOrderTests
        ]


initTests : Test
initTests =
    describe "init"
        [ test "isRunning is False with empty propertyStates" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.isRunning
                    |> Expect.equal False
        , test "isComplete is True with empty propertyStates (vacuously)" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.isComplete
                    |> Expect.equal True
        , test "progress starts at 0.0" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.getProgress
                    |> Expect.equal 0.0
        , test "transform order is non-empty by default" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.getTransformOrder
                    |> List.isEmpty
                    |> Expect.equal False
        ]


isRunningTests : Test
isRunningTests =
    describe "isRunning"
        [ test "returns True when any property is Running" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setPropertyStates
                        (AnimGroups.fromList
                            [ ( "translate", { version = 0, status = Running } )
                            ]
                        )
                    |> AnimGroup.isRunning
                    |> Expect.equal True
        , test "returns False when all properties are Complete" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setPropertyStates
                        (AnimGroups.fromList
                            [ ( "translate", { version = 0, status = Complete } )
                            , ( "opacity", { version = 0, status = Complete } )
                            ]
                        )
                    |> AnimGroup.isRunning
                    |> Expect.equal False
        , test "returns True when at least one of many is Running" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setPropertyStates
                        (AnimGroups.fromList
                            [ ( "translate", { version = 0, status = Complete } )
                            , ( "opacity", { version = 0, status = Running } )
                            ]
                        )
                    |> AnimGroup.isRunning
                    |> Expect.equal True
        , test "returns False when only NotStarted" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setPropertyStates
                        (AnimGroups.fromList
                            [ ( "translate", { version = 0, status = NotStarted } )
                            ]
                        )
                    |> AnimGroup.isRunning
                    |> Expect.equal False
        ]


isCompleteTests : Test
isCompleteTests =
    describe "isComplete"
        [ test "returns True when all properties are Complete" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setPropertyStates
                        (AnimGroups.fromList
                            [ ( "translate", { version = 0, status = Complete } )
                            , ( "opacity", { version = 0, status = Complete } )
                            ]
                        )
                    |> AnimGroup.isComplete
                    |> Expect.equal True
        , test "returns False when any property is Running" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setPropertyStates
                        (AnimGroups.fromList
                            [ ( "translate", { version = 0, status = Running } )
                            , ( "opacity", { version = 0, status = Complete } )
                            ]
                        )
                    |> AnimGroup.isComplete
                    |> Expect.equal False
        , test "returns False when any property is Paused" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setPropertyStates
                        (AnimGroups.fromList
                            [ ( "translate", { version = 0, status = Paused } )
                            ]
                        )
                    |> AnimGroup.isComplete
                    |> Expect.equal False
        , test "returns False when any property is NotStarted" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setPropertyStates
                        (AnimGroups.fromList
                            [ ( "translate", { version = 0, status = NotStarted } )
                            ]
                        )
                    |> AnimGroup.isComplete
                    |> Expect.equal False
        ]


setStatusTests : Test
setStatusTests =
    describe "setStatus"
        [ test "setStatus Running makes isRunning True" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setPropertyStates
                        (AnimGroups.fromList
                            [ ( "translate", { version = 0, status = NotStarted } )
                            ]
                        )
                    |> AnimGroup.setStatus Running
                    |> AnimGroup.isRunning
                    |> Expect.equal True
        , test "setStatus Complete makes isComplete True" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setPropertyStates
                        (AnimGroups.fromList
                            [ ( "translate", { version = 0, status = Running } )
                            , ( "opacity", { version = 0, status = Running } )
                            ]
                        )
                    |> AnimGroup.setStatus Complete
                    |> AnimGroup.isComplete
                    |> Expect.equal True
        , test "setStatus updates all property states" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setPropertyStates
                        (AnimGroups.fromList
                            [ ( "translate", { version = 0, status = NotStarted } )
                            , ( "opacity", { version = 0, status = NotStarted } )
                            ]
                        )
                    |> AnimGroup.setStatus Running
                    |> AnimGroup.getPropertyStates
                    |> AnimGroups.groups
                    |> List.all (\s -> s.status == Running)
                    |> Expect.equal True
        , test "setStatus on empty propertyStates has no effect on isRunning" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setStatus Running
                    |> AnimGroup.isRunning
                    |> Expect.equal False
        ]


bumpVersionsTests : Test
bumpVersionsTests =
    describe "bumpPropertyVersions"
        [ test "bumped property has incremented version" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setPropertyStates
                        (AnimGroups.fromList
                            [ ( "translate", { version = 1, status = Running } )
                            ]
                        )
                    |> AnimGroup.bumpPropertyVersions [ "translate" ]
                    |> AnimGroup.getPropertyStates
                    |> AnimGroups.get "translate"
                    |> Maybe.map .version
                    |> Expect.equal (Just 2)
        , test "bumped property status resets to NotStarted" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setPropertyStates
                        (AnimGroups.fromList
                            [ ( "translate", { version = 0, status = Running } )
                            ]
                        )
                    |> AnimGroup.bumpPropertyVersions [ "translate" ]
                    |> AnimGroup.getPropertyStates
                    |> AnimGroups.get "translate"
                    |> Maybe.map .status
                    |> Expect.equal (Just NotStarted)
        , test "non-bumped properties retain their status" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setPropertyStates
                        (AnimGroups.fromList
                            [ ( "translate", { version = 0, status = Running } )
                            , ( "opacity", { version = 0, status = Complete } )
                            ]
                        )
                    |> AnimGroup.bumpPropertyVersions [ "translate" ]
                    |> AnimGroup.getPropertyStates
                    |> AnimGroups.get "opacity"
                    |> Maybe.map .status
                    |> Expect.equal (Just Complete)
        , test "bumping a non-existent property name has no effect" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setPropertyStates
                        (AnimGroups.fromList
                            [ ( "translate", { version = 2, status = Complete } )
                            ]
                        )
                    |> AnimGroup.bumpPropertyVersions [ "nonexistent" ]
                    |> AnimGroup.getPropertyStates
                    |> AnimGroups.get "translate"
                    |> Maybe.map .version
                    |> Expect.equal (Just 2)
        , test "empty bump list leaves all unchanged" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setPropertyStates
                        (AnimGroups.fromList
                            [ ( "translate", { version = 3, status = Running } )
                            ]
                        )
                    |> AnimGroup.bumpPropertyVersions []
                    |> AnimGroup.getPropertyStates
                    |> AnimGroups.get "translate"
                    |> Maybe.map .version
                    |> Expect.equal (Just 3)
        ]


progressTests : Test
progressTests =
    describe "setProgress / getProgress"
        [ test "setProgress stores value" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setProgress 0.75
                    |> AnimGroup.getProgress
                    |> Expect.within (Expect.Absolute 0.001) 0.75
        , test "progress can be set to 1.0" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setProgress 1.0
                    |> AnimGroup.getProgress
                    |> Expect.equal 1.0
        , test "progress can be set to 0.0" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setProgress 1.0
                    |> AnimGroup.setProgress 0.0
                    |> AnimGroup.getProgress
                    |> Expect.equal 0.0
        ]


transformOrderTests : Test
transformOrderTests =
    describe "transform order"
        [ test "default transform order is set on init" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.getTransformOrder
                    |> List.isEmpty
                    |> Expect.equal False
        , test "setTransformOrder changes the order" <|
            \_ ->
                let
                    customOrder =
                        [ Scale, Translate, Rotate ]
                in
                AnimGroup.init
                    |> AnimGroup.setTransformOrder customOrder
                    |> AnimGroup.getTransformOrder
                    |> Expect.equal customOrder
        , test "setTransformOrder to empty list" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.setTransformOrder []
                    |> AnimGroup.getTransformOrder
                    |> Expect.equal []
        ]
