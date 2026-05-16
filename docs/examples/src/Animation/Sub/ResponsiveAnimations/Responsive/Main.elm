module Animation.Sub.ResponsiveAnimations.Responsive.Main exposing (..)

import Anim.Engine.Sub as Sub exposing (AnimGroupName)
import Anim.Property.Translate as Translate
import Anim.Resize as Resize
import Browser
import Browser.Dom as Dom
import Browser.Events
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (onClick)
import Motion.Easing exposing (Easing(..))
import Process
import Task



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : Sub.AnimState
    , widthPct : WidthPct
    , trackPx : Float
    , animPlayState : AnimPlayState
    }


type AnimPlayState
    = NotStarted
    | Playing
    | Paused


type WidthPct
    = Narrow
    | Normal
    | Widen


widthPctToFloat : WidthPct -> Float
widthPctToFloat pct =
    case pct of
        Narrow ->
            50

        Normal ->
            75

        Widen ->
            100


retargetGroup : String
retargetGroup =
    "retargetBox"


animateGroup : String
animateGroup =
    "animateBox"


{-| One id is enough — both rows share the same inner width because they
sit in the same fixed-width stage. Whichever row we measure tells us the
runway available to both boxes.
-}
trackId : String
trackId =
    "retarget-track"


boxSize : Float
boxSize =
    60


speedPxPerSec : Float
speedPxPerSec =
    200


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            Sub.init
                [ Translate.initX retargetGroup 0
                , Translate.initX animateGroup 0
                ]
      , widthPct = Normal
      , trackPx = 0
      , animPlayState = NotStarted
      }
    , Process.sleep 100
        |> Task.perform (\_ -> OnResize)
    )


animate : AnimGroupName -> Float -> Sub.AnimBuilder mode -> Sub.AnimBuilder mode
animate animGroupName endTarget =
    Sub.loopForever
        >> Sub.alternate
        >> Translate.for animGroupName
        >> Translate.clampX 0 endTarget
        >> Translate.toX endTarget
        >> Translate.easing Linear
        >> Translate.speed speedPxPerSec
        >> Translate.build



-- UPDATE


type Msg
    = GotAnimUpdate Sub.AnimMsg
    | Start
    | Stop
    | SetWidth WidthPct
    | OnResize
    | GotTrack (Result Dom.Error Dom.Element)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAnimUpdate animMsg ->
            let
                ( newState, _ ) =
                    Sub.update animMsg model.animState
            in
            ( { model | animState = newState }, Cmd.none )

        Start ->
            case model.animPlayState of
                NotStarted ->
                    ( startAnimation model, Cmd.none )

                Paused ->
                    ( resumeAnimation model, Cmd.none )

                Playing ->
                    ( model, Cmd.none )

        Stop ->
            ( { model
                | animPlayState =
                    if model.animPlayState == Playing then
                        Paused

                    else
                        model.animPlayState
                , animState =
                    model.animState
                        |> Sub.pause retargetGroup
                        |> Sub.pause animateGroup
              }
            , Cmd.none
            )

        SetWidth pct ->
            ( { model | widthPct = pct }
              -- mimic Browser.onResize event by setting the new width and then dispatching the OnResize msg after a short delay.
            , Process.sleep 100
                |> Task.perform (\_ -> OnResize)
            )

        OnResize ->
            ( model
            , Task.attempt GotTrack <|
                Dom.getElement trackId
            )

        GotTrack (Ok element) ->
            ( handleResize { model | trackPx = element.element.width }
            , Cmd.none
            )

        GotTrack (Err _) ->
            ( model, Cmd.none )


startAnimation : Model -> Model
startAnimation model =
    let
        target =
            model.trackPx - boxSize
    in
    { model
        | animPlayState = Playing
        , animState =
            model.animState
                |> (\s -> Sub.animate s (animate retargetGroup target))
                |> (\s -> Sub.animate s (animate animateGroup target))
    }


resumeAnimation : Model -> Model
resumeAnimation model =
    { model
        | animPlayState = Playing
        , animState =
            model.animState
                |> Sub.resume retargetGroup
                |> Sub.resume animateGroup
    }


{-| The two rows demonstrate the two `Sub.onResize` strategies.

  - The top row uses `Proportional` - the box's progress along the
    track is preserved, so the rhythm of the animation continues to feel
    natural even as the track changes width.
      - The bottom row uses `Retarget` - the box keeps its current pixel
        position, but the leg endpoint follows the new bounds so the
        animation remains edge-to-edge as the track grows or shrinks.

-}
handleResize : Model -> Model
handleResize model =
    case model.animPlayState of
        NotStarted ->
            model

        _ ->
            let
                bounds =
                    { x = Just { min = 0, max = model.trackPx - boxSize }
                    , y = Nothing
                    , z = Nothing
                    }
            in
            { model
                | animState =
                    Sub.onResize model.animState <|
                        Resize.onResize retargetGroup Resize.Proportional bounds
                            >> Resize.onResize animateGroup Resize.Retarget bounds
            }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub.Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.subscriptions GotAnimUpdate model.animState
        , Browser.Events.onResize (\_ _ -> OnResize)
        ]



-- VIEW


view : Model -> Html Msg
view model =
    let
        ctrlBtn label cls msg =
            Html.button
                [ onClick msg
                , class ("ui-action-button " ++ cls)
                , style "background-color" "blue"
                , style "color" "white"
                ]
                [ text label ]
    in
    div
        [ style "text-align" "center" ]
        [ div
            [ class "example-controls"
            , style "margin-top" "5px"
            ]
            [ ctrlBtn "Start" "success" Start
            , ctrlBtn "Stop" "warning" Stop
            ]
        , div
            [ class "example-controls"
            , style "margin-top" "5px"
            ]
            [ ctrlBtn "Narrow" "" (SetWidth Narrow)
            , ctrlBtn "Normal" "" (SetWidth Normal)
            , ctrlBtn "Widen" "" (SetWidth Widen)
            ]
        , div
            [ class "responsive-stage"
            , style "width" (String.fromFloat (widthPctToFloat model.widthPct) ++ "%")
            ]
            [ trackRow "Proportional" trackId retargetGroup proportionalColor model
            , trackRow "Retarget" "" animateGroup clampColor model
            ]
        ]


trackRow : String -> String -> String -> String -> Model -> Html Msg
trackRow label rowId group color model =
    div [ class "responsive-row" ]
        [ div [ class "responsive-row__label" ] [ text label ]
        , div
            ([ class "responsive-row__track"
             , style "background-color" "#f9de10"
             ]
                ++ (if String.isEmpty rowId then
                        []

                    else
                        [ id rowId ]
                   )
            )
            [ div
                (Sub.attributes group model.animState
                    ++ [ style "width" (String.fromFloat boxSize ++ "px")
                       , style "height" (String.fromFloat boxSize ++ "px")
                       , style "background-color" color
                       , style "position" "absolute"
                       , style "top" "0"
                       , style "left" "0"
                       , style "border-radius" "8px"
                       ]
                )
                []
            ]
        ]


proportionalColor : String
proportionalColor =
    "#28a745"


clampColor : String
clampColor =
    "#dc3545"
